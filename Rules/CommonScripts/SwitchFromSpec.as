bool CanSwitchFromSpec(CRules@ this, CPlayer@ player, u8 toTeam)
{
    int maxPlayers = getNet().joined_maxplayers;
    int reservedSlots = getNet().joined_reservedslots;
    int playerCountNotSpec = getPlayersCount_NotSpectator(); 
    u8 specTeamNum = this.getSpectatorTeamNum();

    bool canSwitch = playerCountNotSpec < maxPlayers;
    
    if (canSwitch || player.getTeamNum() != specTeamNum  || toTeam == specTeamNum || player.isMod() ||
        getSecurity().checkAccess_Feature(player, "join_reserved") && maxPlayers + reservedSlots < playerCountNotSpec)
    {
        return true;
    }

    return false;
}