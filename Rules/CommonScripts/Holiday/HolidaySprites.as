#include "HolidayCommon.as";

string active_holiday;
bool holiday_fetched = false;

const string[] christmas_version_exists = {"Hall", "GenericGibs", "TraderMale", "TraderFemale", "world", "Chicken", "Bushes", "Trees", 
											"Tent", "TDM_Ruins", "BackgroundCastle", "BackgroundIsland", "BackgroundTrees", "skygradient", 
											"world_intro", "KAGWorld1-1a", "KAGWorld1-2a", "KAGWorld1-3a", "KAGWorld1-4a", "KAGWorld1-5a", 
											"KAGWorld1-6a", "KAGWorld1-7a", "KAGWorld1-8a", "KAGWorld1-9a", "KAGWorld1-10a", "KAGWorld1-11a", 
											"KAGWorld1-12a", "KAGWorld1-13", "KAGWorld1-14", "KAGWorld1-14outro", "TradingPostChristmas"};
const string[] easter_version_exists 	= {};
const string[] birthday_version_exists 	= {};
const string[] halloween_version_exists = {"TraderMale", "TraderFemale", "WaterBomb", "Heart", "Lantern", "Bushes", "Grain", "world", "Trees",
											"Flowers"};

string getHolidayVersionFileName(string file_name, string suffix = "png")
{
	active_holiday = getActiveHolidayName();
	holiday_fetched = true;
	
	if (isChristmas())
	{
		return christmas_version_exists.find(file_name) != -1 ? file_name + active_holiday + "." + suffix : file_name + "." + suffix;
	}
	else if (isEaster())
	{
		return easter_version_exists.find(file_name) != -1 ? file_name + active_holiday + "." + suffix : file_name + "." + suffix;
	}
	else if (isBirthday())
	{
		return birthday_version_exists.find(file_name) != -1 ? file_name + active_holiday + "." + suffix : file_name + "." + suffix;
	}
	else if (isHalloween())
	{
		return halloween_version_exists.find(file_name) != -1 ? file_name + active_holiday + "." + suffix : file_name + "." + suffix;
	}
	
	return file_name + "." + suffix;
}

bool isChristmas()
{
	active_holiday = getActiveHolidayName();
	return active_holiday == "Christmas";
}

bool isEaster()
{
	FetchHolidayName();
	return active_holiday == "Easter";
}

bool isBirthday()
{
	FetchHolidayName();
	return active_holiday == "Birthday";
}

bool isHalloween()
{
	FetchHolidayName();
	return active_holiday == "Halloween";
}

bool isAnyHoliday()
{
	FetchHolidayName();
	return isChristmas() || isEaster() || isBirthday() || isHalloween();
}

void FetchHolidayName()
{
	if (!holiday_fetched)
	{
		active_holiday = getActiveHolidayName();
		holiday_fetched = true;
	}
}