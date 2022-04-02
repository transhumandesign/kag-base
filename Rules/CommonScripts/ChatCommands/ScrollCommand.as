#include "ChatCommand.as"
#include "MakeScroll.as"

class ScrollCommand : ChatCommand
{
	ScrollCommand()
	{
		super("scroll", "Spawn a scroll by name");
		SetUsage("<name>");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat("Specify the name of a scroll to spawn", ConsoleColour::ERROR, player);
			return;
		}

		Vec2f pos = blob.getPosition();
		string scrollName = join(args, " ");
		server_MakePredefinedScroll(pos, scrollName);
	}
}
