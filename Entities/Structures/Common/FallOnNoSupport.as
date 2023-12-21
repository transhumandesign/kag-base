// FallOnNoSupport.as

#include "StaticToggleCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 17;

	this.addCommandID("static on");
	this.addCommandID("static off");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (isServer() && solid && !this.getShape().isStatic() && !this.isAttached())
	{
		if (this.getOldVelocity().y < 1.0f && !this.hasTag("can settle"))
		{
			this.server_SetTimeToDie(2);
		}
		else
		{
			this.server_Hit(this, this.getPosition(), this.getVelocity() * -1.0f, 10.0f, 0);
		}
	}
}

void onBlobCollapse(CBlob@ this)
{
	if (!isServer() || getGameTime() < 60 || this.hasTag("fallen")) return;

	CShape@ shape = this.getShape();
	if (shape.getCurrentSupport() < 0.001f)
	{
		if (shape.isStatic())
		{
			StaticOff(this);
			this.SendCommand(this.getCommandID("static off"));
		}
	}
	else
	{
		if (!shape.isStatic())
		{
			StaticOn(this);
			this.SendCommand(this.getCommandID("static on"));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("static off") && isClient())
	{
		StaticOff(this);
	}
	else if (cmd == this.getCommandID("static on") && isClient())
	{
		StaticOn(this);
	}
}
