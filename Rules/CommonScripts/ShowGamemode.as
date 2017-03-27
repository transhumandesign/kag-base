#define CLIENT_ONLY

int TIME = 400;
int showTime = TIME;

void Reset(CRules@ this)
{
	showTime = TIME;
}

void onInit(CRules@ this)
{
	Reset(this);
}

void onRender(CRules@ this)
{
	if (showTime > 0)
	{
		showTime--;
		Vec2f middle(getScreenWidth() / 2.0f, showTime < 120 ? showTime : 120.0f);

		//gamemode info
		const string name = this.gamemode_name;
		const string info = this.gamemode_info;
		const string servername = getNet().joined_servername;

		//build display strings
		string display = "  Gamemode: " + name;

		if (name != info && info != "")
			display += "\n\n " + info;

		display += "\n  Server: " + servername + "\n";

		GUI::SetFont("menu");
		GUI::DrawText(display ,
		              Vec2f(middle.x - 140.0f, middle.y), Vec2f(middle.x + 140.0f, middle.y + 60.0f), color_black, true, true, true);
	}
}
