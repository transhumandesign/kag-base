/// Handles achievements that are gamemode agnostic
/// Such as:
/// - Kills/Death types
#define CLIENT_ONLY

#include "Hitter.as";

void onInit(CRules@ this)
{
    onRestart(this);
}

void onRestart(CRules@ this)
{
    this.set_bool("killedAsBuilder", false);
    this.set_bool("killedAsKnight", false);
    this.set_bool("killedAsArcher", false);
}

void onTick(CRules@ this)
{

}

/// Handles the following achievements
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

                // TODO: Shrink?
                // Bomb and keg are similar with amount killed per tick
                case Hitters::bomb:
                {
                    if (myBlob !is null && (myBlob.getName() == "archer" || myBlob.getName() == "builder"))
                        ach.Unlock(Steam::KILL_BOMB_NOT_KNIGHT);

                    if (this.get_u32("bombKillTime") == getGameTime())
                        this.set_u32("BombKillCount", this.get_u32("BombKillCount") + 1);
                    else
                    {
                        this.set_u32("bombKillTime", getGameTime());
                        this.set_u32("bombKillCount", 1);
                        this.set_bool("bombSuicide", false);
                    }

                    int bombKills = this.get_u32("bombKillCount");
                    if (bombKills == 3)
                        ach.Unlock(Steam::KILL_BOMB_COMBO_3);

                    if (bombKills >= 1 && this.get_bool("bombSuicide") == true)
                        ach.Unlock(Steam::KILL_BOMB_SUICIDE);

                    break;
                }

                case Hitters::keg:
                {
                    if (this.get_u32("kegKillTime") == getGameTime())
                    {
                        this.set_u32("kegKillCount", this.get_u32("kegKillCount") + 1);

                        if (this.get_u32("kegKillCount") == 5)
                            ach.Unlock(Steam::KILL_KEG_COMBO_5);
                    }
                    else
                    {
                        this.set_u32("kegKillTime", getGameTime());
                        this.set_u32("kegKillCount", 1);
                    }
                    break;
                }
            }

            if (victim.getBlob() !is null
                && victim.getBlob().getCarriedBlob() !is null
                && victim.getBlob().getCarriedBlob().getName() == "ctf_flag")
			    ach.IncrementStat(Steam::killsEFC);

            if (myBlob !is null)
            {
                string name = myBlob.getName();

                if (name == "archer")
                    this.set_bool("killedAsArcher", true);
                else if (name == "builder")
                    this.set_bool("killedAsBuilder", true);
                else if (name == "knight")
                    this.set_bool("killedAsKnight", true);

                if (this.get_bool("killedAsArcher")
                    && this.get_bool("killedAsKnight")
                    && this.get_bool("killedAsBuilder"))
                    ach.Unlock(Steam::KILL_AS_EVERY_CLASS);

                if (myBlob.hasTag("burning"))
                    ach.Unlock(Steam::KILL_WHILE_ON_FIRE);
            }
            else if (getGameTime() > this.get_u32("deathTime") + 4)
                ach.Unlock(Steam::KILL_WHILE_DEAD);
        }
        else
        {
            // Did we just bomb ourselves?
            if (customData == Hitters::bomb)
            {
                this.set_bool("bombSuicide", true);

                if (this.get_u32("bombKillCount") >= 1)
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
                // TODO: DROWN_WARBOAT
                break;
        }
    }
}

