// Spiker.as

#include "MechanismsCommon.as";
#include "Hitters.as";
#include "PlatformCommon.as";

class Spiker : Component
{
	u16 id;
	Vec2f offset;

	Spiker(Vec2f position, u16 netID, Vec2f _offset)
	{
		x = position.x;
		y = position.y;

		id = netID;
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
		
		if (!canRayCast)
		{
			this.getSprite().PlaySound("dry_hit.ogg");
			return;
		}

		AttachmentPoint@ mechanism = this.getAttachments().getAttachmentPointByName("MECHANISM");
		if (mechanism is null) return;

		mechanism.offset = Vec2f(0, -7);

		CBlob@ spike = mechanism.getOccupied();
		if (spike is null) return;

		spike.set_u8("state", 1);

		// hit flesh at target position
		if (isServer())
		{
			CBlob@[] blobs;
			map.getBlobsAtPosition(offset * 8 + position, @blobs);
			for(uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (!blob.hasTag("flesh")) continue;

				spike.server_Hit(blob, blob.getPosition(), blob.getVelocity() * -1, 1.0f, Hitters::spikes, true);
			}
		}

		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.PlaySound("SpikerThrust.ogg", 2.0f);
	}

	void Deactivate(CBlob@ this)
	{
		// if ! blocked, do stuff

		AttachmentPoint@ mechanism = this.getAttachments().getAttachmentPointByName("MECHANISM");
		if (mechanism is null) return;

		mechanism.offset = Vec2f(0, 0);

		CBlob@ spike = mechanism.getOccupied();
		if (spike is null) return;

		spike.set_u8("state", 0);

		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.PlaySound("LoadingTick.ogg");
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

	Spiker component(position, this.getNetworkID(), offset);
	this.set("component", component);

	this.getAttachments().getAttachmentPointByName("MECHANISM").offsetZ = -5;

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

		CBlob@ spike = server_CreateBlob("spike", this.getTeamNum(), this.getPosition());
		spike.setAngleDegrees(this.getAngleDegrees());
		spike.set_u8("state", 0);

		ShapeConsts@ consts = spike.getShape().getConsts();
		consts.mapCollisions = false;
		consts.collideWhenAttached = true;

		this.server_AttachTo(spike, "MECHANISM");
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetZ(500);
	sprite.SetFrameIndex(angle / 90);
	sprite.SetFacingLeft(false);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Spiker.png", 8, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(4);
	layer.SetRelativeZ(-10);
	layer.SetFacingLeft(false);
}

void onDie(CBlob@ this)
{
	if (!getNet().isServer()) return;

	CBlob@ spike = this.getAttachments().getAttachmentPointByName("MECHANISM").getOccupied();
	if (spike is null) return;

	spike.server_Die();
}
