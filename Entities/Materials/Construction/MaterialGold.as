
void onInit(CBlob@ this)
{
  if (isServer())
  {
	this.set_u8("decay step", 10);
  }

  if (getRules().gamemode_name == "Sandbox")
  {
  	this.Tag("AdminAlertIgnore");
  }
  
  this.maxQuantity = 50;

  this.getCurrentScript().runFlags |= Script::remove_after_this;

  AddIconToken("$Gold_Indicator$", "Materials.png", Vec2f(16, 16), 10);
}

void onRender(CSprite@ this)
{
	// show gold in friendly inventories
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isOnScreen() || !blob.isInInventory()) return;

	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;

	CBlob@ invBlob = blob.getInventoryBlob();
	if (invBlob is null 
		|| localBlob.getTeamNum() != invBlob.getTeamNum() 
		|| localBlob is invBlob
		|| invBlob.getName() == "storage")
	{
		return;
	}
	
	// check if it's actually a player teammate, not just a spawned in blob
	CPlayer@ invPlayer = invBlob.getPlayer();
	if (invBlob.hasTag("player") && invBlob.getPlayer() is null)
	{
		return;
	}

	Vec2f pos2d = blob.getScreenPos();

	if (!getHUD().hasButtons())
	{
		string goldCount = invBlob.getBlobCount("mat_gold");

		u16 offset_x = 0;
		
		if (invBlob.hasTag("player"))
		{
			offset_x = invBlob.getInitialHealth() * 2 * 12;
		}
		
		Vec2f tl(pos2d.x - 6 + offset_x, pos2d.y + 4);
		Vec2f textPos(pos2d.x + 18 + offset_x, pos2d.y + 8);
	
		GUI::DrawText("$Gold_Indicator$", tl, tl, color_white, true, true, false);
		GUI::DrawText(goldCount, textPos, textPos, color_white, true, true, false);
	}
}
