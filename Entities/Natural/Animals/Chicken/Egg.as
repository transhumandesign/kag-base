#include "CrouchCommon.as"

const f32 CHICKEN_LIMIT_RADIUS = 120.0f;
const int HATCHING_UPDATE_INTERVAL = 10;
const int INCUBATION_FACTOR = 3;
const int MAX_CHICKENS_TO_HATCH = 5;
const int TICKS_TO_HATCH_EGG = 50 * getTicksASecond();


void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = HATCHING_UPDATE_INTERVAL;
	this.addCommandID("hatch");
	this.set_u16("hatch_progress", 0);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

void onTick(CBlob@ this)
{
	if (!isServer())
		return;

	if (isChickenLimitReached(this)) {
		return;
	}

	doHatchingProgress(this);

	if (isReadyToHatch(this))
	{
		doHatch(this);
	}
}

/* Check if there are too many chickens around the egg for it to be able to hatch. */
bool isChickenLimitReached(CBlob@ this) {
	int chickenCount = 0;
	CBlob@[] blobs;
	this.getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
	for (uint step = 0; step < blobs.length; ++step)
	{
		CBlob@ other = blobs[step];
		if (other.getName() == "chicken")
		{
			chickenCount++;
		}
	}

	return chickenCount >= MAX_CHICKENS_TO_HATCH;
}

/* Update the hatch_progress counter for this egg. */
void doHatchingProgress(CBlob@ this) {
	u16 progress = isIncubated(this) ? HATCHING_UPDATE_INTERVAL * INCUBATION_FACTOR : HATCHING_UPDATE_INTERVAL;
	u16 updated_progress = this.get_u16("hatch_progress") + progress;
	this.set_u16("hatch_progress", updated_progress);
}

/* Check if the egg is ready to hatch. */
bool isReadyToHatch(CBlob@ this) {
	return this.get_u16("hatch_progress") >= TICKS_TO_HATCH_EGG;
}

/* Check if the egg is being incubated. */
bool isIncubated(CBlob@ this) {
	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);

	bool incubated = false;
	for (int i=0; i < overlapping.length; ++i) {
		CBlob@ blob = overlapping[i];
		if (blob.hasTag("player") && isCrouching(blob)) {
			blob.Tag("is_incubating_egg");
			incubated = true;  // don't break immediately, there might be multiple players incubating.
		}
	}
	return incubated;
}

/* Hatch the egg. */
void doHatch(CBlob@ this) {
	this.SendCommand(this.getCommandID("hatch"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("hatch"))
	{
		CSprite@ s = this.getSprite();
		if (s !is null)
		{
			s.Gib();
		}

		if (getNet().isServer())
		{
			this.server_SetHealth(-1);
			this.server_Die();
			server_CreateBlob("chicken", -1, this.getPosition() + Vec2f(0, -5.0f));
		}
	}
}
