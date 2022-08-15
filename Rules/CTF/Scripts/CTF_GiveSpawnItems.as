// spawn resources

#include "RulesCore.as";
#include "CTF_Structs.as";

const u32 materials_wait = 20; //seconds between free mats
const u32 materials_wait_warmup = 30; //seconds between free mats

const int warmup_wood_amount = 300;
const int warmup_stone_amount = 100;

const int matchtime_wood_amount = 100;
const int matchtime_stone_amount = 30;

//property
const string SPAWN_ITEMS_TIMER_BUILDER = "CTF SpawnItems Builder:";
const string SPAWN_ITEMS_TIMER_ARCHER  = "CTF SpawnItems Archer:";

string base_name() { return "tent"; }

bool SetMaterials(CBlob@ blob,  const string &in name, const int quantity, bool drop = false)
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
		
		if (drop || not blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}
	
	return true;
}

//when the player is set, give materials if possible
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!isServer()) return;
	
	if (blob is null) return;
	if (player is null) return;
	
	doGiveSpawnMats(this, player, blob);
}

//when player dies, unset archer flag so he can get arrows if he really sucks :)
//give a guy a break :)
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	if (victim !is null)
	{
		SetCTFTimer(this, victim, 0, "archer");
	}
}

string getCTFTimerPropertyName(CPlayer@ p, string classname)
{
	if (classname == "builder")
	{
		return SPAWN_ITEMS_TIMER_BUILDER + p.getUsername();
	}
	else
	{
		return SPAWN_ITEMS_TIMER_ARCHER + p.getUsername();
	} 
}

s32 getCTFTimer(CRules@ this, CPlayer@ p, string classname)
{
	string property = getCTFTimerPropertyName(p, classname);
	if (this.exists(property))
		return this.get_s32(property);
	else
		return 0;
}

void SetCTFTimer(CRules@ this, CPlayer@ p, s32 time, string classname)
{
	string property = getCTFTimerPropertyName(p, classname);
	this.set_s32(property, time);
	this.SyncToPlayer(property, p);
}

//takes into account and sets the limiting timer
//prevents dying over and over, and allows getting more mats throughout the game
void doGiveSpawnMats(CRules@ this, CPlayer@ p, CBlob@ b)
{
	s32 gametime = getGameTime();
	string name = b.getName();
	
	if (name == "builder" || this.isWarmup()) 
	{
		if (gametime > getCTFTimer(this, p, "builder")) 
		{
			int wood_amount = matchtime_wood_amount;
			int stone_amount = matchtime_stone_amount;
			
			if (this.isWarmup()) 
			{
				wood_amount = warmup_wood_amount;
				stone_amount = warmup_stone_amount;
			}

			bool drop_mats = (name != "builder");
			
			bool did_give_wood = SetMaterials(b, "mat_wood", wood_amount, drop_mats);
			bool did_give_stone = SetMaterials(b, "mat_stone", stone_amount, drop_mats);
			
			if (did_give_wood || did_give_stone)
			{
				SetCTFTimer(this, p, gametime + (this.isWarmup() ? materials_wait_warmup : materials_wait)*getTicksASecond(), "builder");
			}
		}
	} 

	if (name == "archer") 
	{
		if (gametime > getCTFTimer(this, p, "archer")) 
		{
			CInventory@ inv = b.getInventory();
			if (inv.isInInventory("mat_arrows", 30)) 
			{
				return; // don't give arrows if they have 30 already
			}
			else if (SetMaterials(b, "mat_arrows", 30)) 
			{
				SetCTFTimer(this, p, gametime + (this.isWarmup() ? materials_wait_warmup : materials_wait)*getTicksASecond(), "archer");
			}
		}
	}
}

