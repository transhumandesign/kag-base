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

// QUICK FIX: Whitelist scripts as a quick sanitization check
string[] scriptlist = {
	"Birthday",
	"Halloween",
	"Christmas",
};

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
		holiday = GetCurrentHoliday();
		
		sync = true;
	}
}

void SyncHoliday(CRules@ this, string _holiday, string _holiday_cache)
{
	if (_holiday != _holiday_cache) //changed
	{
		if (_holiday_cache != "")
		{
			if (scriptlist.find(_holiday_cache) == -1) {
				warn("script " + _holiday_cache + " cache not found inside script list");
				return;
			} 
			print("removing " + _holiday_cache + " holiday script");
			//remove old holiday
			this.RemoveScript(_holiday_cache + ".as");
#ifdef STAGING
			CFileMatcher::RemoveOverlay(_holiday_cache);
#endif
			if (isServer())
			{
				holiday_cache = "";
			}
		}
		if (_holiday != "")
		{
			if (scriptlist.find(_holiday) == -1) {
				warn("script " + _holiday + " not found inside script list");
				return;
			}

			print("adding " + _holiday + " holiday script");
			//adds the holiday script
			this.AddScript(_holiday+".as");

#ifdef STAGING
			CFileMatcher::AddOverlay(_holiday);
#endif

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

void onTick(CRules@ this)
{
	if (isServer() && sync)
	{
		SyncHoliday(this, holiday, holiday_cache);
		CBitStream params;
		params.write_string(holiday);
		params.write_string(holiday_cache);
		this.SendCommand(this.getCommandID(SYNC_HOLIDAY_ID), params);
		sync = false;
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(SYNC_HOLIDAY_ID) && isClient())
	{
		string _holiday, _holiday_cache;
		if(!params.saferead_string(_holiday)) return;
		if(!params.saferead_string(_holiday_cache)) return;

		SyncHoliday(this, _holiday, _holiday_cache);
	}
}

// Warning: This is called by the engine on startup to know if there is a holiday going on
string GetCurrentHoliday()
{
	u16 server_year = Time_Year();
	s16 server_date = Time_YearDate();
	u8 server_leap = ((server_year % 4 == 0 && server_year % 100 != 0) || server_year % 400 == 0)? 1 : 0;

	Holiday[] calendar = {
			Holiday(scriptlist[0], 116 + server_leap - 1, 3)
		, Holiday(scriptlist[1], 301 + server_leap - 1, 8)
		, Holiday(scriptlist[2], 357 + server_leap - 2, 16)
	};

	s16 holiday_start;
	s16 holiday_end;
	for (u8 i = 0; i < calendar.length; i++)
	{
		holiday_start = calendar[i].m_date;
		holiday_end = (holiday_start + calendar[i].m_length) % (365 + server_leap);

		bool holiday_active = false;
		if (holiday_start <= holiday_end)
		{
			holiday_active = server_date >= holiday_start && server_date < holiday_end;
		}
		else
		{
			holiday_active = server_date >= holiday_start || server_date < holiday_end;
		}

		if (holiday_active)
		{
			return calendar[i].m_name;
		}
	}

	return "";
}