// Receiver.as

#include "MechanismsCommon.as";

class Receiver : Component
{
	u16 m_id;

	Receiver(Vec2f position, u16 id)
	{
		x = position.x;
		y = position.y;

		m_id = id;
	}

	u8 Special(MapPowerGrid@ grid, u8 power_old, u8 power_new)
	{
		CBlob@ this = getBlobByNetworkID(m_id);

		u16[]@ id;
		if(this.get(EMITTER, @id))
		{
			for(u8 i = 0; i < id.length; i++)
			{
				CBlob@ blob = getBlobByNetworkID(id[i]);
				if(blob is null)
				{
					this.removeAt(EMITTER, i);
					continue;
				}

				Component@ emitter = null;
				if(!blob.get("component", @emitter))
				{
					this.removeAt(EMITTER, i);
					continue;
				}

				if(grid.getPower(emitter.x, emitter.y) > 0)
				{
					if(i > 0)
					{
						this.removeAt(EMITTER, i);
						this.push(EMITTER, grid.getID(emitter.x, emitter.y));
					}
					return power_source;
				}
			}
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

	if(getNet().isServer())
	{
		u16[] emitter;
		this.set(EMITTER, emitter);
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if(!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;
	const u16 ANGLE = this.getAngleDegrees();

	Receiver component(POSITION, this.getNetworkID());
	this.set("component", component);

	if(getNet().isServer())
	{
		CMap@ map = getMap();

		MapPowerGrid@ grid;
		if(!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_NONE,                          // input topology
		rotateTopology(ANGLE, TOPO_DOWN),   // output topology
		INFO_SPECIAL,                       // information
		0,                                  // power
		component.m_id);                    // id

		Vec2f offset = Vec2f(0, -1).RotateBy(ANGLE);

		for(u8 i = 1; i < signal_strength; i++)
		{
			const Vec2f TARGET = offset * i + POSITION;

			if(TARGET.x < 0 || TARGET.y < 0 ||
				TARGET.x >= map.tilemapwidth || TARGET.y >= map.tilemapheight)
			{
				break;
			}

			CBlob@ blob = getBlobByNetworkID(grid.getID(TARGET.x, TARGET.y));
			if(blob is null || blob.getName() != EMITTER) continue;

			u16 difference = Maths::Abs(ANGLE - blob.getAngleDegrees());
			if(difference != 180) continue;

			Component@ emitter = null;
			if(!blob.get("component", @emitter)) continue;

			this.push(EMITTER, grid.getID(emitter.x, emitter.y));
		}
	}

	CSprite@ sprite = this.getSprite();
	if(sprite is null) return;

	const bool facing = ANGLE < 180? false : true;

	sprite.SetZ(-60);
	sprite.SetFacingLeft(facing);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Receiver.png", 16, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
	layer.SetFacingLeft(facing);

	if(ANGLE == 90 || ANGLE == 180)
	{
		sprite.SetOffset(Vec2f(0, 1));
		layer.SetOffset(Vec2f(0, 1));
	}
}

/*
void onDie(CBlob@ this)
{
	if(!getNet().isClient() || !this.exists("component")) return;

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
