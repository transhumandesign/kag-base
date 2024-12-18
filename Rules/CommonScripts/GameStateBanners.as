#define CLIENT_ONLY

Vec2f bannerStart;
Vec2f bannerPos;
Vec2f bannerDest;
f32 frameTime = 0.0f;
const f32 maxTime = 0.6f;

bool minimap = true;

enum BannerType
{
	WARMUP_START = 0,
	GAME_START,
	GAME_END,
	NONE
};

shared class Icon
{
	string file_name;
	Vec2f frame_size;
	int frame;
	Vec2f offset;
	int teamcolor;

	Icon(const string file_name, int frame, Vec2f frame_size, Vec2f offset, int teamcolor)
	{
		this.file_name = file_name;
		this.frame = frame;
		this.frame_size = frame_size;
		this.offset = offset;
		this.teamcolor = teamcolor;
	}
}

shared class Banner
{
	u32 duration;
	string main_text;
	Icon left_icon;
	Icon right_icon;

	int team;
	bool use_team_icon;
	Icon team_icon;

	bool use_two_boxes;
	string secondary_text;

	Banner(u32 duration, string main_text, Icon@ left_icon, Icon@ right_icon, int team, const bool use_team_icon, Icon@ team_icon, const bool use_two_boxes, string secondary_text)
	{
		this.duration = duration;
		this.main_text = main_text;
		this.left_icon = left_icon;
		this.right_icon = right_icon;

		this.team = team;
		this.use_team_icon = use_team_icon;
		if (use_team_icon) this.team_icon = team_icon;

		this.use_two_boxes = use_two_boxes;
		if (use_two_boxes) this.secondary_text = secondary_text;
	}

	Banner(u32 duration, string main_text, Icon@ left_icon, Icon@ right_icon)
	{
		this.duration = duration;
		this.main_text = main_text;
		this.left_icon = left_icon;
		this.right_icon = right_icon;

		this.use_team_icon = false;
		this.use_two_boxes = false;
	}

	Banner(u32 duration, string main_text, Icon@ left_icon, Icon@ right_icon, int team)
	{
		this.duration = duration;
		this.main_text = main_text;
		this.left_icon = left_icon;
		this.right_icon = right_icon;

		this.team = team;
		this.use_team_icon = false;
		this.use_two_boxes = false;
	}

	Banner(u32 duration, string main_text, Icon@ left_icon, Icon@ right_icon, int team, const bool use_team_icon, Icon@ team_icon)
	{
		this.duration = duration;
		this.main_text = main_text;
		this.left_icon = left_icon;
		this.right_icon = right_icon;

		this.team = team;
		this.use_team_icon = use_team_icon;
		if (use_team_icon) this.team_icon = team_icon;

		this.use_two_boxes = false;
	}

	Banner(u32 duration, string main_text, Icon@ left_icon, Icon@ right_icon, const bool use_two_boxes, string secondary_text)
	{
		this.duration = duration;
		this.main_text = main_text;
		this.left_icon = left_icon;
		this.right_icon = right_icon;

		this.use_team_icon = false;

		this.use_two_boxes = use_two_boxes;
		if (use_two_boxes) this.secondary_text = secondary_text;
	}


	void draw(Vec2f center)
	{
		if (!GUI::isFontLoaded("AveriaSerif-Bold_32"))
		{
			string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
			GUI::LoadFont("AveriaSerif-Bold_32", AveriaSerif, 32, true);
		}

		Vec2f tl = center - Vec2f(160, 32);
		Vec2f br = center + Vec2f(160, 32);
		GUI::DrawRectangle(tl, br);
		if (this.use_team_icon)
		{
			GUI::DrawIcon(this.team_icon.file_name, this.team_icon.frame, this.team_icon.frame_size, center - this.team_icon.offset, 1.0f, this.team_icon.teamcolor);
		}
		GUI::DrawIcon(this.left_icon.file_name, this.left_icon.frame, this.left_icon.frame_size, center - this.left_icon.offset, 1.0f, this.left_icon.teamcolor);
		GUI::DrawIcon(this.right_icon.file_name, this.right_icon.frame, this.right_icon.frame_size, center + this.right_icon.offset, 1.0f, this.right_icon.teamcolor);

		GUI::SetFont("AveriaSerif-Bold_32");
		GUI::DrawTextCentered(getTranslatedString(this.main_text), center - Vec2f(0, 4), SColor(255, 255, 255, 255));

		if (this.use_two_boxes)
		{
			string secondary_text = this.secondary_text;
			tl = center - Vec2f(190, 16) + Vec2f(0, 40);
			br = center + Vec2f(190, 16) + Vec2f(0, 40);
			GUI::DrawRectangle(tl, br);

			GUI::SetFont("menu");
			GUI::DrawTextCentered(getTranslatedString(this.secondary_text), center + Vec2f(0, 40), SColor(255, 255, 255, 255));
		}
	}

	void setTeam(int team)
	{
		this.team = team;
		this.left_icon.teamcolor = team;
		this.right_icon.teamcolor = team;
		if (this.use_team_icon)
		{
			this.team_icon = getTeamIcon(team);
		}
	}
};

shared Icon getTeamIcon(int team)
{
	Icon icon;
	icon.file_name = "TeamIcons.png";
	icon.frame_size = Vec2f(96, 96);
	icon.frame = team;
	Vec2f offset = Vec2f(96, 192);
	icon.offset = (team == 0 ? offset : offset + Vec2f(32, 16));
	icon.teamcolor = team;

	return icon;
}

void onRestart(CRules@ this)
{
	ResetBannerInfo(this);
	this.minimap = minimap;

	SetBanner(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (player.isMyPlayer())
	{
		SetBanner(this);
	}
}

void onStateChange(CRules@ this, const u8 oldState)
{
	ResetBannerInfo(this);
	SetBanner(this);
}

void ResetBannerInfo(CRules@ this)
{
	this.set_u8("Animate Banner", BannerType::NONE);
	frameTime = 0.0f;
}

void SetBanner(CRules@ this)
{
	Driver@ driver = getDriver();
	if (driver !is null)
	{
		bannerDest = Vec2f(driver.getScreenWidth()/2, driver.getScreenHeight()/3);
		bannerStart = bannerDest;
		bannerStart.y = 0;
		bannerPos = bannerStart;

		u8 state = this.getCurrentState();

		this.set_bool("Draw Banner", true);
		this.set_u32("Banner Start", getGameTime());

		if (state == GAME_OVER && this.getTeamWon() >= 0)
		{
			this.set_u8("Animate Banner", BannerType::GAME_END);
			this.minimap = false;
		}
		if (state == WARMUP || state == INTERMISSION) // cringe
		{
			this.set_u8("Animate Banner", BannerType::WARMUP_START);
		}
		if (state == GAME)
		{
			this.set_u8("Animate Banner", BannerType::GAME_START);
		}
	}
}