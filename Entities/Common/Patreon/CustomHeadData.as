#include "CustomHeadCheck.as"

const string HEAD_FILENAME = "CustomHead.png";
const string HEAD_TEMP_TEXTURE = "TempCustomHeadTexture";
const string HEAD_STORAGE_PROP = "CustomHeadStorage";

// How big is our head png file?
enum HEAD
{
    Width = 48,
    Height = 16,
    Length = Width + Height
}

class HeadStorage
{
    // Use playerName instead of a CPlayer@ handle
    string playerName = "";
    string texture = "";

    // Note: you must manually call head.CreateHeadFromStream!
    HeadStorage(CPlayer@ player)
    {
        playerName = player.getUsername();
        texture = player.getUsername() + '-CustomHead';
    }

    HeadStorage(CPlayer@ player, CBitStream@ data)
    {
        playerName = player.getUsername();
        texture = player.getUsername() + '-CustomHead';

        if (!CreateHeadFromStream(data))
            RemoveHead();
    }

    ~HeadStorage()
    {
        RemoveHead();
    }

    // Return's false if head could not be made
    bool CreateHeadFromStream(CBitStream@ data)
    {
        if (Texture::exists(texture))
            Texture::destroy(texture);

        ImageData@ temp = ReadHeadFromStream(data);

        if (!Texture::createFromData(texture, temp))
        {
            warn("Could not create texture for " + playerName);
            return false;
        }

        return true;
    }

    // Is our player still alive?
    bool isHeadStillValid()
    {
        return player() !is null;
    }

    CPlayer@ player()
    {
        return getPlayerByUsername(playerName);
    }

    void RemoveHead()
    {
        playerName = "";
        texture = "";
        Texture::destroy(texture);
    }

    void WriteToStream(CBitStream@ stream)
    {
        ImageData@ data = Texture::data(texture);
        WriteHeadToStream(@data, @stream);
    }
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

void ResetHeadStorage(CRules@ this)
{
    if (this.exists(HEAD_STORAGE_PROP))
    {
        GetHeadStorage(this).clear();
    } 
    else 
    {
        HeadStorage[] storage = {};
        this.set(HEAD_STORAGE_PROP, storage);    
    }
}

HeadStorage[]@ GetHeadStorage(CRules@ this)
{
    HeadStorage[]@ heads;
    this.get("CustomHeadStorage", @heads);

    return @heads;
}

void SyncCurrentHeadStorage(CRules@ this, CPlayer@ player)
{
    HeadStorage[]@ heads = GetHeadStorage(this);

    for (int i = 0; i < heads.length; ++i)
    {
        CBitStream stream;
        stream.write_u16(heads[i].player().getNetworkID());
        heads[i].WriteToStream(@stream);

        this.SendCommand(this.getCommandID("syncHead"), stream, player);
    }
}

void RemoveUnusedPlayerHeads(CRules@ this)
{
    HeadStorage[]@ heads = GetHeadStorage(this);
    for (int i = 0; i < heads.length; ++i)
    {
        if (heads[i].player() is null)
        {
            heads[i].RemoveHead();
            heads.removeAt(i);
            i--;
        }
    }
}

void AddNewHead(CRules@ this, HeadStorage@ newHead)
{
    if (newHead.player() is null) 
        return;

    HeadStorage[]@ heads = GetHeadStorage(this);
    for (int i = 0; i < heads.length; i++)
    {
        if (heads[i].player() is newHead.player())
        {
            heads[i].RemoveHead();
            heads.removeAt(i);
            i--;
        }
    }

    heads.push_back(newHead);
}

HeadStorage@ GetHead(CRules@ this, CPlayer@ player)
{
    HeadStorage[]@ heads = GetHeadStorage(this);
    for (int i = 0; i < heads.length; i++)
    {
        if (heads[i].player() is player)
            return @heads[i];
    }

    return null;
}