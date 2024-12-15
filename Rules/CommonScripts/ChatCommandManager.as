#include "ChatCommandCommon.as"
#include "ChatCommand.as"

class ChatCommandManager
{
	private string configName = "ChatCommands.cfg";
	private ChatCommand@[] allCommands;
	private string[] configCommands;
	string[] blacklistedBlobs;
	string[] whitelistedClasses;

	ChatCommandManager()
	{
		if (isServer())
		{
			ConfigFile cfg;
			cfg.loadFile("../Cache/" + configName) || cfg.loadFile(configName);

			cfg.readIntoArray_string(configCommands, "commands");
			cfg.readIntoArray_string(blacklistedBlobs, "blacklisted_blobs");
			cfg.readIntoArray_string(whitelistedClasses, "whitelisted_classes");
		}
	}

	void ProcessConfigCommands()
	{
		if (!isServer()) return;

		if (configCommands.size() % 3 != 0)
		{
			warn("Chat commands config is malformed");
			return;
		}

		string[] commandNames;
		ChatCommand@[] sortedCommands;

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
					sortedCommands.push_back(command);
					break;
				}
			}
		}

		//allCommands no longer contains all commands on server
		allCommands = sortedCommands;

		if (commandNames.size() > 0)
		{
			string prefix = ChatCommands::getPrefixes()[0];
			print("Loaded chat commands: " + prefix + join(commandNames, ", " + prefix), ConsoleColour::CRAZY);
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

	bool processCommand(string text, ChatCommand@ &out command, string[] &out args)
	{
		// Match against known command prefixes
		string prefixMatch;
		const string[] prefixes = ChatCommands::getPrefixes();
		for (uint i = 0; i < prefixes.size(); ++i)
		{
			if (text.substr(0, prefixes[i].size()) == prefixes[i])
			{
				prefixMatch = prefixes[i];
				break;
			}
		}

		if (prefixMatch == "") { return false; }

		string textNoPrefix = text.substr(1);

		string firstLetter = textNoPrefix.substr(1, 1);
		if (firstLetter == "" || firstLetter == " ") { return false; }

		ChatCommand@[] commands = isServer() ? getEnabledCommands() : allCommands;
		for (uint i = 0; i < commands.size(); i++)
		{
			@command = commands[i];

			for (uint j = 0; j < command.aliases.size(); j++)
			{
				string alias = command.aliases[j];
				string aliasCandidate = textNoPrefix.substr(0, alias.size() + 1).toLower();
				if (aliasCandidate == alias || aliasCandidate == alias + " ")
				{
					args = aliasCandidate == alias ? array<string>() : text.substr(alias.size() + 2).split(" ");
					return true;
				}
			}
		}

		return processCommand("/spawn " + text.substr(1), command, args);  // Default to spawn command
	}
}
