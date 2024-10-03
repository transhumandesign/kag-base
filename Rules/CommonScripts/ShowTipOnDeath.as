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
	if (tips.empty())
	{
		tip = "";
		timer = 0;
	}
	else
	{
		tip = getTranslatedString("Tip: {TIP}").replace("{TIP}", getTranslatedString(tips[getGameTime() % tips.length]));
	}
}

void RenderTip()
{
	s32 scrw = getScreenWidth();
	s32 scrh = getScreenHeight();

	GUI::SetFont("menu");

	Vec2f textDim;
	GUI::GetTextDimensions(tip, textDim);

	s32 offset = 200;

	f32 wave = Maths::Sin(getGameTime() / 10.0f) * 3.0f;
	Vec2f tl(scrw / 2 - textDim.x / 2, scrh - textDim.y - offset + wave);
	Vec2f br(scrw / 2 + textDim.x / 2, scrh - offset);
	Vec2f padding(10, 10);

	GUI::DrawButtonPressed(tl - padding, tl + textDim + padding);
	GUI::DrawText(tip, tl, br, color_white, true, true, false);
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
	if (g_videorecording || !u_showtutorial)
		return;

	if (can_show)
	{
		RenderTip();
	}
}
