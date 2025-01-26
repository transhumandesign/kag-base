// Find and sync this file to the server on join
const string FILENAME = "CustomHead.png";

const string TEMP_TEXTURE = "TempCustomHeadTexture";

const string HEAD_STORAGE_PROP = "CustomHeadStorage";

// Falls apart if the texture ever becomes a square :3
enum HEAD {
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
