// Princess brain

#define SERVER_ONLY

#include "BrainCommon.as"

void onInit(CBrain@ this)
{
	InitBrain(this);

	this.server_SetActive(true);   // always running
	CBlob @blob = this.getBlob();
	blob.set_f32("gib health", -1.5f);
}

void onTick(CBrain@ this)
{
	SearchTarget(this);

	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// logic for target

	this.getCurrentScript().tickFrequency = 29;
	if (target !is null)
	{
		this.getCurrentScript().tickFrequency = 1;
		DefaultChaseBlob(blob, target);
	}
	else
	{
		RandomTurn(blob);
	}

	FloatInWater(blob);
}

// BLOB

//physics logic
void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && blob is this.getBrain().getTarget() && !this.hasTag("dead"))
	{
		this.getSprite().PlaySound("/Kiss.ogg");
	}
}