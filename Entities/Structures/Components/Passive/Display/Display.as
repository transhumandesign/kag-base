// Display.as

#include "MechanismsCommon.as";

class Display : Component
{
	u16 id;

	Display(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	u8 Special(MapPowerGrid@ grid, u8 power_old, u8 power_new)
	{
		if (power_old != power_new)
		{
			packet_AddChangeFrame(grid.packet, id, Maths::Min(power_new, 17));
		}

		return power_new;
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");
	
	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);
	
	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Display component(POSITION, this.getNetworkID());
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
		INFO_SPECIAL,                       // information
		0,                                  // power
		component.id);                      // id
	}
	
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetFacingLeft(false);
		sprite.SetZ(-50.0f);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
