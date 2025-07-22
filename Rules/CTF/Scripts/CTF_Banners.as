#define CLIENT_ONLY;

#include "GameStateBanners.as";

const u32 buildBannerDuration = 5;
const u32 gameBannerDuration = 5;
const u32 winBannerDuration = 8;

Banner@ getBuildBanner()
{
	u32 duration = buildBannerDuration * getTicksASecond();
	string text = "Build defenses!";
	string secondary_text = "Increased build speed and resupplies";

	Icon@ left_icon = Icon("InteractionIcons.png", 21, Vec2f(32, 32), Vec2f(160, 32), 0);
	Icon@ right_icon = Icon("InteractionIcons.png", 21, Vec2f(32, 32), Vec2f(96, -32), 0);

	Banner banner(duration, text, left_icon, right_icon, true, secondary_text);

	return banner;
}

Banner@ getGameBanner(int team=0)
{
	u32 duration = gameBannerDuration * getTicksASecond();
	string text = "Capture the flag!";

	Icon@ left_icon = Icon("BannerIcons.png", 0, Vec2f(32, 32), Vec2f(184, 32), team);
	Icon@ right_icon = Icon("BannerIcons.png", 1, Vec2f(32, 32), Vec2f(120, -32), team);

	Banner banner(duration, text, left_icon, right_icon);

	return banner;
}

Banner@ getWinBanner(int team=0)
{
	u32 duration = winBannerDuration * getTicksASecond();
	string text = "{TEAM} team wins!";
	string teamName = (team == 0 ? "Blue" : "Red");
	string actual_text = teamName + " team wins";

	Icon@ team_icon = getTeamIcon(team);
	Icon@ left_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(192, 32), team);
	Icon@ right_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(128, -32), team);

	Banner banner(duration, text, left_icon, right_icon, team, true, team_icon);

	return banner;
}

Banner@[] banners;

void onInit(CRules@ this)
{
	banners.push_back(getBuildBanner());
	banners.push_back(getGameBanner());
	banners.push_back(getWinBanner());
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

		if (this.get_u32("Banner Start") + banner.duration < getGameTime() || banner is null) // banner just finished
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