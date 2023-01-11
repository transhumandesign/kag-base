// generic crate
// can hold items in inventory or unpacks to catapult/ship etc.

#include "CrateCommon.as"
#include "VehicleAttachmentCommon.as"
#include "MiniIconsInc.as"
#include "Help.as"
#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "KnockedCommon.as"

//property name
const string required_space = "required space";

//proportion of distance allowed (1.0f == overlapping radius, 2.0f = within 1 extra radius)
const float ally_allowed_distance = 2.0f;

void onInit(CBlob@ this)
{
	this.checkInventoryAccessibleCarefully = true;

	this.addCommandID("unpack");
	this.addCommandID("getin");
	this.addCommandID("getout");
	this.addCommandID("stop unpack");
	this.addCommandID("boobytrap");

	this.set_u32("boobytrap_cooldown_time", 0);

	this.set_s32("gold building amount", 0);

	u8 frame = 0;
	if (this.exists("frame"))
	{
		frame = this.get_u8("frame");
		string packed = this.get_string("packed");

		// GIANT HACK!!!
		if (packed == "catapult" || packed == "bomber" || packed == "ballista" || packed == "outpost" || packed == "mounted_bow" || packed == "longboat" || packed == "warboat")
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
	else
	{
		this.getAttachments().getAttachmentPointByName("PICKUP").offset = Vec2f(3, 4);
		this.getAttachments().getAttachmentPointByName("PICKUP").offsetZ = -10;
		this.getSprite().SetRelativeZ(-10.0f);
		this.AddScript("BehindWhenAttached.as");

		this.Tag("dont deactivate");
	}
	// Kinda hacky, only normal crates ^ with "dont deactivate" will ignore "activated"
	this.Tag("activated");


	const uint unpackSecs = 3;
	this.set_u32("unpack secs", unpackSecs);
	this.set_u32("unpack time", 0);

	if (this.exists("packed name"))
	{
		string name = getTranslatedString(this.get_string("packed name"));
		if (name.length > 1)
			this.setInventoryName("Crate with " + name);
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
	return (this.getName() == blob.getName())
		|| ((blob.getShape().isStatic() || blob.hasTag("player") || blob.hasTag("projectile")) && !blob.hasTag("parachute"));
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return (this.getTeamNum() == byBlob.getTeamNum() || this.isOverlapping(byBlob));
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (this.hasTag("unpackall") || !canSeeButtons(this, forBlob))
		return false;

	if (!hasSomethingPacked(this)) // It's a normal crate
	{
		if (forBlob.getCarriedBlob() !is null
			&& this.getInventory().canPutItem(forBlob.getCarriedBlob()))
		{
			return true; // OK to put an item in whenever
		}

		if (getPlayerInside(this) !is null)
		{
			return false; // Player getout buttons instead
		}

		if (this.getTeamNum() == forBlob.getTeamNum())
		{
			f32 dist = (this.getPosition() - forBlob.getPosition()).Length();
			f32 rad = (this.getRadius() + forBlob.getRadius());

			if (dist < rad * ally_allowed_distance)
			{
				return true; // Allies can access from further away
			}
		}
		else if (this.isOverlapping(forBlob))
		{
			return true; // Enemies can access when touching
		}

		return false;
	}

	else // has something packed
	{
		return false;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	Vec2f buttonpos(0, 0);

	bool putting = caller.getCarriedBlob() !is null && caller.getCarriedBlob() !is this;
	bool canput = putting && this.getInventory().canPutItem(caller.getCarriedBlob());
	CBlob@ sneaky_player = getPlayerInside(this);
	// If there's a player inside and we aren't just dropping in an item
	if (sneaky_player !is null && !(putting && canput))
	{
		if (sneaky_player.getTeamNum() == caller.getTeamNum())
		{
			CBitStream params;
			params.write_u16( caller.getNetworkID() );
			CButton@ button = caller.CreateGenericButton( 6, Vec2f(0,0), this, this.getCommandID("getout"), getTranslatedString("Get out"), params);
			if (putting)
			{
				button.SetEnabled(false);
			}
			if (sneaky_player !is caller) // it's a teammate, so they have to be close to use button
			{
				button.enableRadius = 20.0f;
			}
		}
		else // make fake buttons for enemy
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			if (caller.getCarriedBlob() is this)
			{
				// Fake get in button
				caller.CreateGenericButton(4, Vec2f(), this, this.getCommandID("getout"), getTranslatedString("Get inside"), params);
			}
			else
			{
				// Fake inventory button
				CButton@ button = caller.CreateGenericButton(13, Vec2f(), this, this.getCommandID("getout"), getTranslatedString("Crate"), params);
				button.enableRadius = 20.0f;
			}
		}
	}
	else if (this.hasTag("unpackall"))
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
		caller.CreateGenericButton( 4, Vec2f(0,0), this, this.getCommandID("getin"), getTranslatedString("Get inside"), params );
	}
	else if (this.getTeamNum() != caller.getTeamNum() && !this.isOverlapping(caller))
	{
		// We need a fake crate inventory button to hint to players that they need to get closer
		// And also so they're unable to discern which crates have hidden players
		if (caller.getCarriedBlob() is null || (putting && !canput))
		{
			CButton@ button = caller.CreateGenericButton(13, Vec2f(), this, this.getCommandID("getout"), getTranslatedString("Crate"));
			button.SetEnabled(false); // they shouldn't be able to actually press it tho
		}
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
		if (this.getHealth() <= 0)
		{
			return;
		}
		CBlob @caller = getBlobByNetworkID( params.read_u16() );

		if (caller !is null && this.getInventory() !is null) 
		{
			CInventory@ inv = this.getInventory();
			u8 itemcount = inv.getItemsCount();
			// Boobytrap if crate has enemy mine
			CBlob@ mine = null;
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ item = inv.getItem(i);
				if (item.getName() == "mine" && item.getTeamNum() != caller.getTeamNum())
				{
					CBitStream params;
					params.write_u16(caller.getNetworkID());
					params.write_u16(item.getNetworkID());
					this.SendCommand(this.getCommandID("boobytrap"), params);
					return;
				}
			}
			while (!inv.canPutItem(caller) && itemcount > 0)
			{
				// pop out last items until we can put in player or there's nothing left
				CBlob@ item = inv.getItem(itemcount - 1);
				this.server_PutOutInventory(item);
				float magnitude = (1 - XORRandom(3) * 0.25) * 5.0f;
				item.setVelocity(caller.getVelocity() + getRandomVelocity(90, magnitude, 45));
				itemcount--;
			}

			Vec2f velocity = caller.getVelocity();
			this.server_PutInInventory( caller );
			this.setVelocity(velocity);
		}
	}
	else if (cmd == this.getCommandID("getout"))
	{
		CBlob @caller = getBlobByNetworkID( params.read_u16() );
		CBlob@ sneaky_player = getPlayerInside(this);
		if (caller !is null && sneaky_player !is null) {
			if (caller.getTeamNum() != sneaky_player.getTeamNum())
			{
				if (isKnockable(caller))
				{
					setKnocked(caller, 30);
				}
			}
			this.Tag("crate escaped");
			this.server_PutOutInventory(sneaky_player);
		}
		// Attack self to pop out items
		this.server_Hit(this, this.getPosition(), Vec2f(), 100.0f, Hitters::crush, true);
		this.server_Die();
	}
	else if (cmd == this.getCommandID("boobytrap"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ mine = getBlobByNetworkID(params.read_u16());
		if (caller !is null && mine !is null && this.get_u32("boobytrap_cooldown_time") <= getGameTime())
		{
			this.set_u32("boobytrap_cooldown_time", getGameTime() + 30);
			this.server_PutOutInventory(mine);
			Vec2f pos = this.getPosition();
			pos.y = this.getTeamNum() == caller.getTeamNum() ? pos.y - 5
						: caller.getPosition().y - caller.getRadius() - 5;
			pos.y = Maths::Min(pos.y, this.getPosition().y - 5);
			mine.setPosition(pos);
			mine.setVelocity(Vec2f((caller.getPosition().x - mine.getPosition().x) / 30.0f, -5.0f));
			mine.set_u8("mine_timer", 255);
			mine.SendCommand(mine.getCommandID("mine_primed"));
		}
	}
	else if (cmd == this.getCommandID("activate"))
	{
		CBlob@ carrier = this.getAttachments().getAttachmentPointByName("PICKUP").getOccupied();
		if (carrier !is null)
		{
			DumpOutItems(this, 5.0f, carrier.getVelocity(), false);
		}
	}
}

void Unpack(CBlob@ this)
{
	if (!getNet().isServer()) return;

	CBlob@ blob = server_CreateBlob(this.get_string("packed"), this.getTeamNum(), Vec2f_zero);

	// put on ground if not in water

	if (blob !is null && blob.getShape() !is null)
	{
		CMap@ map = getMap();

		Vec2f space = this.get_Vec2f(required_space);
		Vec2f offsetPos = crate_getOffsetPos(this, map);
		Vec2f center = offsetPos + (Vec2f(space.x * map.tilesize / 2, space.y * map.tilesize / 2));

		blob.setPosition(center);

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

	this.set_s32("gold building amount", 0); // for crates with vehicles that cost gold
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

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	CInventory@ inv = this.getInventory();
	CBlob@ mine = null;
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item.hasTag("player"))
		{
			// Get out of there, can't grab players
			forBlob.ClearGridMenus();
		}
		if (item.getName() == "mine" && item.getTeamNum() != forBlob.getTeamNum())
		{
			CBitStream params;
			params.write_u16(forBlob.getNetworkID());
			params.write_u16(item.getNetworkID());
			this.SendCommand(this.getCommandID("boobytrap"), params);
			break;
		}
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("thud.ogg");
	if (blob.getName() == "keg")
	{
		if (blob.hasTag("exploding"))
		{
			this.Tag("heavy weight");
		}
		else
		{
			this.Tag("medium weight");
		}
	}
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("player"))
	{
		if (this.hasTag("crate exploded"))
		{
			this.getSprite().PlaySound(getTranslatedString("MigrantSayNo") + ".ogg", 1.0f, blob.getSexNum() == 0 ? 1.0f : 1.5f);
			Vec2f velocity = this.getVelocity();
			if (velocity.x > 0) // Blow them right
			{
				velocity = Vec2f(0.75, -1);
			}
			else if (velocity.x < 0) // Blow them left
			{
				velocity = Vec2f(-0.75, -1);
			}
			else // Go straight up
			{
				velocity = Vec2f(0, -1);
			}
			blob.setVelocity(velocity * 8);
			if (isKnockable(blob))
			{
				setKnocked(blob, 30);
			}
		}
		else if (this.hasTag("crate escaped"))
		{
			Vec2f velocity = this.getOldVelocity();
			if (-5 < velocity.y && velocity.y < 5)
			{
				velocity.y = -5; // Leap out of crate
			}
			Vec2f pos = this.getPosition();
			pos.y -= 5;
			blob.setPosition(pos);
			blob.setVelocity(velocity);

			blob.getSprite().PlaySound(getTranslatedString("MigrantSayHello") + ".ogg", 1.0f, blob.getSexNum() == 0 ? 1.0f : 1.25f);
		}
		else
		{
			blob.setVelocity(this.getOldVelocity());
			if (isKnockable(blob))
			{
				setKnocked(blob, 2);
			}
		}
	}

	if (blob.getName() == "keg")
	{
		if (blob.hasTag("exploding") && blob.get_s32("explosion_timer") - getGameTime() <= 0)
		{
			this.server_Hit(this, this.getPosition(), Vec2f(), 100.0f, Hitters::explosion, true);
		}

		this.Untag("medium weight");
		this.Untag("heavy weight"); // TODO: what if there can be multiple kegs?
	}

	// die on empty crate
	// if (!this.isInInventory() && this.getInventory().getItemsCount() == 0)
	// {
	// 	this.server_Die();
	// }
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	f32 dmg = damage;

	if (customData == Hitters::builder)
	{
		dmg *= 4;
	}
	if (customData == Hitters::saw)
	{
		DumpOutItems(this, 0);
	}
	if (isExplosionHitter(customData) || customData == Hitters::keg)
	{
		if (dmg > 50.0f) // inventory explosion
		{
			this.Tag("crate exploded");
			CBlob@ sneaky_player = getPlayerInside(this);
			DumpOutItems(this, 10);
			// Nearly kill the player
			if (sneaky_player !is null)
			{
				hitterBlob.server_Hit(sneaky_player, this.getPosition(), Vec2f(),
									  sneaky_player.getInitialHealth() * 2 - 0.25f, Hitters::explosion, true);
			}
		}
		else
		{
			if (customData == Hitters::keg)
			{
				dmg = Maths::Max(dmg, this.getInitialHealth() * 2); // Keg always kills crate
			}
			CBlob@ sneaky_player = getPlayerInside(this);
			if (sneaky_player !is null)
			{
				bool should_teamkill = (sneaky_player.getTeamNum() != hitterBlob.getTeamNum()
										|| customData == Hitters::keg);
				hitterBlob.server_Hit(getPlayerInside(this), this.getPosition(), Vec2f_zero,
									  dmg / 2, customData, should_teamkill);
			}
		}
	}
	if (this.getHealth() - (dmg / 2.0f) <= 0.0f)
	{
		DumpOutItems(this);
	}

	return dmg;
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

			if (this.hasTag("unpack_check_nobuild"))
			{
				if (map.getSectorAtPosition(v, "no build") !is null || hasNoBuildBlobs(v))
				{
					return false;
				}
			}
			if (v.y < map.tilesize || map.isTileSolid(v))
			{
				return false;
			}
		}
	}

	string packed = this.get_string("packed");
	//required vertical buffer for siege engines and boats
	if (packed == "ballista" || packed == "catapult" || packed == "longboat" || packed == "warboat")
	{
		if (pos.y < 40)
		{
			return false;
		}
	}

	bool water = packed == "longboat" || packed == "warboat";
	if (this.isAttached())
	{
		CBlob@ parent = this.getAttachments().getAttachmentPointByName("PICKUP").getOccupied();
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
	Vec2f space = blob.get_Vec2f("required space");
	space.x *= 0.5f;
	space.y -= 1;
	Vec2f offsetPos = map.getAlignedWorldPos(blob.getPosition() + Vec2f(4, 6) - space * map.tilesize);
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

bool DumpOutItems(CBlob@ this, float pop_out_speed = 5.0f, Vec2f init_velocity = Vec2f_zero, bool dump_special = true)
{
	bool dumped_anything = false;
	if (getNet().isClient())
	{
		if ((this.getInventory().getItemsCount() > 1)
			 || (getPlayerInside(this) is null && this.getInventory().getItemsCount() > 0))
		{
			this.getSprite().PlaySound("give.ogg");
		}
	}
	if (getNet().isServer())
	{
		Vec2f velocity = (init_velocity == Vec2f_zero) ? this.getOldVelocity() : init_velocity;
		CInventory@ inv = this.getInventory();
		u8 target_items_left = 0;
		u8 item_num = 0;

		while (inv !is null && (inv.getItemsCount() > target_items_left))
		{
			CBlob@ item = inv.getItem(item_num);

			if (!item.hasTag("player") && item.getName() != "mine")
			{
				dumped_anything = true;
				this.server_PutOutInventory(item);
				if (pop_out_speed == 0 || item.getName() == "keg")
				{
					item.setVelocity(velocity);
				}
				else
				{
					float magnitude = (1 - XORRandom(3) * 0.25) * pop_out_speed;
					item.setVelocity(velocity + getRandomVelocity(90, magnitude, 45));
				}
			}
			else if (dump_special && (item.hasTag("player") || item.getName() == "mine"))
			{
				this.server_PutOutInventory(item);
			}
			else // Don't dump player or mine
			{
				target_items_left++;
				item_num++;
			}
		}
	}
	return dumped_anything;
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
			//GUI::DrawIcon("CrateSlots.png", 0, Vec2f(40, 32), aligned, zoom);
			DrawSlots(space, aligned, zoom); //if (getGameTime() % 30 == 0)

			for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
			{
				for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
				{
					Vec2f temp = (Vec2f(step_x + 0.5, step_y + 0.5) * map.tilesize);
					Vec2f v = offsetPos + temp;
				
					if (map.isTileSolid(v) || (blob.hasTag("unpack_check_nobuild") && (map.getSectorAtPosition(v, "no build") !is null || hasNoBuildBlobs(v))))
					{
						GUI::DrawIcon("CrateSlots.png", 5, Vec2f(8, 8), aligned + (temp - Vec2f(0.5f, 0.5f)* map.tilesize) * 2 * zoom, zoom);
					}
				}
			}
		}
	}

}

