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

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	if(getNet().isServer())
	{
		print("Checking any holidays...");

		this.set_string("holiday", "nothing");

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
				this.set_string("holiday", calendar[i].m_name);
				break;
			}
		}

		this.Sync("holiday", true);
	}

	//TODO: fix holidays :)
	// - safe removal after holiday is over needs to be tested

	/*if(this.exists("holiday"))
	{
		string holiday = this.get_string("holiday");

		string old_holiday = this.exists("_holiday_cache") ? this.get_string("_holiday_cache") : "";
		if(old_holiday != "" && old_holiday != holiday)
		{
			//remove old holiday
			this.RemoveScript(old_holiday+".as");
		}

		if(holiday != "nothing")
		{
			this.AddScript(holiday+".as");
			//this is 100% local, so we only have it if we actually attached a script
			this.set_string("_holiday_cache", holiday);
		}
	}*/
}
