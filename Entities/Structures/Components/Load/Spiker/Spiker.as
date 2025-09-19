// Spiker.as

#include "MechanismsCommon.as";
#include "Hitters.as";

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
		CSprite@ sprite = this.getSprite();

		CMap@ map = getMap();
		if (map.rayCastSolid(position + offset * 5, position + offset * 11))
		{
			sprite.PlaySound("dry_hit.ogg", 0.5f);
			return;
		}

		AttachmentPoint@ mechanism = this.getAttachments().getAttachmentPointByName("MECHANISM");
		if (mechanism is null) return;

		CBlob@ spike = mechanism.getOccupied();
		if (spike is null) return;

		// hit flesh at target position
		if (isServer())
		{
			CBlob@[] blobs;
			if (spike.getOverlapping(@blobs))
			{
				for (u16 i = 0; i < blobs.length; i++)
				{
					CBlob@ blob = blobs[i];
					if (!blob.hasTag("flesh")) continue;

					spike.server_Hit(blob, blob.getPosition(), blob.getVelocity() * -1, 1.0f, Hitters::spikes, true);
				}
			}
		}
		
		spike.set_u8("state", 1);
		spike.getSprite().animation.SetFrameIndex(1);

		sprite.PlaySound("SpikerThrust.ogg", 0.5f);
	}

	void Deactivate(CBlob@ this)
	{
		AttachmentPoint@ mechanism = this.getAttachments().getAttachmentPointByName("MECHANISM");
		if (mechanism is null) return;

		CBlob@ spike = mechanism.getOccupied();
		if (spike is null) return;

		spike.set_u8("state", 0);
		spike.getSprite().animation.SetFrameIndex(0);

		CSprite@ sprite = this.getSprite();
		this.getSprite().PlaySound("LoadingTick.ogg", 0.4f);
	}
}

void onInit(CBlob@ this)
{
	// used by KnightLogic.as
	this.Tag("blocks sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.Tag("has damage owner");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();
	const Vec2f OFFSET = Vec2f(0, -1).RotateBy(ANGLE);

	Spiker component(POSITION, this.getNetworkID(), OFFSET);
	this.set("component", component);

	AttachmentPoint@ mechanism = this.getAttachments().getAttachmentPointByName("MECHANISM");
	mechanism.offsetZ = -5;
	mechanism.offset = Vec2f(0, -7);

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
		spike.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
		spike.setAngleDegrees(this.getAngleDegrees());
		spike.set_u8("state", 0);

		CShape@ shape = spike.getShape();
		shape.SetStatic(true);
		ShapeConsts@ consts = shape.getConsts();
		consts.mapCollisions = false;
		consts.collideWhenAttached = true;

		this.server_AttachTo(spike, "MECHANISM");
	}

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(500);
	sprite.SetFrameIndex(ANGLE / 90);
	sprite.SetFacingLeft(false);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Spiker.png", 8, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(4);
	layer.SetRelativeZ(-15);
	layer.SetFacingLeft(false);
}

void onDie(CBlob@ this)
{
	if (!isServer()) return;

	CBlob@ spike = this.getAttachments().getAttachmentPointByName("MECHANISM").getOccupied();
	if (spike is null) return;

	spike.server_Die();
}
