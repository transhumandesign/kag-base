#define CLIENT_ONLY

bool dead = false;
bool been_alive = false;
bool can_show = false;
u32 timer = 0;
u32 show_time;
string tip = "";
string[] tips;

///////////////////////////////////////
// tip system methods
///////////////////////////////////////

void LoadTips()
{
	tips.clear();

	//open cfg
	ConfigFile cfg;
	if (cfg.loadFile("HelpfulDeathTips.cfg"))
	{
		cfg.readIntoArray_string(tips, "tips");
		show_time = cfg.read_u32("show_time", 200);
	}
	else
	{
		show_time = 200;
	}
}

void SelectRandomTip()
{
	tip = "Tip: ";
	if (tips.length == 0)
	{
		tip = "";
		timer = 0;
	}
	else
	{
		tip += tips[getGameTime() % tips.length];
	}
}

void RenderTip()
{
	s32 scrw = getScreenWidth();
	s32 scrh = getScreenHeight();

	s32 w = Maths::Min(800, scrw - 40);
	s32 h = 40;

	s32 offset = 200;

	Vec2f tl(scrw / 2 - w / 2, scrh - h - offset);
	Vec2f br(scrw / 2 + w / 2, scrh - offset);

	GUI::DrawButton(tl, br);
	GUI::DrawText(tip, tl + Vec2f(10, 10), br - Vec2f(10, 10), color_white, true, true, false);
}

///////////////////////////////////////
// rules impl
///////////////////////////////////////

void Reset(CRules@ this)
{
	dead = false;
	been_alive = false;
	can_show = false;

	LoadTips();
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}

void onTick(CRules@ this)
{
	if (!u_showtutorial)
		return;

	CBlob@ b = getLocalPlayerBlob();
	if (b is null || b.hasTag("dead"))
	{
		if (!dead)
		{
			dead = true;
			timer = show_time;
			SelectRandomTip();
		}
	}
	else
	{
		dead = false;
		been_alive = true;
	}

	if (dead && timer > 0)
	{
		timer--;
	}

	CPlayer@ player = getLocalPlayer();
	bool spectator = player is null || player.getTeamNum() == this.getSpectatorTeamNum();
	if (spectator)
	{
		been_alive = false;
	}
	else
	{
		can_show = been_alive && dead && timer > 0;
	}
}

void onRender(CRules@ this)
{
	if (!u_showtutorial)
		return;

	if (can_show)
	{
		RenderTip();
	}
}