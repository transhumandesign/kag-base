void onInit(CBlob@ this)
{
	this.set_string("eat sound", "/Heart.ogg");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
	this.set_u16("decay time", 40);
	this.Tag("ignore_arrow");
	this.Tag("ignore_saw");
}
