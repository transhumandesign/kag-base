void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
    CSteamAchievements@ ach = getSteamAchievements();
    if (isServer() || victim.isBot() || ach is null)
        return;

    if (attacker !is null &&
        attacker.isMyPlayer() &&
        attacker.getTeamNum() != victim.getTeamNum())
    {
        CBlob@ myBlob = attacker.getBlob();

        // Did we kill somebody else?
        if (!victim.isMyPlayer())
        {
            HandleEnemyFlagPrevention(ach, victim);
        }
    }
}


void HandleEnemyFlagPrevention(CSteamAchievements@ ach, CPlayer@ victim)
{
    CBlob@ victimBlob = victim.getBlob();
    if (victimBlob !is null)
    {
        CBlob@ heldBlob = victimBlob.getCarriedBlob();
        if (heldBlob !is null && heldBlob.getName() == "ctf_flag")
            ach.IncrementStat(Steam::killsEFC);
    }
}