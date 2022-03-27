#include "ChatCommand.as"

class EndCommand : ChatCommand
{
	EndCommand()
	{
		super("end", "End the game");
		AddAlias("endgame");
		SetModOnly();
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
