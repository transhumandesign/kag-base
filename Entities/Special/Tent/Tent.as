// Tent logic

#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "GenericButtonCommon.as"
#include "Hitters.as";
#include "BombCommon.as";

const s16 tent_bomb_fuse = 120;

// blob

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50.0f);

	this.CreateRespawnPoint("tent", Vec2f(0.0f, -4.0f));
	InitClasses(this);
	this.Tag("change class drop inventory");

	this.Tag("respawn");

	// minimap
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));
	
	// explosion stuff
	this.set_Vec2f("custom_sparks_offset", Vec2f(0,-24));
	this.set_bool("explosive_teamkill", true);
}


void onTick(CBlob@ this)
{
	if (enable_quickswap)
	{
		//quick switch class
		CBlob@ blob = getLocalPlayerBlob();
		if (blob !is null && blob.isMyPlayer())
		{
			if (
				canChangeClass(this, blob) && blob.getTeamNum() == this.getTeamNum() && //can change class
				blob.isKeyJustReleased(key_use) && //just released e
				isTap(blob, 4) && //tapped e
				blob.getTickSinceCreated() > 1 //prevents infinite loop of swapping class
			) {
				CycleClass(this, blob);
			}
		}
	}
	
	CRules@ rules = getRules();
	int8 winner_team = rules.getTeamWon();

	if (rules.isGameOver() && winner_team >= 0 && winner_team != this.getTeamNum() && !this.hasTag("exploding"))
	{
		SetupBomb(this, tent_bomb_fuse, 64.0f, 8.0f, 48.0f, 1.0f, true);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || this.hasTag("exploding")) return;

	// button for runner
	// create menu for class change
	if (canChangeClass(this, caller) && caller.getTeamNum() == this.getTeamNum())
	{
		caller.CreateGenericButton("$change_class$", Vec2f(0, 0), this, buildSpawnMenu, getTranslatedString("Swap Class"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}

void onDie(CBlob@ this)
{
	this.getSprite().SetEmitSoundPaused(true);

	// custom gib particles
	this.getSprite().Gib();
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	const string fname = CFileMatcher("/Tent.png").getFirst();
	for (int i = 0; i < 100; i++)
	{
		uint frame = i + Maths::Floor(i / 10) * 10;
		makeGibParticle(fname, pos, vel + getRandomVelocity(0, 6 + XORRandom(10), 180), 0, frame, Vec2f(4, 4), 2.0f, 20, "Sounds/material_drop.ogg", this.getTeamNum());
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this is hitterBlob && this.getTickSinceCreated() > 10)
	{
		this.set_s32("bomb_timer", 0);
		RemoveNoBuildArea(this);
		this.getSprite().Gib();
		this.server_Die();
	}

	return 0.0f;
}

void RemoveNoBuildArea(CBlob@ this)
{
	CMap@ map = getMap();
	map.RemoveSectorsAtPosition(this.getPosition(), "no build");
}

// sprite

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickIfTag = "exploding";
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	s32 timer = blob.get_s32("bomb_timer") - getGameTime();

	if (timer < 0)
	{
		return;
	}

	if (timer > 30)
	{
		this.SetAnimation("default");
		this.animation.frame = this.animation.getFramesCount() * (1.0f - ((timer - 30) / 220.0f));
	}
	else
	{
		this.SetAnimation("shes_gonna_blow");
		this.animation.frame = this.animation.getFramesCount() * (1.0f - (timer / 30.0f));
	}
}
