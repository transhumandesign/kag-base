#include "ChatCommandManager.as"
#include "DefaultChatCommands.as"

ChatCommandManager@ manager;

void onInit(CRules@ this)
{
	this.addCommandID("SendChatMessage");
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
		Menu::addInfoBox(contextMenu, "!" + command.aliases[0] + " " + command.usage, getTranslatedString(command.description));
	}
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	textOut = removeExcessSpaces(textIn);
	if (textOut == "") return false;

	ChatCommand@ command;
	string name;
	string[] args;
	if (manager.processCommand(textOut, command, name, args) && command.canPlayerExecute(player))
	{
		command.Execute(name, args, player);
	}
	return true;
}

bool onClientProcessChat(CRules@ this, const string& in textIn, string& out textOut, CPlayer@ player)
{
	ChatCommand@ command;
	string name;
	string[] args;
	if (manager.processCommand(textIn, command, name, args))
	{
		if (command.canPlayerExecute(player))
		{
			if (!isServer())
			{
				command.Execute(name, args, player);
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

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("SendChatMessage") && isClient())
	{
		string message;
		if (!params.saferead_string(message)) return;

		u8 r, g, b, a;
		if (!params.saferead_u8(b)) return;
		if (!params.saferead_u8(g)) return;
		if (!params.saferead_u8(r)) return;
		if (!params.saferead_u8(a)) return;
		SColor color(a, r, g, b);

		client_AddToChat(message, color);
	}
}
