
void onInit(CBlob@ this)
{
  if (getNet().isServer())
  {
    this.set_u8('decay step', 50);
  }

  this.maxQuantity = 250;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
