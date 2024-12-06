// Lamp.as

#include "MechanismsCommon.as";

const u8 MAX_LIGHT_RADIUS = 96.0f;

class Lamp : Component
{
	u16 id;

	Lamp(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	u8 Special(MapPowerGrid@ grid, u8 power_old, u8 power_new)
	{
		if (power_old != power_new)
		{
			CBlob@ blob = getBlobByNetworkID(id);

			if (blob !is null)
			{
				CBitStream params;
				params.write_u8(power_new);
				params.write_u16(id);
				blob.SendCommand(blob.getCommandID("load_client"), params);
			}		
			
			if (power_new > 0)
			{
				packet_AddChangeFrame(grid.packet, id, 1);
			}
			else
			{
				packet_AddChangeFrame(grid.packet, id, 0);
			}
		}

		return power_new;
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
	this.SetLightRadius(0.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	this.addCommandID("load_client");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Lamp component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (getNet().isServer())
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("load_client") && isClient())
	{
		const u8 power_new = params.read_u8();
		const u16 id = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(id);

		if (blob !is null)
		{		
			if (power_new > 0)
			{
				blob.SetLight(true);
				f32 power_factor = Maths::Min((float(power_new + 1) / power_source), 1);
				f32 power_factor_color = Maths::Max(power_factor, 0.4f);
				SColor new_color = SColor(255 * power_factor_color, 
										 255 * power_factor_color,
										 240 * power_factor_color, 
										 171 * power_factor_color);
				blob.SetLightColor(new_color);
				blob.SetLightRadius(power_factor * MAX_LIGHT_RADIUS);
			}
			else
			{
				blob.SetLight(false);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
