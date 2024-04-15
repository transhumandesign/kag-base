// SolarPanel.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";

const u8 TICK_FREQUENCY_IDLE = 45;
const u8 TICK_FREQUENCY_RUNNING = 3;
const u8 IDLE_TICKS_UNTIL_STARTS_RUNNING = 5;

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

	Tile tile = getMap().getTile(this.getPosition());

	u8 light = tile.light;
	s16 light_received_counter = this.get_u16("light received counter");
	bool has_light = this.get_bool("has light");
	
	if (light > 50)
	{
		if (!has_light)
		{
			if (light_received_counter >= IDLE_TICKS_UNTIL_STARTS_RUNNING)
				this.set_bool("has light", true);
		}

		this.set_u16("light received counter",  Maths::Min(light_received_counter + 1, IDLE_TICKS_UNTIL_STARTS_RUNNING));
	}
	else
	{
		if (has_light)
		{	
			if (light_received_counter <= 0)
				this.set_bool("has light", false);
		}

		this.set_u16("light received counter", Maths::Max(light_received_counter - 1, 0));
	}

	if (has_light)
	{
		this.getCurrentScript().tickFrequency = TICK_FREQUENCY_RUNNING;

		u8 power = light / 255.0f * power_source;

		Component@ component = null;
		if (!this.get("component", @component)) return;

		if (isServer())
		{
			MapPowerGrid@ grid;
			if (!getRules().get("power grid", @grid)) return;

			grid.setPower(
			component.x,                        // x
			component.y,                        // y
			power);                             // power
		}
	}
	else
	{
		this.getCurrentScript().tickFrequency = TICK_FREQUENCY_IDLE;
	}

	//print("has_light: " + has_light + " light: " + light + " light_received_counter: " + light_received_counter);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
