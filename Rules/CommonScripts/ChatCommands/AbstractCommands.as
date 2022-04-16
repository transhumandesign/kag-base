#include "ChatCommand.as"

class BlobCommand : ChatCommand
{
	BlobCommand(string name, string description)
	{
		super(name, description);
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			SpawnBlobAt(blob.getPosition(), args, player);
		}
		else
		{
			server_AddToChat(getTranslatedString("Blobs cannot be spawned while dead or spectating"), ConsoleColour::ERROR, player);
		}
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player) {}
}
