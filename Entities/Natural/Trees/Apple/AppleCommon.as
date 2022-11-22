
void MakeStatic(CBlob@ this)
{
	if (this !is null)
	{
		this.getSprite().SetRelativeZ(600);
		this.getShape().SetStatic(true);
		this.getShape().getConsts().collidable = false;	
		this.Tag("growing on tree");
		this.Sync("growing on tree", true);
		this.Tag("ignore_arrow");
		this.Sync("ignore_arrow", true);
	}

	if (isServer())
	{
		getMap().server_AddSector(this.getPosition() + Vec2f(-4, -4), this.getPosition() + Vec2f(4, 4), "no build", "", this.getNetworkID());
	}
}

void MakeNonStatic(CBlob@ this)
{
	if (this !is null)
	{
		this.getSprite().SetRelativeZ(0);
		this.getShape().SetStatic(false);
		this.getShape().getConsts().collidable = true;	
		this.Untag("growing on tree");
		this.Sync("growing on tree", true);
		this.Untag("ignore_arrow");
		this.Sync("ignore_arrow", true);
	}
	
	if (isServer())
	{	
		getMap().RemoveSectorsAtPosition(this.getPosition(), "no build", this.getNetworkID());
		this.server_SetTimeToDie(80); // unspawn so you can't hoard them apples
	}
}
