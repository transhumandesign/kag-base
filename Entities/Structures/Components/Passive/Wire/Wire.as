// Wire.as

#include "MechanismsCommon.as";

enum WireType
{
	COUPLING = 0,
	ELBOW,
	TEE
};

// COUPLING frame weight
const array<u8> WEIGHT = {0, 0, 0, 0, 0, 0, 1, 2, 3, 4};

class Wire : Component
{
	Wire(Vec2f position)
	{
		x = position.x;
		y = position.y;
	}
};

void onInit(CBlob@ this)
{
	// used by BlobPlacement.as
	this.Tag("place ignore facing");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background component, let water overlap
	this.getShape().getConsts().waterPasses = true;

	const string NAME = this.getName();
	if (NAME == "coupling")
	{
		this.set_u8("type", COUPLING);
	}
	else if (NAME == "elbow")
	{
		this.set_u8("type", ELBOW);
	}
	else if (NAME == "tee")
	{
		this.set_u8("type", TEE);
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Wire component(POSITION);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		u8 io;
		switch (this.get_u8("type"))
		{
			case COUPLING:
				io = rotateTopology(ANGLE, TOPO_VERT);
				break;
			case ELBOW:
				io = rotateTopology(ANGLE, TOPO_DOWN | TOPO_RIGHT);
				break;
			case TEE:
				io = rotateTopology(ANGLE, TOPO_DOWN | TOPO_HORI);
				break;
		}

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		io,                                 // input topology
		io,                                 // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	const u8 TYPE = this.get_u8("type");

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-60);

	// set default background frame
	u8 background_frame = 2;

	if (TYPE == COUPLING)
	{
		// change default background frame
		background_frame = 5;
		// and set default frame based on frame weight
		sprite.SetFrameIndex(WEIGHT[XORRandom(WEIGHT.length)]);
	}

	SpriteConsts@ consts = sprite.getConsts();
	CSpriteLayer@ layer = sprite.addSpriteLayer("background", consts.filename, consts.frameWidth, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(background_frame);
	layer.SetRelativeZ(-1);

	Vec2f offset = Vec2f_zero;
	switch (ANGLE)
	{
		case 90:
			offset = Vec2f(0, 1);
			break;
		case 180:
			offset = Vec2f(-1, 1);
			break;
		case 270:
			offset = Vec2f(-1, 0);
			break;
	}
	sprite.SetOffset(offset);
	layer.SetOffset(offset);
}
