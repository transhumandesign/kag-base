#include "PlacementCommon.as"
#include "BuildBlock.as"
#include "Requirements.as"

#include "GameplayEvents.as"


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

	BlockCursor @bc;
	this.get("blockCursor", @bc);
	if (bc is null)
	{
		return;
	}

	TileType buildtile = this.get_TileType("buildtile");

	if (buildtile <= 0)
	{
		return;
	}

	CBlob @carryBlob = this.getCarriedBlob();

	CMap@ map = this.getMap();
	u8 blockIndex = getBlockIndexByTile(this, buildtile);
	BuildBlock @block = getBlockByIndex(this, blockIndex);
	if (block !is null)
	{
		bc.missing.Clear();
	}

	if (bc.cursorClose)
	{
		Vec2f halftileoffset(map.tilesize * 0.5f, map.tilesize * 0.5f);
		bc.buildableAtPos = isBuildableAtPos(this, bc.tileAimPos + halftileoffset, buildtile, null, bc.sameTileOnBack);
		//printf("bc.buildableAtPos " + bc.buildableAtPos );
		bc.buildable = bc.buildableAtPos && !bc.rayBlocked;
		bc.supported = map.hasSupportAtPos(bc.tileAimPos);
	}

	if (!getHUD().hasButtons() && this.isKeyPressed(key_action1))
	{
		if (!(bc.cursorClose && bc.buildable && bc.supported)
		&& this.isKeyJustPressed(key_action1) && !bc.sameTileOnBack)
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 0.5);
		}
	}

}

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

	{
		GUI::SetFont("menu");
		BlockCursor @bc;
		blob.get("blockCursor", @bc);
    	GUI::DrawText("Has requirements " + bc.hasReqs, Vec2f(0,0), color_white);
		GUI::DrawText("Cursor close " + bc.cursorClose, Vec2f(0, 30), color_white);
		GUI::DrawText("Buildable " + bc.buildable, Vec2f(0, 60), color_white);
		GUI::DrawText("Supported " + bc.supported, Vec2f(0, 80), color_white);
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

				if (bc.supported)
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

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (isServer() && cmd == this.getCommandID("place"))
	{
		Vec2f cursorPos;
        if (!params.saferead_Vec2f(cursorPos)) return;

        if (!genericPlaceCheck(this, cursorPos))
        {
            return;
        }

        PlaceBlock(this, cursorPos);
	}
}

void PlaceBlock(CBlob@ this, Vec2f cursorPos)
{
    BuildBlock@ block = GetTileBlock(this);
    if (block is null)
    {
        return;
    }

    if (!hasBlockRequirements(this, block))
    {
        return;
    }

	bool validTile = block.tile > 0;
	bool passesChecks = serverTileCheck(this, getBlockIndexByTile(this, block.tile), cursorPos);

	if (validTile && passesChecks)
	{
		DestroyScenary(cursorPos, cursorPos);
        CInventory@ inv = this.getInventory();
		server_TakeRequirements(inv, block.reqs);
		getMap().server_SetTile(cursorPos, block.tile);

		u32 delay = getCurrentBuildDelay(this);
		SetBuildDelay(this, delay);

		SendGameplayEvent(createBuiltBlockEvent(this.getPlayer(), block.tile));
	}
}

bool serverTileCheck(CBlob@ blob, u8 tileIndex, Vec2f cursorPos)
{
	CBlob @carryBlob = blob.getCarriedBlob();
	if (carryBlob !is null)
	{
		return false;
	}

	// Make sure we actually have support at our cursor pos
    CMap@ map = getMap();
	if (!map.hasSupportAtPos(cursorPos)) 
		return false;

	// Is our tile solid and are we trying to place it into a no build area
	if (map.isTileSolid(tileIndex))
	{
		Vec2f pos = cursorPos + Vec2f(map.tilesize * 0.5f, map.tilesize * 0.5f);

		if (map.getSectorAtPosition(pos, "no build") !is null)
			return false;
	}

	Vec2f halftileoffset = Vec2f(map.tilesize * 0.5f, map.tilesize * 0.5f);
	if (!isBuildableAtPos(blob, cursorPos + halftileoffset, getBlockByIndex(blob, tileIndex).tile, null, false))
    {
        return false;
    }
    
    Vec2f rayBlockedPos;
    if (isBuildRayBlocked(blob.getPosition(), cursorPos + halftileoffset, rayBlockedPos))
    {
        return false;
    }

	return true;
}
