
// Common arrow hover pickup shape
const Vec2f[] arrowHoverRect = 
    { Vec2f(-3.0f, -4.5f)
    , Vec2f(-1.5f, -7.5f)
    , Vec2f(1.5f, -7.5f)
    , Vec2f(3.0f, -4.5f)
    , Vec2f(3.0f, 3.5f)
    , Vec2f(-3.0f,  3.5f)
    , Vec2f(-3.0f,  -4.5f)
    };

// Call this inside onInit
void setArrowHoverRect(CBlob@ this)
{
  this.set("hover-poly", arrowHoverRect);
}