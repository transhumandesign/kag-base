#include "ChatCommandManager.as"
#include "DefaultChatCommands.as"

ChatCommandManager@ manager;

void onInit(CRules@ this)
{
	getSecurity().reloadSecurity();
	@manager = ChatCommands::getManager();
	RegisterDefaultChatCommands(manager);
}

void onTick(CRules@ this)
{
	if (isServer())
	{
		this.set_bool("sv_test", sv_test);
		this.Sync("sv_test", true);
	}
}

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	ChatCommand@[] commands = manager.getExecutableCommands(player);
	if (commands.size() == 0) return;

	CContextMenu@ contextMenu = Menu::addContextMenu(menu, getTranslatedString("Chat Commands"));

	for (uint i = 0; i < commands.size(); i++)
	{
		ChatCommand@ command = commands[i];
		Menu::addInfoBox(contextMenu, getTranslatedString("!" + command.aliases[0]), getTranslatedString(command.description));
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
			if (!isServer())
			{
				command.Execute(args, player);
			}
		}
		else if (player.isMyPlayer())
		{
			client_AddToChat("You are unable to use this command", ConsoleColour::ERROR);
		}
		return false;
	}
	return true;
}
