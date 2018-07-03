// generic crate
// can hold items in inventory or unpacks to catapult/ship etc.

#include "CrateCommon.as"
#include "VehicleAttachmentCommon.as"
#include "MiniIconsInc.as"
#include "Help.as"

const string required_space = "required space";

void onInit(CBlob@ this)
{
	this.addCommandID("unpack");
	this.addCommandID("getin");
	this.addCommandID("getout");
	this.addCommandID("stop unpack");

	u8 frame = 0;
	if (this.exists("frame"))
	{
		frame = this.get_u8("frame");
		string packed = this.get_string("packed");

		// GIANT HACK!!!
		if (packed == "catapult" || packed == "bomber" || packed == "ballista" || packed == "mounted_bow" || packed == "longboat" || packed == "warboat")	 // HACK:
		{
			CSpriteLayer@ icon = this.getSprite().addSpriteLayer("icon", "/MiniIcons.png" , 16, 16, this.getTeamNum(), -1);
			if (icon !is null)
			{
				Animation@ anim = icon.addAnimation("display", 0, false);
				anim.AddFrame(frame);

				icon.SetOffset(Vec2f(-2, 1));
				icon.SetRelativeZ(1);
			}
			this.getSprite().SetAnimation("label");

			// help
			const string iconToken = "$crate_" + packed + "$";
			AddIconToken("$crate_" + packed + "$", "/MiniIcons.png", Vec2f(16, 16), frame);
			SetHelp(this, "help use", "", iconToken + getTranslatedString("Unpack {ITEM}   $KEY_E$").replace("{ITEM}", packed), "", 4);
		}
		else
		{
			u8 newFrame = 0;

			if (packed == "kitchen")
				newFrame = FactoryFrame::kitchen;
			if (packed == "nursery")
				newFrame = FactoryFrame::nursery;
			if (packed == "tunnel")
				newFrame = FactoryFrame::tunnel;
			if (packed == "healing")
				newFrame = FactoryFrame::healing;
			if (packed == "factory")
				newFrame = FactoryFrame::factory;
			if (packed == "storage")
				newFrame = FactoryFrame::storage;

			if (newFrame > 0)
			{
				CSpriteLayer@ icon = this.getSprite().addSpriteLayer("icon", "/MiniIcons.png" , 16, 16, this.getTeamNum(), -1);
				if (icon !is null)
				{
					icon.SetFrame(newFrame);
					icon.SetOffset(Vec2f(-2, 1));
					icon.SetRelativeZ(1);
				}
				this.getSprite().SetAnimation("label");
			}

		}	 //END OF HACK
	}

	const uint unpackSecs = 3;
	this.set_u32("unpack secs", unpackSecs);
	this.set_u32("unpack time", 0);

	if (this.exists("packed name"))
	{
		if (this.get_string("packed name").length > 1)
			this.setInventoryName("Crate with " + this.get_string("packed name"));
	}

	if (!this.exists(required_space))
	{
		this.set_Vec2f(required_space, Vec2f(5, 4));
	}

	this.getSprite().SetZ(-10.0f);
}

void onTick(CBlob@ this)
{
	// parachute

	if (this.hasTag("parachute"))		// wont work with the tick frequency
	{
		if (this.getSprite().getSpriteLayer("parachute") is null)
		{
			ShowParachute(this);
		}

		// para force + swing in wind
		this.AddForce(Vec2f(Maths::Sin(getGameTime() * 0.03f) * 1.0f, -30.0f * this.getVelocity().y));

		if (this.isOnGround() || this.isInWater() || this.isAttached())
		{
			Land(this);
		}
	}
	else
	{
		if (hasSomethingPacked(this))
			this.getCurrentScript().tickFrequency = 15;
		else
		{
			this.getCurrentScript().tickFrequency = 0;
			return;
		}

		// unpack
		u32 unpackTime = this.get_u32("unpack time");

		// can't unpack in no build sector or blocked in with walls!
		if (!canUnpackHere(this))
		{
			this.set_u32("unpack time", 0);
			this.getCurrentScript().tickFrequency = 15;
			this.getShape().setDrag(2.0);
			return;
		}

		if (unpackTime != 0 && getGameTime() >= unpackTime)
		{
			Unpack(this);
			return;
		}
	}
}

