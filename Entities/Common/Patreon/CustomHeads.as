// The goal of this script is as follows:
// # Client
// - Read a custom head png (if it exists)
// - Sync that to the server (if we are patreon)
// - Retrieve and store custom heads sent by the server 
//
// # Server
// - Validate any incoming heads
// - Sync all known heads on new player join
#include "CustomHeadData.as";
#include "RunnerHead.as";

bool HAS_SYNCED = false;

void onInit(CRules@ this)
{
    // Used by both client & server
    this.addCommandID("syncHead");
    
    ResetHeadStorage(this);
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
    if (HAS_SYNCED == false && isClient() && getLocalPlayer() != null)
    {
        Client_SendHead(this);
        HAS_SYNCED = true;
    }

    if (getGameTime() % 300 == 0)
    {
        RemoveUnusedPlayerHeads(this);
    }
}

// Note: This only runs on the server
void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    RemoveUnusedPlayerHeads(this);
}

void Client_SendHead(CRules@ this)
{
    if (!isClient() || !cl_use_custom_head || 
        !isCustomHeadAllowed(getLocalPlayer()) ||
        !Texture::createFromFile(HEAD_TEMP_TEXTURE, HEAD_FILENAME))
        return;

    ImageData@ data = Texture::data(HEAD_TEMP_TEXTURE);

    if (data.width() != HEAD::Width || data.height() != HEAD::Height)
    {
        error(HEAD_FILENAME + " is not " + HEAD::Width + " by " + HEAD::Height + " (was " + data.width() + " by " + data.height() + "), not going to sync");
        Texture::destroy(HEAD_TEMP_TEXTURE);

        return;
    }

    CBitStream stream;
    stream.write_u16(getLocalPlayer().getNetworkID());
    WriteHeadToStream(@data, @stream);

    this.SendCommand(this.getCommandID("syncHead"), stream);
    
    Texture::destroy(HEAD_TEMP_TEXTURE);
}


void onCommand(CRules@ this, u8 cmd, CBitStream @stream)
{
    if (cmd == this.getCommandID("syncHead"))
    {
        u16 id = stream.read_u16();
        CPlayer@ player = getPlayerByNetworkId(id);
        if (player is null)
        {
            warn("Got sent a head for a player that does not exist (network id was " + id);
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
            this.SendCommand(this.getCommandID("syncHead"), stream);
        }

        if (isClient()) 
        {
            CBlob@ blob = player.getBlob();
            if (blob !is null)
                LoadHead(blob.getSprite(), blob.getHeadNum());
        }
    }
}

void onRender(CRules@ this)
{
    ImGui::SetNextWindowBgAlpha(0.8);
    if (!ImGui::Begin("HeadDebugger")) 
    {
        ImGui::End();
        return;
    }

    HeadStorage[]@ heads = GetHeadStorage(this);

    for (int i = 0; i < heads.length; i++)
    {
        HeadStorage@ head = @heads[i];

        if (head !is null)
        {
            ImGui::Text(head.playerName + " custom head");
            ImGui::Image(head.texture, Vec2f(HEAD::Width * 4, HEAD::Height * 4));
        }
    }

    ImGui::End();
}