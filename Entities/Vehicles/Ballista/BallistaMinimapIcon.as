
void onInit(CBlob@ this)
{
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/BallistaIcon.png", 0, Vec2f(9, 10));
	this.SetMinimapRenderAlways(false);

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
