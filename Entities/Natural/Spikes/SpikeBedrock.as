void onInit(CSprite@ this)
{
	this.SetZ(500.0f);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}