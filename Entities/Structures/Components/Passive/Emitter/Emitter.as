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

	u8 Special(MapPowerGrid@ grid, u8 power_old, u8 power_new)
	{
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
		rotateTopology(ANGLE, TOPO_DOWN),   // input topology
		TOPO_NONE,                          // output topology
		INFO_SPECIAL,                       // information
		0,                                  // power
		component.m_id);                    // id

		Vec2f offset = Vec2f(0, -1).RotateBy(ANGLE);

		for(u8 i = 1; i < signal_strength; i++)
		{
			const Vec2f TARGET = offset * i + POSITION;

			CBlob@ blob = getBlobByNetworkID(grid.getID(TARGET.x, TARGET.y));
			if (blob is null || blob.getName() != "receiver" || !blob.getShape().isStatic()) continue;

			const u16 difference = Maths::Abs(ANGLE - blob.getAngleDegrees());
			if (difference != 180) continue;

			blob.push(EMITTER, component.m_id);
		}
	}

	const bool facing = ANGLE >= 180;

	CSprite@ sprite = this.getSprite();
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
	if (!isClient() || !this.exists("component")) return;

	const string image = this.getSprite().getFilename();
	const Vec2f position = this.getPosition();
	const u8 team = this.getTeamNum();

	for (u8 i = 0; i < 3; i++)
	{
		makeGibParticle(image, position, getRandomVelocity(90, 2, 360), i, 2, Vec2f(8, 8), 1.0f, 0, "", team);
	}
}
*/

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
