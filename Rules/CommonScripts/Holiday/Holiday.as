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
	if(getNet().isServer())
	{
		print("Checking any holidays...");

		holiday_cache = this.get_string("holiday");
		holiday = "";

		u16 server_year = Time_Year();
		s16 server_date = Time_YearDate();
		u8 server_leap = ((server_year % 4 == 0 && server_year % 100 != 0) || server_year % 400 == 0)? 1 : 0;

		Holiday[] calendar = {
			  Holiday("Birthday", 116 + server_leap - 1, 3)
			, Holiday("Halloween", 301 + server_leap - 1, 8)
			, Holiday("Christmas", 358 + server_leap - 2, 8)
		};

		s16 holiday_date;
		u8 holiday_length;
		for(u8 i = 0; i < calendar.length; i++)
		{
			holiday_date = calendar[i].m_date;
			holiday_length = calendar[i].m_length;

			if(server_date - holiday_date >= 0 && server_date < holiday_date + holiday_length)
			{
				holiday = calendar[i].m_name;
				print("Holiday: "+holiday);
				break;
			}
		}
		sync = true;
	}
}

void onTick(CRules@ this)
{
	if(getNet().isServer() && sync)
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
				print("adding " + _holiday + " holiday script");
				//adds the holiday script
				this.AddScript(_holiday+".as");

				if(getNet().isServer())
				{
					//this is 100% local, so we only have it if we actually attached a script
					holiday = _holiday;
					holiday_cache = _holiday;
				}
			}
			this.set_string("holiday", holiday);
		}
	}
}