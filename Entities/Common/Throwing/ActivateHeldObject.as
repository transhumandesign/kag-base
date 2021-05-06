
// USAGE:
//  add strings to "names to activate" array
//  add "activate" commands to those objects
//  light and throw them with client_SendThrowOrActivateCommand( this ); in ThrowCommon.as
//  Tag("dont deactivate") to have repeated activation

/**  also...
 * Means this object can throw other objects with client_SendThrowCommand( this ); in ThrowCommon.as
 *
 * for custom throw scales (eg for a super-strong unit) use
 *  the "throw scale" property, default to 1.0f.
 *
 */

#include "ThrowCommon.as";

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

bool ActivateBlob(CBlob@ this, CBlob@ blob, Vec2f pos, Vec2f vector, Vec2f vel)
{
	bool shouldthrow = true;
	bool done = false;

	if (!blob.hasTag("activated") || blob.hasTag("dont deactivate"))
	{
		string carriedname = blob.getName();
		string[]@ names;

		if (this.get("names to activate", @names))
		{
			for (uint step = 0; step < names.length; ++step)
			{
				if (names[step] == carriedname)
				{
					//if compatible
					if (getNet().isServer() && blob.hasTag("activatable"))
					{
						blob.SendCommand(blob.getCommandID("activate"));
					}

					blob.Tag("activated");//just in case
					shouldthrow = false;
					this.Tag(blob.getName() + " done activate");

					// move ouit of inventory if its the case
					if (blob.isInInventory())
					{
						this.server_Pickup(blob);
					}
					done = true;
				}
			}
		}
	}

	//throw it if it's already lit or we cant light it
	if (getNet().isServer() && !blob.hasTag("custom throw") && shouldthrow && this.getCarriedBlob() is blob)
	{
		DoThrow(this, blob, pos, vector, vel);
		done = true;
	}

	return done;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate/throw"))
	{
		Vec2f pos = params.read_Vec2f();
		Vec2f vector = params.read_Vec2f();
		Vec2f vel = params.read_Vec2f();
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
	else if (cmd == this.getCommandID("throw"))
	{
		Vec2f pos = params.read_Vec2f();
		Vec2f vector = params.read_Vec2f();
		Vec2f vel = params.read_Vec2f();
		CBlob @carried = this.getCarriedBlob();

		if (carried !is null)
		{
			if (getNet().isServer() && !carried.hasTag("custom throw"))
			{
				DoThrow(this, carried, pos, vector, vel);
			}
			//this.Tag( carried.getName() + " done throw" );
		}
	}
}