void Land(CBlob@ this)
{
	this.Untag("parachute");
	HideParachute(this);

	// unpack immediately
	if (this.exists("packed") && this.hasTag("unpack on land"))
	{
		Unpack(this);
	}

	if (this.hasTag("destroy on touch"))
	{
		this.server_SetHealth(-1.0f); // TODO: wont gib on client
		this.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("parachute");
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (this.hasTag("unpackall"))
		return false;

	if (!hasSomethingPacked(this)) // It's a normal crate
	{
		CBlob@ sneaky_player = getPlayerInside(this);
		return(sneaky_player is null);
	}

	else // has something packed
	{
		return false;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	Vec2f buttonpos(0, 0);
	CBlob@ sneaky_player = getPlayerInside(this);
	if (sneaky_player !is null && sneaky_player is caller)
	{
		CBitStream params;
		params.write_u16( caller.getNetworkID() );
		caller.CreateGenericButton( 6, Vec2f(0,0), this, this.getCommandID("getout"), "Get out", params );
	}
	else
	if (this.hasTag("unpackall"))
	{
		caller.CreateGenericButton(12, buttonpos, this, this.getCommandID("unpack"), getTranslatedString("Unpack all"));
	}
	else if (hasSomethingPacked(this) && !canUnpackHere(this))
	{
		string msg = getTranslatedString("Can't unpack {ITEM} here").replace("{ITEM}", getTranslatedString(this.get_string("packed name")));

		CButton@ button = caller.CreateGenericButton(12, buttonpos, this, 0, msg);
		if (button !is null)
		{
			button.SetEnabled(false);
		}
	}
	else if (isUnpacking(this))
	{
		caller.CreateGenericButton("$DISABLED$", buttonpos, this, this.getCommandID("stop unpack"), getTranslatedString("Stop {ITEM}").replace("{ITEM}", getTranslatedString(this.get_string("packed name"))));
	}
	else if (hasSomethingPacked(this))
	{
		caller.CreateGenericButton(12, buttonpos, this, this.getCommandID("unpack"), getTranslatedString("Unpack {ITEM}").replace("{ITEM}", getTranslatedString(this.get_string("packed name"))));
	}
	else if (caller.getCarriedBlob() is this)
	{
		CBitStream params;
		params.write_u16( caller.getNetworkID() );
		caller.CreateGenericButton( 4, Vec2f(0,0), this, this.getCommandID("getin"), "Get inside", params );
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("unpack"))
	{
		if (hasSomethingPacked(this))
		{
			if (canUnpackHere(this))
			{
				this.set_u32("unpack time", getGameTime() + this.get_u32("unpack secs") * getTicksASecond());
				this.getShape().setDrag(10.0f);
			}
		}
		else
		{
			this.server_SetHealth(-1.0f);
			this.server_Die();
		}
	}
	else if (cmd == this.getCommandID("stop unpack"))
	{
		this.set_u32("unpack time", 0);
	}
	else if (cmd == this.getCommandID("getin"))
	{
		CBlob @caller = getBlobByNetworkID( params.read_u16() );

		if (caller !is null) {
			Vec2f velocity = caller.getVelocity();
			this.server_PutInInventory( caller );
			this.setVelocity(velocity);
		}
	}
	else if (cmd == this.getCommandID("getout"))
	{
		CBlob @caller = getBlobByNetworkID( params.read_u16() );

		if (caller !is null) {
			this.server_PutOutInventory( caller );
		}
		this.server_Die();
	}
}

void Unpack(CBlob@ this)
{
	if(!getNet().isServer()) return;

	CBlob@ blob = server_CreateBlob(this.get_string("packed"), this.getTeamNum(), Vec2f_zero);

	// put on ground if not in water

	if (blob !is null && blob.getShape() !is null)
	{
		blob.setPosition(this.getPosition() + Vec2f(0, (this.getHeight() - blob.getHeight()) / 2));
		//	if (!getMap().isInWater(this.getPosition() + Vec2f(0.0f, this.getRadius())))
		//	blob.getShape().PutOnGround();
		//	else
		//		blob.getShape().ResolveInsideMapCollision();

		// attach to VEHICLE attachment if possible

		TryToAttachVehicle(blob);

		// msg back factory so it can add this item

		if (this.exists("msg blob"))
		{
			CBitStream params;
			params.write_u16(blob.getNetworkID());
			CBlob@ factory = getBlobByNetworkID(this.get_u16("msg blob"));
			if (factory !is null)
			{
				factory.SendCommand(factory.getCommandID("track blob"), params);
			}
		}

		blob.SetFacingLeft(this.isFacingLeft());
	}

	this.server_SetHealth(-1.0f); // TODO: wont gib on client
	this.server_Die();
}

bool isUnpacking(CBlob@ this)
{
	return getGameTime() <= this.get_u32("unpack time");
}

void ShowParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.addSpriteLayer("parachute",   32, 32);

	if (parachute !is null)
	{
		Animation@ anim = parachute.addAnimation("default", 0, true);
		anim.AddFrame(4);
		parachute.SetOffset(Vec2f(0.0f, - 17.0f));
	}
}

void HideParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.getSpriteLayer("parachute");

	if (parachute !is null && parachute.isVisible())
	{
		parachute.SetVisible(false);
		ParticlesFromSprite(parachute);
	}
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("player"))
	{
		Vec2f velocity = this.getVelocity();
		velocity.y = -5; // Leap out of crate
		blob.setVelocity(velocity);
	}
	// die on empty crate
	// if (!this.isInInventory() && this.getInventory().getItemsCount() == 0)
	// {
	// 	this.server_Die();
	// }
}

