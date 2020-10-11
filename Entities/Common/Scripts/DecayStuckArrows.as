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

			//remove if arrow should decay, blob is dead, or player turned on fast render
			if (time <= getGameTime() || this.hasTag("dead") || v_fastrender)
			{
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
