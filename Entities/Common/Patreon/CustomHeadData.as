#include "Accolades.as"

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