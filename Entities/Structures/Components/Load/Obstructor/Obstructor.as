// Obstructor.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";
#include "Hitters.as";

const u8 BURNOUT_COUNTER_MAX = 32;
const u8 BURNOUT_TIME_STEP = 8;

class Obstructor : Component
{
	u16 id;

	Obstructor(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	void Activate(CBlob@ this)
	{
		if (!isObstructed(this))
		{
			if (getNet().isServer())
			{
				getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR);
			}

			this.getSprite().PlaySound("door_close.ogg");
		}
		else
		{
			this.Tag("obstructed");

			this.set_u32("burnout_time", getGameTime() + BURNOUT_TIME_STEP);
			this.set_u8("burnout_counter", 0);

			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.RewindEmitSound();
				sprite.SetEmitSoundPaused(false);
			}
		}
	}

	void Deactivate(CBlob@ this)
	{
		this.Untag("obstructed");

		CMap@ map = getMap();
		if (map !is null)
		{
			this.getSprite().SetEmitSoundPaused(true);

			if (map.getTile(this.getPosition()).type == Dummy::OBSTRUCTOR)
			{
				this.getSprite().PlaySound("door_close.ogg");
			}

			if (getNet().isServer())
			{
				map.server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR_BACKGROUND);
			}
		}
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by DummyOnStatic.as
	this.set_TileType(Dummy::TILE, Dummy::OBSTRUCTOR_BACKGROUND);

	this.getCurrentScript().tickIfTag = "obstructed";
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Obstructor component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetZ(-50);
		sprite.SetFacingLeft(false);
		sprite.SetEmitSound("Jammed.ogg");
	}
}

void onTick(CBlob@ this)
{
	const u32 TIME = getGameTime();
	if (this.get_u32("burnout_time") + BURNOUT_TIME_STEP > TIME)
	{
		if (!isObstructed(this))
		{
			this.Untag("obstructed");

			if (getNet().isServer())
			{
				getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR);
			}

			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.SetEmitSoundPaused(true);
				sprite.PlaySound("door_close.ogg");
			}
		}
		else
		{
			const u8 BURNOUT_COUNTER = this.get_u8("burnout_counter") + 1;
			if (BURNOUT_COUNTER < BURNOUT_COUNTER_MAX)
			{
				this.set_u32("burnout_time", TIME + BURNOUT_TIME_STEP);
				this.set_u8("burnout_counter", BURNOUT_COUNTER);
			}
			else
			{
				this.Untag("obstructed");

				this.getSprite().SetEmitSoundPaused(true);
			}
		}
	}
}

bool isObstructed(CBlob@ this)
{
	const Vec2f POSITION = this.getPosition();

	CBlob@[] blobs;
	if (getMap().getBlobsAtPosition(POSITION, @blobs))
	{
		for(u32 i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob !is this)
			{
				return true;
			}
		}
	}
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}