// SolarPanel.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";

const u8 TICK_FREQUENCY_IDLE = 45;
const u8 TICK_FREQUENCY_RUNNING = 3;
const u8 LIGHT_THRESHOLD = 140;

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by DummyOnStatic.as
	this.set_TileType(Dummy::TILE, Dummy::BACKGROUND);

	this.getCurrentScript().tickFrequency = TICK_FREQUENCY_IDLE;

	CSprite@ sprite = this.getSprite();
	u16 netID = this.getNetworkID();
	if (sprite !is null)
	{
		sprite.animation.frame = (netID % sprite.animation.getFramesCount());
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Component component(POSITION);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_NONE,                          // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetFacingLeft(false);
		sprite.SetZ(-50);
	}
}

void onTick(CBlob@ this)
{
	if (!this.getShape().isStatic()) return;

	SColor color_light = getMap().getColorLight(this.getPosition());
	u8 light = color_light.getLuminance();
	u8 power = light > LIGHT_THRESHOLD ? (light - LIGHT_THRESHOLD) / (250.0f - LIGHT_THRESHOLD) * power_source : 0;

	Component@ component = null;
	if (!this.get("component", @component)) return;

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setPower(
		component.x,      // x
		component.y,      // y
		power);           // power
	}
	
	this.getCurrentScript().tickFrequency = light > LIGHT_THRESHOLD ? 
	                                        TICK_FREQUENCY_RUNNING : TICK_FREQUENCY_IDLE;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
