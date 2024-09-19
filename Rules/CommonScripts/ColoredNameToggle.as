#include "ColoredNameToggleCommon.as"
#include "ChatCommandCommon.as"

bool ignoreInitial = false;

void onInit(CRules@ this)
{
    this.addCommandID(toggle_command);
    this.addCommandID(prefs_command);

    ChatCommands::RegisterCommand(ToggleNameColorCommand());

    if (isClient())
    {
        ignoreInitial = true;
    }
}

void loadAdminPreferences(CRules@ rules)
{
    if (isClient())
    {
        CPlayer@ player = getLocalPlayer();
        ConfigFile admin_prefs = ConfigFile();
        if (admin_prefs.loadFile("../Cache/admin_prefs.cfg"))
        {
            if (admin_prefs.exists("name_color"))
            {
                bool name_color = admin_prefs.read_bool("name_color");
                rules.set_bool(getToggleID(player), name_color);
                sendNameColorCommand(rules, player, name_color);

            }
        }

    }

}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    InitColoredName(this, player);

    sendNameColorCommand(this, player, this.get_bool(getToggleID(player)));

    if (isSpecial(player))
    {
        CBitStream params;
        params.write_string(player.getUsername());
        this.SendCommand(this.getCommandID(prefs_command), params);
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID(toggle_command) && isClient())
    {
        string toggleID = params.read_string();
        bool visible = params.read_bool();
        this.set_bool(toggleID, visible);

        if (ignoreInitial)
        {
            ignoreInitial = false;
            return;
        }

        if (toggleID == getToggleID(getLocalPlayer()))
        {
            ConfigFile admin_prefs = ConfigFile();
            admin_prefs.add_bool("name_color", visible);
            admin_prefs.saveFile("admin_prefs.cfg");
        }
    }
    else if (cmd == this.getCommandID(prefs_command) && isClient())
    {
        string username = params.read_string();
        if (getLocalPlayer() !is null && username == getLocalPlayer().getUsername())
        {
            loadAdminPreferences(this);
        }

    }
}
