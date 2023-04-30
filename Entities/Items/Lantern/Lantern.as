// Lantern script

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(64.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	this.Tag("dont deactivate");
	this.Tag("fire source");
	this.Tag("ignore_arrow");
	this.Tag("ignore fall");
	
	this.set_bool("lantern lit", true); //isLight() causes problems

	this.getCurrentScript().runFlags |= Script::tick_inwater;
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	this.getSprite().SetAnimation(this.get_bool("lantern lit") ? "fire" : "nofire");
	this.inventoryIconFrame = this.get_bool("lantern lit") ? 0 : 3;
	return true;
}

void onTick(CBlob@ this)
{
	if (this.get_bool("lantern lit"))
	{
		Light(this, false);
	}
}

void Light(CBlob@ this, const bool &in lit)
{
	this.SetLight(lit);
	this.inventoryIconFrame = lit ? 0 : 3;

	this.getSprite().SetAnimation(lit ? "fire" : "nofire");
	this.getSprite().PlaySound("SparkleShort.ogg");
	
	this.set_bool("lantern lit", lit);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		if (this.isInWater()) return;

		Light(this, !this.get_bool("lantern lit"));
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.getShape().isStatic();
}
