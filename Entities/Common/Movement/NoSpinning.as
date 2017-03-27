//turn off rotations for things that shouldn't do physics spinning
void onInit(CShape@ this)
{
	this.SetRotationsAllowed(false);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
