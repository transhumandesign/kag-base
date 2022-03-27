#include "ChatCommand.as"

class EndCommand : ChatCommand
{
	EndCommand()
	{
		super("end", "End the game.");
		AddAlias("endgame");
		SetModOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			getRules().SetCurrentState(GAME_OVER);
		}

		if (isClient())
		{
			client_AddToChat("Game ended by a moderator", ConsoleColour::GAME);
		}
	}
}
