// Blob can place blocks on grid

#include "ThrowCommon.as";
#include "PlacementCommon.as";
#include "BuildBlock.as";
#include "CheckSpam.as";
#include "GameplayEvents.as";
#include "Requirements.as"
#include "RunnerTextures.as"

//server-only
void PlaceBlob(CBlob@ this, CBlob @blob, Vec2f cursorPos)
{
	if (blob !is null)
	{
		blob.Tag("temp blob placed");
		// hack for spike kills
		// TODO: add proper functionality for any block with a specific tag to blob.SetDamageOwnerPlayer(this.getPlayer());
		if (blob.getName() == "spikes")
		{
			blob.SetDamageOwnerPlayer(this.getPlayer());
		}
		if (this.server_DetachFrom(blob))
		{
			blob.setPosition(cursorPos);
			if (blob.isSnapToGrid())
			{
				CShape@ shape = blob.getShape();
				shape.SetStatic(true);
			}
		}
	}
}

Vec2f getBottomOfCursor(Vec2f cursorPos, CBlob@ carryBlob)
{
	// check at bottom of cursor
	CMap@ map = getMap();
	f32 w = map.tilesize / 2.0f;
	f32 h = map.tilesize / 2.0f;
	return Vec2f(cursorPos.x + w, cursorPos.y + h);
}

void PositionCarried(CBlob@ this, CBlob@ carryBlob)
{
	// rotate towards mouse if object allows
	if (carryBlob.hasTag("place45"))
	{
		f32 distance = 8.0f;
		if (carryBlob.exists("place45 distance"))
			distance = f32(carryBlob.get_s8("place45 distance"));

		f32 angleOffset = 0.0f;
		if (!carryBlob.hasTag("place45 perp"))
			angleOffset = 90.0f;

		Vec2f aimpos = this.getAimPos();
		Vec2f pos = this.getPosition();
		Vec2f aim_vec = (pos - aimpos);
		aim_vec.Normalize();
		f32 angle_step = 45.0f;
		f32 mouseAngle = (int(aim_vec.getAngleDegrees() + (angle_step * 0.5)) / int(angle_step)) * angle_step ;
		if (!this.isFacingLeft()) mouseAngle += 180;

		carryBlob.setAngleDegrees(-mouseAngle + angleOffset);
		AttachmentPoint@ hands = this.getAttachments().getAttachmentPointByName("PICKUP");

		aim_vec *= distance;

		if (hands !is null)
		{
			hands.offset.x = 0 + (aim_vec.x * 2 * (this.isFacingLeft() ? 1.0f : -1.0f)); // if blob config has offset other than 0,0 there is a desync on client, dont know why
			hands.offset.y = -(aim_vec.y * (distance < 0 ? 1.0f : 1.0f));
		}
	}
	else
	{
		if (!carryBlob.hasTag("place norotate"))
		{
			carryBlob.setAngleDegrees(0.0f);
		}
		AttachmentPoint@ hands = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (hands !is null)
		{
			// set the pickup offset according to the pink pixel
			CSprite@ sprite = this.getSprite();

			int layer = 0;
			Vec2f head_offset = getHeadOffset(this, -1, layer);
			if (layer != 0)
			{
				// set the proper offset
				Vec2f off(sprite.getFrameWidth() / 2, -sprite.getFrameHeight() / 2);
				off += Vec2f(-head_offset.x, head_offset.y);
				off.x *= -1.0f;
				hands.offset = off;
			}
			else
			{
				hands.offset.Set(0, 0);
			}

			if (this.isKeyPressed(key_down))      // hack for crouch
			{
				if (this.getName() == "archer" && sprite.isAnimation("crouch")) //hack for archer prone
				{
					hands.offset.y -= 4;
					hands.offset.x += 2;
				}
				else
				{
					hands.offset.y += 2;
				}
			}
		}
	}
}

