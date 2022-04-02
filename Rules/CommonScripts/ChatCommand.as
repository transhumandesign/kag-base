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

	void Execute(string name, string[] args, CPlayer@ player) {}
}