void DrawSlots(Vec2f size, Vec2f pos, f32 zoom)
{
	int x = Maths::Floor(size.x);
	int y = Maths::Floor(size.y);
	CMap@ map = getMap();

	GUI::DrawRectangle(pos, pos + Vec2f(x, y) * map.tilesize * zoom * 2, SColor(125, 255, 255, 255));
	GUI::DrawLine2D(pos + Vec2f(0, 0) * map.tilesize * zoom * 2, pos + Vec2f(x, 0) * map.tilesize * zoom * 2, SColor(255, 255, 255, 255));
	GUI::DrawLine2D(pos + Vec2f(x, 0) * map.tilesize * zoom * 2, pos + Vec2f(x, y) * map.tilesize * zoom * 2, SColor(255, 255, 255, 255));
	GUI::DrawLine2D(pos + Vec2f(x, y) * map.tilesize * zoom * 2, pos + Vec2f(0, y) * map.tilesize * zoom * 2, SColor(255, 255, 255, 255));
	GUI::DrawLine2D(pos + Vec2f(0, y) * map.tilesize * zoom * 2, pos + Vec2f(0, 0) * map.tilesize * zoom * 2, SColor(255, 255, 255, 255));
}

const string[] noBuildBlobs = {"wooden_door", "stone_door", "wooden_platform", "bridge"};

bool hasNoBuildBlobs(Vec2f pos)
{
	CBlob@[] blobs;
	if (getMap().getBlobsAtPosition(pos + Vec2f(1, 1), blobs))
	{
		for (int i = 0; i < blobs.size(); i++)
		{
			CBlob@ blob = blobs[i];
			if (blob is null) continue;

			if (noBuildBlobs.find(blob.getName()) != -1)
			{
				return true;
			}
		}
	}

	return false;
}
