// Inverter.as

#include "MechanismsCommon.as";

class Inverter : Component
{
	u16 id;
	u8 base;
	u8 memory;

	Inverter(Vec2f position, u16 netID, u8 input)
	{
		x = position.x;
		y = position.y;

		id = netID;
		base = input;
		memory = 0;
	}

	u8 Special(MapPowerGrid@ _grid, u8 _old, u8 _new)
	{
		const u8 power = _grid.getInputPowerAt(x, y, base, 0);

		if (memory == 0 && power > 0)
		{
			packet_AddChangeFrame(_grid.packet, id, 1);
		}
		else if (power == 0 && memory > 0)
		{
			packet_AddChangeFrame(_grid.packet, id, 0);
		}
		memory = power;

		return (power > 0)? decayedPower(_old) : power_source;
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

	const Vec2f position = this.getPosition() / 8;
	const u16 angle = this.getAngleDegrees();
	const u8 input = rotateTopology(angle, TOPO_DOWN);

	Inverter component(position, this.getNetworkID(), input);
	this.set("component", component);

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		input,                              // input topology
		rotateTopology(angle, TOPO_UP),     // output topology
		INFO_SPECIAL,                       // information
		power_source,                       // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	const bool facing = angle < 180? false : true;

	sprite.SetZ(-60);
	sprite.SetFacingLeft(facing);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Inverter.png", 8, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
	layer.SetFacingLeft(facing);
}

void onDie(CBlob@ this)
{
	if (!getNet().isClient() || !this.exists("component")) return;

	const string image = this.getSprite().getFilename();
	const Vec2f position = this.getPosition();
	const u8 team = this.getTeamNum();

	for(u8 i = 0; i < 4; i++)
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