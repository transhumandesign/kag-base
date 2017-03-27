bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	bool grown = this.getHealth() >= this.getInitialHealth() - 0.01f;
	return !grown;
}
