#include "ChatCommandCommon.as"
#include "ChatCommand.as"
#include "DefaultChatCommands.as"

class ChatCommandManager
{
	private string configName = "ChatCommands.cfg";
	private ChatCommand@[] allCommands;
	string[] blacklistedBlobs;

	ChatCommandManager()
	{
		RegisterDefaultChatCommands(this);
		LoadConfig();
	}

	private ConfigFile getConfig()
	{
		ConfigFile cfg;
		cfg.loadFile("../Cache/" + configName) || cfg.loadFile(configName);
		return cfg;
	}

	private void LoadConfig()
	{
		if (!isServer()) return;

		ConfigFile cfg = getConfig();

		string[] configCommands;
		cfg.readIntoArray_string(configCommands, "commands");
		cfg.readIntoArray_string(blacklistedBlobs, "blacklisted_blobs");

		if (configCommands.size() % 3 != 0)
		{
			warn("Chat commands config is malformed");
			return;
		}

		if (configCommands.empty()) return;

		string[] commandNames;

		for (uint i = 0; i < configCommands.size(); i += 3)
		{
			string name = configCommands[i].toLower();
			bool modOnly = configCommands[i + 1] == "1";
			bool debugOnly = configCommands[i + 2] == "1";

			for (uint j = 0; j < allCommands.size(); j++)
			{
				ChatCommand@ command = allCommands[j];
				if (command.aliases[0] == name)
				{
					command.enabled = true;
					command.modOnly = modOnly;
					command.debugOnly = debugOnly;
					commandNames.push_back(name);
					break;
				}
			}
		}

		if (commandNames.size() > 0)
		{
			print("Loaded chat commands: !" + join(commandNames, ", !"), ConsoleColour::CRAZY);
		}
		else
		{
			print("No chat commands loaded", ConsoleColour::CRAZY);
		}
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
			if (command.enabled)
			{
				enabledCommands.push_back(command);
			}
		}
		return enabledCommands;
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

		return false;
	}
}
