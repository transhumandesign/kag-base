// generic crate
// can hold items in inventory or unpacks to catapult/ship etc.

#include "CrateCommon.as"
#include "VehicleAttachmentCommon.as"
#include "MiniIconsInc.as"
#include "Help.as"
#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "KnockedCommon.as"
#include "NoSwearsCommon.as"
#include "ActivationThrowCommon.as"

// crate tags and their uses

// "parachute"      : this uses a parachute
// "unpackall"       : this can unpack even if there is no "packed" blob
// "unpack on land"    : this unpacks when touching ground
// "destroy on touch"   : this dies when touching ground
// "unpack_only_water"   : this can only unpack in water
// "unpack_check_nobuild" : this can only unpack if block-type blobs arent in the way

//proportion of distance allowed (1.0f == overlapping radius, 2.0f = within 1 extra radius)
const f32 ally_allowed_distance = 2.0f;

//time it takes to unpack the crate
const u32 unpackSecs = 3;

bool swearsReadIntoArray = false;

Crate@[] base_presets = 
{
	Crate("longboat",    FactoryFrame::longboat,    Vec2f(9, 4),  0, "unpack_only_water"),
	Crate("warboat",     FactoryFrame::warboat,     Vec2f(9, 6),  0, "unpack_only_water"),
	Crate("catapult",    FactoryFrame::catapult,    Vec2f(5, 3)),
	Crate("ballista",    FactoryFrame::ballista,    Vec2f(5, 5)),
	Crate("mounted_bow", FactoryFrame::mounted_bow, Vec2f(3, 3)),
	Crate("outpost",     FactoryFrame::outpost,     Vec2f(5, 5), 50, "unpack_check_nobuild")
};

