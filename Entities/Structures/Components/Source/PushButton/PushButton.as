// PushButton.as

#include "MechanismsCommon.as";
#include "GenericButtonCommon.as";

class PushButton : Component
{
	PushButton(Vec2f position)
	{
		x = position.x;
		y = position.y;
	}
};

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	this.addCommandID("activate");
	this.addCommandID("activate client");

	AddIconToken("$pushbutton_1$", "PushButton.png", Vec2f(16, 16), 2);

	this.getCurrentScript().tickIfTag = "active";
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	PushButton component(position);
	this.set("component", component);

	this.set_u8("state", 0);

	if (isServer())
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

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetFacingLeft(false);
	sprite.SetZ(-50);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!this.isOverlapping(caller) || !this.getShape().isStatic() || this.get_u8("state") != 0) return;

	CButton@ button = caller.CreateGenericButton(
	"$pushbutton_1$",                           // icon token
	Vec2f_zero,                                 // button offset
	this,                                       // button attachment
	this.getCommandID("activate"),              // command id
	getTranslatedString("Activate"));           // description

	button.radius = 8.0f;
	button.enableRadius = 20.0f;
}

void onTick(CBlob@ this)
{
	if (getGameTime() < this.get_u32("duration")) return;

	Component@ component = null;
	if (!this.get("component", @component)) return;

	MapPowerGrid@ grid;
	if (!getRules().get("power grid", @grid)) return;

	// set state on server, sync to clients
	this.set_u8("state", 0);
	this.Sync("state", true);

	this.Untag("active");

	grid.setInfo(
	component.x,                        // x
	component.y,                        // y
	INFO_SOURCE);                       // information
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;
					
		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check
		if (this.getDistanceTo(caller) > 20.0f) return;

		// double check state, if state != 0, return
		if (this.get_u8("state") != 0) return;

		Component@ component = null;
		if (!this.get("component", @component)) return;

		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		// only set tag on server, so only the server ticks
		this.Tag("active");

		this.set_u32("duration", getGameTime() + 36);

		// set state, sync to clients
		this.set_u8("state", 1);
		this.Sync("state", true);

		grid.setInfo(
		component.x,                        // x
		component.y,                        // y
		INFO_SOURCE | INFO_ACTIVE);         // information

		this.SendCommand(this.getCommandID("activate client"));

	}
	else if (cmd == this.getCommandID("activate client") && isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.SetAnimation("default");
		sprite.SetAnimation("activate");
		sprite.PlaySound("PushButton.ogg");
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}