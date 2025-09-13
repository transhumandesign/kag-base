#include "PlacementCommon.as"
#include "BuildBlock.as"
#include "Requirements.as"
#include "GameplayEventsCommon.as";

// Called server side
void PlaceBlock(CBlob@ this, u8 index, Vec2f cursorPos)
{
	BuildBlock @bc = getBlockByIndex(this, index);

	if (bc is null)
	{
		warn("BuildBlock is null " + index);
		return;
	}

	string name = "Blob " + this.getName();

	CPlayer@ p = this.getPlayer();
	if (p !is null) 
		name = "User " + p.getUsername();

	CBitStream missing;

	CInventory@ inv = this.getInventory();

	bool validTile = bc.tile > 0;
	bool hasReqs = hasRequirements(inv, bc.reqs, missing);
	bool passesChecks = serverTileCheck(this, index, cursorPos);
	bool stillOnDelay = isBuildDelayed(this);

	if (validTile && hasReqs && passesChecks && !stillOnDelay)
	{
		CMap@ map = getMap();
		DestroyScenary(cursorPos, Vec2f(cursorPos.x+map.tilesize, cursorPos.y+map.tilesize));
		server_TakeRequirements(inv, bc.reqs);
		map.server_SetTile(cursorPos, bc.tile);

		// one day we will reach an ideal world without latency, dumb edge cases and bad netcode
		// that day is not today
		u32 delay = getCurrentBuildDelay(this) - 1;
		SetBuildDelay(this, delay);

		// GameplayEvent
		if (p !is null)
		{
			GE_BuildBlock(p.getNetworkID(), bc.tile); // gameplay event for coins
		}
	}
}

// Returns true if pos is valid
bool serverTileCheck(CBlob@ blob, u8 tileIndex, Vec2f cursorPos)
{
	// Pos check of about 8 tiles, accounts for people with lag
	Vec2f pos = (blob.getPosition() - cursorPos) / 2;

	if (pos.Length() > 30)
		return false;
    
	// Are we still on cooldown?
	if (isBuildDelayed(blob)) 
		return true;

	// Are we trying to place in a bad pos?
	CMap@ map = getMap();
	Tile backtile = map.getTile(cursorPos);

	if (map.isTileBedrock(backtile.type) || map.isTileSolid(backtile.type) && map.isTileGroundStuff(backtile.type)) 
		return false;

	// Make sure we actually have support at our cursor pos
	if (!map.hasSupportAtPos(cursorPos)) 
		return false;

	// Is the pos currently collapsing?
	if (map.isTileCollapsing(cursorPos))
		return false;

	// Is our tile solid and are we trying to place it into a no build or no solids sectors
	BuildBlock @blockToPlace = getBlockByIndex(blob, tileIndex);
	if (map.isTileSolid(blockToPlace.tile) || cursorPos.y < map.tilesize * 3.0f)
	{
		pos = cursorPos + Vec2f(map.tilesize * 0.5f, map.tilesize * 0.5f);

		if (map.getSectorAtPosition(pos, "no build") !is null || map.getSectorAtPosition(pos, "no solids") !is null)
			return false;
	}

	// Are we trying to place a tile on the same tile (usually due to lag)?
	if (backtile.type == blockToPlace.tile)
	{
		return false;
	}

	// Are we trying to place a solid tile on a door/ladder/platform/bridge (usually due to lag)?
	if (fakeHasTileSolidBlobs(cursorPos) && map.isTileSolid(blockToPlace.tile))
	{
		return false;
	}

	return true;
}

