// Standard menu player controls
// add to blob and sprite

#include "StandardControlsCommon.as"
#include "ThrowCommon.as"
#include "WheelMenuCommon.as"
#include "KnockedCommon.as"

const u32 PICKUP_ERASE_TICKS = 80;

void onInit(CBlob@ this)
{
	CBlob@[] blobs;
	this.set("pickup blobs", blobs);
	CBlob@[] closestblobs;
	this.set("closest blobs", closestblobs);

//	this.addCommandID("detach"); in StandardControls

	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	AddIconToken("$filled_bucket$", "Bucket.png", Vec2f(16, 16), 1);

	// setup pickup menu wheel
	WheelMenu@ menu = get_wheel_menu("pickup");
	if (menu.entries.length == 0)
	{
		menu.option_notice = "Pickup";

		// knight stuff
		menu.add_entry(PickupWheelMenuEntry("Keg", "$keg$", "keg"));

		const PickupWheelOption[] bomb_options = {PickupWheelOption("bomb", 1), PickupWheelOption("mat_bombs", 0)};
		menu.add_entry(PickupWheelMenuEntry("Bomb", "$mat_bombs$", bomb_options, Vec2f(0, -8.0f)));

		const PickupWheelOption[] waterbomb_options = {PickupWheelOption("waterbomb", 1), PickupWheelOption("mat_waterbombs", 0)};
		menu.add_entry(PickupWheelMenuEntry("Water Bomb", "$mat_waterbombs$", waterbomb_options, Vec2f(0, -6.0f)));

		menu.add_entry(PickupWheelMenuEntry("Mine", "$mine$", "mine"));

		// archer stuff
		menu.add_entry(PickupWheelMenuEntry("Arrows", "$mat_arrows$", "mat_arrows", Vec2f(0, -8.0f)));
		menu.add_entry(PickupWheelMenuEntry("Water Arrows", "$mat_waterarrows$", "mat_waterarrows", Vec2f(0, 2.0f)));
		menu.add_entry(PickupWheelMenuEntry("Fire Arrows", "$mat_firearrows$", "mat_firearrows", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Bomb Arrows", "$mat_bombarrows$", "mat_bombarrows"));

		// builder stuff
		menu.add_entry(PickupWheelMenuEntry("Gold", "$mat_gold$", "mat_gold", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Stone", "$mat_stone$", "mat_stone", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Wood", "$mat_wood$", "mat_wood", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Drill", "$drill$", "drill", Vec2f(-16.0f, 0.0f)));
		menu.add_entry(PickupWheelMenuEntry("Saw", "$saw$", "saw", Vec2f(-16.0f, -16.0f)));
		menu.add_entry(PickupWheelMenuEntry("Trampoline", "$trampoline$", "trampoline", Vec2f(-16.0f, -8.0f)));
		menu.add_entry(PickupWheelMenuEntry("Boulder", "$boulder$", "boulder"));
		menu.add_entry(PickupWheelMenuEntry("Sponge", "$sponge$", "sponge", Vec2f(0, 8.0f)));
		menu.add_entry(PickupWheelMenuEntry("Seed", "$seed$", "seed", Vec2f(8.0f, 8.0f)));

		// misc
		menu.add_entry(PickupWheelMenuEntry("Log", "$log$", "log"));
		const PickupWheelOption[] food_options = {
			PickupWheelOption("food"),
			PickupWheelOption("heart"),
			PickupWheelOption("fishy"),
			PickupWheelOption("grain"),
			PickupWheelOption("steak"),
			PickupWheelOption("egg")
		};
		menu.add_entry(PickupWheelMenuEntry("Food", "$food$", food_options));
		menu.add_entry(PickupWheelMenuEntry("Ballista Ammo", "$mat_bolts$", "mat_bolts"));
		menu.add_entry(PickupWheelMenuEntry("Crate", "$crate$", "crate", Vec2f(-16.0f, 0)));
		menu.add_entry(PickupWheelMenuEntry("Bucket", "$filled_bucket$", "bucket"));
	}

}

void onTick(CBlob@ this)
{
	if (this.isInInventory() || isKnocked(this))
	{
		this.clear("pickup blobs");
		this.clear("closest blobs");
		return;
	}

	CControls@ controls = getControls();

	// drop / pickup / throw
	if (controls.ActionKeyPressed(AK_PICKUP_MODIFIER))
	{
		WheelMenu@ menu = get_wheel_menu("pickup");
		if (this.isKeyPressed(key_pickup) && menu !is get_active_wheel_menu())
		{
			set_active_wheel_menu(@menu);
		}
		
		GatherPickupBlobs(this);

		CBlob@[]@ pickupBlobs;
		this.get("pickup blobs", @pickupBlobs);

		CBlob@[] available;
		FillAvailable(this, available, pickupBlobs);

		for (uint i = 0; i < menu.entries.length; i++)
		{
			PickupWheelMenuEntry@ entry = cast<PickupWheelMenuEntry>(menu.entries[i]);
			entry.disabled = true;

			for (uint j = 0; j < available.length; j++)
			{
				string bname = available[j].getName();
				for (uint k = 0; k < entry.options.length; k++)
				{
					if (entry.options[k].name == bname)
					{
						entry.disabled = false;
						break;
					}
				}

				if (!entry.disabled)
				{
					break;
				}
			}
		}
	}
	else if (this.isKeyJustPressed(key_pickup))
	{
		TapPickup(this);

		CBlob @carryBlob = this.getCarriedBlob();

		if (this.isAttached()) // default drop from attachment
		{
			int count = this.getAttachmentPointCount();

			for (int i = 0; i < count; i++)
			{
				AttachmentPoint @ap = this.getAttachmentPoint(i);

				if (ap.getOccupied() !is null && ap.name != "PICKUP")
				{
					CBitStream params;
					params.write_netid(ap.getOccupied().getNetworkID());
					this.SendCommand(this.getCommandID("detach"), params);
					this.set_bool("release click", false);
					break;
				}
			}
		}
		else if (carryBlob !is null && !carryBlob.hasTag("custom drop") && (!carryBlob.hasTag("temp blob")))
		{
			ClearPickupBlobs(this);
			client_SendThrowCommand(this);
			this.set_bool("release click", false);

		}
		else
		{
			this.set_bool("release click", true);
		}
	}
	else
	{
		WheelMenu@ menu = get_wheel_menu("pickup");
		if ((this.isKeyJustReleased(key_pickup) || controls.isKeyJustReleased(controls.getActionKeyKey(AK_PICKUP_MODIFIER)))
			&&  get_active_wheel_menu() is menu)
		{
			PickupWheelMenuEntry@ selected = cast<PickupWheelMenuEntry>(menu.get_selected());
			set_active_wheel_menu(null);

			if (selected !is null && !selected.disabled)
			{
				CBlob@[] blobsInRadius;
				if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + 50.0f, @blobsInRadius))
				{
					uint highestPriority = 0;
					float closestScore = 600.0f;
					CBlob@ closest;

					for (uint i = 0; i < blobsInRadius.length; i++)
					{
						CBlob@ b = blobsInRadius[i];

						string bname = b.getName();
						for (uint j = 0; j < selected.options.length; j++)
						{
							PickupWheelOption@ selectedOption = @selected.options[j];
							if (bname == selectedOption.name)
							{
								if (!canBlobBePickedUp(this, b))
								{
									break;
								}

								float maxDist = Maths::Max(this.getRadius() + b.getRadius() + 20.0f, 36.0f);
								float dist = (this.getPosition() - b.getPosition()).Length();
								float factor = dist / maxDist;

								float score = getPriorityPickupScale(this, b, factor);

								if (score < closestScore || selectedOption.priority > highestPriority)
								{
									highestPriority = selectedOption.priority;
									closestScore = score;
									@closest = @b;
								}
							}
						}
					}

					if (closest !is null)
					{
						// NOTE: optimisation: use selected-option-blobs-in-radius
						@closest = @GetBetterAlternativePickupBlobs(blobsInRadius, closest);
						server_Pickup(this, this, closest);
					}
				}
			}

			return;

		}

		if (this.isKeyPressed(key_pickup))
		{
			GatherPickupBlobs(this);

			CBlob@[]@ closestBlobs;
			this.get("closest blobs", @closestBlobs);
			closestBlobs.clear();
			CBlob@ closest = getClosestBlob(this);
			if (closest !is null)
			{
				closestBlobs.push_back(closest);
				/*
				if (this.isKeyJustPressed(key_action1))	// pickup
				{
					server_Pickup(this, this, closest);
					this.set_bool("release click", false);
				}
				*/
			}

		}

		if (this.isKeyJustReleased(key_pickup))
		{
			if (this.get_bool("release click"))
			{
				CBlob@[]@ closestBlobs;
				this.get("closest blobs", @closestBlobs);
				if (closestBlobs.length > 0)
				{
					server_Pickup(this, this, closestBlobs[0]);
				}
			}
			ClearPickupBlobs(this);
		}
	}
}

void GatherPickupBlobs(CBlob@ this)
{
	CBlob@[]@ pickupBlobs;
	this.get("pickup blobs", @pickupBlobs);
	pickupBlobs.clear();
	CBlob@[] blobsInRadius;

	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + 50.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];

			if (b.canBePickedUp(this))
			{
				pickupBlobs.push_back(b);
			}
		}
	}
}

