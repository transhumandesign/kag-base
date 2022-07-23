
#define SERVER_ONLY

void onInit(CBlob@ this)
{
  this.set_u16("decay time", 300);

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
