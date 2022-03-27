#include "ChatCommand.as"
#include "MakeScroll.as"

class ScrollCommand : ChatCommand
{
	ScrollCommand()
	{
		super("scroll", "Spawn a scroll by name.");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (blob is null)
		{
			if (player.isMyPlayer())
			{
				client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
			}
			return;
		}

		if (args.size() == 0)
		{
			if (player.isMyPlayer())
			{
				client_AddToChat("Specify the name of a scroll to spawn", ConsoleColour::ERROR);
			}
			return;
		}

		if (isServer())
		{
			Vec2f pos = blob.getPosition();
			string name = join(args, " ");
			server_MakePredefinedScroll(pos, name);
		}
	}
}
