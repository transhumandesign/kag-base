#include "ChatCommand.as"

const string toggle_id_string = " status toggle";
const string toggle_command = "toggle colored name command";
const string prefs_command = "request admin prefs";

bool isAdmin(CPlayer@ player)
{
    return getSecurity().checkAccess_Feature(player, "admin_color") || player.isRCON();
}

bool isSpecial(CPlayer@ player)
{
    return player.isDev() || player.isGuard() || isAdmin(player);
}

string getToggleID(CPlayer@ player)
{
    return player.getUsername() + toggle_id_string;
}

void InitColoredName(CRules@ rules, CPlayer@ player)
{
    if (isSpecial(player))
    {
        rules.set_bool(getToggleID(player), true);
    }
}

bool coloredNameEnabled(CRules@ rules, CPlayer@ player)
{
    if (rules.exists(getToggleID(player)))
    {
        // return enabled
        return rules.get_bool(getToggleID(player));
    }
    else
    {
        // not a special user??
        return true;
    }
}

void sendNameColorCommand(CRules@ rules, CPlayer@ player, bool nameColorOn)
{
	string toggleID = getToggleID(player);

	rules.set_bool(toggleID, nameColorOn);

	CBitStream params;
	params.write_string(toggleID);
	params.write_bool(nameColorOn);
	rules.SendCommand(rules.getCommandID(toggle_command), params);

}

class ToggleNameColorCommand : ChatCommand
{
	ToggleNameColorCommand()
	{
		super("toggle color", "Toggle your name color on the scoreboard");
		AddAlias("toggle colour");
		AddAlias("toggle name");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CRules@ rules = getRules();

        string toggleID = getToggleID(player);
        if (!rules.exists(toggleID)) return;

		bool visible = !rules.get_bool(toggleID);
		sendNameColorCommand(rules, player, visible);

		server_AddToChat(getTranslatedString("Your name color is now " + (visible ? "visible" : "invisible")), ConsoleColour::INFO, player);
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return (
			ChatCommand::canPlayerExecute(player) &&
			isSpecial(player)
		);
	}
}
