void onInit(CBlob@ this)
{
	this.set_string("eat sound", "/Heart.ogg");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
	this.server_SetTimeToDie(40);
	this.Tag("ignore_arrow");
}
