#include "ChatCommand.as"

class StartCommand : ChatCommand
{
	StartCommand()
	{
		super("startgame", "Start the game");
		AddAlias("start");
		SetModOnly();
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
