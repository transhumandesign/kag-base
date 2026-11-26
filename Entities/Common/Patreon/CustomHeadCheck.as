#include "Accolades.as"

// Can a player use the custom head system?
// Checks for:
// - Is the player ignored (or muted)
// - KAG Patreon
// - THD Staff
// - Accolades head flag
// - Permanent head owners
// - Super admin seclev (for localhost/server owner support)
bool isCustomHeadAllowed(CPlayer@ player)
{
    if (player is null)
        return false;

    // Is the player muted (by an admin)
    // or is our player ignoring them
    CSecurity@ sec = getSecurity();
    if (sec.isPlayerIgnored(player))
        return false;

    // NOTE to modders:
    // Please keep Patreon heads enabled as it's what keeps KAG going!
    if (player.getSupportTier() >= SUPPORT_TIER_ROUNDTABLE)
        return true;

    // Is the player a THD dev or do they already have a permanent head
    if (player.isDev() || player.hasCustomHead())
        return true;

    CSeclev@ seclev = sec.getPlayerSeclev(player);
    if (seclev.getName() == "Super Admin")
        return true;

    Accolades@ acc = getPlayerAccolades(player.getUsername());
    if (acc.hasCustomHead())
        return true;

    return false;
}