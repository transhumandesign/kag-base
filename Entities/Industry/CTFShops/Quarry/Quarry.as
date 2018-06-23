//Auto-mining quarry
//mines stone over time, faster near mid

#include "Costs.as"

//balance        seconds * 30  // ticks
const int min_time =  60 * 30; // ticks
const int max_time = 180 * 30; // ticks
const int amount_dropped = 100; // stone dropped

const int tickrate = 90;

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
	this.getCurrentScript().tickFrequency = tickrate;

	//quarry properties

	f32 xpos = this.getPosition().x;
	CMap@ map = this.getMap();
	f32 mapcenter = map.tilesize * map.tilemapwidth / 2;

	this.set_u16("ticks_worked", 0);
	// % efficiency from 0-1, increases linearly from edge to center
	this.set_f32("efficiency", (mapcenter - Maths::Abs(mapcenter - xpos)) / mapcenter);
	// immediately start production
	this.set_bool("working", true);

	//commands
	this.addCommandID("collect stone");
}

void onTick(CBlob@ this)
{
	//only do "real" update logic on server
	if(getNet().isServer())
	{

		if (this.get_bool("working"))
		{
			u16 ticks_of_work = this.get_u16("ticks_worked");

			// If we've worked long enough to make stone, stop working and wait for button press
			if (ticks_of_work >= max_time - (this.get_f32("efficiency") * (max_time - min_time)))
			{
				this.set_bool("working", false);
				this.set_u16("ticks_worked", 0);
			}
			else
			{
				this.set_u16("ticks_worked", ticks_of_work + tickrate);
			}
		}

		//keep properties in sync (only done each update and delta-compressed anyway)
		this.Sync("working", true);
	}

	if (getNet().isClient())
	{
		//update sprite based on modified or synced properties
		UpdateStoneLayer(this.getSprite());
		AnimateBelt(this, this.get_bool("working"));
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
		float prog = (blob.get_u16("ticks_worked")
					 / (max_time - (blob.get_f32("efficiency") * (max_time - min_time))));
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
			button.deleteAfterClick = false;
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
			if (not this.get_bool("working"))
			{
				CPlayer@ player = caller.getPlayer();
				if (player !is null) 
				{
					player.server_setCoins(player.getCoins() - CTFCosts::dispense_stone);
				}
				this.set_bool("working", true);
				SpawnOre(this);
			}
		}

		if (getNet().isClient())
		{
			this.set_bool("working", true);
			UpdateStoneLayer(this.getSprite());
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

		// Kill any lanterns that may be there

		if (blob.exists("lantern id"))
		{
			CBlob@ lantern = getBlobByNetworkID(blob.get_u16("lantern id"));
			if (lantern !is null)
			{
				lantern.server_Die();
			}
		}
	}
	else
	{
		layer.SetVisible(true);

		// Also attach a lantern *ding*
		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("LANTERN");
		if (getNet().isServer() && point.getOccupied() is null)
		{
			CBlob@ lantern = server_CreateBlob("lantern");
			if (lantern !is null)
			{
				lantern.server_setTeamNum(blob.getTeamNum());
				lantern.getShape().getConsts().collidable = false;
				blob.server_AttachTo(lantern, "LANTERN");
				blob.set_u16("lantern id", lantern.getNetworkID());
				Sound::Play("SparkleShort.ogg", lantern.getPosition());
			}
		}
	}

	// Attach a lantern *ding*
}

void AnimateBelt(CBlob@ this, bool isActive)
{
	//safely fetch the animation to modify
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ belt = sprite.getSpriteLayer("belt");
	if (belt is null) return;
	Animation@ anim = belt.getAnimation("default");
	if (anim is null) return;

	//modify it based on activity
	if (isActive)
	{
		anim.time = 7 - 5 * this.get_f32("efficiency");
	}
	else
	{
		//(not tossing stone)
		if(anim.frame < 2 || anim.frame > 8)
		{
			anim.time = 0;
		}
	}
}
