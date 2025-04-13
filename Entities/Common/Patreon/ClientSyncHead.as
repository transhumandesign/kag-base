#include "CustomHeads.as";

// DUMB HACK:
// getLocalPlayer is null in onInit(Crules@), 
// and onNewPlayerJoin does not run on the client that joins
// I need to have player send off their head on join
void onTick(CRules@ this)
{
    if (isClient() && getLocalPlayer() != null)
    {
        Client_SendHead(this);
        this.RemoveScript("ClientSyncHead.as");
    }
}