const SColor CHAT_COLOR = SColor(255, 255, 0, 0);

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	AttributeBlobToPlayer(this, attached.getPlayer());
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	AttributeBlobToPlayer(this, inventoryBlob.getPlayer());
}

void onDie(CBlob@ this)
{
	if (this.hasTag("AdminAlertIgnore") || this.getQuantity() == 0) return;

	string message;

	string username = this.get_string("last held by");
	CPlayer@ holder = getPlayerByUsername(username);
	if (holder !is null)
	{
		message = getTranslatedString("{PLAYER} caused {COUNT} {MATERIAL} to fall into the void!")
			.replace("{PLAYER}", formatPlayerName(holder))
			.replace("{COUNT}", "" + this.getQuantity())
			.replace("{MATERIAL}", getTranslatedString(this.getInventoryName()));
	}
	else
	{
		message = getTranslatedString("{COUNT} {MATERIAL} fell into the void!")
			.replace("{COUNT}", "" + this.getQuantity())
			.replace("{MATERIAL}", getTranslatedString(this.getInventoryName()));
	}

	if (isServer())
	{
		print(message, CHAT_COLOR);
	}

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer !is null && localPlayer.isMod())
	{
		client_AddToChat(message, CHAT_COLOR);
	}
}

void AttributeBlobToPlayer(CBlob@ blob, CPlayer@ player)
{
	if (player !is null)
	{
		blob.set_string("last held by", player.getUsername());
	}
}

string formatPlayerName(CPlayer@ player)
{
	string username = player.getUsername();
	string nickname = player.getCharacterName();
	return username == nickname ? username : nickname + " (" + username + ")";
}