CBlob@ GetBetterAlternativePickupBlobs(CBlob@[] available_blobs, CBlob@ reference)
{
	if (reference is null)
		return reference;

	CBlob@[] blobsInRadius;
	const string ref_name = reference.getName();
	const u32 ref_quantity = reference.getQuantity();
	Vec2f ref_pos = reference.getPosition();

	CBlob @result = reference;

	for (uint i = 0; i < available_blobs.length; i++)
	{
		CBlob @b = available_blobs[i];
		Vec2f b_pos = b.getPosition();
		if ((b_pos - ref_pos).Length() > 10.0f)
			continue;

		const string name = b.getName();
		const u32 quantity = b.getQuantity();
		if (name == ref_name && quantity > ref_quantity)
			@result = @b;
	}

	return result;
}

void ClearPickupBlobs(CBlob@ this)
{
	this.clear("pickup blobs");
}

void FillAvailable(CBlob@ this, CBlob@[]@ available, CBlob@[]@ pickupBlobs)
{
	for (uint i = 0; i < pickupBlobs.length; i++)
	{
		CBlob @b = pickupBlobs[i];

		if (b !is this && canBlobBePickedUp(this, b))
		{
			available.push_back(b);
		}
	}
}

f32 getPriorityPickupScale(CBlob@ this, CBlob@ b)
{
	u32 gameTime = getGameTime();

	const string thisname = this.getName(),
		name = b.getName();
	u32 unpackTime = b.get_u32("unpack time");

	const bool same_team = b.getTeamNum() == this.getTeamNum();
	const bool material = b.hasTag("material");

	// Military scale factor constants, NOT including military resources
	const float factor_military = 0.4f,
		factor_military_team = 0.6f,
		factor_military_useful = 0.3f,
		factor_military_lit = 0.2f,
		factor_military_important = 0.15f,
		factor_military_critical = 0.1f;

	// Resource scale factor constants
	const float factor_resource_boring = 0.7f,
		factor_resource_useful = 0.5f,
		factor_resource_useful_rare = 0.45f,
		factor_resource_strategic = 0.4f,
		factor_resource_critical = 0.3f;

	// Generic scale factor constants
	const float factor_very_boring = 10.0f,
		factor_common = 0.9f,
		factor_boring = 0.8f,
		factor_important = 0.025f,
		factor_very_important = 0.01f,
		factor_super_important = 0.001f;

	//// MISC ////

	// Special stuff such as flags
	if (b.hasTag("special"))
	{
		return factor_super_important;
	}

	//// MILITARY ////
	{
		// special mine check for unarmed enemy mines
		if (name == "mine" && b.hasTag("mine_priming") && !same_team)
		{
			return factor_important;
		}

		// Military stuff we don't want to pick up when in the same team and always considered lit
		if (name == "mine" || name == "bomb" || name == "waterbomb")
		{
			// Make an exception to the team rule: when the explosive is the holder's
			bool mine = b.getDamageOwnerPlayer() is this.getPlayer();

			return (same_team && !mine) ? factor_military_team : factor_military_lit;
		}

		bool exploding = b.hasTag("exploding");

		// Kegs, really matters when lit (exploding)
		// But we still want a high priority so bombjumping with kegs is easier
		if (name == "keg")
		{
			return exploding ? factor_very_important : factor_military_important;
		}

		// Regular military stuff
		if (name == "boulder" || name == "saw")
		{
			return factor_military;
		}

		if (name == "drill")
		{
			return thisname == "builder" ? factor_military_useful : factor_military;
		}

		if (name == "crate")
		{
			if (same_team)
			{
				return factor_military_team;
			}

			// Consider crates useful usually but unpacking enemy crates important
			return (unpackTime > gameTime && !same_team) ? factor_military_important : factor_military_useful;
		}

		// Other exploding stuff we don't recognize
		if (exploding)
		{
			return factor_military_lit;
		}
	}

	//// MATERIALS ////
	if (material)
	{
		const bool builder = (thisname == "builder");

		if (name == "mat_gold")
		{
			return factor_resource_strategic;
		}

		if (name == "mat_stone")
		{
			return builder ? factor_resource_useful_rare : factor_resource_boring;
		}

		if (name == "mat_wood")
		{
			return builder ? factor_resource_useful : factor_resource_boring;
		}

		const bool knight = (thisname == "knight");

		if (name == "mat_bombs" || name == "mat_waterbombs")
		{
			return knight ? factor_resource_useful_rare : factor_resource_useful;
		}

		const bool archer = (thisname == "archer");

		if (name == "mat_arrows")
		{
			// Lower priority for regular arrows when the archer has more than 15 in the inventory
			return archer && !this.hasBlob("mat_arrows", 15) ? factor_resource_useful : factor_resource_boring;
		}

		if (name == "mat_waterarrows" || name == "mat_firearrows" || name == "mat_bombarrows")
		{
			return archer ? factor_resource_useful_rare : factor_resource_useful;
		}
	}

	//// MISC ////
	if (name == "food" || name == "heart" || (name == "fishy" && b.hasTag("dead"))) // Wait, is there a better way to do that?
	{
		float factor_full_life = (thisname == "archer" ? factor_resource_useful : factor_resource_boring);
		return this.getHealth() < this.getInitialHealth() ? factor_resource_critical : factor_full_life;
	}

	//low priority
	if (name == "log" || b.hasTag("tree"))
	{
		return factor_boring;
	}

	if (name == "bucket" && b.get_u8("filled") > 0)
	{
		return factor_resource_useful;
	}


	// super low priority, dead stuff - sick of picking up corpses
	if (b.hasTag("dead"))
	{
		return factor_very_boring;
	}

	return factor_common;
}

