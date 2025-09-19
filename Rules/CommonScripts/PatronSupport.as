void onInit(CRules@ this)
{
    if (isServer()) {
        this.AddScript("PatreonJoinSlots.as");
    }

    this.AddScript("CustomHeads.as");
}