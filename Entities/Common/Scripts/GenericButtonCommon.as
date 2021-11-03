bool canSeeButtons(CBlob@ this, CBlob@ caller)
{
	if ((this is null || caller is null)) { return false; }

	CInventory@ inv = this.getInventory();
	return (
		//is attached to this or not attached at all (applies to vehicles and quarters)
		(caller.isAttachedTo(this) || !caller.isAttached()) &&
		//is inside this inventory or not inside an inventory at all (applies to crates)
		((inv !is null && inv.isInInventory(caller)) || !caller.isInInventory())
	);
}
