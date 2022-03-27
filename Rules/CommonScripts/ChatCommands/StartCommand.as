#include "ChatCommand.as"

class StartCommand : ChatCommand
{
	StartCommand()
	{
		super("start", "Start the game.");
		AddAlias("startgame");
		SetModOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			getRules().SetCurrentState(GAME);
		}

		if (isClient())
		{
			client_AddToChat("Game started by a moderator", ConsoleColour::GAME);
		}
	}
}
