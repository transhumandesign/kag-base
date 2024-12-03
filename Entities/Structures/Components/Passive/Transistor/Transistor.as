// Transistor.as

#include "MechanismsCommon.as";

class Transistor : Component
{
	u16 id;
	u8 base;
	u8 collector;
	u8 memory;

	Transistor(Vec2f position, u16 netID, u8 _base, u8 _collector)
	{
		x = position.x;
		y = position.y;

		id = netID;
		base = _base;
		collector = _collector;
		memory = 0;
	}

	u8 Special(MapPowerGrid@ _grid, u8 _old, u8 _new)
	{
		const u8 t_base = _grid.getInputPowerAt(x, y, base, 0);
		const u8 power = _grid.getInputPowerAt(x, y, collector, 0);

		if (memory == 0 && t_base > 0)
		{
			packet_AddChangeFrame(_grid.packet, id, 1);
		}
		else if (t_base == 0 && memory > 0)
		{
			packet_AddChangeFrame(_grid.packet, id, 0);
		}
		memory = t_base;

		return t_base > 0 ? power : decayedPower(_old);
	}
};

void onInit(CBlob@ this)
{
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
	const u8 INPUT = rotateTopology(ANGLE, TOPO_LEFT | TOPO_RIGHT);
	const u8 BASE = rotateTopology(ANGLE, TOPO_DOWN);

	Transistor component(POSITION, this.getNetworkID(), BASE, INPUT);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		INPUT | BASE,                       // input topology
		INPUT,                              // output topology
		INFO_SPECIAL,                       // information
		0,                                  // power
		component.id);                      // id
	}

	const bool facing = ANGLE >= 180;

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-60);
	sprite.SetFacingLeft(facing);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Transistor.png", 16, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
	layer.SetFacingLeft(facing);

	if (ANGLE == 90 || ANGLE == 180)
	{
		sprite.SetOffset(Vec2f(0, 1));
		layer.SetOffset(Vec2f(0, 1));
	}
}

void onDie(CBlob@ this)
{
	if (!isClient() || !this.exists("component")) return;

	const string image = this.getSprite().getFilename();
	const Vec2f position = this.getPosition();
	const u8 team = this.getTeamNum();

	for (u8 i = 0; i < 4; i++)
	{
		makeGibParticle(image, position, getRandomVelocity(90, 2, 360), i, 2, Vec2f(8, 8), 1.0f, 0, "", team);
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	stream.write_u8(this.getSprite().getFrameIndex());
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	u8 frame;
	if (!stream.saferead_u8(frame)) return false;
	this.getSprite().SetFrameIndex(frame);
	return true;
}