void displayResupply(CRules@ this, string player_class, string resupply_class, Vec2f offset, Vec2f offset_second, string propname)
{
	s32 next_items = this.get_s32(propname);

	u32 secs = ((next_items - 1 - getGameTime()) / getTicksASecond()) + 1;
	string units = ((secs != 1) ? " seconds" : " second");

	string resupply_available;
	string resupply_unavailable;

	if (resupply_class == "archer")
	{
		// TODO: maybe only draw the cooldown/helptext for archer if low on arrows?
		resupply_available = getTranslatedString("Go to an archer shop or a respawn point to get a resupply of 30 arrows.");

		resupply_unavailable = getTranslatedString("Next resupply of 30 arrows in {SEC}{TIMESUFFIX}.")
			.replace("{SEC}", "" + secs)
			.replace("{TIMESUFFIX}", getTranslatedString(units));
	}
	else // default: builder
	{
		int wood_amount = matchtime_wood_amount;
		int stone_amount = matchtime_stone_amount;
		if (this.isWarmup())
		{
			wood_amount = warmup_wood_amount;
			stone_amount = warmup_stone_amount;
		}

		string need_to_switch_string = "";
		if (player_class != "builder") need_to_switch_string = getTranslatedString("and switch to builder ");

		resupply_available = getTranslatedString("Go to a builder shop or a respawn point {SWITCH}to get a resupply of {WOOD} wood and {STONE} stone.")
			.replace("{SWITCH}", need_to_switch_string)
			.replace("{WOOD}", "" + wood_amount)
			.replace("{STONE}", "" + stone_amount);

		resupply_unavailable = getTranslatedString("Next resupply of {WOOD} wood and {STONE} stone in {SEC}{TIMESUFFIX}.")
			.replace("{SEC}", "" + secs)
			.replace("{TIMESUFFIX}", getTranslatedString(units))
			.replace("{WOOD}", "" + wood_amount)
			.replace("{STONE}", "" + stone_amount);
	}
		
	if (next_items > getGameTime()) // Unavailable resupply - shown on upper center of screen
	{
		SColor color = SColor(255, 255, 55, 55);
			
		string text = resupply_unavailable;

		float x = getScreenWidth() / 2;
		float y = getScreenHeight() / 3 - offset_second.y;

		GUI::DrawTextCentered(text, Vec2f(x, y), color);
	}
	else if (this.getCurrentState() == GAME) // Available resupply & not warmup - shown above inventory GUI
	{
		SColor color = SColor(200, 135, 185, 45);

		string text = resupply_available;

		float x = getScreenWidth() / 3 + offset.x;
		float y = getScreenHeight() - offset.y;

		GUI::DrawTextCentered(text, Vec2f(x, y), color);
	}
}

// normal hooks

void Reset(CRules@ this)
{
	//restart everyone's timers
	for (uint i = 0; i < getPlayersCount(); ++i) {
		SetCTFTimer(this, getPlayer(i), 0, "builder");
		SetCTFTimer(this, getPlayer(i), 0, "archer");
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

void onTick(CRules@ this)
{
	if (!isServer())
		return;
	
	s32 gametime = getGameTime();
	
	if ((gametime % 15) != 5)
		return;
	
	if (this.isWarmup()) 
	{
		// during building time, give everyone resupplies no matter where they are
		for (int i = 0; i < getPlayerCount(); i++) 
		{
			CPlayer@ player = getPlayer(i);
			CBlob@ blob = player.getBlob();
			if (blob !is null) 
			{
				doGiveSpawnMats(this, player, blob);
			}
		}
	}
	else 
	{
		CBlob@[] spots;
		getBlobsByName(base_name(),   @spots);
		getBlobsByName("ballista",	@spots);
		getBlobsByName("warboat",	 @spots);
		getBlobsByName("buildershop", @spots);
		getBlobsByName("archershop",  @spots);
		// getBlobsByName("knightshop",  @spots);
		for (uint step = 0; step < spots.length; ++step) 
		{
			CBlob@ spot = spots[step];
			if (spot is null) continue;

			CBlob@[] overlapping;
			if (!spot.getOverlapping(overlapping)) continue;

			string name = spot.getName();
			bool isShop = (name.find("shop") != -1);

			for (uint o_step = 0; o_step < overlapping.length; ++o_step) 
			{
				CBlob@ overlapped = overlapping[o_step];
				if (overlapped is null) continue;
				
				if (!overlapped.hasTag("player")) continue;
				CPlayer@ p = overlapped.getPlayer();
				if (p is null) continue;

				string class_name = overlapped.getName();
				
				if (isShop && name.find(class_name) == -1) continue; // NOTE: builder doesn't get wood+stone at archershop, archer doesn't get arrows at buildershop

				doGiveSpawnMats(this, p, overlapped);
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
	if (p is null || !p.isMyPlayer()) return;
	
	CBlob@ b = p.getBlob();
	if (b is null) return;
	
	string name = b.getName();

	GUI::SetFont("menu");

	// Display builder resupply text for everyone
	string propname = getCTFTimerPropertyName(p, "builder");
	if (this.exists(propname)) 
	{
		Vec2f offset = Vec2f(20, 64);
		Vec2f offset_second = Vec2f(0, 70);
		string resupply_class = "builder";
		displayResupply(this, name, resupply_class, offset, offset_second, propname);
	}
	
	// Display archer resupply text for archers
	propname = getCTFTimerPropertyName(p, "archer");
	if (name == "archer" && this.exists(propname))
	{
		Vec2f offset = Vec2f(20, 96);
		Vec2f offset_second = Vec2f(0, 16);
		string resupply_class = "archer";
		displayResupply(this, name, resupply_class, offset, offset_second, propname);
	}
}

// Reset timer in case player who joins has an outdated timer
void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	s32 next_add_time = getGameTime() + (this.isWarmup() ? materials_wait_warmup : materials_wait) * getTicksASecond();

	if (next_add_time < getCTFTimer(this, player, "builder") || next_add_time < getCTFTimer(this, player, "archer"))
	{
		SetCTFTimer(this, player, getGameTime(), "builder");
		SetCTFTimer(this, player, getGameTime(), "archer");
	}
}