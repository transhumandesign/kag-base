#define CLIENT_ONLY

void onStateChange(CRules@ this, const u8 oldState)
{
    CSteamAchievements@ ach = getSteamAchievements();
    CPlayer@ player = getLocalPlayer();
    if (ach is null || player is null
        || !this.isGameOver())
        return;

    if (this.getTeamWon() == player.getTeamNum())
        ach.IncrementStat(Steam::challengesCompleted);
}