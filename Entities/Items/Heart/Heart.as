
#include "HolidaySprites.as";

string heart_file_name;

void onInit(CBlob@ this)
{
	this.set_string("eat sound", "/Heart.ogg");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
	this.server_SetTimeToDie(40);
	this.Tag("ignore_arrow");
	this.Tag("ignore_saw");
}

void onInit(CSprite@ this)
{
	if (isAnyHoliday())
	{
		heart_file_name = getHolidayVersionFileName("Heart");
		this.ReloadSprite(heart_file_name);
	}
}
