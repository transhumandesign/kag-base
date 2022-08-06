// Vehicle Workshop

#include "GenericButtonCommon.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "TunnelCommon.as"

const u8 respawn_immunity_time = 30 * 1; // 1 second

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	InitRespawnCommand(this);
	InitClasses(this);

	this.Tag("respawn");
	this.Tag("change class drop inventory");
	this.Tag("travel tunnel");
	this.Tag("teamlocked tunnel");
	this.Tag("ignore raid");
	this.Tag("builder always hit");

	this.set_u8("custom respawn immunity", respawn_immunity_time); 

	this.set_Vec2f("travel button pos", Vec2f(-6, 6));
	this.set_Vec2f("travel offset", Vec2f(-10, 0));
	this.inventoryButtonPos = Vec2f(12, -12);

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ flag = sprite.addSpriteLayer("flag layer", "Outpost.png", 32, 32);
	if (flag !is null)
	{
		flag.addAnimation("default", 5, true);
		int[] frames = { 9, 10, 11 };
		flag.animation.AddFrames(frames);
		flag.SetRelativeZ(0.8f);
		flag.SetOffset(Vec2f(10.5f, -12.0f));
	}

	CSpriteLayer@ planks = sprite.addSpriteLayer("planks", "Outpost.png", 16, 16);
	if (planks !is null)
	{
		Animation@ anim = planks.addAnimation("default", 0, false);
		anim.AddFrame(40);
		planks.SetRelativeZ(10.0f);
		planks.SetOffset(Vec2f(9.0f, 10.0f));
	}

	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 7, Vec2f(16, 16));
	this.SetMinimapRenderAlways(true);
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ planks = this.getSpriteLayer("planks");
	if (planks is null) return;
	CBlob@[] list;

	planks.SetVisible(!getTunnels(this.getBlob(), list));
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (canChangeClass(this, caller))
	{
		caller.CreateGenericButton("$change_class$", Vec2f(6, 6), this, buildSpawnMenu, getTranslatedString("Swap Class"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this) && canSeeButtons(this, forBlob));
}
