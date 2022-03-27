namespace ChatCommands
{
	string[] blacklistedBlobs = {
		"hall",         // grief
		"shark",        // grief spam
		"bison",        // grief spam
		"necromancer",  // annoying/grief
		"greg",         // annoying/grief
		"ctf_flag",     // sound spam
		"flag_base"     // sound spam + bedrock grief
	};

	ChatCommandManager@ getManager()
	{
		ChatCommandManager@ manager;
		if (!getRules().get("chat command manager", @manager))
		{
			@manager = ChatCommandManager();
			getRules().set("chat command manager", @manager);
		}
		return manager;
	}

	void RegisterCommand(ChatCommand@ command)
	{
		ChatCommands::getManager().RegisterCommand(command);
	}

	bool isBlobBlacklisted(string name)
	{
		return blacklistedBlobs.find(name) != -1;
	}
}
