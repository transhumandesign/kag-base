#include "BuildBlock.as"
#include "PlacementCommon.as"
#include "Requirements.as"
#include "GameplayEvents.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
    this.addCommandID("place");
}

void onTick(CBlob@ this)
{
    BlockCursor @bc;
	this.get("blockCursor", @bc);
	if (bc is null)
	{
		return;
	}

    SetTileAimpos(this, bc);
    bc.blockActive = false;
    bc.blobActive = false;

    CMap@ map = this.getMap();
	Vec2f halftileoffset = Vec2f(map.tilesize * 0.5f, map.tilesize * 0.5f);
	bc.rayBlocked = isBuildRayBlocked(this.getPosition(), bc.tileAimPos + halftileoffset, bc.rayBlockedPos);

    BuildBlock@ block = GetBlobBlock(this);
    if (block !is null && this.getCarriedBlob() !is null && this.getCarriedBlob().getName() == block.name)
    {
        bc.missing.Clear();
        bc.hasReqs = hasRequirements(this.getInventory(), block.reqs, bc.missing, not block.buildOnGround);
    }
    else
    {
        @block = GetTileBlock(this);
        if (block !is null)
        {
            bc.missing.Clear();
            bc.hasReqs = hasRequirements(this.getInventory(), block.reqs, bc.missing, not block.buildOnGround);
        }
    }

    TileType buildtile = this.get_TileType("buildtile");
    if (buildtile > 0)
    {
        bc.blockActive = true;
    }
    else
    {
        CBlob@ carriedBlob = this.getCarriedBlob();
        if (carriedBlob !is null)
        {
            if (carriedBlob.isSnapToGrid())
            {
                bc.blobActive = true;
            }
        }
    }

    if (!this.isInInventory()
    && !getHUD().hasMenus()
    && !getHUD().hasButtons()
    && this.isKeyPressed(key_action1))
    {
        CBitStream params;
        params.write_Vec2f(bc.tileAimPos);
        this.SendCommand(this.getCommandID("place"), params);
    }
}

/*
TODO list:
clean code massively
fix requirements text showing up buggily


*/