#include "ArcherCommon.as";

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

void turnOffFire(CBlob@ this)
{
	this.SetLight(false);
	this.set_u8("arrow type", ArrowType::normal);
	this.Untag("fire source");
	this.getSprite().SetAnimation("arrow");
	this.getSprite().PlaySound("/ExtinguishFire.ogg");
}

void turnOnFire(CBlob@ this)
{
	this.SetLight(true);
	this.set_u8("arrow type", ArrowType::fire);
	this.Tag("fire source");
	this.getSprite().SetAnimation("fire arrow");
	this.getSprite().PlaySound("/FireFwoosh.ogg");
}
