
#include "HolidaySprites.as";

string grain_file_name;

void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
}

void onInit(CSprite@ this)
{
	if (isAnyHoliday())
	{
		grain_file_name = getHolidayVersionFileName("Grain");
		this.ReloadSprite(grain_file_name);
	}
}
