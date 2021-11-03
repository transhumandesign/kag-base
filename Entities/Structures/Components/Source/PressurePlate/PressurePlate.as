// PressurePlate.as

#include "MechanismsCommon.as";

class Plate : Component
{
	Plate(Vec2f position)
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
	this.Tag("blocks sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.addCommandID("activate");
	this.addCommandID("deactivate");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	Plate component(position);
	this.set("component", component);

	this.set_u8("state", 0);
	this.set_u32("cooldown", getGameTime() + 40);
	this.set_u16("angle", this.getAngleDegrees());

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_NONE,                          // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_SOURCE,                        // information
		0,                                  // power
		0);                                 // id
	}

	this.getSprite().SetZ(100);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	Component@ component = null;
	if (!this.get("component", @component)) return;

	// if active, ignore
	if (this.get_u8("state") > 0) return;

	if (blob is null || !canActivatePlate(blob) || !isTouchingPlate(this, blob)) return;

	this.SendCommand(this.getCommandID("activate"));
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
	Component@ component = null;
	if (!this.get("component", @component)) return;

	// if !active, ignore
	if (this.get_u8("state") == 0) return;

	const uint touching = this.getTouchingCount();
	for(uint i = 0; i < touching; i++)
	{
		CBlob@ t = this.getTouchingByIndex(i);
		if (t !is null && canActivatePlate(t) && isTouchingPlate(this, t)) return;
	}

	this.SendCommand(this.getCommandID("deactivate"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	Component@ component = null;
	if (!this.get("component", @component)) return;

	u8 state = this.get_u8("state");

	if (cmd == this.getCommandID("activate"))
	{
		state = 1;

		// setInfo is too slow for fast collisions, need to set power as well
		if (getNet().isServer())
		{
			MapPowerGrid@ grid;
			if (!getRules().get("power grid", @grid)) return;

			grid.setAll(
			component.x,                        // x
			component.y,                        // y
			TOPO_NONE,                          // input topology
			TOPO_CARDINAL,                      // output topology
			INFO_SOURCE | INFO_ACTIVE,          // information
			power_source,                       // power
			0);                                 // id
		}
	}
	else if (cmd == this.getCommandID("deactivate"))
	{
		state = 0;

		if (getNet().isServer())
		{
			MapPowerGrid@ grid;
			if (!getRules().get("power grid", @grid)) return;

			grid.setInfo(
			component.x,                        // x
			component.y,                        // y
			INFO_SOURCE);                       // information
		}
	}

	this.set_u8("state", state);

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetFrameIndex(state);
	sprite.PlaySound("LeverToggle.ogg");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool canActivatePlate(CBlob@ blob)
{
	CShape@ shape = blob.getShape();
	if (shape is null || shape.isStatic() || !blob.isCollidable())
	{
		return false;
	}
	return true;
}

bool isTouchingPlate(CBlob@ this, CBlob@ blob)
{
	Vec2f touch = this.getTouchingOffsetByBlob(blob);
	f32 angle = touch.Angle();

	switch (this.get_u16("angle"))
	{
		case 0: if (angle <= 135 && angle >= 45) return true;
			break;

		case 90: if (angle <= 45 || angle >= 315) return true;
			break;

		case 180: if (angle <= 315 && angle >= 225) return true;
			break;

		case 270: if (angle <= 225 && angle >= 135) return true;
			break;
	}

	return false;
}