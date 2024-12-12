// HolidayCommon.as;

const string holiday_prop = "holiday";
const string holiday_head_prop = "holiday head num";
const string holiday_head_texture_prop = "holiday head custom texture";

enum Holidays {
	None = -1,
	Birthday = 0,
	Halloween = 1,
	Christmas = 2,
}

string[] HolidayList = {
	"Birthday",
	"Halloween",
	"Christmas",
};

int getHoliday() {
	return getRules().get_s8(holiday_prop);
}

int getHolidayFromString(const string&in holiday) {
	return HolidayList.find(holiday);
}

string getStringFromHoliday(s8 holiday) {
	if (holiday == -1)
		return "";
	
	return HolidayList[holiday];
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
