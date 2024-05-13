#define CLIENT_ONLY;

#include "GameStateBanners.as";

const u32 waitForPlayersBannerDuration = -1;  // no duration stated. The banner is present untill the players join
const u32 gameStartBannerDuration = 2; // less than CTF as TDM is more fast paced
const u32 gameTieBannerDuration = 5;
const u32 winBannerDuration = 5;

Banner@ getWaitForPlayersBanner()
{
	u32 duration = waitForPlayersBannerDuration;
	string main_text = getTranslatedString("Not enough players in each team for the game to start.");
	string secondary_text = getTranslatedString("Please wait for someone to join...");

	Icon@ left_icon = Icon("InteractionIcons.png", 29, Vec2f(32, 32), Vec2f(340, 32), 0);
	Icon@ right_icon = Icon("InteractionIcons.png", 29, Vec2f(32, 32), Vec2f(276, -32), 0);

	Banner banner(duration, main_text, left_icon, right_icon, true, secondary_text, 330);

	return banner;
}

Banner@ getGameStartBanner(int team=0)
{
	u32 duration = gameStartBannerDuration * getTicksASecond();
	string main_text = "Go Fight!";

	Icon@ left_icon = Icon("BannerIconTDM.png", 0, Vec2f(32, 32), Vec2f(160, 32), team);
	Icon@ right_icon = Icon("BannerIconTDM.png", 0, Vec2f(32, 32), Vec2f(96, -32), team);

	Banner banner(duration, main_text, left_icon, right_icon);

	return banner;
}

Banner@ getTieBanner()
{
	u32 duration = gameTieBannerDuration * getTicksASecond();
	string main_text = "It's a tie!";

	Icon@ left_icon = Icon("BannerIconTDMTie.png", 0, Vec2f(32, 32), Vec2f(160, 32), 0);
	Icon@ right_icon = Icon("BannerIconTDMTie.png", 1, Vec2f(32, 32), Vec2f(96, -32), 0);

	Banner banner(duration, main_text, left_icon, right_icon);

	return banner;
}

Banner@ getWinBanner(int team=0)
{
	u32 duration = winBannerDuration * getTicksASecond();
	string main_text = "{TEAM} team wins!";

	Icon@ team_icon = getTeamIcon(team);
	Icon@ left_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(160, 32), team);
	Icon@ right_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(96, -32), team);

	Banner banner(duration, main_text, left_icon, right_icon, team, true, team_icon);

	return banner;
}

void checkTeamsGotEnoughPlayers(CRules@ this)
{
	// remove banner that appears at the begining for 1v1 etc.
	int playerCount = getPlayerCount();
	bool blue_has_players = false;
	bool red_has_players = false;
	for (uint8 i = 0; i < playerCount; ++i)
	{
		CPlayer@ p = getPlayer(i);
		if (p is null) continue;
		if (p.getTeamNum() == 0)
			blue_has_players = true;
		if (p.getTeamNum() == 1)
			red_has_players = true;
		if (blue_has_players && red_has_players)
		{
			this.set_bool("suspend_wait_for_players_banner", true);
			break;
		}
	}
}

void setBannerTeam(Banner@ banner)
{
	// show flags with player team colour
	CPlayer@ p = getLocalPlayer();
	int team = (p is null ? 0 : p.getTeamNum());
	banner.setTeam(team);
}

void setMainTextTeam(CRules@ this, Banner@ banner)
{
	banner.setTeam(this.getTeamWon());
	banner.main_text = banner.main_text.replace("{TEAM}", (banner.team == 0 ? getTranslatedString("Blue") : getTranslatedString("Red")));
}

Banner@[] banners;

void onInit(CRules@ this)
{
	// banners have to be in the exact same order as the BannerType enum aliases
	banners.push_back(getWaitForPlayersBanner());
	banners.push_back(getGameStartBanner());
	banners.push_back(getWinBanner());
	banners.push_back(getTieBanner());
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

		if (banner_type == BannerType::WARMUP_START)
			checkTeamsGotEnoughPlayers(this);

		else if (banner_type == BannerType::GAME_START)
		{
			this.set_bool("suspend_wait_for_players_banner", false);
			setBannerTeam(banner);
		}
		else if (banner_type == BannerType::GAME_END)
		{
			setMainTextTeam(this, banner);
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
	if (this.get_bool("Draw Banner") && !(this.getCurrentState() == WARMUP && this.get_bool("suspend_wait_for_players_banner")))
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