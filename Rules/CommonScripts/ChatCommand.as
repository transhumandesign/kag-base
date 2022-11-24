#include "ChatCommandCommon.as"
#include "ChatCommandManager.as"

class ChatCommand
{
	string[] aliases;
	string description;
	bool enabled = false;
	bool modOnly = false;
	bool debugOnly = false;
	string usage = "";

	ChatCommand(string name, string description)
	{
		aliases.push_back(name.toLower());
		this.description = description;
	}

	void AddAlias(string name)
	{
		aliases.push_back(name);
	}

	void SetUsage(string usage)
	{
		this.usage = usage;
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return (
			(!modOnly || player.isMod()) &&
			(!debugOnly || sv_test)
		);
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CommandNotImplemented(aliases[0], player);
	}
}

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

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		CommandNotImplemented(aliases[0], player);
	}
}
