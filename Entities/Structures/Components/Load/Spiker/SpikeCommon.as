
namespace Spike
{
	enum pointing
	{
		pointing_up = 0,
		pointing_right,
		pointing_down,
		pointing_left
	};

	enum state
	{
		hidden = 0,
		stabbing,
		falling
	};
}

void UpdateSprite(CBlob@ this)
{
	if (isClient())
	{
		// spike frame
		uint frame_add = this.hasTag("bloody") && !g_kidssafe ? 1 : 0;
		bool is_hidden = this.get_u8("state") == Spike::hidden;
		
		this.getSprite().animation.frame = is_hidden ? 2 + frame_add: frame_add;
	}
}
