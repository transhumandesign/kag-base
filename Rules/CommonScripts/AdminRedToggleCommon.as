const string toggle_id_string = " red name toggle";
const string toggle_string = "!toggle redname";

bool isAdmin(CPlayer@ player)
{
    return getSecurity().checkAccess_Feature(player, "admin_color") || player.isRCON();
}

string getToggleID(CPlayer@ player)
{
    return player.getUsername() + toggle_id_string;
}

void InitRedName(CRules@ rules, CPlayer@ player)
{
    if (isAdmin(player))
    {
        rules.set_bool(getToggleID(player), false);
    }
}

bool redNameEnabled(CRules@ rules, CPlayer@ player)
{
    if (rules.exists(getToggleID(player)))
    {
        // return enabled
        return rules.get_bool(getToggleID(player));
    }
    else
    {
        // not an admin??
        return true;
    }
}