
void onInit(CBlob@ this)
{
  if (getNet().isServer())
  {
    this.set_u16('decay time', 180);
  }

  this.maxQuantity = 2;

  this.getCurrentScript().runFlags |= Script::remove_after_this;

  // Pickup: custom hover area
  Vec2f[] hoverRect = 
    { Vec2f(-3.0f, -4.5f)
    , Vec2f(-1.5f, -7.5f)
    , Vec2f(1.5f, -7.5f)
    , Vec2f(3.0f, -4.5f)
    , Vec2f(3.0f, 3.5f)
    , Vec2f(-3.0f,  3.5f)
    , Vec2f(-3.0f,  -4.5f)
    };

  this.set("hover-poly", hoverRect);
}
