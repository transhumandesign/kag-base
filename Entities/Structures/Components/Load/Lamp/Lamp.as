// Lamp.as

#include "MechanismsCommon.as";

class Lamp : Component
{
	u16 id;

	Lamp(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	void Activate(CBlob@ this, u16 section)
	{
		if (section > 0) return; // only runs on section 0
	
		this.SetLight(true);
		this.getSprite().SetFrameIndex(1);
	}

	void Deactivate(CBlob@ this, u16 section)
	{
		if (section > 0) return; // only runs on section 0
	
		this.SetLight(false);
		this.getSprite().SetFrameIndex(0);
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place ignore facing");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	this.SetLight(false);
	this.SetLightRadius(96.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Lamp component(POSITION, this.getNetworkID());
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
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		const bool FACING = ANGLE < 180? false : true;

		sprite.SetZ(-55);
		sprite.SetFacingLeft(FACING);

		CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Lamp.png", 16, 16);
		layer.addAnimation("default", 0, false);
		layer.animation.AddFrame(2);
		layer.SetRelativeZ(-1);
		layer.SetFacingLeft(FACING);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}