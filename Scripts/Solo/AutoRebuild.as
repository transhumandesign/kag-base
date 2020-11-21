const bool enabled = true; // if disabled the script will be removed
const uint checkTimer = 90; // 30 ticks in a second, default is 90 (3 seconds)

void onInit(CRules@ this)
{
    print("Auto rebuild has been enabled.\nTo disable/edit this check AutoRebuild.as.\nCan cause stutters.");
}

void onTick(CRules@ this)
{
    if (getGameTime() % checkTimer == 0)
    {
        rebuild();
    }

    if (!enabled)
    {
        getRules().RemoveScript("AutoRebuild.as");
    }
}