#define CLIENT_ONLY

void onInit(CRules@ this) {
    onRestart(this);
}

// TODO: nextmap?
void onRestart(CRules@ this) {
    this.set_bool("oneManArmy", true);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
    CSteamAchievements@ ach = getSteamAchievements();
    CPlayer@ player = getLocalPlayer();
    s32 blueCount = getTeamSize(0);
    s32 redCount = getTeamSize(1);

    if (blueCount < 3 || redCount < 3 ||
         player is null || victim is null ||
         attacker is null || ach is null)
        return;


    bool diffTeam = victim.getTeamNum() != player.getTeamNum();

    if (diffTeam && !attacker.isMyPlayer())
        this.set_bool("oneManArmy", false);

    if (this.get_bool("oneManArmy") && diffTeam && attacker.isMyPlayer())
    {
        bool allEnemiesDead = false;

        for (int i = 0; i < getPlayerCount(); i++)
        {
            CPlayer@ p = getPlayer(i);
	       	if (p is null)
                continue;

            if (p.getTeamNum() != player.getTeamNum() && p !is victim && p.getBlob() !is null) {
                allEnemiesDead = false;
                break;
            }
        }

        if (allEnemiesDead)
            ach.Unlock(Steam::KILL_WHOLE_TEAM_TDM);
    }

    if (player.getBlob() !is null)
    {
        bool allDead = false;

        for (int i = 0; i < getPlayerCount(); i++)
        {
            CPlayer@ p = getPlayer(i);
	       	if (p is null)
                continue;

            if (p !is victim && p.getBlob() !is null) {
                allDead = false;
                break;
            }
        }

        if (allDead)
            ach.Unlock(Steam::LAST_MAN_TDM);
    }
}



s32 getTeamSize(s16 team) {
    s32 size = 0;

    for (int i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
		if (p is null)
            continue;

        if (p.getTeamNum() == team)
            size++;
    }

    return size;
}