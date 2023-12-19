// Attach this to objects activatable with ActivateHeldObject.as

void onInit(CBlob@ this)
{
	this.Tag("activatable");
	this.addCommandID("activate");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
