// This script is used to keep a hack in a single place
// HACK: player is null on the client in onInit
// and may be null for the first few ticks
//
// I need a way to sync the client head ONCE, but we need to know
// our player stats before we can do that
#include "CustomHeadData.as";

void onTick(CRules@ this)
{
    if (getLocalPlayer() != null)
    {
        Client_SendHead(this);
        this.RemoveScript("CustomHeadInitialSync.as");
    }
}
