#include "ChatCommand.as"

class HelpCommand : ChatCommand
{
	HelpCommand()
	{
		super("help", "List available commands");
		AddAlias("commands");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isClient()) return;

		ChatCommandManager@ manager = ChatCommands::getManager();
		ChatCommand@[] commands = manager.getExecutableCommands(player);

		for (uint i = 0; i < commands.size(); i++)
		{
			PrintCommand(commands[i]);
		}

		if (manager.fallbackCommand.canPlayerExecute(player))
		{
			PrintCommand(manager.fallbackCommand);
		}
	}

	private void PrintCommand(ChatCommand@ command)
	{
		string[] names;
		for (uint j = 0; j < command.aliases.size(); j++)
		{
			string alias = command.aliases[j];
			string cmdName = "!" + alias;
			if (command.usage != "")
			{
				cmdName += " " + command.usage;
			}
			names.push_back(cmdName);
		}

		client_AddToChat(join(names, ", "), ConsoleColour::CRAZY);
		client_AddToChat("   ↳ " + getTranslatedString(command.description), ConsoleColour::INFO);
	}
}
