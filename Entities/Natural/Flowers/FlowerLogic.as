// Flowers logic

#include "PlantGrowthCommon.as";

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(2) == 0); //random facing

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		//random color
		u8 col = XORRandom(8);
		if (this.exists("color"))
			col = this.get_u8("color");
		else
			this.set_u8("color", col);
		sprite.ReloadSprites(col, 0);
		
		sprite.SetZ(10.0f);
	}

	this.getCurrentScript().tickFrequency = 15;

	this.set_u8(growth_chance, default_growth_chance);
	this.set_u8(growth_time, default_growth_time);

	this.Tag("scenary");
}


void onTick(CBlob@ this)
{
	bool grown = this.hasTag(grown_tag);
	if (grown)
	{
		this.AddScript("Eatable.as");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}
