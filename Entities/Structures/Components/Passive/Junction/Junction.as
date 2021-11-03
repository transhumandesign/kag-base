// Junction.as

#include "MechanismsCommon.as";

class Junction : Component
{
	u16 id;

	Junction(Vec2f position, u16 netID)
	{
		x = position.x;
		y = position.y;

		id = netID;
	}

	u8 Special(MapPowerGrid@ _grid, u8 _old, u8 _new)
	{
		if (_old == 0 && _new > 0)
		{
			packet_AddChangeFrame(_grid.packet, id, 1);
		}
		else if (_old > 0 && _new == 0)
		{
			packet_AddChangeFrame(_grid.packet, id, 0);
		}

		return _new;
	}
};

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

	// background component, let water overlap
	this.getShape().getConsts().waterPasses = true;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	Junction component(position, this.getNetworkID());
	this.set("component", component);

	if (getNet().isServer())
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
	if (sprite is null) return;

	sprite.SetZ(-60);
	sprite.SetFacingLeft(false);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Junction.png", 16, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
	layer.SetFacingLeft(false);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}