void onInit(CBlob@ this)
{
	this.checkInventoryAccessibleCarefully = true;

	this.Tag("activatable");

	this.addCommandID("unpack");
	this.addCommandID("unpack_client"); // just sets the drag...
	this.addCommandID("getin");
	this.addCommandID("getout");
	this.addCommandID("stop unpack");
	this.addCommandID("boobytrap");

	Activate@ func = @onActivate;
	this.set("activate handle", @func);

	const string packed = this.exists("packed") ? this.get_string("packed") : "";
	if (!packed.isEmpty())
	{
		// use a preset if we can
		Crate@[] presets;
		getRules().get("crate presets", presets); //take from rules if applicable
		if (!UseCratePreset(this, packed, presets))
		{
			UseCratePreset(this, packed, base_presets);
		}
	}

	if (this.exists("frame") && !packed.isEmpty())
	{
		const u8 frame = this.get_u8("frame");

		CSpriteLayer@ icon = this.getSprite().addSpriteLayer("icon", "/MiniIcons.png", 16, 16, this.getTeamNum(), -1);
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
		AddIconToken(iconToken, "/MiniIcons.png", Vec2f(16, 16), frame);
		SetHelp(this, "help use", "", iconToken + getTranslatedString("Unpack {ITEM}   $KEY_E$").replace("{ITEM}", packed), "", 4);
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

	this.set_u32("unpack secs", unpackSecs);
	this.set_u32("unpack time", 0);
	this.set_u32("boobytrap_cooldown_time", 0);

	if (this.exists("packed name"))
	{
		const string name = getTranslatedString(this.get_string("packed name"));
		if (name.length > 1)
		{
			this.set_bool("no swears allowed", g_noswears);
			changeInventoryName(this);
		}
	}

	if (!this.exists("required space"))
	{
		this.set_Vec2f("required space", Vec2f(5, 4));
	}
	
	if (!this.exists("gold building amount"))
	{
		this.set_s32("gold building amount", 0);
	}

	this.getSprite().SetZ(-10.0f);
	
	// swears-related
	if (!swearsReadIntoArray)
		swearsReadIntoArray = InitSwearsArray();
}

bool UseCratePreset(CBlob@ this, const string &in packed, Crate@[] presets)
{
	for (int i = 0; i < presets.length; i++)
	{
		Crate@ preset = presets[i];
		if (preset.name != packed) continue;

		this.set_u8("frame", preset.frame);
		this.set_Vec2f("required space", preset.space);
		this.set_s32("gold building amount", preset.gold);

		for (int i = 0; i < preset.tags.length; i++)
		{
			this.Tag(preset.tags[i]);
		}

		return true;
	}
	return false;
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
		{
			this.getCurrentScript().tickFrequency = 15;
		
			bool no_swears_allowed = this.get_bool("no swears allowed");
			
			if (g_noswears != no_swears_allowed) // we need to update the inventory name
			{
				changeInventoryName(this);
				this.set_bool("no swears allowed", g_noswears);
			}
		}
		else
		{
			this.getCurrentScript().tickFrequency = 0;
			return;
		}

		// can't unpack in no build sector or blocked in with walls!
		if (!canUnpackHere(this))
		{
			this.set_u32("unpack time", 0);
			this.getCurrentScript().tickFrequency = 15;
			this.getShape().setDrag(2.0);
			return;
		}

		const u32 unpackTime = this.get_u32("unpack time");
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
		
	if (hasSomethingPacked(this))
	{
		return false;
	}

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
		const f32 dist = (this.getPosition() - forBlob.getPosition()).Length();
		const f32 rad = (this.getRadius() + forBlob.getRadius());

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

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	Vec2f buttonpos(0, 0);

	CBlob@ carried = caller.getCarriedBlob();
	const bool putting = carried !is null && carried !is this;
	const bool canput = putting && this.getInventory().canPutItem(carried);
	CBlob@ sneaky_player = getPlayerInside(this);
	// If there's a player inside and we aren't just dropping in an item
	if (sneaky_player !is null && !(putting && canput))
	{
		if (sneaky_player.getTeamNum() == caller.getTeamNum())
		{
			CButton@ button = caller.CreateGenericButton(6, buttonpos, this, this.getCommandID("getout"), getTranslatedString("Get out"));
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
			if (carried is this)
			{
				// Fake get in button
				caller.CreateGenericButton(4, buttonpos, this, this.getCommandID("getout"), getTranslatedString("Get inside"));
			}
			else
			{
				// Fake inventory button
				CButton@ button = caller.CreateGenericButton(13, buttonpos, this, this.getCommandID("getout"), getTranslatedString("Crate"));
				button.enableRadius = 20.0f;
			}
		}
	}
	else if (this.hasTag("unpackall"))
	{
		caller.CreateGenericButton(12, buttonpos, this, this.getCommandID("unpack"), getTranslatedString("Unpack all"));
	}
	else 
	{
		// censoring swears if necessary
		string packed_name;
		processSwears(this.get_string("packed name"), packed_name);
	
		if (hasSomethingPacked(this) && !canUnpackHere(this))
		{
			const string msg = getTranslatedString("Can't unpack {ITEM} here").replace("{ITEM}", getTranslatedString(packed_name));
			CButton@ button = caller.CreateGenericButton(12, buttonpos, this, 0, msg);
			if (button !is null)
			{
				button.SetEnabled(false);
			}
		}
		else if (isUnpacking(this))
		{		
			string text = getTranslatedString("Stop {ITEM}").replace("{ITEM}", getTranslatedString(packed_name));
			CButton@ button = caller.CreateGenericButton("$DISABLED$", buttonpos, this, this.getCommandID("stop unpack"), text);
			
			button.enableRadius = 20.0f;
		}
		else if (hasSomethingPacked(this))
	  {		
		  string text = getTranslatedString("Stop {ITEM}").replace("{ITEM}", getTranslatedString(packed_name));
	  	CButton@ button = caller.CreateGenericButton("$DISABLED$", buttonpos, this, this.getCommandID("stop unpack"), text);

		  button.enableRadius = 20.0f;
	  }
	  else if (hasSomethingPacked(this))
	  {
		  string text = getTranslatedString("Unpack {ITEM}").replace("{ITEM}", getTranslatedString(packed_name));
		  CButton@ button = caller.CreateGenericButton(12, buttonpos, this, this.getCommandID("unpack"), text);

		  button.enableRadius = 20.0f;
	  }
  	else if (carried is this)
    {
      caller.CreateGenericButton(4, buttonpos, this, this.getCommandID("getin"), getTranslatedString("Get inside"));
    }
    else if (this.getTeamNum() != caller.getTeamNum() && !this.isOverlapping(caller))
    {
      // We need a fake crate inventory button to hint to players that they need to get closer
      // And also so they're unable to discern which crates have hidden players
      if (carried is null || (putting && !canput))
      {
        CButton@ button = caller.CreateGenericButton(13, buttonpos, this, this.getCommandID("getout"), getTranslatedString("Crate"));
        button.SetEnabled(false); // they shouldn't be able to actually press it tho
      }
    }
	}
}

void onActivate(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;
		
	u16 caller_id;
	if (!params.saferead_u16(caller_id)) return;

	CBlob@ caller = getBlobByNetworkID(caller_id);
	if (caller is null) return;

	DumpOutItems(this, 5.0f, caller.getVelocity(), false);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("unpack") && isServer())
	{
		if (hasSomethingPacked(this))
		{
			if (canUnpackHere(this))
			{
				CPlayer@ p = getNet().getActiveCommandPlayer();
				if (p is null) return;
					
				CBlob@ caller = p.getBlob();
				if (caller is null) return;

				// range check
				if (this.getDistanceTo(caller) > 32.0f) return;

				this.server_setTeamNum(caller.getTeamNum());

				this.set_u32("unpack time", getGameTime() + this.get_u32("unpack secs") * getTicksASecond());
				this.Sync("unpack time", true);

				this.getShape().setDrag(10.0f);

				this.SendCommand(this.getCommandID("unpack_client"));
			}
		}
		else
		{
			this.server_SetHealth(-1.0f);
			this.server_Die();
		}
	}
	else if (cmd == this.getCommandID("unpack_client") && isClient())
	{
		this.getShape().setDrag(10.0f);
	}
	else if (cmd == this.getCommandID("stop unpack") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check
		f32 distance = this.getDistanceTo(caller);
		if (distance > 32.0f) return;

		this.set_u32("unpack time", 0);
		this.Sync("unpack time", true);
	}
	else if (cmd == this.getCommandID("getin") && isServer())
	{
		// i don't know why this check is here so not touching it...
		if (this.getHealth() <= 0) return;

		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// only getin if caller is holding this crate
		CBlob@ helditem = caller.getCarriedBlob();
		if (helditem is null) return;
		if (helditem !is this) return;

		CInventory@ inv = this.getInventory();
		if (caller !is null && inv !is null) 
		{
			u8 itemcount = inv.getItemsCount();
			// Boobytrap if crate has enemy mine
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ item = inv.getItem(i);
				if (item.getName() == "mine" && item.getTeamNum() != caller.getTeamNum())
				{
					BoobyTrap(this, caller, item);
					return;
				}
			}
			while (!inv.canPutItem(caller) && itemcount > 0)
			{
				// pop out last items until we can put in player or there's nothing left
				CBlob@ item = inv.getItem(itemcount - 1);
				this.server_PutOutInventory(item);
				const f32 magnitude = (1 - XORRandom(3) * 0.25) * 5.0f;
				item.setVelocity(caller.getVelocity() + getRandomVelocity(90, magnitude, 45));
				itemcount--;
			}

			Vec2f velocity = caller.getVelocity();
			this.server_PutInInventory(caller);
			this.setVelocity(velocity);
		}
	}
	else if (cmd == this.getCommandID("getout") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check
		f32 distance = this.getDistanceTo(caller);
		if (distance > 32.0f) return;

		CBlob@ sneaky_player = getPlayerInside(this);
		if (caller !is null && sneaky_player !is null)
		{
			if (caller.getTeamNum() != sneaky_player.getTeamNum())
			{
				if (isKnockable(caller))
				{
					setKnocked(caller, 30);
				}
			}
			this.Tag("crate escaped");
			this.Sync("crate escaped", true);
			this.server_PutOutInventory(sneaky_player);
		}
		// Attack self to pop out items
		this.server_Hit(this, this.getPosition(), Vec2f(), 100.0f, Hitters::crush, true);
		this.server_Die();
	}
	else if (cmd == this.getCommandID("boobytrap") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check
		f32 distance = this.getDistanceTo(caller);
		if (distance > 32.0f) return;

		CInventory@ inv = this.getInventory();
		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			if (item.hasTag("player"))
			{
				// This command should not have been sent if there's a player in the crate
				return;
			}
			if (item.getName() == "mine" && item.getTeamNum() != caller.getTeamNum())
			{
				// tell server to activate trap
				BoobyTrap(this, caller, item);
				break;
			}
		}
	}
}

