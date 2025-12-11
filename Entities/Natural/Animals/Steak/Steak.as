
#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.Tag("decay not moving");
	this.set_u16("decay time", 60);

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
