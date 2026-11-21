//Wheeled vehicle deactivate script

#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("pop_wheels");
	this.addCommandID("pop_wheels_client");
	if (this.hasTag("immobile"))
	{
		PopWheels(this, false);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	
	if (this.isAttached() || caller.isAttached()) return;

	if (this.getAttachments().getAttachmentPointByName("DRIVER").getOccupied() !is null) return;

	if (this.getTeamNum() == caller.getTeamNum() && this.getDistanceTo(caller) < this.getRadius() && !this.hasTag("immobile"))
	{
		caller.CreateGenericButton(2, Vec2f(0.0f, 8.0f), this, this.getCommandID("pop_wheels"), getTranslatedString("Immobilise"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pop_wheels") && isServer())
	{
		if (!this.hasTag("immobile"))
		{
			if (isServer())
			{
				CPlayer@ caller = getNet().getActiveCommandPlayer();
				if (caller is null) return;

				CBlob@ blob = caller.getBlob();
				if (blob is null) return;

				if (this.getDistanceTo(blob) > (this.getRadius() * 2)) return;

				if (this.getTeamNum() != blob.getTeamNum()) return;
			}

			CBlob@ chauffeur = this.getAttachments().getAttachmentPointByName("DRIVER").getOccupied();
			if (chauffeur !is null) return;

			this.Tag("immobile");
			PopWheels(this, true);

			this.SendCommand(this.getCommandID("pop_wheels_client"));
		}
	}
	else if (cmd == this.getCommandID("pop_wheels_client") && isClient())
	{
		this.Tag("immobile");
		PopWheels(this, true);
	}
}

void PopWheels(CBlob@ this, bool addparticles = true)
{
	this.getShape().setFriction(0.75f);   //grippy now

	if (!isClient()) //don't bother w/o graphics
		return;

	CSprite@ sprite = this.getSprite();

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	//remove wheels
	for (int i = 0; i < sprite.getSpriteLayerCount(); ++i)
	{
		CSpriteLayer@ wheel = sprite.getSpriteLayer(i);
		if (wheel !is null && wheel.name.substr(0, 2) == "!w")
		{
			if (addparticles)
			{
				//todo: wood falling sounds...
				makeGibParticle("Entities/Vehicles/Common/WoodenWheels.png", pos + wheel.getOffset(), vel + getRandomVelocity(90, 5, 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/material_drop", 0);
			}

			sprite.RemoveSpriteLayer(wheel.name);
			i--;
		}
	}

	//add chocks
	CSpriteLayer@ chocks = sprite.addSpriteLayer("!chocks", "Entities/Vehicles/Common/WoodenChocks.png", 32, 16);
	if (chocks !is null)
	{
		Animation@ anim = chocks.addAnimation("default", 0, false);
		anim.AddFrame(0);
		chocks.SetOffset(Vec2f(0, this.getHeight() * 0.5f - 2.5f));
	}
}
