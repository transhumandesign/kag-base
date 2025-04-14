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

void onInit(CRules@ this)
{
    // Used by both client & server
    this.addCommandID("syncHead");
    
    ResetHeadStorage(this);

    if (isClient())
        this.AddScript("ClientSyncHead.as");
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

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    // TODO: Check if this can run server side
    RemoveUnusedPlayerHeads(this);
}

void Client_SendHead(CRules@ this)
{
    if (!isClient() || !cl_use_custom_head || !Texture::createFromFile(TEMP_TEXTURE, FILENAME))
        return;

    ImageData@ data = Texture::data(TEMP_TEXTURE);

    if (data.width() != HEAD::Width || data.height() != HEAD::Height)
    {
        error(FILENAME + " is not " + HEAD::Width + " by " + HEAD::Height + " (was " + data.width() + " by " + data.height() + "), not going to sync");
        Texture::destroy(TEMP_TEXTURE);

        return;
    }

    CBitStream stream;
    stream.write_u16(getLocalPlayer().getNetworkID());

    WriteHeadToStream(@data, @stream);

    this.SendCommand(this.getCommandID("syncHead"), stream);
    
    
    Texture::destroy(TEMP_TEXTURE);
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

        string textureName = player.getUsername() + "-CustomHead";

        if (Texture::exists(textureName))
            Texture::destroy(textureName);

        ImageData@ tempData = ReadHeadFromStream(@stream);

        if (!Texture::createFromData(textureName, tempData))
        {
            warn("Could not create texture for " + player.getUsername());
            return;
        }

        AddNewHead(this, HeadStorage(player, textureName));

        // Sync the incoming head to clients
        if (isServer() && !isClient())
        {
            // Just reuse the buffer
            stream.ResetBitIndex();
            this.SendCommand(this.getCommandID("syncHead"), stream);
        }
	}
}

void onRender(CRules@ this)
{
    ImGui::SetNextWindowBgAlpha(0.8);
    if (!ImGui::Begin("HeadDebugger")) {
        ImGui::End();
        return;
    }

    HeadStorage@[]@ heads = GetHeadStorage(this);

    for (int i = 0; i < heads.length; i++)
    {
        HeadStorage@ head = heads[i];

        ImGui::Text(head.player.getUsername() + " custom head");
        ImGui::Image(head.textureName, Vec2f(HEAD::Width * 4, HEAD::Height * 4));
    }

    ImGui::End();
}