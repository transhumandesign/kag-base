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

    if (this.isInInventory())
    {
        return;
    }

    if (getHUD().hasMenus())
    {
        return;
    }

    if (getHUD().hasButtons())
    {
        return;
    }

    if (this.isKeyPressed(key_action1))
    {
        CBitStream params;
        params.write_Vec2f(bc.tileAimPos);
        this.SendCommand(this.getCommandID("place"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (isServer() && cmd == this.getCommandID("place"))
	{
        print("received");
		Vec2f cursorPos;
        if (!params.saferead_Vec2f(cursorPos)) return;
		BlockCursor @bc;
        this.get("blockCursor", @bc);
        if (bc is null)
        {
            return;
        }

        CBlob@ carriedBlob = this.getCarriedBlob();
        if (carriedBlob !is null)
        {
            cursorPos = getBottomOfCursor(cursorPos, carriedBlob);   
        }
        
        if (!genericPlaceCheck(this, cursorPos))
        {
            return;
        }

        PlaceBlock(this, cursorPos);
        if (carriedBlob !is null)
        {
            PlaceBlob(this, carriedBlob, cursorPos);
        }            
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

// Returns true if pos is valid
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

	return true;
}

void PlaceBlob(CBlob@ this, CBlob @blob, Vec2f cursorPos)
{
    if (!serverBlobCheck(this, blob, cursorPos))
        return;

    u32 delay = getCurrentBuildDelay(this);
    SetBuildDelay(this, delay * 2);

	BuildBlock@ block = GetBlobBlock(this);
    if (!hasBlockRequirements(this, block))
    {
        return;
    }

    CShape@ shape = blob.getShape();
    shape.server_SetActive(true);

    blob.Tag("temp blob placed");
    if (blob.hasTag("has damage owner"))
    {
        blob.SetDamageOwnerPlayer(this.getPlayer());
    }

    if (this.server_DetachFrom(blob))
    {
        blob.setPosition(cursorPos);
        if (blob.isSnapToGrid())
        {
            shape.SetStatic(true);
        }
    }

    DestroyScenary(cursorPos, cursorPos);
    SendGameplayEvent(createBuiltBlobEvent(this.getPlayer(), blob.getName()));
}

// Returns true if pos is valid
bool serverBlobCheck(CBlob@ blob, CBlob@ blobToPlace, Vec2f cursorPos)
{
	// Make sure we actually have support at our cursor pos
	CMap@ map = getMap();
	if (!(blobToPlace.getShape().getConsts().support > 0 ? map.hasSupportAtPos(cursorPos) : true)) 
		return false;

	// Is our blob not a ladder and are we trying to place it into a no build area
	if (blobToPlace.getName() != "ladder")
	{
		Vec2f pos = cursorPos + Vec2f(map.tilesize * 0.2f, map.tilesize * 0.2f);

		if (map.getSectorAtPosition(pos, "no build") !is null)
			return false;
	}


	return true;
} 


Vec2f getBottomOfCursor(Vec2f cursorPos, CBlob@ carryBlob)
{
	// check at bottom of cursor
	CMap@ map = getMap();
	f32 w = map.tilesize / 2.0f;
	f32 h = map.tilesize / 2.0f;
	return Vec2f(cursorPos.x + w, cursorPos.y + h);
}


/*
TODO list:

move render block stuff into blockPlacementrender.as, blobplacementrender.as
fix being able to place blocks on blocks
fix blob placement


*/