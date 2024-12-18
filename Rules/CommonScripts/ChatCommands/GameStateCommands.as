#include "ChatCommand.as"

class StartCommand : ChatCommand
{
	StartCommand()
	{
		super("startgame", "Start the game");
		AddAlias("start");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		if (!getRules().isMatchRunning())
		{
			getRules().SetCurrentState(GAME);
			server_AddToChat(getTranslatedString("Game started by an admin"), ConsoleColour::GAME);
		}
		else
		{
			server_AddToChat(getTranslatedString("Game is already in progress"), ConsoleColour::ERROR, player);
		}
	}
}

class EndCommand : ChatCommand
{
	EndCommand()
	{
		super("endgame", "End the game");
		AddAlias("end");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		if (!getRules().isGameOver())
		{
			getRules().SetCurrentState(GAME_OVER);
			server_AddToChat(getTranslatedString("Game ended by an admin"), ConsoleColour::GAME);
		}
		else
		{
			server_AddToChat(getTranslatedString("Game has already ended"), ConsoleColour::ERROR, player);
		}
	}
}

class NextMapCommand : ChatCommand
{
	NextMapCommand()
	{
		super("nextmap", "Load the next map");
		AddAlias("next");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			LoadNextMap();
		}
	}
}

class RestartMapCommand : ChatCommand
{
	RestartMapCommand()
	{
		super("restartmap", "Restart the current map");
		AddAlias("restart");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			LoadMap(getMap().getMapName());
		}
	}
}
