// HolidayCommon.as;

const string holiday_prop = "holiday";
const string holiday_head_prop = "holiday head num";
const string holiday_head_texture_prop = "holiday head custom texture";

enum Holidays {
	HOLIDAY_NONE = 0, // so that init to 0 is HOLIDAY_NONE

	HOLIDAY_FIRST = 1,
	HOLIDAY_BIRTHDAY = 1, // == first
	HOLIDAY_HALLOWEEN = 2,
	HOLIDAY_CHRISTMAS = 3,
}

string[] holiday_names = {
	"",                // HOLIDAY_NONE
	"Birthday",        // HOLIDAY_BIRTHDAY
	"Halloween",       // HOLIDAY_HALLOWEEN
	"Christmas",       // HOLIDAY_CHRISTMAS
};

int getHoliday() {
	return getRules().get_s8(holiday_prop);
}

int getHolidayFromString(const string&in holiday) {
	const int idx = holiday_names.find(holiday);
	return idx != -1 ? idx : HOLIDAY_NONE;
}

string getStringFromHoliday(s8 holiday) {
	return holiday_names[holiday];
}

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
