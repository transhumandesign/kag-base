// CoinSlot.as

#include "MechanismsCommon.as";
#include "LootCommon.as";
#include "GenericButtonCommon.as";

enum state
{
	DISABLED = 0,
	POWERED
};

const u32 DURATION = 40;
const u8 COIN_COST = 60;

class CoinSlot : Component
{
	CoinSlot(Vec2f position)
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

	if (isServer())
	{
		addCoin(this, COIN_COST / 3);
	}

	this.addCommandID("activate");
	this.addCommandID("activate client");

	AddIconToken("$insert_coin$", "InteractionIcons.png", Vec2f(32, 32), 26);

	this.getCurrentScript().tickIfTag = "active";
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	CoinSlot component(POSITION);
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

	if (!this.isOverlapping(caller) || !this.getShape().isStatic()) return;

	CPlayer@ player = caller.getPlayer();
	if (player !is null && player.isMyPlayer() && player.getCoins() < COIN_COST)
	{
		this.getSprite().PlaySound("NoAmmo.ogg", 0.5);
		return;
	}

	CButton@ button = caller.CreateGenericButton(
	"$insert_coin$",                            // icon token
	Vec2f_zero,                                 // button offset
	this,                                       // button attachment
	this.getCommandID("activate"),              // command id
	getTranslatedString("Insert 60 coins"));    // description

	button.radius = 8.0f;
	button.enableRadius = 20.0f;
}

void onTick(CBlob@ this)
{
	if (!isServer() || this.get_u32("duration") > getGameTime()) return;

	Component@ component = null;
	if (!this.get("component", @component)) return;

	MapPowerGrid@ grid;
	if (!getRules().get("power grid", @grid)) return;

	this.Untag("active");

	this.set_u8("state", DISABLED);

	grid.setInfo(
	component.x,                        // x
	component.y,                        // y
	INFO_SOURCE);                       // information
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate") && isServer())
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

		player.server_setCoins(Maths::Max(player.getCoins() - COIN_COST, 0));

		addCoin(this, COIN_COST / 3);

		this.Tag("active");

		this.set_u32("duration", getGameTime() + DURATION);

		this.set_u8("state", POWERED);

		grid.setInfo(
		component.x,                        // x
		component.y,                        // y
		INFO_SOURCE | INFO_ACTIVE);         // information
	}
	else if (cmd == this.getCommandID("activate client") && isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.SetAnimation("default");
		sprite.SetAnimation("activate");
		sprite.PlaySound("Cha.ogg");
	}
}

void onDie(CBlob@ this)
{
	if (isServer() && this.exists("component"))
	{
		server_CreateLoot(this, this.getPosition(), this.getTeamNum());
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
