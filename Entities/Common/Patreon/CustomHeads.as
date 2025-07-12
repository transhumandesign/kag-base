// The goal of this script is as follows:
// # Client
// - Attempt to sync on startup (by adding 'CustomHeadInitialSync.as')
// - Net Sync - Store any custom heads, update their current blob 
// - Net Rm - Remove any matching store heads, update their current blob
//
// # Server
// - Validate any incoming heads
// - Sync all known heads on new player join
// - Relay all cmds to the clients (if its valid)
#include "CustomHeadData.as";
#include "RunnerHead.as";

void onInit(CRules@ this)
{
    // Used by both client & server
    this.addCommandID(HEAD_SYNC_CMD);
    this.addCommandID(HEAD_RM_CMD);
    
    ResetHeadStorage(this);

    if (isClient())
        this.AddScript("CustomHeadInitialSync.as");
}

void onReload(CRules@ this)
{
    ResetHeadStorage(this);

    Client_SendHead(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    if (isServer())
        SyncCurrentHeadStorage(this, player);
}

void onTick(CRules@ this)
{
    if (getGameTime() % 150 != 0)
        return;

    const bool hasSynced = this.hasTag(HeadSyncedTag);

    RemoveUnusedPlayerHeads(this);

    if (isClient() && getLocalPlayer() != null) 
    {
        if (hasSynced && !cl_use_custom_head)
            Client_RemoveHead(this);
        else if (!hasSynced && cl_use_custom_head) 
            Client_SendHead(this);
    }
}

// Note: This only runs on the server
void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    RemoveUnusedPlayerHeads(this);
}

void onCommand(CRules@ this, u8 cmd, CBitStream @stream)
{
    if (cmd == this.getCommandID(HEAD_SYNC_CMD))
    {
        u16 id = stream.read_u16();
        CPlayer@ player = getPlayerByNetworkId(id);
        if (player is null)
        {
            warn("Got sent a head for a player that does not exist. Network id is " + id);
            return;
        }

        if (isServer() && !isCustomHeadAllowed(player))
        {
            warn(player.getUsername() + " attempted to sync their custom head without passing allowed checks");
            return;
        }

        AddNewHead(this, HeadStorage(player, @stream));

        // Sync the incoming head to clients
        if (isServer() && !isClient())
        {
            // Just reuse the buffer
            stream.ResetBitIndex();
            this.SendCommand(this.getCommandID(HEAD_SYNC_CMD), stream);
        }

        if (isClient()) 
        {
            CBlob@ blob = player.getBlob();
            if (blob !is null)
                LoadHead(blob.getSprite(), blob.getHeadNum());
        }
    }
    else if (cmd == this.getCommandID(HEAD_RM_CMD))
    {
        u16 id = stream.read_u16();
        CPlayer@ player = getPlayerByNetworkId(id);
        if (player is null)
        {
            warn("Got asked to remove custom head for a player that does not exist. Network id is " + id);
            return;
        }

        RemoveHead(this, player);

        // Sync the incoming head to clients
        if (isServer() && !isClient())
        {
            // Just reuse the buffer
            stream.ResetBitIndex();
            this.SendCommand(this.getCommandID(HEAD_RM_CMD), stream);
        }

        if (isClient()) 
        {
            CBlob@ blob = player.getBlob();
            if (blob !is null)
                LoadHead(blob.getSprite(), blob.getHeadNum());
        }

    }
}

// void onRender(CRules@ this)
// {
//     ImGui::SetNextWindowBgAlpha(0.8);
//     if (!ImGui::Begin("HeadDebugger")) 
//     {
//         ImGui::End();
//         return;
//     }

//     HeadStorage[]@ heads = GetHeadStorage(this);

//     for (int i = 0; i < heads.length; i++)
//     {
//         HeadStorage@ head = @heads[i];
//         ImGui::Text(head.playerName + " custom head");
//         ImGui::Image(head.texture, Vec2f(HEAD::Width * 4, HEAD::Height * 4));
//     }

//     ImGui::End();
// }