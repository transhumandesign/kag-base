#include "ChatCommandCommon.as"
#include "ChatCommandManager.as"

class ChatCommand
{
	string[] aliases;
	string description;
	bool modOnly = false;

	ChatCommand(string name, string description, bool modOnly = false)
	{
		aliases.push_back(name);
		this.description = description;
		this.modOnly = modOnly;
	}

	void AddAlias(string name)
	{
		aliases.push_back(name);
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return !modOnly || player.isMod();
	}

	void Execute(string[] args, CPlayer@ player) {}
}
