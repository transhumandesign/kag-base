#include "HolidaySprites.as";

string gibs_file_name;

void onInit(CBlob@ this)
{
	gibs_file_name = isAnyHoliday() ? getHolidayVersionFileName("GenericGibs") : "GenericGibs.png";
}

Random rand(Time());

void onTick(CBlob@ this)
{
	string[]@ names;
	uint[]@ times;

	if (this.get("stuck_arrow_names", @names) && this.get("stuck_arrow_times", @times))
	{
		CSprite@ sprite = this.getSprite();

		for (int i = 0; i < times.size(); i++)
		{
			string name = names[i];
			uint time = times[i];
			bool decay = time <= getGameTime();
			CSpriteLayer@ arrow = sprite.getSpriteLayer(name);

			//remove if arrow should decay, blob is dead, or player turned on fast render
			if (decay || this.hasTag("dead") || v_fastrender)
			{
				if (arrow.isOnScreen() && !v_fastrender)
				{
					//gib copied from Arrow.as
					Vec2f pos = arrow.getWorldTranslation();
					Vec2f vel = this.getVelocity();
					makeGibParticle(
						gibs_file_name, pos, vel,
						1, rand.NextRanged(4) + 4,
						Vec2f(8, 8), 2.0f, 20, "/thud",
						this.getTeamNum()
					);
				}

				sprite.RemoveSpriteLayer(name);

				names.removeAt(i);
				times.removeAt(i);
				i--;
			}
			else
			{
				//support blobs that use fake rolling
				if ((this.hasScript("CheapFakeRolling.as") || this.hasScript("FakeRolling.as")) && !this.isAttached())
				{
					float angle = this.get_f32("angle");
					float oldAngle = this.get_f32("old_angle");
					float deltaAngle = (angle - oldAngle) % 360;

					Vec2f offset = -arrow.getOffset();
					if (arrow.isFacingLeft())
						offset.x *= -1;

					arrow.RotateBy(deltaAngle, offset);
				}
			}
		}
	}

	if (times.empty())
	{
		//no more stuck arrows so remove this script
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}
