bool CanSwitchFromSpec(CRules@ this, CPlayer@ player, u8 toTeam)
{
    int maxPlayers = getNet().joined_maxplayers;
    int reservedSlots = getNet().joined_reservedslots;
    int playerCountNotSpec = getPlayersCount_NotSpectator(); 
    u8 specTeamNum = this.getSpectatorTeamNum();
    bool patreon_player = player.getSupportTier() >= SUPPORT_TIER_ROYALGUARD;

    bool canSwitch = playerCountNotSpec < maxPlayers;
    
    if (canSwitch || player.getTeamNum() != specTeamNum  || 
        toTeam == specTeamNum || player.isMod() ||
        (patreon_player && playerCountNotSpec < maxPlayers + reservedSlots))
    {
        return true;
    }

    return false;
}