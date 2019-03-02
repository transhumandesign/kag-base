const string toggle_id_string = " status toggle";
const string toggle_command = "toggle colored name command";
const string prefs_command = "request admin prefs";
const array<string> toggle_strings = { "!toggle color", "!toggle colour", "!toggle name" };

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
        rules.set_bool(getToggleID(player), false);
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
