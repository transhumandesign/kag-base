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

	this.addCommandID("activate client");
	
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
	if (cmd == this.getCommandID("activate") && isServer())
	{		
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		/*
		Lanterns can be activated by:
		ActivateHeldObject.as - "activate/throw" command ActivateBlob, SERVERSIDE
		There is no instance of lanterns being activated with a direct client->server command
		*/
		bool from_server = (callerp is null);
		if (!from_server)
		{
			return;
		}

		if (this.isInWater()) return;

		// localhost xd
		if (!isClient())
			Light(this, !this.get_bool("lantern lit"));

		this.SendCommand(this.getCommandID("activate client"));
	}
	else if (cmd == this.getCommandID("activate client") && isClient())
	{
		Light(this, !this.get_bool("lantern lit"));
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.getShape().isStatic();
}
