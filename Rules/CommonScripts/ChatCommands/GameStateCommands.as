#include "ChatCommand.as"

class StartCommand : ChatCommand
{
	StartCommand()
	{
		super("start", "Start the game");
		AddAlias("startgame");
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
		super("end", "End the game");
		AddAlias("endgame");
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
