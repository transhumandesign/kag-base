#define CLIENT_ONLY;

#include "GameStateBanners.as";

const u32 waitForPlayersBannerDuration = -1;  // no duration stated. The banner is present untill the players join
const u32 gameStartBannerDuration = 5;
const u32 gameTieBannerDuration = 5;
const u32 gameTimeEndBannerDuration = 5;
const u32 winBannerDuration = 5;

Banner@ getWaitForPlayersBanner()
{
	u32 duration = waitForPlayersBannerDuration;
	string main_text = "Not enough players to start the game..."; // todo: adjust local translations getTranslatedString()
	string secondary_text = "Please wait for someone to join...";

	Icon@ left_icon = Icon("InteractionIcons.png", 29, Vec2f(32, 32), Vec2f(250, 32), 0);
	Icon@ right_icon = Icon("InteractionIcons.png", 29, Vec2f(32, 32), Vec2f(186, -32), 0);

	Banner banner(duration, main_text, left_icon, right_icon, true, secondary_text, 240);

	return banner;
}

Banner@ getGameStartBanner(int team=0)
{
	u32 duration = gameStartBannerDuration * getTicksASecond();
	string main_text = "Fight!";

	Icon@ left_icon = Icon("BannerIconTDM.png", 0, Vec2f(32, 32), Vec2f(160, 32), team);
	Icon@ right_icon = Icon("BannerIconTDM.png", 0, Vec2f(32, 32), Vec2f(96, -32), team);

	Banner banner(duration, main_text, left_icon, right_icon);

	return banner;
}

Banner@ getTieBanner()
{
	u32 duration = gameTieBannerDuration * getTicksASecond();
	string main_text = "It's a tie!";

	Icon@ left_icon = Icon("MenuItems.png", 18, Vec2f(32, 32), Vec2f(160, 32), 0);  // 17 is cool too...
	Icon@ right_icon = Icon("MenuItems.png", 18, Vec2f(32, 32), Vec2f(96, -32), 0);

	Banner banner(duration, main_text, left_icon, right_icon);

	return banner;
}

Banner@ getTimeEndBanner()
{
	u32 duration = gameTimeEndBannerDuration * getTicksASecond();
	string main_text = "Time is up!";
	string secondary_text = "It's a tie!";

	Icon@ left_icon = Icon("MenuItems.png", 18, Vec2f(32, 32), Vec2f(160, 32), 0);  // 17 is cool too...
	Icon@ right_icon = Icon("MenuItems.png", 18, Vec2f(32, 32), Vec2f(96, -32), 0);

	Banner banner(duration, main_text, left_icon, right_icon, true, secondary_text);

	return banner;
}

Banner@ getWinBanner(int team=0)
{
	u32 duration = winBannerDuration * getTicksASecond();
	string main_text = "{TEAM} team wins";

	Icon@ team_icon = getTeamIcon(team);
	Icon@ left_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(160, 32), team);
	Icon@ right_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(96, -32), team);

	Banner banner(duration, main_text, left_icon, right_icon, team, true, team_icon);

	return banner;
}

Banner@[] banners;

void onInit(CRules@ this)
{
	// banners have to be in the exact same order as the BannerType enum aliases... (dumb af)
	banners.push_back(getWaitForPlayersBanner());
	banners.push_back(getGameStartBanner());
	banners.push_back(getWinBanner());
	banners.push_back(getTieBanner());
	banners.push_back(getTimeEndBanner());
}

void onReload(CRules@ this)
{
	banners.clear();
	onInit(this);
}

void onTick(CRules@ this)
{
	if (this.get_bool("Draw Banner"))
	{
		u8 banner_type = this.get_u8("Animate Banner");
		
		if (banner_type >= banners.length)	
			return;
		
		Banner@ banner = banners[banner_type];

		// TODO: Check if there is at least 1v1. If there is, don't display the getWaitForPlayersBanner
		// TODO: this.set_bool("is_time_finished", true); Not working
		// TODO: Wrong swords color while "Fight!" banner
		// TODO: Line 14 TDM_Banners.as fix translation and adjust the locals
		// TODO: Test CTF and other modes potentially
		if (banner_type == BannerType::GAME_START)
		{
			CPlayer@ p = getLocalPlayer();
			int team = (p is null ? 0 : p.getTeamNum());
			// show flags of enemy team colour
			team ^= 1;

			banner.setTeam(team);
		}
		else if (banner_type == BannerType::GAME_END)
		{
			banner.setTeam(this.getTeamWon());
			banner.main_text = banner.main_text.replace("{TEAM}", (banner.team == 0 ? getTranslatedString("Blue") : getTranslatedString("Red")));
		}

		if ((this.get_u32("Banner Start") + banner.duration < getGameTime() || banner is null) && banner.duration != -1) // banner just finished
		{
			this.set_bool("Draw Banner", false);
			onReload(this);
		}
	}
}

void onRender(CRules@ this)
{
	if (this.get_bool("Draw Banner"))
	{
		u8 banner_type = this.get_u8("Animate Banner");

		Driver@ driver = getDriver();
		if (driver !is null)
		{
			if (bannerPos != bannerDest)
			{
				frameTime = Maths::Min(frameTime + (getRenderDeltaTime() / maxTime), 1);

				bannerPos = Vec2f_lerp(bannerStart, bannerDest, frameTime);
			}

			if (banner_type >= banners.length)
				return;

			Banner@ banner = banners[banner_type];

			if (banner !is null)
			{
				banner.draw(bannerPos);
			}
		}
	}
}