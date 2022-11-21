// Spike.as

void onInit(CSprite@ this)
{
	CRules@ rules = getRules();
	if (!rules.hasScript("ToggleBloodyStuff.as"))
	{
		rules.AddScript("ToggleBloodyStuff.as");
	}
}