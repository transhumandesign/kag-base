// Obstructor.as

#include "DummyCommon.as";
#include "MechanismsCommon.as";
#include "Hitters.as";

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
		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("closed");
		sprite.PlaySound("door_close.ogg");
		sprite.SetRelativeZ(600);
		MakeDamageFrame(this);

		SetMapObstructed(this, true);
	}

	void Deactivate(CBlob@ this)
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("open");
		sprite.PlaySound("door_close.ogg");
		sprite.SetRelativeZ(0);
		MakeDamageFrame(this);
		
		for (u16 i = 0; i < this.getTouchingCount(); i++)
		{
			this.getTouchingByIndex(i).AddForce(Vec2f_zero); // forces collision checks again
		}

		SetMapObstructed(this, false);
	}
}

void onInit(CBlob@ this)
{
	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getShape().getConsts().collidable = false;
	this.getShape().getConsts().waterPasses = true;

	this.server_setTeamNum(-1);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Obstructor component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (isServer())
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
	sprite.SetZ(-50);
	sprite.SetFacingLeft(false);
	MakeDamageFrame(this);
}

void onBlobCollapse(CBlob@ this)
{
	this.server_Die();
}

void onDie(CBlob@ this)
{
	if (this.exists("component"))
	{
		getMap().server_SetTile(this.getPosition(), CMap::tile_empty);
	}
}

void SetMapObstructed(CBlob@ this, const bool&in obstructed)
{
	this.getShape().getConsts().collidable = obstructed;

	CMap@ map = getMap();
	const u16 type = obstructed ? Dummy::OBSTRUCTOR : Dummy::OBSTRUCTOR_BACKGROUND;
	map.server_SetTile(this.getPosition(), type);
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	MakeDamageFrame(this);
}

void MakeDamageFrame(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	const f32 hp = this.getHealth();
	const f32 full_hp = this.getInitialHealth();
	if (hp < full_hp)
	{
		const f32 ratio = hp / full_hp;
		if (ratio <= 0.0f)
		{
			sprite.animation.frame = sprite.animation.getFramesCount() - 1;
		}
		else
		{
			sprite.animation.frame = (1.0f - ratio) * (sprite.animation.getFramesCount());
		}
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	stream.write_bool(this.getShape().getConsts().collidable);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	bool collidable;
	if (!stream.saferead_bool(collidable)) return false;

	this.getShape().getConsts().collidable = collidable;

	CSprite@ sprite = this.getSprite();
	sprite.SetAnimation(collidable ? "closed" : "open");
	sprite.SetRelativeZ(collidable ? 600 : 0);
	MakeDamageFrame(this);

	return true;
}
