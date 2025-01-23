// Lamp.as

#include "MechanismsCommon.as";
#include "TeamColour.as";

class Lamp : Component
{
	u16 id;

	Lamp(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	void Activate(CBlob@ this)
	{
		this.SetLight(true);
		CSprite@ sprite = this.getSprite();
		
		if (sprite !is null)
		{
			sprite.SetFrameIndex(1);
			CSpriteLayer@ light = sprite.getSpriteLayer("light");
			
			if (light !is null)
			{
				light.setRenderStyle(RenderStyle::light);
			}
		}
	}

	void Deactivate(CBlob@ this)
	{
		this.SetLight(false);
		CSprite@ sprite = this.getSprite();
		
		if (sprite !is null)
		{
			sprite.SetFrameIndex(0);
			CSpriteLayer@ light = sprite.getSpriteLayer("light");
			
			if (light !is null)
			{
				light.setRenderStyle(RenderStyle::normal);
			}
		}
	}
}

void onInit(CBlob@ this)
{
	// used by BlobPlacement.as
	this.Tag("place ignore facing");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	// blob light
	this.SetLight(false);
	this.SetLightRadius(64.0f);
	const u8 team = this.getTeamNum();
	const SColor team_color = getTeamColor(team);
	this.SetLightColor(team_color);
	
	// spritelayer that will be set to RenderStyle::light
	CSprite@ sprite = this.getSprite();
	sprite.addSpriteLayer("light", sprite.getFilename(), 8,8, team, this.getSkinNum());
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
		rotateTopology(ANGLE, TOPO_DOWN),   // input topology
		TOPO_NONE,                          // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	const bool FACING = ANGLE < 180? false : true;

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-55);
	sprite.SetFacingLeft(FACING);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Lamp.png", 16, 16);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
	layer.SetFacingLeft(FACING);
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	stream.write_bool(this.isLight());
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	bool activated;
	if (!stream.saferead_bool(activated)) return false;

	this.SetLight(activated);
	this.getSprite().SetFrameIndex(activated ? 1 : 0);

	return true;
}
