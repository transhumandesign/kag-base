// Emitter.as

#include "MechanismsCommon.as";

class Emitter : Component
{
	u16 m_id;

	Emitter(Vec2f position, u16 id)
	{
		x = position.x;
		y = position.y;

		m_id = id;
	}

	u8 Special(MapPowerGrid@ grid, u8 power_old, u8 power_new, u16 section)
	{
		if (section > 0) return 0; // only runs on section 0
	
		if (power_old == 0 && power_new > 0)
		{
			packet_AddChangeFrame(grid.packet, m_id, 1);
		}
		else if (power_old > 0 && power_new == 0)
		{
			packet_AddChangeFrame(grid.packet, m_id, 0);
		}

		return power_new;
	}
};

const string EMITTER = "emitter";

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Emitter component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		rotateTopology(ANGLE, TOPO_DOWN),	// input topology section 0
		TOPO_NONE,							// output topology section 0
		TOPO_NONE,							// input topology section 1
		TOPO_NONE,							// output topology section 1
		INFO_SPECIAL,                       // information
		0,                                  // power
		component.m_id);                    // id

		Vec2f offset = Vec2f(0, -1).RotateBy(ANGLE);

		for(u8 i = 1; i < signal_strength; i++)
		{
			const Vec2f TARGET = offset * i + POSITION;

			CBlob@ blob = getBlobByNetworkID(grid.getID(TARGET.x, TARGET.y));
			if (blob is null || blob.getName() != "receiver" || !blob.getShape().isStatic()) continue;

			u16 difference = Maths::Abs(ANGLE - blob.getAngleDegrees());
			if (difference != 180) continue;

			blob.push(EMITTER, component.m_id);
		}
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	const bool facing = ANGLE < 180? false : true;

	sprite.SetZ(-60);
	sprite.SetFacingLeft(facing);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Receiver.png", 16, 16);
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

/*
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
*/

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}