#define SERVER_ONLY

// regen hp back to

const string max_prop = "regen maximum";
const string rate_prop = "regen rate";

void onInit(CBlob@ this)
{
	if (!this.exists(max_prop))
		this.set_f32(max_prop, this.getInitialHealth());

	if (!this.exists(rate_prop))
		this.set_f32(rate_prop, 0.25f); //0.5 hearts per second

	this.getCurrentScript().tickFrequency = 90;
}

void onTick(CBlob@ this)
{
	this.server_Heal(this.get_f32(rate_prop));
}
