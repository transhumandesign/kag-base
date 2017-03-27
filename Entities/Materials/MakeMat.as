void MakeMat(CBlob@ this, Vec2f worldPoint, const string& in name, int quantity)
{
	// decide whether to fly it or put directly in inv
	bool putInInv = true;
	int added = 0;

	CInventory@ inv = this.getInventory();
	if (inv is null) //we dont have an inventory to put it into
	{
		putInInv = false;
		if (this.isAttached()) //do we have a holder?
		{
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
			CBlob@ holder = point.getOccupied();

			if (holder !is null) // we have something holding us, make the mat for it instead
			{
				MakeMat(holder, worldPoint, name, quantity);
				return;
			}
		}
	}
	else
	{
		// find if a mat is already in inv which we can fill in

		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob @invblob = inv.getItem(i);

			if (invblob !is this && invblob.getName() == name)
			{
				int spaceLeft = invblob.maxQuantity - invblob.getQuantity();
				if (spaceLeft > 0)
				{
					int toAdd = Maths::Min(spaceLeft, quantity);
					invblob.server_SetQuantity(invblob.getQuantity() + toAdd);
					added += toAdd;
				}
			}

			if (added >= quantity) // we're done
			{
				return;
			}
		}
	}

	quantity -= added;
	if (quantity <= 0) // safety
		return;

	// make a new blob mat

	CBlob @mat = server_CreateBlob(name, this.getTeamNum(), worldPoint);

	if (mat !is null)
	{
		f32 dir = this.isFacingLeft() ? 1.0f : -1.0f;
		worldPoint.x -= getMap().tilesize / 2.0f;
		mat.server_SetQuantity(quantity);
		Vec2f newpos =  this.getPosition();

		if (putInInv)
			putInInv = this.server_PutInInventory(mat);	// it might not fit

		if (!putInInv)
		{
			mat.setPosition(newpos);
			mat.setVelocity(Vec2f(dir, -1.0f) * 0.5f);
		}
	}
}
