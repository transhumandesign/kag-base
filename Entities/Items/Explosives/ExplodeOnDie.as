//pretty straightforward, set properties for larger explosives
// wont work without "exploding"  tag

#include "Explosion.as";  // <---- onHit()

void onDie(CBlob@ this)
{
	if (this.hasTag("exploding"))
	{
		if (this.exists("explosive_radius") && this.exists("explosive_damage"))
		{
			Explode(this, this.get_f32("explosive_radius"), this.get_f32("explosive_damage"));
		}
		else //default "bomb" explosion
		{
			Explode(this, 64.0f, 3.0f);
		}
	}
}
