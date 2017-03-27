
void onTick(CBlob@ this)
{
	CPlayer@ player = this.getPlayer();
	if (player !is null)
	{
		this.setInventoryName(player.getCharacterName());
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}