void onInit(CBlob@ this)
{
	AddCursor(this);
	SetupBuildDelay(this);

	this.addCommandID("placeBlob");
	this.addCommandID("settleLadder");
	this.addCommandID("rotateBlob");

	this.set_u16("build_angle", 0);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	if (this.getControls() is null || this.isInInventory())
	{
		return;
	}

	//don't build with menus open
	if (getHUD().hasMenus())
	{
		return;
	}

	CBlob @carryBlob = this.getCarriedBlob();
	if (carryBlob !is null)
	{
		if(carryBlob.hasTag("place ignore facing"))
		{
			carryBlob.getSprite().SetFacingLeft(false);
		}

		// hide block in hands when placing close
		if (!carryBlob.isSnapToGrid())
		{
			PositionCarried(this, carryBlob);
		}
		else
		{
			if (carryBlob.hasTag("place norotate"))
			{
				this.getCarriedBlob().setAngleDegrees(0.0f);
			}
			else
			{
				this.getCarriedBlob().setAngleDegrees(this.get_u16("build_angle"));
			}
		}
	}

	if (!this.isMyPlayer())
	{
		return;
	}

////                     ONLY MYPLAYER STUFF BEYOND THIS LINE                   ////
	BlockCursor @bc;
	this.get("blockCursor", @bc);
	if (bc is null)
	{
		return;
	}

	bc.blobActive = false;

	if (carryBlob is null)
	{
		return;
	}

	if (isBuildDelayed(this))
	{
		// don't draw blob while waiting to build
		if (carryBlob !is null)
		{
			carryBlob.SetVisible(false);
		}
		return;
	}

	SetTileAimpos(this, bc);
	// check buildable

	bc.buildable = false;
	bc.supported = false;
	bc.hasReqs = true;

	u8 blockIndex = this.get_u8("buildblob");
	BuildBlock @block = getBlockByIndex(this, blockIndex);
	if (block !is null) {
		bc.hasReqs = hasRequirements(this.getInventory(), block.reqs, bc.missing);
	}

	if (carryBlob !is null)
	{
		CMap@ map = this.getMap();
		bool snap = carryBlob.isSnapToGrid();

		carryBlob.SetVisible(!carryBlob.hasTag("temp blob"));

		bool onetile = false;
		if (carryBlob.getName() == "ladder")
		{
			onetile = true;
		}

		if (snap) // activate help line
		{
			bc.blobActive = true;
			bc.blockActive = false;
		}

		if (bc.cursorClose)
		{
			if (snap) // if snaps to grid make cursor
			{
				Vec2f halftileoffset(map.tilesize * 0.5f, map.tilesize * 0.5f);

				CMap@ map = this.getMap();
				TileType buildtile = 256;   // something else than a tile
				Vec2f bottomPos = getBottomOfCursor(bc.tileAimPos, carryBlob);

				bool overlapped;

				if (onetile)
				{
					Vec2f ontilepos = halftileoffset + bc.tileAimPos;

					overlapped = false;
					CBlob@[] b;

					f32 tsqr = halftileoffset.LengthSquared() - 1.0f;

					if (map.getBlobsInRadius(ontilepos, 0.5f, @b))
					{
						for (uint nearblob_step = 0; nearblob_step < b.length && !overlapped; ++nearblob_step)
						{
							CBlob@ blob = b[nearblob_step];

							if (blob is carryBlob || blob is this) continue;

							overlapped = (blob.getPosition() - ontilepos).LengthSquared() < tsqr;
						}
					}
				}
				else
				{
					overlapped = carryBlob.isOverlappedAtPosition(bottomPos, carryBlob.getAngleDegrees());
				}

				bc.buildableAtPos = isBuildableAtPos(this, bottomPos, buildtile, carryBlob, bc.sameTileOnBack) && !overlapped;
				bc.rayBlocked = isBuildRayBlocked(this.getPosition(), bc.tileAimPos + halftileoffset, bc.rayBlockedPos);
				bc.buildable = bc.buildableAtPos && !bc.rayBlocked;
				bc.supported = carryBlob.getShape().getConsts().support > 0 ? map.hasSupportAtPos(bc.tileAimPos) : true;
				//printf("bc.buildableAtPos " + bc.buildableAtPos + " bc.supported " + bc.supported );
			}
		}

		// place blob with action1 key
		if (!getHUD().hasButtons() && !carryBlob.hasTag("custom drop"))
		{
			if (this.isKeyPressed(key_action1))
			{
				if (snap && bc.cursorClose && bc.hasReqs && bc.buildable && bc.supported)
				{
					CBitStream params;
					params.write_u16(carryBlob.getNetworkID());
					params.write_Vec2f(getBottomOfCursor(bc.tileAimPos, carryBlob));
					this.SendCommand(this.getCommandID("placeBlob"), params);
					u32 delay = 2 * this.get_u32("build delay");
					SetBuildDelay(this, delay);
					bc.blobActive = false;
				}
				else if (snap && this.isKeyJustPressed(key_action1))
				{
					Sound::Play("NoAmmo.ogg");
				}
			}

			if (this.isKeyJustPressed(key_action3))
			{
				CBitStream params;
				params.write_u16((this.get_u16("build_angle") + 90) % 360);
				this.SendCommand(this.getCommandID("rotateBlob"), params);
			}
		}
	}

}

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_hasattached;
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

