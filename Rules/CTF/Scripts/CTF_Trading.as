#define SERVER_ONLY

#include "GameplayEvents.as"
#include "AssistCommon.as"

const int coinsOnDamageAdd = 5;
const int coinsOnAssistAdd = 7;
const int coinsOnKillAdd = 10;
const f32 killstreakFactor = 1.2f;

const int coinsOnDeathLosePercent = 20;
const int coinsOnTKLose = 50;

const int coinsOnRestartAdd = 0;
const bool keepCoinsOnRestart = false;

const int coinsOnHitSiege = 5; //per heart of damage
const int coinsOnKillSiege = 20;

const int coinsOnCapFlag = 100;

const int coinsOnBuildStoneBlock = 3;
const int coinsOnBuildStoneDoor = 5;
const int coinsOnBuildWood = 1;
const int coinsOnBuildWorkshop = 10;

const int warmupFactor = 3;

string[] names;

void GiveRestartCoins(CPlayer@ p)
{
	if (keepCoinsOnRestart)
		p.server_setCoins(p.getCoins() + coinsOnRestartAdd);
	else
		p.server_setCoins(coinsOnRestartAdd);
}

void GiveRestartCoinsIfNeeded(CPlayer@ player)
{
	const string s = player.getUsername();
	for (uint i = 0; i < names.length; ++i)
	{
		if (names[i] == s)
		{
			return;
		}
	}

	names.push_back(s);
	GiveRestartCoins(player);
}

//extra coins on start to prevent stagnant round start
void Reset(CRules@ this)
{
	names.clear();

	uint count = getPlayerCount();
	for (uint p_step = 0; p_step < count; ++p_step)
	{
		CPlayer@ p = getPlayer(p_step);
		GiveRestartCoins(p);
		names.push_back(p.getUsername());
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}

//also given when plugging player -> on first spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (player !is null)
	{
		GiveRestartCoinsIfNeeded(player);
	}
}

//
// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null)
	{
		if (killer !is null)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				killer.server_setCoins(killer.getCoins() + coinsOnKillAdd * Maths::Pow(killstreakFactor, killer.get_u8("killstreak")));
			}
			else if (killer !is victim && killer.getTeamNum() == victim.getTeamNum())
			{
				killer.server_setCoins(killer.getCoins() - coinsOnTKLose);
			}
			
			CPlayer@ helper = getAssistPlayer (victim, killer);
			if (helper !is null) 
			{ 
				helper.server_setCoins(helper.getCoins() + coinsOnAssistAdd);
			}
		}
		if (!this.isWarmup())	//only reduce coins if the round is on.
		{
			s32 lost = victim.getCoins() * (coinsOnDeathLosePercent * 0.01f);

			victim.server_setCoins(victim.getCoins() - lost);

			//drop coins
			CBlob@ blob = victim.getBlob();
			if (blob !is null)
				server_DropCoins(blob.getPosition(), lost*0.75f + XORRandom(lost*0.25f));
		}
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	if (attacker !is null && attacker !is victim && attacker.getTeamNum() != victim.getTeamNum())
	{
        CBlob@ v = victim.getBlob();
        f32 health = 0.0f;
        if(v !is null)
            health = v.getHealth();
        f32 dmg = DamageScale;
        dmg = Maths::Min(health, dmg);

		attacker.server_setCoins(attacker.getCoins() + dmg * coinsOnDamageAdd / this.attackdamage_modifier);
	}

	return DamageScale;
}

// coins for various game events
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == getGameplayEventID(this))
	{
		GameplayEvent g(params);

		CPlayer@ p = g.getPlayer();
		if (p !is null)
		{
			u32 coins = 0;

			switch (g.getType())
			{
				case GE_built_block:

				{
					g.params.ResetBitIndex();
					u16 tile = g.params.read_u16();
					if (tile == CMap::tile_castle)
					{
						coins = coinsOnBuildStoneBlock;
					}
					else if (tile == CMap::tile_wood)
					{
						coins = coinsOnBuildWood;
					}
				}

				break;

				case GE_built_blob:

				{
					g.params.ResetBitIndex();
					string name = g.params.read_string();

					if (name == "trap_block" ||
					    name == "spikes")
					{
						coins = coinsOnBuildStoneBlock;
					}
					else if (name == "stone_door")
					{
						coins = coinsOnBuildStoneDoor;
					}
					else if (name == "wooden_platform" ||
							name == "wooden_door" ||
							name == "bridge" ||
							name == "ladder")
					{
						coins = coinsOnBuildWood;
					}
					else if (name == "building")
					{
						coins = coinsOnBuildWorkshop;
					}
				}

				break;

				case GE_hit_vehicle:

				{
					g.params.ResetBitIndex();
					f32 damage = g.params.read_f32();
					coins = coinsOnHitSiege * damage;
				}

				break;

				case GE_kill_vehicle:
					coins = coinsOnKillSiege;
					break;

				case GE_captured_flag:
					coins = coinsOnCapFlag;
					break;
			}

			if (coins > 0)
			{
				if (this.isWarmup())
					coins /= warmupFactor;

				p.server_setCoins(p.getCoins() + coins);
			}
		}
	}
}
