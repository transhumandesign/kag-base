// requires VEHICLE attachment point

#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("detach vehicle");
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_hasattached;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || caller.getTeamNum() != this.getTeamNum())
		return;

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			if (ap.socket && ap.name == "VEHICLE")
			{
				CBlob@ occBlob = ap.getOccupied();
				if (occBlob !is null) //detach button
				{
					if (this.isOnGround() || occBlob.getName() == "mounted_bow")	  // HACK:
					{
						Vec2f button_offset = ap.offset/2;
						button_offset.RotateByDegrees(occBlob.getAngleDegrees());
						string text = getTranslatedString("Detach {ITEM}").replace("{ITEM}", getTranslatedString(occBlob.getInventoryName()));
						caller.CreateGenericButton(1, button_offset, this, this.getCommandID("detach vehicle"), text);
					}
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("detach vehicle") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ b = p.getBlob();
		if (b is null) return;

		AttachmentPoint@[] aps;
		if (this.getAttachmentPoints(@aps))
		{
			for (uint i = 0; i < aps.length; i++)
			{
				AttachmentPoint@ ap = aps[i];
				if (ap.socket && ap.name == "VEHICLE")
				{
					CBlob@ occBlob = ap.getOccupied();
					if (occBlob !is null) //detach button
					{
						// range check
						if (this.getDistanceTo(b) > 64.0f) return;

						if (this.isOnGround() || occBlob.getName() == "mounted_bow")
						{
							occBlob.server_DetachFrom(this);
						}
					}
				}
			}
		}
	}
}
