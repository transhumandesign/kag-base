// Diode.as

#include "MechanismsCommon.as";

class Diode : Component
{
	Diode(Vec2f position)
	{
		x = position.x;
		y = position.y;
	}
};

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

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

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Diode component(POSITION);
	this.set("component", component);

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		rotateTopology(ANGLE, TOPO_DOWN),   // input topology
		rotateTopology(ANGLE, TOPO_UP),     // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	const bool facing = ANGLE < 180? false : true;

	sprite.SetZ(-60);
	sprite.SetFacingLeft(facing);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Diode.png", 8, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(1);
	layer.SetRelativeZ(-1);
	layer.SetFacingLeft(facing);
}

void onDie(CBlob@ this)
{
	if (!getNet().isClient() || !this.exists("component")) return;

	const string image = this.getSprite().getFilename();
	const Vec2f position = this.getPosition();
	const u8 team = this.getTeamNum();

	for(u8 i = 0; i < 3; i++)
	{
		makeGibParticle(
		image,                              // file name
		position,                           // position
		getRandomVelocity(90, 2, 360),      // velocity
		i,                                  // column
		2,                                  // row
		Vec2f(8, 8),                        // frame size
		1.0f,                               // scale?
		0,                                  // ?
		"",                                 // sound
		team);                              // team number
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}