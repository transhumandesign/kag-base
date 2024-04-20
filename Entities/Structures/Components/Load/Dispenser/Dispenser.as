// Dispenser.as

#include "MechanismsCommon.as";
#include "PlatformCommon.as";

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

		CMap@ map = getMap();
		bool canRayCast = true;
		HitInfo@[] hitInfos;
		Vec2f start_pos = position + offset * map.tilesize/2;
		Vec2f end_pos = position + offset * 11;
		Vec2f ray_vec = (end_pos - start_pos);

		// check if exit is blocked
		if (map.getHitInfosFromRay(start_pos, -ray_vec.getAngle(), ray_vec.Length(), this, hitInfos))
		{
			for (int i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;

				if (b is this)
					continue;

				if (b is null) // hit map
				{
					if (map.isTileSolid(hi.hitpos))
					{
						canRayCast = false;
						break;
					}
				}
				else // hit blob
				{
					if (b.isCollidable() && b.getShape().isStatic())
					{
						if (b.isPlatform() && CollidesWithPlatform(ray_vec, hi.hitpos, b))
						{
							canRayCast = false;
							break;
						}
					}
				}
			}
		}

		// play sound always
		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite is null) return;
			
			if (canRayCast)
				sprite.PlaySound("DispenserFire.ogg", 4.0f);
			else
				sprite.PlaySound("DispenserFireBlocked.ogg", 4.0f);
		}

		// if exit is not blocked, make particle and pop out item from one nearby magazine
		if (!canRayCast)
		{
			return;
		}

		ParticleAnimated(
		"DispenserFire.png",                // file name
		position + (offset * 8),            // position
		Vec2f_zero,                         // velocity
		angle,                              // rotation
		1.0f,                               // scale
		3,                                  // ticks per frame
		0.0f,                               // gravity
		false);                             // self lit

		if (isServer())
		{
			CBlob@[] blobs;
			getMap().getBlobsAtPosition((offset * -1) * 8 + position, @blobs);

			for(uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.getName() != "magazine" || !blob.getShape().isStatic()) continue;

				CBlob@ item = blob.getInventory().getItem(0);
				if (item is null) break;

				blob.server_PutOutInventory(item);

				item.setPosition(position + (offset * 8));
				item.AddForce(offset * (item.getMass() * 4.8f));

				break;
			}
		}
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