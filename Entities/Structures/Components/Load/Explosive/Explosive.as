// Explosive.as

#include "MechanismsCommon.as";
#include "BombCommon.as";
#include "FireCommon.as";

const u8 FUSE_TIME = 4;

class Explosive: Component
{
	u16 id;

	Explosive(Vec2f position, u16 netID)
	{
		x = position.x;
		y = position.y;

		id = netID;
	}

	void Activate(CBlob@ this)
	{
		SetToExplode(this);
	}

	void Deactivate(CBlob@ this)
	{
	}
}

void onInit(CBlob@ this)
{
	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by KnightLogic.as
	this.Tag("blocks sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.server_setTeamNum(-1);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	Explosive component(position, this.getNetworkID());
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_NONE,                          // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetZ(500);
	sprite.SetFacingLeft(false);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isExplosionHitter(customData) || isIgniteHitter(customData))
	{
		SetToExplode(this);
		return 0.0f;
	}
	return damage;
}

void SetToExplode(CBlob@ this)
{
	if (!this.hasTag("exploding"))
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.animation.frame = 1;
		}
		
		SetupBomb(this, FUSE_TIME, 48.0f, 3.0f, 24.0f, 0.4f, true);	
	}
}
