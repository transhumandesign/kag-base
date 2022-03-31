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
			AddCommandToChat(commands[i]);
		}

		if (manager.fallbackCommand.canPlayerExecute(player))
		{
			AddCommandToChat(manager.fallbackCommand);
		}
	}

	private void AddCommandToChat(ChatCommand@ command)
	{
		string[] names;
		for (uint i = 0; i < command.aliases.size(); i++)
		{
			string alias = command.aliases[i];
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
