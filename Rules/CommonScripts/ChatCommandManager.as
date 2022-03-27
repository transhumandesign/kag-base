#include "ChatCommandCommon.as"
#include "ChatCommand.as"

class ChatCommandManager
{
	private ChatCommand@[] commands;

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

	bool processCommand(string text, ChatCommand@ &out command, string[] &out args)
	{
		text = removeExcessSpaces(text);

		if (text.find("!") == 0)
		{
			args = text.split(" ");
			string cmd = args[0].toLower().substr(1);

			args.removeAt(0);

			for (uint i = 0; i < commands.size(); i++)
			{
				@command = commands[i];
				if (command.aliases.find(cmd) != -1)
				{
					return true;
				}
			}
		}

		return false;
	}

	private string removeExcessSpaces(string text)
	{
		// Reduce all spaces down to one space
		while (text.find("  ") != -1)
		{
			text = text.replace("  ", " ");
		}

		// Remove space at start
		if (text.find(" ") == 0)
		{
			text = text.substr(1);
		}

		// Remove space at end
		uint lastIndex = text.size() - 1;
		if (text.findLast(" ") == lastIndex)
		{
			text = text.substr(0, lastIndex);
		}

		return text;
	}
}
