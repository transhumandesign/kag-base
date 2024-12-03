// Sensor.as

#include "MechanismsCommon.as";

void onInit(CBlob@ this)
{
	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Component component(POSITION);
	this.set("component", component);

	if (isServer())
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
	sprite.SetFacingLeft(false);
	sprite.SetZ(-50);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.getShape().isStatic()) return;

	Component@ component = null;
	if (!this.get("component", @component)) return;

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setPower(
		component.x,                        // x
		component.y,                        // y
		power_source);                      // power
	}

	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("mechanical_click.ogg");

	if (sprite.isAnimation("impulse"))
	{
		sprite.SetAnimation("default");
	}
	sprite.SetAnimation("impulse");

	CParticle@ particle = ParticleAnimated("SensorBlink.png", this.getPosition(), Vec2f_zero, 0.0f, 1.0f, 3, 0.0f, true);
	if (particle !is null)
	{
		particle.Z = -25;
	}
}
