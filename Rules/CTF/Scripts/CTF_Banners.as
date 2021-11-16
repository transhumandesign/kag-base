#define CLIENT_ONLY;

#include "GameStateBanners.as";

Banner current_banner;

Banner@ getBuildBanner()
{
	string text = "Build defenses!";
	string secondary_text = "Increased build speed and resupplies";

	Icon left_icon = Icon("InteractionIcons.png", 21, Vec2f(32, 32), Vec2f(160, 32), 0);
	Icon right_icon = Icon("InteractionIcons.png", 21, Vec2f(32, 32), Vec2f(96, -32), 0);

	Banner banner;

	banner.main_text = text;
	banner.left_icon = left_icon;
	banner.right_icon = right_icon;

	banner.use_team_icon = false;

	banner.use_two_boxes = true;
	banner.secondary_text = secondary_text;

	return banner;
}

Banner@ getGameBanner(int team)
{
	string text = "Capture the flag!";

	Icon left_icon = Icon("BannerIcons.png", 0, Vec2f(32, 32), Vec2f(184, 32), team);
	Icon right_icon = Icon("BannerIcons.png", 1, Vec2f(32, 32), Vec2f(120, -32), team);

	Banner banner;

	banner.main_text = text;
	banner.left_icon = left_icon;
	banner.right_icon = right_icon;

	banner.use_team_icon = false;
	banner.use_two_boxes = false;

	return banner;
}

Banner@ getWinBanner(int team)
{
	string teamName = (team == 0 ? "Blue" : "Red");
	Vec2f offset = (team == 0 ? Vec2f_zero : Vec2f(-32, -16));
	string text = teamName + " team wins";

	Icon team_icon = getTeamIcon(team);
	Icon left_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(192, 32), team);
	Icon right_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(128, -32), team);

	Banner banner;

	banner.main_text = text;
	banner.left_icon = left_icon;
	banner.right_icon = right_icon;

	banner.use_team_icon = true;
	banner.team_icon = team_icon;

	banner.use_two_boxes = false;

	return banner;
}

void onRender(CRules@ this)
{
	u8 banner_type = this.get_u8("Animate Banner");

	if (banner_type != Banner::none)
	{
		Driver@ driver = getDriver();
		if (driver !is null)
		{
			if (bannerPos != bannerDest)
			{
				frameTime = Maths::Min(frameTime + (getRenderDeltaTime() / maxTime), 1);

				bannerPos = Vec2f_lerp(bannerStart, bannerDest, frameTime);
			}

			if (banner_type == Banner::win) 
			{
				Banner@ banner = getWinBanner(this.getTeamWon());
				DrawBanner(bannerPos, banner);
				this.SetGlobalMessage("");
			}
			else if (banner_type == Banner::build)
			{
				Banner@ banner = getBuildBanner();
				DrawBanner(bannerPos, banner);
			} 
			else if (banner_type == Banner::game)
			{
				CPlayer@ p = getLocalPlayer();
				int team = p is null ? 0 : p.getTeamNum();
				// show flags of enemy team colour
				if (team == 0) team = 1;
				else team = 0;

				Banner@ banner = getGameBanner(team);
				DrawBanner(bannerPos, banner);
			}
		}
	}
}