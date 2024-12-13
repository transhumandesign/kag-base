void StaticOn(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetStatic(true);
	shape.SetGravityScale(0.0f);
}

void StaticOff(CBlob@ this)
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