void BoobyTrap(CBlob@ this, CBlob@ caller, CBlob@ mine)
{
	if (caller !is null && mine !is null && this.get_u32("boobytrap_cooldown_time") <= getGameTime())
	{
		this.set_u32("boobytrap_cooldown_time", getGameTime() + 30);
		this.Sync("boobytrap_cooldown_time", true);
		this.server_PutOutInventory(mine);
		Vec2f pos = this.getPosition();
		pos.y = this.getTeamNum() == caller.getTeamNum() ? pos.y - 5
					: caller.getPosition().y - caller.getRadius() - 5;
		pos.y = Maths::Min(pos.y, this.getPosition().y - 5);
		mine.setPosition(pos);
		mine.setVelocity(Vec2f((caller.getPosition().x - mine.getPosition().x) / 30.0f, -5.0f));

		// maybe add MineCommon.as in the future..?
		mine.set_u8("mine_timer", 255);
		mine.Sync("mine_timer", true);
		mine.set_u8("mine_state", 1);
		mine.Sync("mine_state", true);
		mine.getShape().checkCollisionsAgain = true;

		mine.SendCommand(mine.getCommandID("mine_primed_client"));
	}
}

void Unpack(CBlob@ this)
{
	if (!isServer()) return;
	
	CMap@ map = getMap();
	Vec2f space = this.get_Vec2f("required space");
	Vec2f offsetPos = crate_getOffsetPos(this, map);
	Vec2f center = offsetPos + space * map.tilesize * 0.5f;

	CBlob@ blob = server_CreateBlob(this.get_string("packed"), this.getTeamNum(), center);
	if (blob !is null && blob.getShape() !is null)
	{
		// put on ground if not in water
		//	if (!getMap().isInWater(this.getPosition() + Vec2f(0.0f, this.getRadius())))
		//		blob.getShape().PutOnGround();
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
	CSpriteLayer@ parachute = sprite.addSpriteLayer("parachute", 32, 32);
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
			// tell server to activate trap
			this.SendCommand(this.getCommandID("boobytrap"));
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

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
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
			DumpOutItems(this, 10);
			// Nearly kill the player
			CBlob@ sneaky_player = getPlayerInside(this);
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
				hitterBlob.server_Hit(sneaky_player, this.getPosition(), Vec2f_zero,
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
	const string fname = CFileMatcher("/Crate.png").getFirst();
	for (int i = 0; i < 4; i++)
	{
		CParticle@ temp = makeGibParticle(fname, pos, vel + getRandomVelocity(90, 1 , 120), 9, 2 + i, Vec2f(16, 16), 2.0f, 20, "Sounds/material_drop.ogg", 0);
	}
}

bool canUnpackHere(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	Vec2f space = this.get_Vec2f("required space");
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

	//no unpacking at map ceiling
	if (pos.y + 4 < (space.y + 2) * map.tilesize)
	{
		return false;
	}

	const bool water = this.hasTag("unpack_only_water");
	bool inwater = this.isInWater() || map.isInWater(pos + Vec2f(0.0f, map.tilesize));
	if (this.isAttached())
	{
		CBlob@ parent = this.getAttachments().getAttachmentPointByName("PICKUP").getOccupied();
		if (parent !is null)
		{
			inwater = parent.isInWater() || map.isInWater(parent.getPosition() + Vec2f(0.0f, parent.getRadius()));
			return ((!water && parent.isOnGround()) || (water && inwater));
		}
	}
	const bool supported = ((!water && this.isOnGround()) || (water && inwater));
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

bool DumpOutItems(CBlob@ this, f32 pop_out_speed = 5.0f, Vec2f init_velocity = Vec2f_zero, bool dump_special = true)
{
	bool dumped_anything = false;
	if (isClient())
	{
		if ((this.getInventory().getItemsCount() > 1)
			 || (getPlayerInside(this) is null && this.getInventory().getItemsCount() > 0))
		{
			this.getSprite().PlaySound("give.ogg");
		}
	}
	if (isServer())
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
					const f32 magnitude = (1 - XORRandom(3) * 0.25) * pop_out_speed;
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
	if (!blob.exists("packed") || blob.get_string("packed name").size() == 0) return;
	
	Vec2f pos2d = blob.getScreenPos();
	const u32 gameTime = getGameTime();
	const u32 unpackTime = blob.get_u32("unpack time");

	if (unpackTime > gameTime)
	{
		// draw drop time progress bar
		const int top = pos2d.y - 1.0f * blob.getHeight();
		Vec2f dim(32.0f, 12.0f);
		const int secs = 1 + (unpackTime - gameTime) / getTicksASecond();
		Vec2f upperleft(pos2d.x - dim.x / 2, top - dim.y - dim.y);
		Vec2f lowerright(pos2d.x + dim.x / 2, top - dim.y);
		const f32 progress = 1.0f - (f32(secs) / f32(blob.get_u32("unpack secs")));
		GUI::DrawProgressBar(upperleft, lowerright, progress);
	}

	if (blob.isAttached())
	{
		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");

		CBlob@ holder = point.getOccupied();
		if (holder is null || !holder.isMyPlayer()) return;

		CMap@ map = getMap();
		if (map is null) return;

		Vec2f space = blob.get_Vec2f("required space");
		Vec2f offsetPos = crate_getOffsetPos(blob, map);
		Vec2f aligned = getDriver().getScreenPosFromWorldPos(offsetPos);

		const f32 scalex = getDriver().getResolutionScaleFactor();
		const f32 zoom = getCamera().targetDistance * scalex;

		DrawSlots(space, aligned, zoom);

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

void DrawSlots(Vec2f size, Vec2f pos, const f32 zoom)
{
	const int x = Maths::Floor(size.x);
	const int y = Maths::Floor(size.y);
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

void changeInventoryName(CBlob@ this)
{
	string invName;
	processSwears(this.get_string("packed name"), invName);
	
	this.setInventoryName("Crate with " + invName);
}
