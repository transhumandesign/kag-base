// Standard menu player controls
// add to blob and sprite

#include "StandardControlsCommon.as"
#include "ThrowCommon.as"

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
}

void onTick(CBlob@ this)
{
	if (this.isInInventory() || this.get_u8("knocked") > 0)
	{
		this.clear("pickup blobs");
		this.clear("closest blobs");
		return;
	}

	// drop / pickup / throw
	if (this.isKeyJustPressed(key_pickup))
	{
		TapPickup(this);

		CBlob @carryBlob = this.getCarriedBlob();

		/*if (isTap( this ))	tap pickup
		{
		CBlob@ carry = this.getCarriedBlob();
		if (carry !is null)
		{
		server_PutIn( this, this, carry );
		}
		}
		else*/
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
		else if (carryBlob !is null && !carryBlob.hasTag("custom drop") && (!carryBlob.hasTag("temp blob") || carryBlob.getName() == "ladder"))
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
				if (this.isKeyJustPressed(key_action1))	// pickup
				{
					server_Pickup(this, this, closest);
				}
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

	const bool same_team = b.getTeamNum() != this.getTeamNum();
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
	const float factor_very_boring = 1.0f,
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
			return knight ? factor_resource_useful : factor_resource_boring;
		}

		const bool archer = (thisname == "archer");

		if (name == "mat_arrows")
		{
			// Lower priority for regular arrows when the archer has more than 15 in the inventory
			return archer && !this.hasBlob("mat_arrows", 15) ? factor_resource_useful : factor_resource_boring;
		}

		if (name == "mat_waterarrows" || name == "mat_firearrows" || name == "mat_bombarrows")
		{
			return archer ? factor_resource_useful_rare : factor_resource_boring;
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
		if (radius > 3.0f && cursorDistance > current.getRadius() * 1.5f)
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

	CBlob@[]@ pickupBlobs;
	if (this.get("pickup blobs", @pickupBlobs))
	{
		Vec2f pos = this.getPosition();

		CBlob@[] available;
		FillAvailable(this, available, pickupBlobs);

		if (available.length == 0)
		{
			FillAvailable(this, available, pickupBlobs);
		}

		if (!isTapPickup(this))
		{
			CBlob@ closestAimed = getClosestAimedBlob(this, available);
			if (closestAimed !is null)
			{
				return closestAimed;
			}
		}

		float closestFactor = 999999.9f;
		
		for (uint i = 0; i < available.length; ++i)
		{
			CBlob @b = available[i];
			Vec2f bpos = b.getPosition();

			float dist = (bpos - pos).getLength();
			float factor = dist / 30.0f;
			factor += getPriorityPickupScale(this, b);

			if (factor < closestFactor)
			{
				closestFactor = factor;
				@closest = @b;
			}
		}
	}

	return closest;
}

bool canBlobBePickedUp(CBlob@ this, CBlob@ blob)
{
	Vec2f pos = this.getPosition() + Vec2f(0.0f, -this.getRadius() * 0.9f);
	Vec2f pos2 = blob.getPosition();
	return (((pos2 - pos).getLength() < (this.getRadius() + blob.getRadius()) + 20.0f)
	        && !blob.isAttached() && !blob.hasTag("no pickup")
	        && (!this.getMap().rayCastSolid(pos, pos2) || (this.isOverlapping(blob)) ) //overlapping fixes "in platform" issue
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