// render block placement
void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (getHUD().hasButtons())
	{
		return;
	}
	if (blob.isKeyPressed(key_action2) || blob.isKeyPressed(key_pickup))   //hack: dont show when builder is attacking
	{
		return;
	}
	if (isBuildDelayed(blob))
	{
		return;
	}

	// draw a map block or other blob that snaps to grid
	CBlob@ carryBlob = blob.getCarriedBlob();

	if (carryBlob !is null) // && carryBlob.isSnapToGrid()
	{
		if (!carryBlob.isSnapToGrid())
		{
			return;
		}

		BlockCursor @bc;
		blob.get("blockCursor", @bc);

		if (bc !is null)
		{
			if (bc.cursorClose && bc.hasReqs && bc.buildable)
			{
				SColor color;

				if (bc.buildable && bc.supported)
				{
					color.set(255, 255, 255, 255);
					carryBlob.RenderForHUD(getBottomOfCursor(bc.tileAimPos, carryBlob) - carryBlob.getPosition(), 0.0f, color, RenderStyle::normal);
				}
				else
				{
					color.set(255, 255, 46, 50);
					Vec2f offset(0.0f, -1.0f + 1.0f * ((getGameTime() * 0.8f) % 8));
					carryBlob.RenderForHUD(getBottomOfCursor(bc.tileAimPos, carryBlob) + offset - carryBlob.getPosition(), 0.0f, color, RenderStyle::normal);
				}
			}
			else
			{
				f32 halfTile = getMap().tilesize / 2.0f;
				Vec2f aimpos = blob.getMovement().getVars().aimpos;
				carryBlob.RenderForHUD(Vec2f(aimpos.x - halfTile, aimpos.y - halfTile) - carryBlob.getPosition(), 0.0f,
				                       SColor(255, 255, 46, 50) ,
				                       RenderStyle::normal);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("rotateBlob"))
	{
		this.set_u16("build_angle", params.read_u16());
		return;
	}

	if (!getNet().isServer())
	{
		return;
	}

	if (cmd == this.getCommandID("placeBlob"))
	{
		CBlob @carryBlob = getBlobByNetworkID(params.read_u16());
		if (carryBlob !is null)
		{
			Vec2f pos = params.read_Vec2f();
			PlaceBlob(this, carryBlob, pos);
			SendGameplayEvent(createBuiltBlobEvent(this.getPlayer(), carryBlob.getName()));
		}
	}
	else if (cmd == this.getCommandID("settleLadder"))
	{
		CBlob @carryBlob = getBlobByNetworkID(params.read_u16());
		Vec2f pos = params.read_Vec2f();
		if (carryBlob !is null)
		{
			carryBlob.Tag("temp blob placed");
			carryBlob.server_DetachFrom(this);
			carryBlob.getShape().SetStatic(true);
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	// set visible in case of detachment and was invisible for HUD
	detached.SetVisible(true);

	if (detached.hasTag("temp blob placed"))  // wont happen on client
	{
		// override ignore collision so we can step on our ladder
		this.IgnoreCollisionWhileOverlapped(null);
		detached.IgnoreCollisionWhileOverlapped(null);
		detached.Untag("temp blob placed");
	}
}
