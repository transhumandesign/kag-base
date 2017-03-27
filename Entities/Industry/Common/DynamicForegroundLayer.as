void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 10;
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ front = this.getSpriteLayer("front layer");
	if (front !is null)
	{
		front.SetVisible(false);

		bool visible = front.isVisible();
		int frame = front.getFrameIndex();

		CBlob@ blob = this.getBlob();

		bool anim = blob.hasTag("animated front");

		CPlayer@ p = getLocalPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				f32 length = (local.getPosition() - blob.getPosition()).Length();
				f32 popdistance = visible ? 24 : 32;
				if (visible)
				{
					if (length < popdistance)
					{
						if (anim)
							frame = 1;
						else
							visible = false;
					}
				}
				else
				{
					if (length > popdistance)
					{
						if (anim)
							frame = 0;
						else
							visible = true;
					}
				}
			}
			else
			{
				visible	= true;
			}
		}
		else
		{
			visible	= true;
		}

		front.SetVisible(visible);

		if (anim)
			front.SetFrameIndex(frame);
		else
			front.animation.setFrameFromRatio(1.0f - (blob.getHealth() / blob.getInitialHealth()));
	}
}
