// use this script if you want a blob to be a respawn

void onInit(CBlob@ this)
{
	this.CreateRespawnPoint(this.getName(), Vec2f(0.0f, -this.getHeight() / 2.0f));

	// minimap icon
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 9, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
