
/**
 * Fake attachment script, for when static is just too
 * fiddly and you want it stuck at some point.
 */

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 5; // opt
}

void onTick(CBlob@ this)
{
	if (this.hasTag("idle"))
	{
		Vec2f attached = this.get_Vec2f("attach");
		this.setPosition(attached);

		CShape@ shape = this.getShape();
		if (!shape.isStatic()) //dont spam this or we'll fuck static state
			shape.SetStatic(true);
	}

}
