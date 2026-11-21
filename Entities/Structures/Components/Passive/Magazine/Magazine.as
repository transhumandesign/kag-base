// Bolter.as

#include "MechanismsCommon.as";
#include "GenericButtonCommon.as";

class Magazine : Component
{
	Magazine(Vec2f position)
	{
		x = position.x;
		y = position.y;
	}
}

void onInit(CBlob@ this)
{
	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Magazine component(POSITION);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(500);
	sprite.SetFacingLeft(false);
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().SetFrameIndex(1);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if (this.getInventory().getItem(0) is null)
	{
		this.getSprite().SetFrameIndex(0);
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return this.isOverlapping(forBlob);
}
