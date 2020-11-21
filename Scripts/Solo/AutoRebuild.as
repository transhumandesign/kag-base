// Explanations are in AutoRebuild.cfg
bool enabled;
bool check_x_tick;
s32 check_timer;
bool check_focus;

bool focused = false;

void onInit(CRules@ this)
{
	onReload(this);
}

void onReload(CRules@ this)
{
	ConfigFile cfg = ConfigFile(CFileMatcher("AutoRebuild.cfg").getFirst());

	enabled = cfg.read_bool("enabled", true);
	check_timer = cfg.read_s32("check_timer", 0);
	check_focus = cfg.read_bool("check_focus", true);

	if (!enabled)
	{
		removeMe(this);
	}    
}

void onTick(CRules@ this)
{
	if (check_focus)
	{
		if (isWindowFocused() && isWindowFocused() != focused)
		{
			rebuild();
		}

		focused = isWindowFocused();
	}

	if (check_timer > 0 && getGameTime() % check_timer == 0)
	{
		rebuild();
	}
}

void removeMe(CRules@ this)
{
	this.RemoveScript("AutoRebuild.as");
}