f32 getPriorityPickupScale(CBlob@ this, CBlob@ b, f32 scale)
{
	return scale * getPriorityPickupScale(this, b);
}

CBlob@ getClosestAimedBlob(CBlob@ this, CBlob@[] available)
{
	CBlob@ closest;
	float lowestScore = 16.0f; // TODO provide better sorting routines in the interface

	for (int i = 0; i < available.length; ++i)
	{
		CBlob@ current = available[i];

		float cursorDistance = (this.getAimPos() - current.getPosition()).Length();

		float radius = current.getRadius();
		if (radius > 3.0f && cursorDistance > radius * (current.hasTag("dead") ? 0.5f : 1.5f)) // corpses don't count unless you really try to aim at one
		{
			continue;
		}

		if (cursorDistance < lowestScore)
		{
			lowestScore = cursorDistance;
			@closest = @current;
		}
	}

	return closest;
}



CBlob@ getClosestBlob(CBlob@ this)
{
	CBlob@ closest;
	CBlob@ target; // when hovering a blob

	CBlob@[]@ pickupBlobs;
	if (this.get("pickup blobs", @pickupBlobs))
	{
		Vec2f pos = this.getPosition();

		CBlob@[] available;
		FillAvailable(this, available, pickupBlobs);

		if (!isTapPickup(this))
		{
			CBlob@ closestAimed = getClosestAimedBlob(this, available);
			if (closestAimed !is null)
			{
				return closestAimed;
			}
		}

		float closestScore = 999999.9f;
		float drawOrderScore = -999999.9f;
		for (uint i = 0; i < available.length; ++i)
		{
			CBlob @b = available[i];

			Vec2f bpos = b.getPosition();
			// consider corpse center to be lower than it actually is because otherwise centers of player and corpse are on the same level,
			// which makes corpse priority skyrocket if player is standing too close 
			if (b.hasTag("dead")) bpos += Vec2f(0, 6.0f);


			Vec2f[]@ hoverShape;
			bool isPointInsidePolygon = false;
			
			if (b.get("hover-poly", @hoverShape))
			{
				isPointInsidePolygon = pointInsidePolygon(this.getAimPos(),  hoverShape, bpos, b.isFacingLeft());
			}
			
			if (isPointInsidePolygon || b.isPointInside(this.getAimPos())) 
			{
				// Let's just get the draw order of the sprite
				CSprite @bs = b.getSprite();
				float draworder = bs.getDrawOrder();

				if (draworder > drawOrderScore)
				{
					drawOrderScore = draworder;
					@target = @b;
				}			
			}


			float maxDist = Maths::Max(this.getRadius() + b.getRadius() + 20.0f, 36.0f);

			float dist = (bpos - pos).getLength();
			float factor = dist / maxDist;
			float score = getPriorityPickupScale(this, b, factor);

			if (score < closestScore)
			{
				closestScore = score;
				@closest = @b;
			}
		}

		if (closest !is null) {
			@closest = @GetBetterAlternativePickupBlobs(available, closest);
		}
	}

	if (target !is null)
		return target;

	return closest;
}

