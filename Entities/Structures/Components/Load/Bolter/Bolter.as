// Bolter.as

#include "MechanismsCommon.as";
#include "ArcherCommon.as";

class Bolter : Component
{
	u16 id;
	f32 angle;
	Vec2f offset;

	Bolter(Vec2f position, u16 _id, f32 _angle, Vec2f _offset)
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
			CBlob@[] blobs;
			getMap().getBlobsAtPosition((offset * -1) * 8 + position, @blobs);

			for (u16 i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.getName() != "magazine" || !blob.getShape().isStatic()) continue;

				CBlob@ ammo = blob.getInventory().getItem(0);
				if (ammo is null) break;

				const s8 arrow_type = arrowTypeNames.find(ammo.getName());
				if (arrow_type == -1) break;

				// decrement
				const u8 quantity = ammo.getQuantity() - 1;
				if (quantity > 0)
				{
					ammo.server_SetQuantity(quantity);
				}
				else
				{
					ammo.server_Die();
				}

				// calculate deviation
				f32 deviation = (XORRandom(100) - 50) / 20.0f;

				// calculate velocity based on deviation
				Vec2f velocity = offset;
				velocity.RotateBy(deviation);
				velocity *= 17.59f;

				// spawn projectile
				CBlob@ projectile = server_CreateBlobNoInit("arrow");

				projectile.set_u8("arrow type", arrow_type);
				projectile.server_setTeamNum(this.getTeamNum());
				projectile.Init();

				projectile.IgnoreCollisionWhileOverlapped(this);
				projectile.setPosition(position);
				projectile.setVelocity(velocity);

				break;
			}
		}
		
		if (isClient())
		{
			this.getSprite().PlaySound("BolterFire.ogg");
			ParticleAnimated("BolterFire.png", position + (offset * 8), Vec2f_zero, angle, 1.0f, 3, 0.0f, false);
		}
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

	Bolter component(POSITION, this.getNetworkID(), ANGLE, OFFSET);
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

	this.getSprite().SetZ(500);
}
