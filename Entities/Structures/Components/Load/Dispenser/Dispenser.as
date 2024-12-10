// Dispenser.as

#include "MechanismsCommon.as";

class Dispenser : Component
{
	u16 id;
	f32 angle;
	Vec2f offset;

	Dispenser(Vec2f position, u16 _id, f32 _angle, Vec2f _offset)
	{
		x = position.x;
		y = position.y;

		id = _id;
		angle = _angle;
		offset = _offset;
	}

	void Activate(CBlob@ this)
	{
		Vec2f position = this.getPosition();

		if (isServer())
		{
			CMap@ map = getMap();
			CBlob@[] blobs;
			getMap().getBlobsAtPosition((offset * -1) * 8 + position, @blobs);

			for (uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.getName() != "magazine" || !blob.getShape().isStatic()) continue;

				CBlob@ item = blob.getInventory().getItem(0);
				if (item is null) break;

				if (map.isTileSolid(map.getTile(position + offset * 8))) break;

				blob.server_PutOutInventory(item);

				item.setPosition(position + (offset * 8));
				item.AddForce(offset * (item.getMass() * 4.8f));

				break;
			}
		}

		CSprite@ sprite = this.getSprite();
		sprite.PlaySound("DispenserFire.ogg", 1.5f);
		ParticleAnimated("DispenserFire.png", position + (offset * 8), Vec2f_zero, angle, 1.0f, 3, 0.0f, false);
	}
}

void onInit(CBlob@ this)
{
	// used by KnightLogic.as
	this.Tag("blocks sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_castle_back);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();
	const Vec2f OFFSET = Vec2f(0, -1).RotateBy(ANGLE);

	Dispenser component(POSITION, this.getNetworkID(), ANGLE, OFFSET);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_NONE,                          // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	sprite.SetFacingLeft(false);
	sprite.SetZ(500);
}
