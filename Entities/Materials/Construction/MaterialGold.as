
void onInit(CBlob@ this)
{
  if (isServer())
  {
	this.set_u8("decay step", 10);
  }
  
  this.maxQuantity = 50;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
