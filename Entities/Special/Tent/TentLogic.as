// Tent logic

#include "StandardRespawnCommand.as"

const int upgrade_cost = 100;
const string upgrade_material = "mat_gold";

const Vec2f upgrade_button(12.0f, 0.0f);
const Vec2f class_button(-6.0f, 0.0f);

void onInit(CBlob@ this)
{
	this.SetFacingLeft(this.getTeamNum() != 0);
	this.getSprite().SetZ(-50.0f);
	this.set_TileType("background tile", CMap::tile_wood_back);

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

	// Upgrade stuff
	this.set_bool("upgraded", false);
	this.addCommandID("upgrade");
	getRules().set_bool("tent quarry upgrade " + this.getTeamNum(), false);

	// Quary layers
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ belt = sprite.addSpriteLayer("belt", "QuarryBelt.png", 32, 32);
	if (belt !is null)
	{
		//default anim
		{
			Animation@ anim = belt.addAnimation("default", 4, true);
			int[] frames = {
				0, 1, 2, 3,
				4, 5, 6, 7,
				8, 9, 10, 11,
				12, 13
			};
			anim.AddFrames(frames);
		}
		//belt setup
		belt.SetOffset(Vec2f(-24.0f, -4.0f));
		belt.SetRelativeZ(2);
		belt.SetVisible(false);
	}

	CSpriteLayer@ bucketstone = sprite.addSpriteLayer("bucketstone", "Tent.png", 8, 8);
	if (bucketstone !is null)
	{
		//default anim
		{
			Animation@ anim = bucketstone.addAnimation("default", 0, true);
			anim.AddFrame(8);
		}
		//bucketstone setup
		bucketstone.SetOffset(Vec2f(-13.0f, 0.0f));
		bucketstone.SetRelativeZ(1);
		bucketstone.SetVisible(false);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	// button for runner
	// create menu for class change
	if (canChangeClass(this, caller) && caller.getTeamNum() == this.getTeamNum())
	{
		caller.CreateGenericButton("$change_class$", class_button, this, SpawnCmd::buildMenu, getTranslatedString("Swap Class"), params);
	}

	// upgrade button (canChangeClass to check if in range - consistency)
	if (canChangeClass(this, caller) && !this.get_bool("upgraded"))
	{
		CButton@ upgradebtn = caller.CreateGenericButton("$mat_gold$", upgrade_button, this, this.getCommandID("upgrade"), getTranslatedString("Upgrade to increase stone output at resupply"), params);
		if (upgradebtn !is null)
		{
			upgradebtn.deleteAfterClick = true;
			upgradebtn.SetEnabled(caller.hasBlob(upgrade_material, upgrade_cost));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("upgrade") && !this.get_bool("upgraded"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if(caller is null) return;

		caller.TakeBlob(upgrade_material, upgrade_cost);

		this.set_bool("upgraded", true);

		getRules().set_bool("tent quarry upgrade" + this.getTeamNum(), true);
		getRules().Sync("tent quarry upgrade" + this.getTeamNum(), true );

		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;
		CSpriteLayer@ belt = sprite.getSpriteLayer("belt");
		if (belt is null) return;

		belt.SetVisible(true);

		CSpriteLayer@ bucketstone = sprite.getSpriteLayer("bucketstone");
		if (belt is null) return;

		bucketstone.SetVisible(true);
	}
	else
	{
		onRespawnCommand(this, cmd, params);
	}
}