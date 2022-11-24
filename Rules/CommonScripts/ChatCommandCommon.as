namespace ChatCommands
{
	ChatCommandManager@ getManager()
	{
		ChatCommandManager@ manager;
		if (!getRules().get("chat command manager", @manager))
		{
			@manager = ChatCommandManager();
			getRules().set("chat command manager", @manager);
		}
		return manager;
	}

	void RegisterCommand(ChatCommand@ command)
	{
		ChatCommands::getManager().RegisterCommand(command);
	}
}

string removeExcessSpaces(string text)
{
	// Reduce all spaces down to one space
	while (text.find("  ") != -1)
	{
		text = text.replace("  ", " ");
	}

	// Remove space at start
	if (text.substr(0, 1) == " ")
	{
		text = text.substr(1);
	}

	// Remove space at end
	uint lastIndex = text.size() - 1;
	if (text.substr(lastIndex, 1) == " ")
	{
		text = text.substr(0, lastIndex);
	}

	return text;
}

bool isBlobBlacklisted(string name)
{
	return ChatCommands::getManager().blacklistedBlobs.find(name) != -1;
}

bool isClassWhitelisted(string name)
{
	return ChatCommands::getManager().whitelistedClasses.find(name) != -1;
}

void server_AddToChat(string message, SColor color, CPlayer@ player = null)
{
	if (player !is null && player.isMyPlayer())
	{
		client_AddToChat(message, color);
	}
	else
	{
		CBitStream bs;
		bs.write_string(message);
		bs.write_u8(color.getBlue());
		bs.write_u8(color.getGreen());
		bs.write_u8(color.getRed());
		bs.write_u8(color.getAlpha());

		if (player !is null)
		{
			getRules().SendCommand(getRules().getCommandID("SendChatMessage"), bs, player);
		}
		else
		{
			getRules().SendCommand(getRules().getCommandID("SendChatMessage"), bs, true);
		}
	}
}

void CommandNotImplemented(string name, CPlayer@ player)
{
	if (isClient())
	{
		client_AddToChat(getTranslatedString("Unable to execute command"), ConsoleColour::ERROR);
	}
	else
	{
		print("Unable to execute !" + name + " command because it is not implemented", ConsoleColour::ERROR);
	}
}
