#include "ChatCommandCommon.as"
#include "ChatCommandManager.as"

class ChatCommand
{
	string[] aliases;
	string description;
	bool modOnly = false;
	bool debugOnly = false;
	bool defaultCommand = false;

	ChatCommand(string name, string description)
	{
		aliases.push_back(name.toLower());
		this.description = description;
	}

	void AddAlias(string name)
	{
		aliases.push_back(name);
	}

	void SetModOnly()
	{
		modOnly = true;
	}

	void SetDebugOnly()
	{
		debugOnly = true;
	}

	void SetDefaultCommand()
	{
		defaultCommand = true;
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return (
			(!modOnly || player.isMod()) &&
			(!debugOnly || getRules().get_bool("sv_test"))
		);
	}

	void Execute(string name, string[] args, CPlayer@ player) {}
}
