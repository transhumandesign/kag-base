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
				//only show gibs on decay
				if (decay)
				{
					//gib copied from Arrow.as
					Vec2f pos = arrow.getWorldTranslation();
					Vec2f vel = this.getVelocity();
					makeGibParticle(
						"GenericGibs.png", pos, vel,
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
		}
	}

	if (times.empty())
	{
		//no more stuck arrows so remove this script
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}
