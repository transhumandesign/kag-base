
#define SERVER_ONLY;

// Use `.set_u8("decay step", ..)` to
// define the quantity that should be
// discarded each step

const uint16 FREQUENCY = 2000;
const uint16 QUICK_FREQUENCY = 30;
const uint16 QUARTER = FREQUENCY / 4;

void onInit(CBlob@ this)
{
	ScriptData@ script = this.getCurrentScript();
	script.runFlags |= Script::tick_not_attached;
	script.runFlags |= Script::tick_not_ininventory;

	this.getCurrentScript().tickFrequency = (getRules().hasTag("quick decay") ? QUICK_FREQUENCY : FREQUENCY);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() < (getRules().hasTag("quick decay") ? QUICK_FREQUENCY : FREQUENCY)) return;

	uint8 step = this.get_u8("decay step");
	uint16 quantity = this.getQuantity();

	if (step >= quantity)
	{
		this.server_Die();
		return;
	}

	this.server_SetQuantity(quantity - step);

	ScriptData@ script = this.getCurrentScript();

	// Halve the frequency up to 2 times
	if (script.tickFrequency > QUARTER)
	{
		script.tickFrequency /= 2;
	}
}

void onAttach(CBlob@ this, CBlob@ blob, AttachmentPoint@ point)
{
	this.getCurrentScript().tickFrequency = (getRules().hasTag("quick decay") ? QUICK_FREQUENCY : FREQUENCY);
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getCurrentScript().tickFrequency = (getRules().hasTag("quick decay") ? QUICK_FREQUENCY : FREQUENCY);
}
