// HolidayCommon.as;

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