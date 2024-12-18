#include "ArrowCommon.as"

void onInit(CBlob@ this)
{
  this.set_u16("decay time", 300);

  this.getCurrentScript().runFlags |= Script::remove_after_this;

  setArrowHoverRect(this);

  this.set_f32("important-pickup", 30.0f);
}
