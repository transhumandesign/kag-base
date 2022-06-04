// spawn resources

#include "RulesCore.as";
#include "CTF_Structs.as";

const u32 materials_wait = 20; //seconds between free mats
const u32 materials_wait_warmup = 40; //seconds between free mats

//property
const string SPAWN_ITEMS_TIMER = "CTF SpawnItems:";

bool SetMaterials(CBlob@ blob,  const string &in name, const int quantity)
{
	CInventory@ inv = blob.getInventory();

	//avoid over-stacking arrows
	if (name == "mat_arrows")
	{
		inv.server_RemoveItems(name, quantity);
	}

	CBlob@ mat = server_CreateBlobNoInit(name);

	if (mat !is null)
	{
		mat.Tag('custom quantity');
		mat.Init();

		mat.server_SetQuantity(quantity);

		if (not blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}

	return true;
}

bool GiveSpawnResources(CRules@ this, CBlob@ blob, CPlayer@ player, CTFPlayerInfo@ info)
{
	bool ret = false;

	if (blob.getName() == "builder")
	{
		if (this.isWarmup())
		{
			ret = SetMaterials(blob, "mat_wood", 300) || ret;
			ret = SetMaterials(blob, "mat_stone", 100) || ret;

		}
		else
		{
			ret = SetMaterials(blob, "mat_wood", 100) || ret;
			ret = SetMaterials(blob, "mat_stone", 30) || ret;
		}

		if (ret)
		{
			info.items_collected |= ItemFlag::Builder;
		}
	}
	else if (blob.getName() == "archer")
	{
		ret = SetMaterials(blob, "mat_arrows", 30) || ret;

		if (ret)
		{
			info.items_collected |= ItemFlag::Archer;
		}
	}
	else if (blob.getName() == "knight")
	{
		if (ret)
		{
			info.items_collected |= ItemFlag::Knight;
		}
	}

	return ret;
}

//when the player is set, give materials if possible
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	if (blob !is null && player !is null)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			doGiveSpawnMats(this, player, blob, core);
		}
	}
}

//when player dies, unset archer flag so he can get arrows if he really sucks :)
//give a guy a break :)
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	if (victim !is null)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (core.getInfoFromPlayer(victim));
			if (info !is null)
			{
				info.items_collected &= ~ItemFlag::Archer;
			}
		}
	}
}

bool canGetSpawnmats(CRules@ this, CPlayer@ p, RulesCore@ core)
{
	s32 next_items = getCTFTimer(this, p);
	s32 gametime = getGameTime();

	CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (core.getInfoFromPlayer(p));

	if (gametime > next_items)		// timer expired
	{
		info.items_collected = 0; //reset available class items
		return true;
	}
	else //trying to get new class items, give a guy a break
	{
		u32 items = info.items_collected;
		u32 flag = 0;

		CBlob@ b = p.getBlob();
		string name = b.getName();
		if (name == "builder")
			flag = ItemFlag::Builder;
		else if (name == "knight")
			flag = ItemFlag::Knight;
		else if (name == "archer")
			flag = ItemFlag::Archer;

		if (info.items_collected & flag == 0)
		{
			return true;
		}
	}

	return false;

}

string getCTFTimerPropertyName(CPlayer@ p)
{
	return SPAWN_ITEMS_TIMER + p.getUsername();
}

s32 getCTFTimer(CRules@ this, CPlayer@ p)
{
	string property = getCTFTimerPropertyName(p);
	if (this.exists(property))
		return this.get_s32(property);
	else
		return 0;
}

void SetCTFTimer(CRules@ this, CPlayer@ p, s32 time)
{
	string property = getCTFTimerPropertyName(p);
	this.set_s32(property, time);
	this.SyncToPlayer(property, p);
}

//takes into account and sets the limiting timer
//prevents dying over and over, and allows getting more mats throughout the game
void doGiveSpawnMats(CRules@ this, CPlayer@ p, CBlob@ b, RulesCore@ core)
{
	if (canGetSpawnmats(this, p, core))
	{
		s32 gametime = getGameTime();

		CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (core.getInfoFromPlayer(p));

		bool gotmats = GiveSpawnResources(this, b, p, info);
		if (gotmats)
		{
			SetCTFTimer(this, p, gametime + (this.isWarmup() ? materials_wait_warmup : materials_wait)*getTicksASecond());
		}
	}
}

// normal hooks

void Reset(CRules@ this)
{
	//restart everyone's timers
	for (uint i = 0; i < getPlayersCount(); ++i)
		SetCTFTimer(this, getPlayer(i), 0);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}

void onTick(CRules@ this)
{
	if (!getNet().isServer())
		return;

	s32 gametime = getGameTime();

	if ((gametime % 15) != 5)
		return;

	RulesCore@ core;
	this.get("core", @core);
	
	if (core !is null)
	{
		CBlob@ playerBlob = getLocalPlayerBlob();
		
		if (playerBlob !is null)
		{
			CBlob@[] overlapping;
			playerBlob.getOverlapping(overlapping);
			
			for (uint i = 0; i < overlapping.length; i++)
			{
				bool isMyBase = overlapping[i].hasTag("respawn") && playerBlob.getTeamNum() == overlapping[i].getTeamNum(); // Base of same team
				bool isClassShop = overlapping[i].get_string("required class") == playerBlob.getName(); // Shop of same class, of any team

				if ( isMyBase || isClassShop )
				{
					doGiveSpawnMats(this, getLocalPlayer(), playerBlob, core);
					return;
				}
			}
		}
	}
}

// render gui for the player
void onRender(CRules@ this)
{
	if (g_videorecording || this.isGameOver())
		return;

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) { return; }

	string propname = getCTFTimerPropertyName(p);
	CBlob@ b = p.getBlob();
	if (b !is null && this.exists(propname))
	{
		s32 next_items = this.get_s32(propname);
		if (next_items > getGameTime())
		{
			string action = (b.getName() == "builder" ? "Go Build" : "Go Fight");
			if (this.isWarmup())
			{
				action = "Prepare for Battle";
			}

			u32 secs = ((next_items - 1 - getGameTime()) / getTicksASecond()) + 1;
			string units = ((secs != 1) ? " seconds" : " second");
			GUI::SetFont("menu");
			GUI::DrawTextCentered(getTranslatedString("Next resupply in {SEC}{TIMESUFFIX}, {ACTION}!")
							.replace("{SEC}", "" + secs)
							.replace("{TIMESUFFIX}", getTranslatedString(units))
							.replace("{ACTION}", getTranslatedString(action)),
			              Vec2f(getScreenWidth() / 2, getScreenHeight() / 3 - 70.0f + Maths::Sin(getGameTime() / 3.0f) * 5.0f),
			              SColor(255, 255, 55, 55));
		}
	}
}
