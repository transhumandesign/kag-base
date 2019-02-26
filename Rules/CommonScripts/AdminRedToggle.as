#include "AdminRedToggleCommon.as"

void onInit(CRules@ this)
{
    this.addCommandID("toggle red name command");
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    InitRedName(this, player);
    CBitStream params;
    params.write_string(getToggleID(player));
    params.write_bool(this.get_bool(getToggleID(player)));
    this.SendCommand(this.getCommandID("toggle red name command"), params);
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
    if (textIn == toggle_string && isAdmin(player))
    {
        string toggleID = getToggleID(player);
        if (this.exists(toggleID))
        {
            bool visible = !this.get_bool(toggleID);
            this.set_bool(toggleID, visible);
            CBitStream params;
            params.write_string(toggleID);
            params.write_bool(visible);
            this.SendCommand(this.getCommandID("toggle red name command"), params);
            return false;
        }
    }
    return true;
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("toggle red name command"))
    {
        string toggleID = params.read_string();
        bool visible = params.read_bool();
        this.set_bool(toggleID, visible);
    }
}