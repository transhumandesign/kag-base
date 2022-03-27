#include "ChatCommandManager.as"

ChatCommandManager@ manager;

void onInit(CRules@ this)
{
	@manager = ChatCommands::getManager();
}

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	ChatCommand@[] commands = manager.getCommands();
	if (commands.size() > 0)
	{
		CContextMenu@ contextMenu = Menu::addContextMenu(menu, getTranslatedString("Chat Commands"));
		CPlayer@ player = getLocalPlayer();

		for (uint i = 0; i < commands.size(); i++)
		{
			ChatCommand@ command = commands[i];
			if (command.canPlayerExecute(player))
			{
				Menu::addInfoBox(contextMenu, getTranslatedString("!" + command.aliases[0]), getTranslatedString(command.description));
			}
		}
	}
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textIn, command, args) && command.canPlayerExecute(player))
	{
		command.Execute(args, player);
	}
	return true;
}

bool onClientProcessChat(CRules@ this, const string& in textIn, string& out textOut, CPlayer@ player)
{
	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textIn, command, args))
	{
		if (command.canPlayerExecute(player))
		{
			command.Execute(args, player);
		}
		else if (player.isMyPlayer())
		{
			client_AddToChat("You are unable to use this command", ConsoleColour::ERROR);
		}
		return false;
	}
	return true;
}
