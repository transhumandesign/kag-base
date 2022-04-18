
#define SERVER_ONLY

void onInit(CBlob@ this)
{
  this.set_u16('decay time', 300);

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

  this.set_f32("important-pickup", 25.0f);
}