bool canBlobBePickedUp(CBlob@ this, CBlob@ blob)
{
	if (!blob.canBePickedUp(this)) return false;

	float maxDist = Maths::Max(this.getRadius() + blob.getRadius() + 20.0f, 36.0f);

	Vec2f pos = this.getPosition() + Vec2f(0.0f, -this.getRadius() * 0.9f);
	Vec2f pos2 = blob.getPosition();

	Vec2f ray = pos2 - pos;
	bool canRayCast = false;

	CMap@ map = getMap();

	HitInfo@[] hitInfos;
	if(map.getHitInfosFromRay(pos, -ray.getAngle(), ray.Length(), this, hitInfos))
	{
		for (int i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;

			// collide with anything that isn't a platform
			// could do proper platform direction check but probably not needed
			if (b !is null && b !is this && b !is blob && b.isCollidable() && b.getShape().isStatic() && !b.isPlatform())
			{
				canRayCast = false;
				break;

			}

			if(map.isTileSolid(hi.tile))
			{
				canRayCast = false;
				break;
			}

			// if our blob isn't in the list that means the ray stopped at a block
			if (b is blob)
			{
				canRayCast = true;
			}
		}

	} else {
		canRayCast = true;
	}

	return (((pos2 - pos).getLength() <= maxDist)
	        && !blob.isAttached() && !blob.hasTag("no pickup")
	        && (canRayCast || this.isOverlapping(blob)) //overlapping fixes "in platform" issue
	       );
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();


	// render item held when in inventory

	if (blob.isKeyPressed(key_inventory))
	{
		CBlob @pickBlob = blob.getCarriedBlob();

		if (pickBlob !is null)
		{
			pickBlob.RenderForHUD((blob.getAimPos() + Vec2f(0.0f, 8.0f)) - blob.getPosition() , RenderStyle::normal);
		}
	}

	if (blob.isKeyPressed(key_pickup))
	{
		// pickup render
		bool tickPlayed = false;
		bool hover = false;
		CBlob@[]@ pickupBlobs;
		CBlob@[]@ closestBlobs;
		blob.get("closest blobs", @closestBlobs);
		CBlob@ closestBlob = null;
		if (closestBlobs.length > 0)
		{
			@closestBlob = closestBlobs[0];
		}

		if (blob.get("pickup blobs", @pickupBlobs))
		{
			// render outline only if hovering
			for (uint i = 0; i < pickupBlobs.length; i++)
			{
				CBlob @b = pickupBlobs[i];

				bool canBePicked = canBlobBePickedUp(blob, b);

				if (canBePicked)
				{
					b.RenderForHUD(RenderStyle::outline_front);
				}

				if (b is closestBlob)
				{
					hover = true;
					Vec2f dimensions;
					GUI::SetFont("menu");

					/*
					GUI::DrawCircle(
						getDriver().getScreenPosFromWorldPos(b.getPosition()),
						32.0f,
						SColor(255, 255, 255, 255)
					);
					*/

					GUI::GetTextDimensions(b.getInventoryName(), dimensions);
					GUI::DrawText(getTranslatedString(b.getInventoryName()), getDriver().getScreenPosFromWorldPos(b.getPosition() - Vec2f(0, -b.getHeight() / 2)) - Vec2f(dimensions.x / 2, -8.0f), color_white);

					// draw mouse hover effect
					//if (canBePicked)
					{
						b.RenderForHUD(RenderStyle::additive);

						if (!tickPlayed)
						{
							if (blob.get_u16("hover netid") != b.getNetworkID())
							{
								Sound::Play(CFileMatcher("/select.ogg").getFirst());
							}

							blob.set_u16("hover netid", b.getNetworkID());
							tickPlayed = true;
						}

						//break;
					}
				}

			}

			// no hover
			if (!hover)
			{
				blob.set_u16("hover netid", 0);
			}

			// render outlines

			//for (uint i = 0; i < pickupBlobs.length; i++)
			//{
			//    pickupBlobs[i].RenderForHUD( RenderStyle::outline_front );
			//}
		}
	}
}
