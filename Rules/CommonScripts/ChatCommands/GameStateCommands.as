#include "ChatCommand.as"

class StartCommand : ChatCommand
{
	StartCommand()
	{
		super("startgame", "Start the game");
		AddAlias("start");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		if (!getRules().isMatchRunning())
		{
			getRules().SetCurrentState(GAME);
			server_AddToChat("Game started by an admin", ConsoleColour::GAME);
		}
		else
		{
			server_AddToChat("Game is already in progress", ConsoleColour::ERROR, player);
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

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		if (!getRules().isGameOver())
		{
			getRules().SetCurrentState(GAME_OVER);
			server_AddToChat("Game ended by an admin", ConsoleColour::GAME);
		}
		else
		{
			server_AddToChat("Game has already ended", ConsoleColour::ERROR, player);
		}
	}
}
