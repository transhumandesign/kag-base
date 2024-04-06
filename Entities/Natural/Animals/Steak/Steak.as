
#include "ArcherCommon.as";
#include "MakeFood.as";

void onInit(CBlob@ this)
{
	this.Tag("cookable in fireplace");
	this.set_string("cooked name", "Cooked Steak");
	this.set_u8("cooked sprite index", 0);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "arrow" 
		&& hitterBlob.get_u8("arrow type") == ArrowType::fire)
	{
		Cook(this); // MakeFood.as
	}
	
	return damage;
}
