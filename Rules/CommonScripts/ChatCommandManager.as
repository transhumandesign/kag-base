#include "ChatCommandCommon.as"
#include "ChatCommand.as"
#include "FallbackCommand.as"

class ChatCommandManager
{
	private string configName = "ChatCommands.cfg";
	private ChatCommand@[] allCommands;
	private string[] enabledCommandNames;
	ChatCommand@ fallbackCommand = FallbackCommand();

	ChatCommandManager()
	{
		if (isServer())
		{
			ConfigFile cfg = getConfig();
			cfg.readIntoArray_string(enabledCommandNames, "commands");

			if (enabledCommandNames.size() > 0)
			{
				for (uint i = 0; i < enabledCommandNames.size(); i++)
				{
					enabledCommandNames[i] = enabledCommandNames[i].toLower();
				}

				print("Chat commands: !" + join(enabledCommandNames, ", !"));
			}
		}
	}

	private ConfigFile getConfig()
	{
		ConfigFile cfg;
		cfg.loadFile("../Cache/" + configName) || cfg.loadFile(configName);
		return cfg;
	}

	void RegisterCommand(ChatCommand@ command)
	{
		allCommands.push_back(command);
	}

	ChatCommand@[] getAllCommands()
	{
		return allCommands;
	}

	ChatCommand@[] getEnabledCommands()
	{
		ChatCommand@[] enabledCommands;
		for (uint i = 0; i < allCommands.size(); i++)
		{
			ChatCommand@ command = allCommands[i];
			if (isCommandEnabled(command))
			{
				enabledCommands.push_back(command);
			}
		}
		return enabledCommands;
	}

	bool isCommandEnabled(ChatCommand@ command)
	{
		return enabledCommandNames.find(command.aliases[0]) != -1;
	}

	ChatCommand@[] getExecutableCommands(CPlayer@ player)
	{
		ChatCommand@[] executableCommands;
		ChatCommand@[] commands = getEnabledCommands();
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
		if (text.find("!") != 0) return false;

		args = text.split(" ");
		name = args[0].substr(1);

		if (name == "") return false;

		args.removeAt(0);

		ChatCommand@[] commands = isServer() ? getEnabledCommands() : getAllCommands();
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
}
