#define CLIENT_ONLY

Vec2f bannerStart = Vec2f_zero;
Vec2f bannerPos = Vec2f_zero;
Vec2f bannerDest = Vec2f_zero;
f32 frameTime = 0;
const f32 maxTime = 0.6f;

bool minimap = true;

const u32 winBannerDuration = 8 * getTicksASecond();
const u32 buildBannerDuration = 5 * getTicksASecond();
const u32 gameBannerDuration = 5 * getTicksASecond();

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

void onTick(CRules@ this)
{
	if (this.get_string("Animate Banner") != "none" && this.get_u32("Banner End") < getGameTime())
	{
		ResetBannerInfo(this);
	}
}

void onStateChange(CRules@ this, const u8 oldState)
{
	ResetBannerInfo(this);
	SetBanner(this);
}

void onRender(CRules@ this)
{
	if (this.get_string("Animate Banner") != "none")
	{
		Driver@ driver = getDriver();
		if (driver !is null)
		{
			if (bannerPos != bannerDest)
			{
				frameTime = Maths::Min(frameTime + (getRenderDeltaTime() / maxTime), 1);

				bannerPos = Vec2f_lerp(bannerStart, bannerDest, frameTime);
			}

			if (this.get_string("Animate Banner") == "win") 
			{
				DrawWinBanner(bannerPos, this.getTeamWon());
				this.SetGlobalMessage("");
			}
			// todo: implement tth versions (alternatively remove TTH)
			else if (this.get_string("Animate Banner") == "build" && (this.gamemode_name == "CTF" || this.gamemode_name == "SmallCTF")
			{
				DrawBuildBanner(bannerPos);
			} 
			else if (this.get_string("Animate Banner") == "game" && (this.gamemode_name == "CTF" || this.gamemode_name == "SmallCTF")
			{
				CPlayer@ p = getLocalPlayer();
				int team = p is null ? 0 : p.getTeamNum();
				// show flags of enemy team colour
				if (team == 0) team = 1;
				else team = 0;

				DrawGameBanner(bannerPos, team);
			} 
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (getLocalPlayer() !is null && getLocalPlayer().getUsername() == player.getUsername())
	{
		SetBanner(this);
	}
}

void ResetBannerInfo(CRules@ this)
{
	this.set_string("Animate Banner", "none");
	bannerPos = Vec2f_zero;
	bannerDest = Vec2f_zero;
	frameTime = 0;
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

		if (this.isGameOver() && this.getTeamWon() >= 0)
		{
			this.set_u32("Banner End", getGameTime() + winBannerDuration);
			this.set_string("Animate Banner", "win");
			this.minimap = false;
		}
		if (this.getCurrentState() == WARMUP || this.getCurrentState() == INTERMISSION) // cringe
		{
			this.set_u32("Banner End", getGameTime() + buildBannerDuration);
			this.set_string("Animate Banner", "build");
		}
		if (this.getCurrentState() == GAME)
		{
			this.set_u32("Banner End", getGameTime() + gameBannerDuration);
			this.set_string("Animate Banner", "game");
		}
	}
}

void DrawWinBanner(Vec2f center, int team)
{
	string teamName = "Blue";
	Vec2f offset = Vec2f_zero;
	if (team == 1)
	{
		teamName = "Red";
		offset = Vec2f(-32, -16);
	}

	Vec2f tl = center - Vec2f(160, 32);
	Vec2f br = center + Vec2f(160, 32);
	GUI::DrawRectangle(tl, br);
	GUI::DrawIcon("TeamIcons.png", team, Vec2f(96, 96), center - Vec2f(96, 192) + offset, 1.0f, team);
	GUI::DrawIcon("MenuItems.png", 31, Vec2f(32, 32), center - Vec2f(192, 32), 1.0f, team);
	GUI::DrawIcon("MenuItems.png", 31, Vec2f(32, 32), center + Vec2f(128, -32), 1.0f, team);

	GUI::SetFont("AveriaSerif-Bold_32");
	string text = teamName + " team wins";
	GUI::DrawTextCentered(getTranslatedString(text), center, SColor(255, 255, 255, 255));
}

void DrawBuildBanner(Vec2f center)
{
	string text = "Build the base!";

	Vec2f tl = center - Vec2f(160, 32);
	Vec2f br = center + Vec2f(160, 32);
	GUI::DrawRectangle(tl, br);
	GUI::DrawIcon("InteractionIcons.png", 21, Vec2f(32, 32), center - Vec2f(160, 32), 1.0f);
	GUI::DrawIcon("InteractionIcons.png", 21, Vec2f(32, 32), center + Vec2f(96, -32), 1.0f);

	GUI::SetFont("AveriaSerif-Bold_32");
	GUI::DrawTextCentered(getTranslatedString(text), center - Vec2f(0, 4), SColor(255, 255, 255, 255));

	tl = center - Vec2f(190, 16) + Vec2f(0, 40);
	br = center + Vec2f(190, 16) + Vec2f(0, 40);
	GUI::DrawRectangle(tl, br);

	text = "Increased build speed and resupplies";

	GUI::SetFont("menu");
	GUI::DrawTextCentered(getTranslatedString(text), center + Vec2f(0, 40), SColor(255, 255, 255, 255));
}

void DrawGameBanner(Vec2f center, int team)
{
	string text = "Capture the flag!";

	Vec2f tl = center - Vec2f(160, 32);
	Vec2f br = center + Vec2f(160, 32);
	GUI::DrawRectangle(tl, br);
	GUI::DrawIcon("BannerIcons.png", 0, Vec2f(32, 32), center - Vec2f(184, 32), 1.0f, team);
	GUI::DrawIcon("BannerIcons.png", 1, Vec2f(32, 32), center + Vec2f(120, -32), 1.0f, team);

	GUI::SetFont("AveriaSerif-Bold_32");
	GUI::DrawTextCentered(getTranslatedString(text), center, SColor(255, 255, 255, 255));
}