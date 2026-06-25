
const u8 THRESHOLD_FLICKER = 4;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 100;
}

void onTick(CBlob@ this)
{
	f32 remaining_time;
	u32 threshold_ticks = THRESHOLD_FLICKER * getTicksASecond();
	
	if (isServer()) // save server-only information "time to die" to blob, so client can fetch it
	{
		remaining_time = this.getTimeToDie();	
		
		bool closeToThreshold = remaining_time * getTicksASecond() < threshold_ticks + 200;
		bool remainderNotZero = remaining_time > 0;
		bool shouldTickOften = (closeToThreshold && remainderNotZero) ? true : false;
		this.set_bool("should tick often", shouldTickOften);
		this.Sync("should tick often", true);
		
		this.set_f32("remaining_time", remaining_time);
		this.Sync("remaining_time", true);
	}
	
	if (isClient()) // fetch "time to die" from blob, manage sprite flickering
	{
		remaining_time = this.exists("remaining_time") ? this.get_f32("remaining_time") : -1;
		
		if (remaining_time > 0 
			&& remaining_time < THRESHOLD_FLICKER) 
		{		
			if (this.getTickSinceCreated() % Maths::Ceil(remaining_time) == 0)
			{
				CSprite@ s = this.getSprite();
				s.SetVisible(!s.isVisible());
			}
		}
	}
	
	this.getCurrentScript().tickFrequency = this.get_bool("should tick often") ? 1 : 100;
}
