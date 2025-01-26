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
    {
        this.AddScript("ClientSyncHead.as");
    }
}

void onReload(CRules@ this)
{
    ResetHeadStorage(this);

    Client_SendHead(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    if (isServer())
    {
        HeadStorage@[]@ heads = GetHeadStorage(this);
        for (int i = 0; i < heads.length; ++i)
        {
            CBitStream stream;

            stream.write_u16(heads[i].player.getNetworkID());

            ImageData@ data = Texture::data(heads[i].textureName);

            WriteHeadToStream(@data, @stream);

            this.SendCommand(this.getCommandID("syncHead"), stream, player);
        }
    }
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    HeadStorage@[]@ heads = GetHeadStorage(this);
    for (int i = 0; i < heads.length; ++i)
    {
        if (heads[i].player is player)
        {
            heads.removeAt(i);
            break;
        }
    }
}

void Client_SendHead(CRules@ this)
{
    if (!isClient() || !Texture::createFromFile(TEMP_TEXTURE, FILENAME))
        return;

    ImageData@ data = Texture::data(TEMP_TEXTURE);

    if (data.width() != HEAD::Width || data.height() != HEAD::Height )
    {
        error(FILENAME + " is not " + HEAD::Width + " by " + HEAD::Height + " (was " + data.width() + " by " + data.height() + "), not going to sync");
        Texture::destroy(TEMP_TEXTURE);

        return;
    }

    CBitStream stream;

    stream.write_u16(getLocalPlayer().getNetworkID());

    WriteHeadToStream(@data, @stream);

#ifdef STAGING
    //stream.Compress(6);
#endif

    this.SendCommand(this.getCommandID("syncHead"), stream);
    
    
    Texture::destroy(TEMP_TEXTURE);
}


void WriteHeadToStream(ImageData@ data, CBitStream@ stream)
{
    SColor color;

    for (int y = 0; y < HEAD::Height; y++)
        for (int x = 0; x < HEAD::Width; x++)
        {
            color = data.get(x, y);

            stream.write_u8(color.getAlpha());
            stream.write_u8(color.getRed());
            stream.write_u8(color.getGreen());
            stream.write_u8(color.getBlue());
        }
}

ImageData@ ReadHeadFromStream(CBitStream@ stream)
{
    ImageData@ data = ImageData(HEAD::Width, HEAD::Height);

    for (int y = 0; y < HEAD::Height; y++)
        for (int x = 0; x < HEAD::Width; x++)
        {
            u8 alpha = stream.read_u8();
            u8 red = stream.read_u8();
            u8 green = stream.read_u8();
            u8 blue = stream.read_u8();

            data.put(x, y, SColor(alpha, red, green, blue));
        }

    return @data;
}


void onCommand(CRules@ this, u8 cmd, CBitStream @stream)
{
    if (cmd == this.getCommandID("syncHead"))
	{
#ifdef STAGING
        //stream.Decompress();
#endif 
        u16 id = stream.read_u16();
        CPlayer@ player = getPlayerByNetworkId(id);
        if (player is null)
        {
            warn("Got sent a head for a player that does not exist (network id was " + id);
            return;
        }

        string textureName = player.getUsername() + "-CustomHead";

        // DEBUG
        Texture::destroy(textureName);

        ImageData@ tempData = ReadHeadFromStream(@stream);

        if (!Texture::createFromData(textureName, tempData))
        {
            warn("Could not create texture for " + player.getUsername());
            return;
        }

        HeadStorage@[]@ storage = GetHeadStorage(this);
        
        storage.push_back(HeadStorage(player, textureName));

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
    if (!ImGui::Begin("HeadDebugger"))
        return;

    HeadStorage@[]@ heads = GetHeadStorage(this);

    for (int i = 0; i < heads.length; i++)
    {
        HeadStorage@ head = heads[i];

        ImGui::Text(head.player.getUsername() + " custom head");
        ImGui::Image(head.textureName, Vec2f(HEAD::Width * 4, HEAD::Height * 4));
    }

    ImGui::End();
}