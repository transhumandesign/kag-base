#define CLIENT_ONLY

Vec2f bannerStart;
Vec2f bannerPos;
Vec2f bannerDest;
f32 frameTime = 0.0f;
const f32 maxTime = 0.6f;

bool minimap = true;

const u32 winBannerDuration = 8 * getTicksASecond();
const u32 buildBannerDuration = 5 * getTicksASecond();
const u32 gameBannerDuration = 5 * getTicksASecond();

namespace Banner
{
	enum State
	{
		none = 0,
		build,
		game,
		win
	};
}

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

	bool use_team_icon;
	Icon team_icon;

	bool use_two_boxes;
	string secondary_text;
};

Icon getTeamIcon(int team)
{
	Icon icon;
	icon.file_name = "TeamIcons.png";
	icon.frame_size = Vec2f(96, 96);
	icon.frame = team;
	Vec2f offset = Vec2f(96, 192);
	icon.offset = (team == 0 ? offset : offset + Vec2f(-32, -16));
	icon.teamcolor = team;

	return icon;
}

void onInit(CRules@ this)
{
	if (!GUI::isFontLoaded("AveriaSerif-Bold_32"))
	{
		string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("AveriaSerif-Bold_32", AveriaSerif, 32, true);
	}

	minimap = this.minimap;
	onRestart(this);
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

void onTick(CRules@ this)
{
	if (this.get_u8("Animate Banner") != Banner::none && this.get_u32("Banner End") < getGameTime())
	{
		ResetBannerInfo(this);
	}
}

void ResetBannerInfo(CRules@ this)
{
	this.set_u8("Animate Banner", Banner::none);
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

		if (state == GAME_OVER && this.getTeamWon() >= 0)
		{
			this.set_u32("Banner End", getGameTime() + winBannerDuration);
			this.set_u8("Animate Banner", Banner::win);
			this.minimap = false;
		}
		if (state == WARMUP || state == INTERMISSION) // cringe
		{
			this.set_u32("Banner End", getGameTime() + buildBannerDuration);
			this.set_u8("Animate Banner", Banner::build);
		}
		if (state == GAME)
		{
			this.set_u32("Banner End", getGameTime() + gameBannerDuration);
			this.set_u8("Animate Banner", Banner::game);
		}
	}
}

void DrawBanner(Vec2f center, Banner@ banner)
{
	Vec2f tl = center - Vec2f(160, 32);
	Vec2f br = center + Vec2f(160, 32);
	GUI::DrawRectangle(tl, br);
	if (banner.use_team_icon)
	{
		GUI::DrawIcon(banner.team_icon.file_name, banner.team_icon.frame, banner.team_icon.frame_size, center - banner.team_icon.offset, 1.0f, banner.team_icon.teamcolor);
	}
	GUI::DrawIcon(banner.left_icon.file_name, banner.left_icon.frame, banner.left_icon.frame_size, center - banner.left_icon.offset, 1.0f, banner.left_icon.teamcolor);
	GUI::DrawIcon(banner.right_icon.file_name, banner.right_icon.frame, banner.right_icon.frame_size, center + banner.right_icon.offset, 1.0f, banner.right_icon.teamcolor);

	GUI::SetFont("AveriaSerif-Bold_32");
	GUI::DrawTextCentered(getTranslatedString(banner.main_text), center - Vec2f(0, 4), SColor(255, 255, 255, 255));

	if (banner.use_two_boxes)
	{
		string secondary_text = banner.secondary_text;
		tl = center - Vec2f(190, 16) + Vec2f(0, 40);
		br = center + Vec2f(190, 16) + Vec2f(0, 40);
		GUI::DrawRectangle(tl, br);

		GUI::SetFont("menu");
		GUI::DrawTextCentered(getTranslatedString(banner.secondary_text), center + Vec2f(0, 40), SColor(255, 255, 255, 255));
	}
}