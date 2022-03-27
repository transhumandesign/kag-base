#include "ChatCommandCommon.as"
#include "ChatCommand.as"
#include "FallbackCommand.as"

class ChatCommandManager
{
	private ChatCommand@[] commands;
	private ChatCommand@ fallbackCommand;

	ChatCommandManager()
	{
		@fallbackCommand = FallbackCommand();
	}

	void RegisterCommand(ChatCommand@ command)
	{
		commands.push_back(command);
	}

	ChatCommand@[] getCommands()
	{
		return commands;
	}

	ChatCommand@[] getExecutableCommands(CPlayer@ player)
	{
		ChatCommand@[] executableCommands;
		for (uint i = 0; i < commands.size(); i++)
		{
			ChatCommand@ command = commands[i];
			if (command.canPlayerExecute(player))
			{
				executableCommands.push_back(command);
			}
		}
		return executableCommands;
	}

	bool processCommand(string text, ChatCommand@ &out command, string &out name, string[] &out args)
	{
		if (text.find("!") == 0)
		{
			args = text.split(" ");
			name = args[0].substr(1);

			if (name == "")
			{
				return false;
			}

			args.removeAt(0);

			for (uint i = 0; i < commands.size(); i++)
			{
				@command = commands[i];
				if (command.aliases.find(name.toLower()) != -1)
				{
					return true;
				}
			}

			@command = fallbackCommand;
			return true;
		}

		return false;
	}
}