void onInit(CBlob@ this)
{
	AddCursor(this);
	SetupBuildDelay(this);
	this.addCommandID("placeBlock");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	if (this.isInInventory())
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
		return;
	}

	if (isBuildDelayed(this))
	{
		return;
	}

	BlockCursor @bc;
	this.get("blockCursor", @bc);
	if (bc is null)
	{
		return;
	}

	SetTileAimpos(this, bc);
	// check buildable
	bc.buildable = false;
	bc.supported = false;
	bc.hasReqs = false;
	TileType buildtile = this.get_TileType("buildtile");

	if (buildtile > 0)
	{
		bc.blockType = buildtile;
		bc.blockActive = true;
		bc.blobActive = false;
		CMap@ map = this.getMap();
		u8 blockIndex = getBlockIndexByTile(this, buildtile);
		BuildBlock @block = getBlockByIndex(this, blockIndex);
		if (block !is null)
		{
			bc.missing.Clear();
			bc.hasReqs = hasRequirements(this.getInventory(), block.reqs, bc.missing, not block.buildOnGround);
		}

		if (bc.cursorClose)
		{
			Vec2f halftileoffset(map.tilesize * 0.5f, map.tilesize * 0.5f);
			bc.buildableAtPos = isBuildableAtPos(this, bc.tileAimPos + halftileoffset, buildtile, null, bc.sameTileOnBack);
			//printf("bc.buildableAtPos " + bc.buildableAtPos );
			bc.rayBlocked = isBuildRayBlocked(this.getPosition(), bc.tileAimPos + halftileoffset, bc.rayBlockedPos);
			bc.buildable = bc.buildableAtPos && !bc.rayBlocked;

			bc.supported = bc.buildable && map.hasSupportAtPos(bc.tileAimPos);
		}

		// place block

		if (!getHUD().hasButtons() && this.isKeyPressed(key_action1))
		{
			if (bc.cursorClose && bc.buildable && bc.supported)
			{
				CBitStream params;
				params.write_u8(blockIndex);
				//params.write_Vec2f(bc.tileAimPos);
				params.write_Vec2f(this.getAimPos()); // we're gonna send the aimpos and double-check range on server for safety
				this.SendCommand(this.getCommandID("placeBlock"), params);
				u32 delay = getCurrentBuildDelay(this);
				SetBuildDelay(this, block.tile < 255 ? delay : delay / 3);
				bc.blockActive = false;
			}
			else if (this.isKeyJustPressed(key_action1) && !bc.sameTileOnBack)
			{
				this.getSprite().PlaySound("NoAmmo.ogg", 0.5);
			}
		}
	}
	else
	{
		bc.blockActive = false;
	}
}

// render block placement

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

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

	CBlob @carryBlob = blob.getCarriedBlob();
	if (carryBlob !is null)
	{
		return;
	}

	if (isBuildDelayed(blob))
	{
		return;
	}

	// draw a map block or other blob that snaps to grid
	TileType buildtile = blob.get_TileType("buildtile");

	if (buildtile > 0)
	{
		CMap@ map = getMap();
		BlockCursor @bc;
		blob.get("blockCursor", @bc);

		if (bc !is null)
		{
			if (bc.cursorClose && bc.hasReqs && bc.buildable)
			{
				SColor color;
				Vec2f aimpos = bc.tileAimPos;

				if (bc.buildable && bc.supported)
				{
					color.set(255, 255, 255, 255);
					map.DrawTile(aimpos, buildtile, color, getCamera().targetDistance, false);
				}
				else
				{
					// no support
					color.set(255, 255, 46, 50);
					const u32 gametime = getGameTime();
					Vec2f offset(0.0f, -1.0f + 1.0f * ((gametime * 0.2f) % 8));
					map.DrawTile(aimpos + offset, buildtile, color, getCamera().targetDistance, false);

					if (gametime % 16 < 9)
					{
						Vec2f supportPos = aimpos + Vec2f(blob.isFacingLeft() ? map.tilesize : -map.tilesize, map.tilesize);
						Vec2f point;
						if (map.rayCastSolid(supportPos, supportPos + Vec2f(0.0f, map.tilesize * 32.0f), point))
						{
							const uint count = (point - supportPos).getLength() / map.tilesize;
							for (uint i = 0; i < count; i++)
							{
								map.DrawTile(supportPos + Vec2f(0.0f, map.tilesize * i), buildtile,
								             SColor(255, 205, 16, 10),
								             getCamera().targetDistance, false);
							}
						}
					}
				}
			}
			else
			{
				f32 halfTile = map.tilesize / 2.0f;
				Vec2f aimpos = blob.getAimPos() + getCamera().getInterpolationOffset();
				Vec2f offset(-0.2f + 0.4f * (Maths::Sin(getGameTime() * 0.5f)), 0.0f);
				map.DrawTile(Vec2f(aimpos.x - halfTile, aimpos.y - halfTile) + offset, buildtile,
				             SColor(255, 255, 46, 50),
				             getCamera().targetDistance, false);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("placeBlock") && isServer())
	{
		u8 index;
		if (!params.saferead_u8(index)) return;

		Vec2f aimpos;
		if (!params.saferead_Vec2f(aimpos)) return;

		// convert aimpos to tileaimpos (on server this time);
		Vec2f pos = this.getPosition();
		Vec2f mouseNorm = aimpos - pos;
		f32 mouseLen = mouseNorm.Length();
		const f32 maxLen = MAX_BUILD_LENGTH;
		mouseNorm /= mouseLen;

		Vec2f tileaimpos;

		if (mouseLen > maxLen * getMap().tilesize)
		{
			f32 d = maxLen * getMap().tilesize;
			Vec2f p = pos + Vec2f(d * mouseNorm.x, d * mouseNorm.y);
			tileaimpos = getMap().getTileWorldPosition(getMap().getTileSpacePosition(p));
		}
		else
		{
			tileaimpos = getMap().getTileWorldPosition(getMap().getTileSpacePosition(aimpos));
		}

		// out of range
		if (mouseLen >= getMaxBuildDistance(this))
		{
			return;
		} 
		PlaceBlock(this, index, tileaimpos);
	}
}