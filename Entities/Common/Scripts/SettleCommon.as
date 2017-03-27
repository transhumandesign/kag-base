
void Disable(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetStatic(true);
	shape.doTickScripts = false;

}

void Enable(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetStatic(false);
	shape.doTickScripts = true;
}
