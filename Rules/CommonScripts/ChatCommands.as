#include "ChatCommandManager.as"
#include "DefaultChatCommands.as"

ChatCommandManager@ manager;

void onInit(CRules@ this)
{
	this.addCommandID("SendChatMessage");
	onReload(this);
}

void onReload(CRules@ this)
{
	@manager = ChatCommands::getManager();
	RegisterDefaultChatCommands(manager);
	manager.ProcessConfigCommands();
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	textOut = removeExcessSpaces(textIn);
	if (textOut == "") return false;

	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textOut, command, args))
	{
		if (!command.canPlayerExecute(player))
		{
			server_AddToChat(getTranslatedString("You are unable to use this command"), ConsoleColour::ERROR, player);
			return false;
		}

		command.Execute(args, player);
	}
	else if (command !is null)
	{
		server_AddToChat(getTranslatedString("'{COMMAND}' is not a valid command").replace("{COMMAND}", textOut), ConsoleColour::ERROR, player);
		return false;
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in textIn, string& out textOut, CPlayer@ player)
{
	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textIn, command, args))
	{
		//don't run command a second time on localhost
		if (!isServer())
		{
			//assume command can be executed if server forwards it to clients
			command.Execute(args, player);
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
