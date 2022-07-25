// Fishing line

#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("detach item");
	this.getSprite().SetVisible(false);
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("rod exists") && isServer())
		this.server_Die();
		
	this.getCurrentScript().tickFrequency = 60;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller))	return;
	
	CAttachment@ a = this.getAttachments();
	if (a !is null)
	{
		AttachmentPoint@ ap = a.getAttachmentPointByName("HOOK");
		if (ap !is null && ap.getOccupied() !is null)
		{
			CBitStream params;
			params.write_netid(ap.getOccupied().getNetworkID());
			CButton@ button = caller.CreateGenericButton(1, Vec2f(ap.offset.x-6, ap.offset.y-4), this, this.getCommandID("detach item"), getTranslatedString("Detach {ITEM}").replace("{ITEM}", ap.getOccupied().getInventoryName()), params);
			button.enableRadius = 32.0f;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer() && cmd == this.getCommandID("detach item"))
	{
		CBlob@ item = getBlobByNetworkID(params.read_netid());
		if (item !is null)
		{
			item.server_DetachFrom(this);
		}
	}
}