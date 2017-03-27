// spawn resources

#include "RulesCore.as";
#include "CTF_Structs.as";

const u32 materials_wait = 20; //seconds between free mats
const u32 materials_wait_warmup = 40; //seconds between free mats

//property
const string SPAWN_ITEMS_TIMER = "CTF SpawnItems:";

string base_name() { return "tent"; }

bool SetMaterials(CBlob@ blob,  const string &in name, const int quantity)
{
	CInventory@ inv = blob.getInventory();

	//already got them?
	if (inv.isInInventory(name, quantity))
		return false;

	//otherwise...
	inv.server_RemoveItems(name, quantity); //shred any old ones

	CBlob@ mat = server_CreateBlob(name);
	if (mat !is null)
	{
		mat.Tag("do not set materials");
		mat.server_SetQuantity(quantity);
		if (!blob.server_PutInInventory(mat))
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

	if (gametime > next_items ||		//timer expired
	        gametime < next_items - materials_wait * getTicksASecond() * 4) //residual prop
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
		SetCTFTimer(this, getPlayer(i), materials_wait_warmup);//this used to be set to 0, but now its not
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

	if ((gametime % 31) != 5)
		return;


	RulesCore@ core;
	this.get("core", @core);
	if (core !is null)
	{

		CBlob@[] spots;
		getBlobsByName(base_name(), @spots);
		getBlobsByName("buildershop", @spots);
		getBlobsByName("knightshop", @spots);
		getBlobsByName("archershop", @spots);
		for (uint step = 0; step < spots.length; ++step)
		{
			CBlob@ spot = spots[step];
			CBlob@[] overlapping;
			if (spot !is null && spot.getOverlapping(overlapping))
			{
				string name = spot.getName();
				bool isShop = (name.find("shop") != -1);
				for (uint o_step = 0; o_step < overlapping.length; ++o_step)
				{
					CBlob@ overlapped = overlapping[o_step];
					if (overlapped !is null && overlapped.hasTag("player"))
					{
						if (!isShop || name.find(overlapped.getName()) != -1)
						{
							CPlayer@ p = overlapped.getPlayer();
							if (p !is null)
							{
								doGiveSpawnMats(this, p, overlapped, core);
							}
						}
					}
				}
			}

		}
	}
}

// render gui for the player
void onRender(CRules@ this)
{
	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) { return; }

	string propname = getCTFTimerPropertyName(p);
	CBlob@ b = p.getBlob();
	if (b !is null && this.exists(propname))
	{
		s32 next_items = this.get_s32(propname);
		if (getGameTime() < next_items - materials_wait * getTicksASecond() * 2)
		{
			this.set_s32(propname, 0); //clear residue
		}
		else if (next_items > getGameTime())
		{
			f32 offset = 140.0f;
			string verb = (b.getName() == "builder" ? "Build" : "Fight");
			if (this.isWarmup())
			{
				verb = "Prepare for Battle";
				offset = 175.0f;
			}

			u32 secs = ((next_items - 1 - getGameTime()) / getTicksASecond()) + 1;
			string units = ((secs != 1) ? "seconds" : "second");
			GUI::SetFont("menu");
			GUI::DrawText("Next Resupply in " + secs + " " + units + ", Go " + verb + "!" ,
			              Vec2f(getScreenWidth() / 2 - offset, getScreenHeight() / 3 - 70.0f + Maths::Sin(getGameTime() / 3.0f) * 5.0f),
			              SColor(255, 255, 55, 55));
		}
	}
}
