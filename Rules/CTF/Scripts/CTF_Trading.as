//not server only so the client also gets the game event setup stuff

#include "GameplayEventsCommon.as";
#include "AssistCommon.as"
#include "Hitters.as"

const int coinsOnDamageAdd = 6;
const int coinsOnAssistAdd = 8;
const int coinsOnKillAdd = 12;

// bonus for being an offensive builder
const int coinsOnDamageAddBuilder = 8;
const int coinsOnAssistAddBuilder = 10;
const int coinsOnKillAddBuilder = 15;

const int coinsOnDeathLosePercent = 15;

const int coinsOnRestartAdd = 0;
const bool keepCoinsOnRestart = false;

const int coinsOnHitSiege = 2; //per heart of damage
const int coinsOnKillSiege = 20;

const int coinsOnCapFlag = 100;

const int coinsOnBuildStoneBlock = 3;
const int coinsOnBuildStoneDoor = 5;
const int coinsOnBuildWood = 1;
const int coinsOnBuildWorkshop = 10;

const int warmupFactor = 3;

const f32 killstreakFactor = 1.2f;

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
	if (!isServer()) return;

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
	CGameplayEvent@ func = @awardCoins;
	getRules().set("awardCoins handle", @func );

	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);

	CGameplayEvent@ func = @awardCoins;
	getRules().set("awardCoins handle", @func );
}

//also given when plugging player -> on first spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	if (player !is null)
	{
		GiveRestartCoinsIfNeeded(player);
	}
}

//
// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (!getNet().isServer())
		return;

	bool giveBuilderBonus = false;

	if(customData == Hitters::drill || customData == Hitters::spikes || customData == Hitters::builder) 
	{
		giveBuilderBonus = true;
	}

	if (victim !is null)
	{
		if (killer !is null)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				killer.server_setCoins(killer.getCoins() + ((giveBuilderBonus ? coinsOnKillAddBuilder : coinsOnKillAdd) * Maths::Pow(killstreakFactor, killer.get_u8("killstreak"))));
			}
			
			CPlayer@ helper = getAssistPlayer (victim, killer);
			if (helper !is null) 
			{ 
				helper.server_setCoins(helper.getCoins() + (giveBuilderBonus ? coinsOnAssistAddBuilder : coinsOnAssistAdd));
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
	if (!getNet().isServer())
		return DamageScale;

	bool giveBuilderBonus = false;


	if (attacker !is null && attacker !is victim && attacker.getTeamNum() != victim.getTeamNum())
	{
		if(attacker.lastBlobConfig == "builder")
		{
			giveBuilderBonus = true;
		}
        CBlob@ v = victim.getBlob();
        f32 health = 0.0f;
        if(v !is null)
            health = v.getHealth();
        f32 dmg = DamageScale;
        dmg = Maths::Min(health, dmg);

		attacker.server_setCoins(attacker.getCoins() + dmg * (giveBuilderBonus ? coinsOnDamageAddBuilder : coinsOnDamageAdd) / this.attackdamage_modifier);
	}

	return DamageScale;
}

// Gameplay events stuff

void awardCoins(CBitStream@ params)
{
	if (!isServer()) return;

	params.ResetBitIndex();

	u8 event_id;
	if (!params.saferead_u8(event_id)) return;

	u16 player_id;
	if (!params.saferead_u16(player_id)) return;

	CPlayer@ p = getPlayerByNetworkId(player_id);
	if (p is null) return;

	u32 coins = 0;

	if (event_id == CGameplayEvent_IDs::BuildBlock)
	{
		u16 tile;
		if (!params.saferead_u16(tile)) return;

		if (tile == CMap::tile_castle)
		{
			coins = coinsOnBuildStoneBlock;
		}
		else if (tile == CMap::tile_wood)
		{
			coins = coinsOnBuildWood;
		}
	}
	else if (event_id == CGameplayEvent_IDs::BuildBlob)
	{
		string name;
		if (!params.saferead_string(name)) return;

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
	else if (event_id == CGameplayEvent_IDs::HitVehicle)
	{
		f32 damage; 
		if (!params.saferead_f32(damage)) return;

		coins = coinsOnHitSiege * damage;
	}
	else if (event_id == CGameplayEvent_IDs::KillVehicle)
	{
		coins = coinsOnKillSiege;
	}
	else if (event_id == CGameplayEvent_IDs::CaptureFlag)
	{
		coins = coinsOnCapFlag;
	}

	if (coins > 0)
	{
		if (getRules().isWarmup())
			coins /= warmupFactor;

		p.server_setCoins(p.getCoins() + coins);
	}
}