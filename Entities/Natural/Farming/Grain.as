void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
