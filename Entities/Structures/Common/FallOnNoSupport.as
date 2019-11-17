// FallOnNoSupport.as

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
			this.SendCommand(this.getCommandID("static off"));
		}
	}
	else
	{
		if (!shape.isStatic())
		{
			this.SendCommand(this.getCommandID("static on"));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("static off"))
	{
		CShape@ shape = this.getShape();
		shape.SetStatic(false);
		shape.SetGravityScale(1.0f);

		ShapeConsts@ consts = shape.getConsts();
		consts.mapCollisions = true;

		if (!this.hasTag("fallen"))
		{
			this.Tag("fallen");
			this.server_SetTimeToDie(3.0f);
            ShapeVars@ vars = this.getShape().getVars();
            if (vars.isladder)
            {
                vars.isladder = false;

            }

		}
	}
	else if (cmd == this.getCommandID("static on"))
	{
		CShape@ shape = this.getShape();
		shape.SetStatic(true);
		shape.SetGravityScale(0.0f);
	}
}
