//Auto-mining quarry
//mines stone over time, faster near mid

#include "Costs.as"

//balance        seconds * 30   = ticks
//Resupply: 100stone/ 67 * 30
const int min_time =  60 * 30; // ticks
const int max_time = 120 * 30; // ticks
// If min_time >= max_time, all quarries will work at max_time
const int amount_dropped = 100; // stone dropped

void onInit(CSprite@ this)
{
	CSpriteLayer@ belt = this.addSpriteLayer("belt", "QuarryBelt.png", 32, 32);
	if (belt !is null)
	{
		//default anim
		{
			Animation@ anim = belt.addAnimation("default", 0, true);
			int[] frames = {
				0, 1, 2, 3,
				4, 5, 6, 7,
				8, 9, 10, 11,
				12, 13
			};
			anim.AddFrames(frames);
		}
		//belt setup
		belt.SetOffset(Vec2f(-7.0f, -4.0f));
		belt.SetRelativeZ(1);
		belt.SetVisible(true);
	}

	CSpriteLayer@ stone = this.addSpriteLayer("stone", "Quarry.png", 16, 16);
	if (stone !is null)
	{
		stone.SetOffset(Vec2f(8.0f, -1.0f));
		stone.SetVisible(false);
		stone.SetFrameIndex(5);
	}
}

void onInit(CBlob@ this)
{
	InitCosts();

	//building properties

	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getSprite().SetZ(-50);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 90; // Tickrate

	//quarry properties

	f32 xpos = this.getPosition().x;
	CMap@ map = this.getMap();
	f32 mapcenter = map.tilesize * map.tilemapwidth / 2;

	this.set_u16("ticks_worked", 0);
	// % efficiency from 0-1, increases linearly from edge to center
	if (min_time < max_time)
	{
		this.set_f32("efficiency", (mapcenter - Maths::Abs(mapcenter - xpos)) / mapcenter);
	}
	else // min_time >= max_time; all quarries same speed
	{
		// math will use max_time, so this is just for animation
		this.set_f32("efficiency", 0.5);
	}
	// immediately start production
	this.set_bool("working", true);

	//commands
	this.addCommandID("collect stone");
}

void onTick(CBlob@ this)
{
	bool client = getNet().isClient();
	if (this.get_bool("working"))
	{
		u16 ticks_of_work = this.get_u16("ticks_worked");
		u8 tickrate = this.getCurrentScript().tickFrequency;

		// If we've worked long enough to make stone, stop working and wait for button press
		u16 time_to_produce = (min_time < max_time ? 
								  (max_time - (this.get_f32("efficiency") * (max_time - min_time)))
								: (max_time));
		if (ticks_of_work >= time_to_produce) // we're done!
		{
			if (client)
			{
				// Speed up tickrate temporarily to make sure the belt stops quickly
				this.getCurrentScript().tickFrequency = 10;
			}
			else // server
			{
				SetQuarryLantern(this, true);
			}
			this.set_bool("working", false);
			this.set_u16("ticks_worked", 0);
		}
		else
		{
			this.set_u16("ticks_worked", ticks_of_work + tickrate);
		}
	}

	if (client)
	{
		//update sprite based on modified or synced properties
		UpdateStoneLayer(this.getSprite());
		AnimateBelt(this);
	}
}

void onDie(CBlob@ this)
{
	if (getNet().isServer() && not this.get_bool("working"))
	{
		// Drop the stone that was there so it isn't wasted
		SpawnOre(this);

		// Kill the light, free lanterns OP
		SetQuarryLantern(this, false);
	}
}

