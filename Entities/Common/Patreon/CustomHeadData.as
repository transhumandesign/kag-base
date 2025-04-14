#include "Accolades.as"

// Find and sync this file to the server on join
const string FILENAME = "CustomHead.png";
const string TEMP_TEXTURE = "TempCustomHeadTexture";
const string HEAD_STORAGE_PROP = "CustomHeadStorage";

// Falls apart if the texture ever becomes a square :3
enum HEAD
{
    Width = 48,
    Height = 16
}

class HeadStorage
{
    CPlayer@ player = null;
    string textureName = "";

    HeadStorage(CPlayer@ p, string texture)
    {
        @player = p;
        textureName = texture;
    }
}

void ResetHeadStorage(CRules@ this)
{
    if (this.exists(HEAD_STORAGE_PROP))
    {
        HeadStorage@[]@ heads = GetHeadStorage(this);
        heads.clear();
    } 
    else 
    {
        HeadStorage@[]@ storage = {};
        this.set("CustomHeadStorage", @storage);    
    }
}

HeadStorage@[]@ GetHeadStorage(CRules@ this)
{
    HeadStorage@[]@ heads = {};
    this.get("CustomHeadStorage", @heads);

    return @heads;
}

void SyncCurrentHeadStorage(CRules@ this, CPlayer@ player)
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

void RemoveUnusedPlayerHeads(CRules@ this)
{
    HeadStorage@[]@ heads = GetHeadStorage(this);
    for (int i = 0; i < heads.length; ++i)
    {
        if (heads[i].player is null)
        {
            print("removing unused head")
            heads.removeAt(i);
            i--;
        }
    }
}

void AddNewHead(CRules@ this, HeadStorage@ newHead)
{
    HeadStorage@[]@ heads = GetHeadStorage(this);
    for (int i = 0; i < heads.length; i++)
    {
        if (heads[i].player is newHead.player)
        {
            print("removing head");
            heads.removeAt(i);
            i--;
        }
    }

    heads.push_back(newHead);
}

void WriteHeadToStream(ImageData@ data, CBitStream@ stream)
{
    SColor color;

    for (int y = 0; y < HEAD::Height; y++)
    {
        for (int x = 0; x < HEAD::Width; x++)
        {
            color = data.get(x, y);

            stream.write_u8(color.getAlpha());
            stream.write_u8(color.getRed());
            stream.write_u8(color.getGreen());
            stream.write_u8(color.getBlue());
        }
    }
}

ImageData@ ReadHeadFromStream(CBitStream@ stream)
{
    ImageData@ data = ImageData(HEAD::Width, HEAD::Height);

    for (int y = 0; y < HEAD::Height; y++)
    {
        for (int x = 0; x < HEAD::Width; x++)
        {
            u8 alpha = stream.read_u8();
            u8 red = stream.read_u8();
            u8 green = stream.read_u8();
            u8 blue = stream.read_u8();

            data.put(x, y, SColor(alpha, red, green, blue));
        }
    }

    return @data;
}


// Can a player use the custom head system?
// Checks for:
// - KAG Patreon
// - THD Staff
// - Accolades head flag
// - Permanent head owners
// - Super admin seclev (for localhost/server owner support)
bool isCustomHeadAllowed(CPlayer@ player)
{
    if (player is null)
    return false;

    // NOTE to modders:
    // Please keep Patreon heads enabled as it's what keeps KAG going!
    if (player.getSupportTier() >= SUPPORT_TIER_ROUNDTABLE)
        return true;

    if (player.isDev() || player.hasCustomHead())
        return true;

    // TODO: Check how this works client side?
    CSeclev@ seclev = getSecurity().getPlayerSeclev(player);
    if (seclev.getName() == "Super Admin")
        return true;

    Accolades@ acc = getPlayerAccolades(player.getUsername());
    if (acc.hasCustomHead())
        return true;

    return false;
}

string getCustomPlayerHeadName(CPlayer@ player)
{
    if (player is null)
    {
        warn("getCustomPlayerHeadName was passed a null player");
        return "";
    }

    return player.getUsername() + "-CustomHead";
}