void onDie(CBlob@ this)
{
	HideParachute(this);
	this.getSprite().Gib();
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	//custom gibs
	string fname = CFileMatcher("/Crate.png").getFirst();
	for (int i = 0; i < 4; i++)
	{
		CParticle@ temp = makeGibParticle(fname, pos, vel + getRandomVelocity(90, 1 , 120), 9, 2 + i, Vec2f(16, 16), 2.0f, 20, "Sounds/material_drop.ogg", 0);
	}
}

bool canUnpackHere(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	Vec2f space = this.get_Vec2f(required_space);
	Vec2f t_off = Vec2f(map.tilesize * 0.5f, map.tilesize * 0.5f);
	Vec2f offsetPos = crate_getOffsetPos(this, map);
	for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
	{
		for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
		{
			Vec2f temp = (Vec2f(step_x + 0.5, step_y + 0.5) * map.tilesize);
			Vec2f v = offsetPos + temp;
			if (v.y < map.tilesize || map.isTileSolid(v))
			{
				return false;
			}
		}
	}

	string packed = this.get_string("packed");
	//required vertical buffer for siege engines and boats
	if(packed == "ballista" || packed == "catapult" || packed == "longboat" || packed == "warboat")
	{
		if(pos.y < 32)
		{
			return false;
		}
	}

	bool water = packed == "longboat" || packed == "warboat";
	if (this.isAttached())
	{
		CBlob@ parent = this.getAttachments().getAttachedBlob("PICKUP", 0);
		if (parent !is null)
		{
			return ((!water && parent.isOnGround()) || (water && map.isInWater(parent.getPosition() + Vec2f(0.0f, 8.0f))));
		}
	}
	bool inwater = map.isInWater(this.getPosition() + Vec2f(0.0f, 8.0f));
	bool supported = ((!water && (this.isOnGround() || inwater)) || (water && inwater));
	return (supported);
}

Vec2f crate_getOffsetPos(CBlob@ blob, CMap@ map)
{
	Vec2f halfSize = blob.get_Vec2f(required_space) * 0.5f;

	Vec2f alignedWorldPos = map.getAlignedWorldPos(blob.getPosition() + Vec2f(0, -2)) + (Vec2f(0.5f, 0.0f) * map.tilesize);
	Vec2f offsetPos = alignedWorldPos - Vec2f(halfSize.x , halfSize.y) * map.tilesize;
	return offsetPos;
}

CBlob@ getPlayerInside(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item.hasTag("player"))
			return item;
	}
	return null;
}

// SPRITE

// render unpacking time

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!(blob.exists("packed")) || blob.get_string("packed name").size() == 0) return;

	Vec2f pos2d = blob.getScreenPos();
	u32 gameTime = getGameTime();
	u32 unpackTime = blob.get_u32("unpack time");

	if (unpackTime > gameTime)
	{
		// draw drop time progress bar
		int top = pos2d.y - 1.0f * blob.getHeight();
		Vec2f dim(32.0f, 12.0f);
		int secs = 1 + (unpackTime - gameTime) / getTicksASecond();
		Vec2f upperleft(pos2d.x - dim.x / 2, top - dim.y - dim.y);
		Vec2f lowerright(pos2d.x + dim.x / 2, top - dim.y);
		f32 progress = 1.0f - (float(secs) / float(blob.get_u32("unpack secs")));
		GUI::DrawProgressBar(upperleft, lowerright, progress);
	}

	if (blob.isAttached())
	{
		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");

		CBlob@ holder = point.getOccupied();

		if (holder is null) { return; }

		CPlayer@ local = getLocalPlayer();
		if (local !is null && local.getBlob() is holder)
		{
			CMap@ map = blob.getMap();
			if (map is null) return;

			Vec2f space = blob.get_Vec2f(required_space);
			Vec2f offsetPos = crate_getOffsetPos(blob, map);

			const f32 scalex = getDriver().getResolutionScaleFactor();
			const f32 zoom = getCamera().targetDistance * scalex;
			Vec2f aligned = getDriver().getScreenPosFromWorldPos(offsetPos);
			GUI::DrawIcon("CrateSlots.png", 0, Vec2f(40, 32), aligned, zoom);

			for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
			{
				for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
				{
					Vec2f temp = (Vec2f(step_x + 0.5, step_y + 0.5) * map.tilesize);
					Vec2f v = offsetPos + temp;
					if (map.isTileSolid(v))
					{
						GUI::DrawIcon("CrateSlots.png", 5, Vec2f(8, 8), aligned + (temp - Vec2f(0.5f, 0.5f)* map.tilesize) * 2 * zoom, zoom);
					}
				}
			}
		}
	}

}
