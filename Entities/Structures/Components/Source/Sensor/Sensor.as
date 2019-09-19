// Sensor.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by DummyOnStatic.as
	this.set_TileType(Dummy::TILE, Dummy::BACKGROUND);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Component component(POSITION);
	this.set("component", component);

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_NONE,                          // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetFacingLeft(false);
		sprite.SetZ(-50);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.getShape().isStatic()) return;

	Component@ component = null;
	if (!this.get("component", @component)) return;

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setPower(
		component.x,                        // x
		component.y,                        // y
		power_source);                      // power
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.PlaySound("mechanical_click.ogg");

		if (sprite.isAnimation("impulse"))
		{
			sprite.SetAnimation("default");
		}
		sprite.SetAnimation("impulse");

		CParticle@ particle = ParticleAnimated(
		"SensorBlink.png",                  // file name
		this.getPosition(),                 // position
		Vec2f_zero,                         // velocity
		0.0f,                               // rotation
		1.0f,                               // scale
		3,                                  // ticks per frame
		0.0f,                               // gravity
		true);                              // self lit
		if (particle !is null)
		{
			particle.Z = -25;
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}