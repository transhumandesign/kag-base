// HolidayCommon.as;

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

const string holiday_prop = "holiday";
const string holiday_head_prop = "holiday head num";
const string holiday_head_texture_prop = "holiday head custom texture";

// QUICK FIX: Whitelist scripts as a quick sanitization check
string[] scriptlist = {
	"Easter",
	"Birthday",
	"Halloween",
	"Christmas",
};

shared class Holiday
{
	string m_name;
	u16 m_date;
	u8 m_length;

	Holiday()
	{
		m_name = "";
		m_date = 0;
		m_length = 0;
	}

	Holiday(
	const string &in NAME,
	const u16 &in DATE,
	const u8 &in LENGTH)
	{
		m_name = NAME;
		m_date = DATE;
		m_length = LENGTH;
	}
};

u16 getEasterSunday(u16 server_year)
{
	// calculating date of easter sunday using Gauß' formula

	u8 M = 24;	// these two values are said to change every 100 years
	u8 N = 5;	// Easter sunday this year is 31 March 2024, this function therefore returning 31

	u8 a = server_year % 19;
	u8 b = server_year % 4;
	u8 c = server_year % 7;
	u8 d = (19 * a + M) % 30;
	u8 e = (2 * b + 4 * c + 6 * d + N) % 7;

	return 22 + d + e;
}

string getActiveHolidayName()
{
	u16 server_year = Time_Year();
	s16 server_date = Time_YearDate();
	u8 server_leap = ((server_year % 4 == 0 && server_year % 100 != 0) || server_year % 400 == 0)? 1 : 0;
	u8 days_to_add_to_february = getEasterSunday(server_year); // equals date for easter sunday

	Holiday[] calendar = {
		  Holiday(scriptlist[0], 59 + server_leap - 1 + days_to_add_to_february, 14)
		, Holiday(scriptlist[1], 116 + server_leap - 1, 3)
		, Holiday(scriptlist[2], 301 + server_leap - 1, 8)
		, Holiday(scriptlist[3], 357 + server_leap - 2, 16)
	};

	s16 holiday_start;
	s16 holiday_end;
	for(u8 i = 0; i < calendar.length; i++)
	{
		holiday_start = calendar[i].m_date;
		holiday_end = (holiday_start + calendar[i].m_length) % (365 + server_leap);

		bool holiday_active = false;
		
		if(holiday_start <= holiday_end)
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