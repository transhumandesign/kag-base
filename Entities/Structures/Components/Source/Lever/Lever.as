// Lever.as

#include "MechanismsCommon.as";
#include "GenericButtonCommon.as";

class Lever : Component
{
	Lever(Vec2f position)
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

	this.set_bool("activated", true);

	this.addCommandID("server_activate");
	this.addCommandID("client_activate");

	AddIconToken("$lever_false$", "Lever.png", Vec2f(16, 16), 4);
	AddIconToken("$lever_true$", "Lever.png", Vec2f(16, 16), 5);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Lever component(POSITION);
	this.set("component", component);

	const bool activated = this.get_bool("activated");

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                                            // x
		component.y,                                            // y
		TOPO_NONE,                                              // input topology
		TOPO_CARDINAL,                                          // output topology
		(!activated ? INFO_SOURCE : INFO_SOURCE | INFO_ACTIVE), // information
		0,                                                      // power
		0);                                                     // id
	}

	CSprite@ sprite = this.getSprite();
	sprite.SetFacingLeft(false);
	sprite.SetFrameIndex(activated ? 1 : 0);
	sprite.SetZ(-50);

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Lever.png", 8, 8);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!this.isOverlapping(caller) || !this.getShape().isStatic()) return;

	const bool activated = this.get_bool("activated");
	const string description = activated ? "Deactivate" : "Activate";

	CButton@ button = caller.CreateGenericButton("$lever_"+activated+"$", Vec2f_zero, this, this.getCommandID("server_activate"), description);
	if (button !is null)
	{
		button.radius = 8.0f;
		button.enableRadius = 20.0f;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_activate") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
		
		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		// range check
		if (this.getDistanceTo(caller) > 20.0f) return;

		Component@ component = null;
		if (!this.get("component", @component)) return;

		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		const bool activated = this.get_bool("activated");
		const u8 info = activated ? INFO_SOURCE : INFO_SOURCE | INFO_ACTIVE;

		this.set_bool("activated", !activated);

		grid.setInfo(component.x, component.y, info);

		CBitStream stream;
		stream.write_bool(!activated);
		this.SendCommand(this.getCommandID("client_activate"), stream);
	}
	else if (cmd == this.getCommandID("client_activate") && isClient())
	{
		bool activated;
		if (!params.saferead_bool(activated)) return;

		this.set_bool("activated", activated);
		CSprite@ sprite = this.getSprite();
		sprite.SetFrameIndex(activated ? 1 : 0);
		sprite.PlaySound("LeverToggle.ogg");
	}
}
