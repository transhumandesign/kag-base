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

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	textOut = removeExcessSpaces(textIn);
	if (textOut == "") return false;

	ChatCommand@ command;
	string name;
	string[] args;
	if (manager.processCommand(textOut, command, name, args))
	{
		if (!command.canPlayerExecute(player))
		{
			server_AddToChat("You are unable to use this command", ConsoleColour::ERROR, player);
			return false;
		}

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
		//don't run command a second time on localhost
		if (!isServer())
		{
			//assume command can be executed if server forwards it to clients
			command.Execute(name, args, player);
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