void onRender(CSprite@ this)
{
	// Progress bar when moused over

	CBlob@ blob = this.getBlob();

	if (not blob.get_bool("working")) return;

	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;

	// Not for enemies to see
	if (localBlob.getTeamNum() != blob.getTeamNum()) return;

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;

	if (mouseOnBlob and localBlob.isKeyPressed(key_use))
	{
		Vec2f pos = blob.getScreenPos();
		Vec2f upperleft = Vec2f(pos.x - 30.f, pos.y - 15.f);
		Vec2f lowerright = Vec2f(pos.x + 30.f, pos.y);
		u16 time_to_produce = (min_time < max_time ? 
								  (max_time - (blob.get_f32("efficiency") * (max_time - min_time)))
								: (max_time));
		float prog = (blob.get_u16("ticks_worked") / float(time_to_produce));
		GUI::DrawProgressBar(upperleft, lowerright, prog);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (not this.get_bool("working") and this.isOverlapping(caller))
	{
		CButton@ button = caller.CreateGenericButton("$mat_stone$", Vec2f(-4.0f, 0.0f), this,
													 this.getCommandID("collect stone"), 
													 "Collect stone (" + CTFCosts::dispense_stone 
													 	+ " coins)", params);
		if (button !is null)
		{
			button.deleteAfterClick = true;
			button.SetEnabled(caller.getPlayer().getCoins() >= CTFCosts::dispense_stone);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("collect stone"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if(caller is null) return;


		if (getNet().isServer())
		{
			// Make sure it's actually ready
			if (not this.get_bool("working"))
			{
				// Sell the stone
				CPlayer@ player = caller.getPlayer();
				if (player !is null)
				{
					player.server_setCoins(player.getCoins() - CTFCosts::dispense_stone);
				}
				this.set_bool("working", true);
				SpawnOre(this);

				// Turn off the light
				SetQuarryLantern(this, false);
			}
		}

		if (getNet().isClient())
		{
			if (caller.isMyPlayer())
			{
				this.getSprite().PlaySound("/ChaChing.ogg");
			}

			this.set_bool("working", true);
			UpdateStoneLayer(this.getSprite());
			AnimateBelt(this);
		}
	}
}

void SpawnOre(CBlob@ this)
{
	CBlob@ ore = server_CreateBlobNoInit("mat_stone");

	if (ore is null) return;

	ore.Tag('custom quantity');
	ore.Init();
	ore.setPosition(this.getPosition() + Vec2f(-8.0f, 0.0f));
	ore.server_SetQuantity(amount_dropped);
}

void UpdateStoneLayer(CSprite@ this)
{
	CSpriteLayer@ layer = this.getSpriteLayer("stone");
	CBlob@ blob = this.getBlob();

	if (layer is null) return;

	if (this.getBlob().get_bool("working"))
	{
		layer.SetVisible(false);
	}
	else // Not working
	{
		layer.SetVisible(true);
	}
}

void AnimateBelt(CBlob@ this)
{
	//safely fetch the animation to modify
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ belt = sprite.getSpriteLayer("belt");
	if (belt is null) return;
	Animation@ anim = belt.getAnimation("default");
	if (anim is null) return;

	//modify it based on activity
	if (this.get_bool("working"))
	{
		anim.time = 7 - 5 * this.get_f32("efficiency");
	}
	else
	{
		//(not tossing stone)
		if(anim.frame < 2 || anim.frame > 8)
		{
			if (anim.time != 0)
			{
				this.getCurrentScript().tickFrequency = 90;
			}
			anim.time = 0;
		}
	}
}

void SetQuarryLantern(CBlob@ this, bool lit)
{
	if (not getNet().isServer())
	{
		return;
	}

	if (lit) // make sure there's a lantern
	{
		// Attach a lantern *ding*
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("LANTERN");
		if (point.getOccupied() is null)
		{
			CBlob@ lantern = server_CreateBlob("lantern");
			if (lantern !is null)
			{
				lantern.server_setTeamNum(this.getTeamNum());
				lantern.getShape().getConsts().collidable = false;
				this.server_AttachTo(lantern, "LANTERN");
				this.set_u16("lantern id", lantern.getNetworkID());
				Sound::Play("SparkleShort.ogg", lantern.getPosition());
			}
		}
	}
	else // Not lit, we should turn off/ kill lantern
	{
		if (this.exists("lantern id"))
		{
			CBlob@ lantern = getBlobByNetworkID(this.get_u16("lantern id"));
			if (lantern !is null)
			{
				lantern.server_Die();
			}
		}
	}
}
