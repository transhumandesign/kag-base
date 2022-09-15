#include "Hitters.as"
#include "GenericButtonCommon.as"

const u32 VANISH_BODY_SECS = 45;
const f32 CARRIED_BLOB_VEL_SCALE = 1.0;
const f32 MEDIUM_CARRIED_BLOB_VEL_SCALE = 0.8;
const f32 HEAVY_CARRIED_BLOB_VEL_SCALE = 0.6;


void onInit(CBlob@ this)
{
	this.set_f32("hit dmg modifier", 0.0f);
	this.getCurrentScript().tickFrequency = 0; // make it not run ticks until dead
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// make dead state; make sure this script is at the end of onHit scripts
	if (this.getHealth() <= 0.0f && !this.hasTag("dead"))
	{
		this.set_u32("death time", getGameTime());
		this.Tag("dead");

		if (isServer())
			getRules().server_BlobDie(this);

		// sound
		if (this.getSprite() !is null 
			&& this !is hitterBlob
			&& this.exists("death cry"))
		{
			this.getSprite().PlaySound(this.get_string("death cry"));
		}
		
		// detach player
		this.server_DetachAll();

		this.getCurrentScript().tickFrequency = 30;
		this.set_f32("hit dmg modifier", 0.5f);
		this.getShape().setFriction(0.75f);
		this.getShape().setElasticity(0.2f);
	}
	
	return damage;
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.hasTag("dead") 
		&& !(blob.getName() == "arrow" && this.getTeamNum() != blob.getTeamNum()))
		return false;
	return true;
}

void onTick(CBlob@ this)
{
	// (drop anything attached)
	CBlob @carried = this.getCarriedBlob();
	if (carried !is null)
	{
		carried.server_DetachFromAll();
	}

	//we have expired -> turning into skeleton
	if (this.get_u32("death time") + VANISH_BODY_SECS * getTicksASecond() < getGameTime())
	{
		if (this.exists("can decompose"))
		{
			this.Tag("decomposed");
			this.Untag("flesh");
			
			this.RemoveScript("GibIntoSteaks.as");
			this.RemoveScript("FleshHitEffects.as");
			this.RemoveScript("FleshHit.as");
			this.server_SetHealth(1.0f);
		}
		else
		{
			this.server_Die();
		}
	}
}

// reset vanish counter on pickup
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this.hasTag("dead"))
	{
		this.set_u32("death time", getGameTime());
	}
}