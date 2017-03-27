
#include "DetectTiles.as"

const string supported = "supported by tiles";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 5;
}

void onTick(CBlob@ this)
{
	Vec2f tl, br;
	CShape@ shape = this.getShape();

	if (shape.isStatic())
	{
		shape.getBoundingRect(tl, br);
		if (!DetectTiles(tl + Vec2f(1, 0), br + Vec2f(-1, 8)))
		{
			shape.SetStatic(false);   // THIS IS CLIENT SIDE TOO< WHICH IS BAD
			shape.SetGravityScale(1.0f);
			shape.getConsts().mapCollisions = true;
			this.getCurrentScript().runFlags |= Script::remove_after_this;
		}
	}
}
