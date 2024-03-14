#include "ChatCommand.as"

class HelpCommand : ChatCommand
{
	HelpCommand()
	{
		super("help", "List available commands");
		AddAlias("commands");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		ChatCommandManager@ manager = ChatCommands::getManager();
		ChatCommand@[]@ commands = manager.getExecutableCommands(player);

		for (uint i = 0; i < commands.size(); i++)
		{
			ChatCommand@ command = commands[i];

			string[] names;
			for (uint i = 0; i < command.aliases.size(); i++)
			{
				string alias = command.aliases[i];
				string cmdName = ChatCommands::getPrefix() + alias;
				if (command.usage != "")
				{
					cmdName += " " + command.usage;
				}
				names.push_back(cmdName);
			}

			server_AddToChat(join(names, ", "), ConsoleColour::CRAZY, player);
			server_AddToChat("   ↳ " + getTranslatedString(command.description), ConsoleColour::INFO, player);
		}

		server_AddToChat(getTranslatedString("Tip: Press Shift ↑/↓ keys while chat is focused to navigate through chat history"), ConsoleColour::GAME, player);
	}
}

class BotCommand : ChatCommand
{
	BotCommand()
	{
		super("bot", "Spawn a bot");
		SetUsage("[name]");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			string name = args.size() > 0 ? args[0] : "Henry";
			AddBot(name);
		}
	}
}

class WaterCommand : ChatCommand
{
	WaterCommand()
	{
		super("water", "Create a water source");
		AddAlias("spawnwater");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			getMap().server_setFloodWaterWorldspace(pos, true);
		}
		else
		{
			server_AddToChat(getTranslatedString("Water cannot be created while dead or spectating"), ConsoleColour::ERROR, player);
		}
	}
}

class TipCommand : ChatCommand
{
	string[] tips;

	TipCommand()
	{
		super("tip", "Show a useful tip to help you improve");
		AddAlias("tips");
		SetUsage("[tip #]");

		ConfigFile cfg;
		if (cfg.loadFile("HelpfulDeathTips.cfg"))
		{
			cfg.readIntoArray_string(tips, "tips");
		}
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return ChatCommand::canPlayerExecute(player) && !tips.empty();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!player.isMyPlayer()) return;

		int index = args.size() == 0
			? XORRandom(tips.size())
			: parseInt(args[0]) - 1;

		if (index < 0 || index >= tips.size())
		{
			client_AddToChat(getTranslatedString("Specify a tip number between 1 and " + tips.size()), ConsoleColour::ERROR);
			return;
		}

		string text = getTranslatedString("Tip #{NUMBER}: {TIP}")
			.replace("{NUMBER}", "" + (index + 1))
			.replace("{TIP}", getTranslatedString(tips[index]));

		client_AddToChat(text, ConsoleColour::INFO);
	}
}
