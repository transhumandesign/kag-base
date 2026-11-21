#include "ActivationThrowCommon.as"

void onInit(CBlob@ this)
{
	if (!this.exists("names to activate"))
	{
		string[] names;
		this.set("names to activate", names);
	}

	this.addCommandID("activate/throw");
	// throw
	this.Tag("can throw");
	this.addCommandID("throw");
	this.set_f32("throw scale", 1.0f);
	this.set_bool("throw uses ourvel", true);
	this.set_f32("throw ourvel scale", 1.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate/throw") && isServer())
	{
		Vec2f pos = this.getVelocity();
		Vec2f vector = this.getAimPos() - this.getPosition();
		Vec2f vel = this.getVelocity();
		CBlob @carried = this.getCarriedBlob();
		if (carried !is null)
		{
			ActivateBlob(this, carried, pos, vector, vel);
		}
		else // search in inv
		{
			CInventory@ inv = this.getInventory();
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @blob = inv.getItem(i);
				if (ActivateBlob(this, blob, pos, vector, vel))
					return;
			}
		}
	}
	else if (cmd == this.getCommandID("throw") && isServer())
	{
		Vec2f pos = this.getVelocity();
		Vec2f vector = this.getAimPos() - this.getPosition();
		Vec2f vel = this.getVelocity();
		CBlob @carried = this.getCarriedBlob();

		if (carried !is null)
		{
			if (!carried.hasTag("custom throw"))
			{
				DoThrow(this, carried, pos, vector, vel);
			}
			//this.Tag( carried.getName() + " done throw" );
		}
	}
}