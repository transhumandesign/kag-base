/// Handles achievements that are gamemode agnostic
/// Such as:
/// - Kills/Death types
#define CLIENT_ONLY

#include "Hitter.as";
#include "ArcherCommon.as";
#include "AchievementsCommon.as"

void onInit(CRules@ this)
{
    onRestart(this);

    CSteamAchievements@ ach = getSteamAchievements();

    if (ach !is null && !isServer())
    {
        ach.Unlock(Steam::JOIN_MULTI);

        if (getNet().isUsingMods())
            ach.Unlock(Steam::JOIN_MODDED);
    }
}

void onRestart(CRules@ this)
{
    SetStat(KilledAs_Builder, false);
    SetStat(KilledAs_Archer,  false);
    SetStat(KilledAs_Knight,  false);
}

void onStateChange(CRules@ this, const u8 oldState)
{
    CSteamAchievements@ ach = getSteamAchievements();
    CPlayer@ localPlayer = getLocalPlayer();
    if (ach is null || localPlayer is null
        || !this.isGameOver() || isServer() && isClient())
        return;


    if (this.getTeamWon() == localPlayer.getTeamNum())
        ach.IncrementStat(Steam::wins);
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	CSteamAchievements@ ach = getSteamAchievements();
	CPlayer@ localPlayer = getLocalPlayer();

	if (blob.getPlayerOfRecentDamage() is localPlayer && ach !is null)
	{
		if (blob.getName() == "mine" && blob.getTeamNum() != localPlayer.getTeamNum())
			ach.Unlock(Steam::DEFUSE_MINE);
	}
}

void onBlobCreated(CBlob@ blob)
{
	CSteamAchievements@ ach = getSteamAchievements();
	CPlayer@ localPlayer = getLocalPlayer();
	if (ach is null)
		return;

	if (blob.getName() == "arrow" && blob.getDamageOwnerPlayer() is localPlayer)
	{
		const u8 arrowType = blob.get_u8("arrow type");

		switch (arrowType)
		{
			case ArrowType::water:
				ach.IncrementStat(Steam::usedWaterAmmo);
				break;
			
			case ArrowType::fire:
				ach.IncrementStat(Steam::usedFireAmmo);
		}
	}
}

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
            ach.IncrementStat(Steam::kills);

            switch (customData)
            {
                case Hitters::drill:
                    ach.IncrementStat(Steam::killsDrill);
                    break;

                case Hitters::stomp:
                    ach.IncrementStat(Steam::killsStomp);
                    break;

                case Hitters::boulder:
                    ach.IncrementStat(Steam::killsBoulder);
                    break;

                case Hitters::cata_boulder:
                    ach.Unlock(Steam::KILL_BOULDER_CATAPULT);
                    break;

                case Hitters::bite:
                    ach.Unlock(Steam::KILL_SHARK);
                    break;

                case Hitters::fire:
                case Hitters::burn:
                    ach.Unlock(Steam::KILL_FIRE_ARROW);
                    break;

                // Prev note from engine: TODO: REPLACE flying WITH RAMMING
                case Hitters::flying:
                    ach.Unlock(Steam::KILL_RUN_OVER);
                    break;

                // TODO: Shrink code?
                // Bomb and keg are similar with amount killed per tick
                case Hitters::bomb:
                    HandleBombDeath(ach, myBlob);
                    break;

                case Hitters::keg:
                    HandleKegDeath(ach);
                    break;
            }

            if (myBlob !is null)
                HandleMyKills(ach, myBlob);
            else if (getGameTime() > this.get_u32("deathTime") + 4)
                ach.Unlock(Steam::KILL_WHILE_DEAD);
        }
        else
        {
            // Did we just bomb ourselves?
            if (customData == Hitters::bomb)
            {
                SetStat(Bomb_S, true);

                if (GetStat(Bomb_KC) >= 1)
                    ach.Unlock(Steam::KILL_BOMB_SUICIDE);
            }
        }
    }
    else
    {
        this.set_u32("deathTime", getGameTime());

        switch (customData)
        {
            case Hitters::arrow:
                ach.IncrementStat(Steam::deathsArrow);
                break;

            case Hitters::sword:
                ach.IncrementStat(Steam::deathsSword);
                break;

            case Hitters::builder:
                ach.IncrementStat(Steam::deathsHammer);
                break;

            case Hitters::drown:
                HandleDrowning(ach, victim);
                break;
        }
    }
}

void HandleBombDeath(CSteamAchievements@ ach, CBlob@ myBlob)
{
    if (myBlob !is null && (myBlob.getName() != "knight"))
        ach.Unlock(Steam::KILL_BOMB_NOT_KNIGHT);

    if (GetStat(Bomb_KT) == getGameTime())
        IncrementStat(Bomb_KC);
    else
    {
        SetStat(Bomb_KT, getGameTime());
        SetStat(Bomb_KC, 1);
        SetStat(Bomb_KS, false);
    }

    int bombKills = GetStat(Bomb_KC);

    if (bombKills == 3)
        ach.Unlock(Steam::KILL_BOMB_COMBO_3);

    if (bombKills >= 1 && GetStat(Bomb_KS) == true)
        ach.Unlock(Steam::KILL_BOMB_SUICIDE);
}


void HandleKegDeath(CSteamAchievements@ ach)
{
    if (GetStat(Keg_KT) == getGameTime())
    {
        IncrementStat(Keg_KC);

        if (GetStat(Keg_KC) == 5)
            ach.Unlock(Steam::KILL_KEG_COMBO_5);
    }
    else
    {
        SetStat(Keg_KT, getGameTime());
        SetStat(Keg_KC, 1);
    }
}


void HandleMyKills(CSteamAchievements@ ach, CBlob@ myBlob)
{
    string name = myBlob.getName();

    if (name == "archer")
        SetStat(KilledAs_Archer, true);
    else if (name == "builder")
        SetStat(KilledAs_Builder, true);
    else if (name == "knight")
        SetStat(KilledAs_Knight, true);

    if (GetStat(KilledAs_Archer)
        && GetStat(KilledAs_Builder)
        && GetStat(KilledAs_Knight))
        ach.Unlock(Steam::KILL_AS_EVERY_CLASS);

    if (myBlob.hasTag("burning"))
        ach.Unlock(Steam::KILL_WHILE_ON_FIRE);
}

void HandleDrowning(CSteamAchievements@ ach, CPlayer@ myPlayer)
{
    CBlob@ blob = myPlayer.getBlob();

    if (blob is null)
        return;

    // Are we inside a drowning boat and stayed till the end?
    AttachmentPoint@[] aps;
	if (blob.getAttachmentPoints(@aps))
    {
        for (uint i = 0; i < aps.length; i++)
        {
            AttachmentPoint@ ap = aps[i];
            CBlob@ occupied = ap.getOccupied();
            if (occupied !is null && occupied.getName() == "warboat")
            {
                ach.Unlock(Steam::DROWN_WARBOAT);
                return;
            }
        }
    }

    // Are we overlapping with a boat and drowned
    CBlob@[] overlaps;
    if (blob.getOverlapping(@overlaps))
    {
        for (uint i = 0; i < overlaps.length; i++)
        {
            CBlob@ overlap = overlaps[i];
            if (overlap !is null && overlap.getName() == "warboat") {
                ach.Unlock(Steam::DROWN_WARBOAT);
                return;
            }
        }
    }

}