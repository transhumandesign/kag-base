// Holiday.as

#include "HolidayCommon.as";

const string SYNC_HOLIDAY_ID = "sync_holiday";

string holiday = "";
string holiday_cache = "";
bool sync = false;

void onInit(CRules@ this)
{
	this.addCommandID(SYNC_HOLIDAY_ID);
	onRestart(this);
}

void onRestart(CRules@ this)
{
	if (isServer())
	{
		print("Checking any holidays...");
		
		holiday_cache = this.get_string(holiday_prop);
		holiday = getActiveHolidayName();
		
		print("Holiday: " + holiday);

		sync = true;
	}
}

void onTick(CRules@ this)
{
	if(isServer() && sync)
	{
		CBitStream params;
		params.write_string(holiday);
		params.write_string(holiday_cache);
		this.SendCommand(this.getCommandID(SYNC_HOLIDAY_ID), params);
		sync = false;
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if(cmd == this.getCommandID(SYNC_HOLIDAY_ID))
	{
		string _holiday, _holiday_cache;
		if(!params.saferead_string(_holiday)) return;
		if(!params.saferead_string(_holiday_cache)) return;

		if(_holiday != _holiday_cache) //changed
		{
			if(_holiday_cache != "")
			{
				if (scriptlist.find(_holiday_cache) == -1) {
					warn("script " + _holiday_cache + " cache not found inside script list");
					return;
				} 
				print("removing " + _holiday_cache + " holiday script");
				//remove old holiday
				this.RemoveScript(_holiday_cache + ".as");
				if(getNet().isServer())
				{
					holiday_cache = "";
				}
			}
			if(_holiday != "")
			{
				if (scriptlist.find(_holiday) == -1) {
					warn("script " + _holiday + " not found inside script list");
					return;
				}

				print("adding " + _holiday + " holiday script");
				//adds the holiday script
				this.AddScript(_holiday+".as");

				if(isServer())
				{
					//this is 100% local, so we only have it if we actually attached a script
					holiday = _holiday;
					holiday_cache = _holiday;
				}
			}
			this.set_string(holiday_prop, holiday);
		}
	}
}
