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
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// background, let water overlap
	this.getShape().getConsts().waterPasses = true;

	this.addCommandID("toggle");
	this.addCommandID("toggle client");

	AddIconToken("$lever_0$", "Lever.png", Vec2f(16, 16), 4);
	AddIconToken("$lever_1$", "Lever.png", Vec2f(16, 16), 5);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;

	Lever component(position);
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

	CSpriteLayer@ layer = sprite.addSpriteLayer("background", "Lever.png", 8, 8);
	layer.addAnimation("default", 0, false);
	layer.animation.AddFrame(2);
	layer.SetRelativeZ(-1);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!this.isOverlapping(caller) || !this.getShape().isStatic()) return;

	u8 state = this.get_u8("state");
	string description = (state > 0)? "Deactivate" : "Activate";

	CButton@ button = caller.CreateGenericButton(
	"$lever_"+state+"$",                        // icon token
	Vec2f_zero,                                 // button offset
	this,                                       // button attachment
	this.getCommandID("toggle"),                // command id
	description);                               // description

	button.radius = 8.0f;
	button.enableRadius = 20.0f;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("toggle") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;
					
		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check
		if (this.getDistanceTo(caller) > 20.0f) return;

		Component@ component = null;
		if (!this.get("component", @component)) return;

		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		u8 state = this.get_u8("state") == 0? 1 : 0;
		u8 info = state == 0? INFO_SOURCE : INFO_SOURCE | INFO_ACTIVE;

		this.set_u8("state", state);
		this.Sync("state", true);

		grid.setInfo(
		component.x,                        // x
		component.y,                        // y
		info);                              // information
	}
	if (cmd == this.getCommandID("toggle client") && isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.SetFrameIndex(this.get_u8("state"));
		sprite.PlaySound("LeverToggle.ogg");
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}