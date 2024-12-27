// Tent logic

#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "GenericButtonCommon.as"
#include "HolidayCommon.as"

void onInit(CBlob@ this)
{
#ifdef STAGING
	if (getHoliday() == Holidays::Christmas)
		this.getSprite().ReloadSprite("Tent", 48, 40);
#endif

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

}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

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
