// Holiday.as

// =========================================
// | Month     | Date | Days | Start | End |
// =========================================
// | January   | 01   | 31   | 001   | 031 |
// | February  | 02   | 28+  | 032   | 059 |
// | March     | 03   | 31   | 060   | 090 |
// | April     | 04   | 30   | 091   | 120 |
// | May       | 05   | 31   | 121   | 151 |
// | Juny      | 06   | 30   | 152   | 181 |
// | July      | 07   | 31   | 182   | 212 |
// | August    | 08   | 31   | 213   | 243 |
// | September | 09   | 30   | 244   | 273 |
// | October   | 10   | 31   | 274   | 304 |
// | November  | 11   | 30   | 305   | 334 |
// | December  | 12   | 31   | 335   | 365 |
// =========================================

#include "HolidayCommon.as";

const string SYNC_HOLIDAY_ID = "sync_holiday";
const string REMOVE_CLIENT_SCRIPTS_ID = "remove_client_holiday_scripts";

string holiday = "";
bool sync = false;
string[] added_scripts;

void onInit(CRules@ this)
{
    this.addCommandID(SYNC_HOLIDAY_ID);
    this.addCommandID(REMOVE_CLIENT_SCRIPTS_ID);
    onRestart(this);
}

void onRestart(CRules@ this)
{
    if(getNet().isServer())
    {
        print("Checking any holidays...");
        u16 server_year = Time_Year();
        s16 server_date = Time_YearDate();
        u8 server_leap = ((server_year % 4 == 0 && server_year % 100 != 0) || server_year % 400 == 0)? 1 : 0;

        Holiday[] calendar = {
              Holiday("Birthday", 116 + server_leap - 1, 3)
            , Holiday("Halloween", 303 + server_leap - 1, 3)
            , Holiday("Christmas", 358 + server_leap - 1, 3)
        };

        s16 holiday_date;
        u8 holiday_length;
        for(u8 i = 0; i < calendar.length; i++)
        {
            holiday_date = calendar[i].m_date;
            holiday_length = calendar[i].m_length;

            if(server_date - holiday_date >= 0 && server_date < holiday_date + holiday_length)
            {
                //this is stored for later use in the onTick function
                holiday = calendar[i].m_name;
                break;
            }
        }
        sync = true;
    }
}

void onTick(CRules@ this){
    if(getNet().isServer() && sync){
        CBitStream params;
        params.write_string(holiday);
        this.SendCommand(this.getCommandID(SYNC_HOLIDAY_ID), params);
        sync = false;
        holiday = "";
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params){
    //this command is responsible for ensuring all clients and the server has the correct holiday script running
    if(cmd == this.getCommandID(SYNC_HOLIDAY_ID)){
        string holiday = params.read_string();
        string holiday_cache = this.get_string("_holiday_cache");
        if(holiday != holiday_cache)
        {
            if(holiday_cache != "")
            {
                print("Removing " + holiday_cache + " holiday script");
                this.RemoveScript(holiday_cache+".as");
                this.set_string("_holiday_cache", "");
            }
            if(holiday != "")
            {
                print("Adding " + holiday + " holiday script");
                this.AddScript(holiday+".as");
                //this is 100% local, so we only have it if we actually attached a script
                this.set_string("_holiday_cache", holiday);
                //here the name of the script we added is kept track, so we can remove them later
                if(getNet().isServer()){
                    added_scripts.push_back(holiday);
                }
            }
        }
    }
    //this command will remove all holiday scripts currently running on the client
    //also, it will add the current holiday script
    //this ensures that the same script is never added twice
    else if(getNet().isClient() && cmd == this.getCommandID(REMOVE_CLIENT_SCRIPTS_ID)){
        CPlayer@ local_player = getLocalPlayer();
        if (local_player !is null && local_player.getUsername() == params.read_string()){
            u32 len = params.read_u32();
            for(u32 i = 0; i < len; i++){
                this.RemoveScript(params.read_string()+".as");
            }
            string active_script = params.read_string();
            if(active_script != ""){
                this.AddScript(active_script+".as");
            }
        }
    }
}

//here, the server sends a command to the clients with the scripts that the client has to remove upon joining
void onNewPlayerJoin(CRules@ this, CPlayer@ player){
    if(getNet().isServer()){
        CBitStream params;
        params.write_string(player.getUsername());
        params.write_u32(added_scripts.length);
        for(u32 i = 0; i < added_scripts.length; i++){
            params.write_string(added_scripts[i]);
        }
        //_holiday_cache will be the currect holiday script in this context
        params.write_string(this.get_string("_holiday_cache"));
        //sends the names of the scripts to be removed from the client upon joining
        this.SendCommand(this.getCommandID(REMOVE_CLIENT_SCRIPTS_ID), params);
    }
}