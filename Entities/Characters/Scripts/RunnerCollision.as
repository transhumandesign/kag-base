//needed for crouch logic
#include "CrouchCommon.as";

// character was placed in crate
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true; // run scripts while in crate
	this.getMovement().server_SetActive(true);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CShape@ shape = this.getShape();
	CShape@ oShape = blob.getShape();
	if (shape is null || oShape is null)
	{
		error("error: missing shape in runner doesCollideWithBlob");
		return false;
	}

	if (blob.isPlatform() && blob.getAngleDegrees() == 0
		&& this.get_u8("crouch_through") > 0
		&& this.getTeamNum() == blob.getTeamNum())
	{
		return false;
	}

	bool colliding_block = (oShape.isStatic() && oShape.getConsts().collidable);

	// when dead, collide only if its moving and some time has passed after death
	if (this.hasTag("dead"))
	{
		bool slow = (this.getShape().vellen < 1.5f);
		//static && collidable should be doors/platform etc             fast vel + static and !player = other entities for a little bit (land on the top of ballistas).
		return colliding_block || (!slow && oShape.isStatic() && !blob.hasTag("player"));
	}
	else // collide only if not a player or other team member, or crouching
	{
		//other team member
		if (blob.hasTag("player") && this.getTeamNum() == blob.getTeamNum())
		{
			//knight shield up logic

			//we're a platform if they aren't pressing down
			bool thisplatform = this.hasTag("shieldplatform") &&
								!blob.isKeyPressed(key_down);

			if (thisplatform || blob.getName() == "knight")
			{
				Vec2f pos = this.getPosition();
				Vec2f bpos = blob.getPosition();

				const f32 size = 9.0f;

				if (thisplatform)
				{
					if (bpos.y < pos.y - size && thisplatform)
					{
						return true;
					}
				}

				if (bpos.y > pos.y + size && blob.hasTag("shieldplatform"))
				{
					return true;
				}
			}

			return false;
		}

		//don't collide migrants
		if (blob.hasTag("migrant"))
		{
			return false;
		}

		//don't collide if crouching (but doesn't apply to blocks)
		if (!shape.isStatic() && !colliding_block && isCrouching(this))
		{
			return false;
		}

	}

	return true;
}

void onTick(CBlob@ this)
{
	if (hasJustCrouched(this))
	{
		const uint count = this.getTouchingCount();
		for (uint step = 0; step < count; ++step)
		{
			CBlob@ blob = this.getTouchingByIndex(step);
			if ((this.getPosition()-blob.getPosition()).y > 0) //prevents player from dropping through enemies they're stading on
				blob.getShape().checkCollisionsAgain = true;
		}
	}
}
