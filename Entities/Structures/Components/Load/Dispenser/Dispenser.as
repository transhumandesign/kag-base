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

		if (getNet().isServer())
		{
			CBlob@[] blobs;
			getMap().getBlobsAtPosition((offset * -1) * 8 + position, @blobs);

			for(uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.getName() != "magazine" || !blob.getShape().isStatic()) continue;

				CBlob@ item = blob.getInventory().getItem(0);
				if (item is null) break;

				// todo: check for spawnable position based on blob radius, offset by radius towards facing
				// break if output is ray blocked
				if (getMap().rayCastSolid(position + offset * 5, position + offset * 11)) break;

				blob.server_PutOutInventory(item);

				item.setPosition(position + (offset * 8));
				item.AddForce(offset * (item.getMass() * 4.8f));

				break;
			}
		}

		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.PlaySound("DispenserFire.ogg", 4.0f);

		ParticleAnimated(
		"DispenserFire.png",                // file name
		position + (offset * 8),            // position
		Vec2f_zero,                         // velocity
		angle,                              // rotation
		1.0f,                               // scale
		3,                                  // ticks per frame
		0.0f,                               // gravity
		false);                             // self lit
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by KnightLogic.as
	this.Tag("blocks sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;
	const u16 angle = this.getAngleDegrees();
	const Vec2f offset = Vec2f(0, -1).RotateBy(angle);

	Dispenser component(position, this.getNetworkID(), angle, offset);
	this.set("component", component);

	if (getNet().isServer())
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
	if (sprite is null) return;

	sprite.SetFacingLeft(false);
	sprite.SetZ(500);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}