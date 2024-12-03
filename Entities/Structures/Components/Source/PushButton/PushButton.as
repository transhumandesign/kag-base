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
	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	this.addCommandID("server_activate");
	this.addCommandID("client_activate");

	AddIconToken("$pushbutton_1$", "PushButton.png", Vec2f(16, 16), 2);

	this.getCurrentScript().tickIfTag = "active";
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	PushButton component(POSITION);
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
	sprite.SetFacingLeft(false);
	sprite.SetZ(-50);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!this.isOverlapping(caller) || !this.getShape().isStatic() || this.get_u8("state") != 0) return;

	CButton@ button = caller.CreateGenericButton("$pushbutton_1$", Vec2f_zero, this, this.getCommandID("server_activate"), getTranslatedString("Activate"));
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
	if (cmd == this.getCommandID("server_activate") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
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

		this.SendCommand(this.getCommandID("client_activate"));
	}
	else if (cmd == this.getCommandID("client_activate") && isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("default");
		sprite.SetAnimation("activate");
		sprite.PlaySound("PushButton.ogg");
	}
}
