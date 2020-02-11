/*
 * convertible if enemy outnumbers friends in radius
 */

const string counter_prop = "capture ticks";
const string raid_tag = "under raid";
const int capture_half_seconds = 30;
const int short_capture_half_seconds = 10;
const int capture_radius = 80;

const string friendly_prop = "capture friendly count";
const string enemy_prop = "capture enemy count";

const string short_raid_tag = "short raid time";

void onInit(CBlob@ this)
{
	this.addCommandID("convert");
	this.getCurrentScript().tickFrequency = 15;
	this.set_s16(counter_prop, GetCaptureTime(this));
	this.set_s16("max capture ticks", GetCaptureTime(this)); //for normalizing capture ticks
	this.set_s16(friendly_prop, 0);
	this.set_s16(enemy_prop, 0);
}

//add
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!this.hasTag("convert on sit"))
		return;

	if (attachedPoint.socket &&
	        attached.getTeamNum() != this.getTeamNum() &&
	        attached.hasTag("player"))
	{
		this.server_setTeamNum(attached.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
	if (!getNet().isServer()) return;

	bool reset_timer = true;
	bool sync = false;

	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), capture_radius, @blobsInRadius))
	{
		// count friendlies and enemies
		int attackersCount = 0;
		int friendlyCount = 0;

		int attackerTeam = 255;
		Vec2f pos = this.getPosition();
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is this && b.hasTag("player") && !b.hasTag("dead"))
			{
				if (b.getTeamNum() != this.getTeamNum())
				{
					Vec2f bpos = b.getPosition();
					if (bpos.x > pos.x - this.getWidth() / 1.0f && bpos.x < pos.x + this.getWidth() / 1.0f &&
					        bpos.y < pos.y + this.getHeight() / 1.0f && bpos.y > pos.y - this.getHeight() / 1.0f)
					{
						attackersCount++;
						attackerTeam = b.getTeamNum();
					}
				}
				else
				{
					friendlyCount++;
				}
			}
		}

		int ticks = GetCaptureTime(this);
		if (this.hasTag(raid_tag))
		{
			ticks = this.get_s16(counter_prop);
		}

		if (attackersCount > 0 || ticks < GetCaptureTime(this))
		{
			//convert
			if (attackersCount > friendlyCount)
			{
				ticks--;
			}
			//un-convert gradually
			else if (attackersCount < friendlyCount || attackersCount == 0)
			{
				ticks = Maths::Min(ticks + 1, GetCaptureTime(this));
			}

			this.set_s16(counter_prop, ticks);
			this.Tag(raid_tag);

			if (ticks <= 0)
			{
				this.server_setTeamNum(attackerTeam);
				reset_timer = true;
			}
			else
			{
				this.set_s16(friendly_prop, friendlyCount);
				this.set_s16(enemy_prop, attackersCount);
				reset_timer = false;
			}

			sync = true;
		}
	}
	else
	{
		this.Untag(raid_tag);
	}

	if (reset_timer)
	{
		this.set_s16(friendly_prop, 0);
		this.set_s16(enemy_prop, 0);

		this.set_s16(counter_prop, GetCaptureTime(this));
		this.Untag(raid_tag);
		sync = true;
	}

	if (sync)
	{
		this.Sync(friendly_prop, true);
		this.Sync(enemy_prop, true);

		this.Sync(counter_prop, true);
		this.Sync(raid_tag, true);
	}

}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (this.getTeamNum() >= 0 && this.getTeamNum() < 10)
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.PlaySound("/VehicleCapture");
		}

		ConvertPoint(this, "VEHICLE");
		ConvertPoint(this, "DOOR");
	}
}

void ConvertPoint(CBlob@ this, const string pointName)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName(pointName);
	if (point !is null)
	{
		CBlob@ blob = point.getOccupied();
		if (blob !is null)
		{
			blob.server_setTeamNum(this.getTeamNum());
		}
	}
}

int GetCaptureTime(CBlob@ blob)
{
	if (blob.hasTag(short_raid_tag))
	{
		return short_capture_half_seconds;
	}
	return capture_half_seconds;
}


// alert and capture progress bar

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	CCamera@ camera = getCamera();
	if (blob is null || !blob.hasTag(raid_tag))
		return;

	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(blob.getPosition());

	s16 friendlyCount = blob.get_s16(friendly_prop);
	s16 enemyCount = blob.get_s16(enemy_prop);

	f32 hwidth = 45 + Maths::Max(0, Maths::Max(friendlyCount, enemyCount) - 3) * 8;
	f32 hheight = 30;

	if (camera.targetDistance > 0.9) 			//draw bigger capture bar if zoomed in
	{
		pos2d.y -= 40;
	 	f32 padding = 4.0f;
	 	f32 shift = 29.0f;
	 	s32 captureTime = blob.get_s16(counter_prop);
	 	f32 progress = (1.1f - float(captureTime) / float(GetCaptureTime(blob)))*(hwidth*2-13); //13 is a magic number used to perfectly align progress
	 	GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
	 		      Vec2f(pos2d.x + hwidth - padding, pos2d.y + hheight - padding),
			      SColor(175,200,207,197)); 				//draw capture bar background
		if (progress >= float(8)) 					//draw progress if capture can start
		{
	 		GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
			      	      Vec2f((pos2d.x - hwidth + padding) + progress, pos2d.y + hheight - padding),
				      SColor(175,200,207,197));
		}
		//draw balance of power
		for (int i = 1; i <= friendlyCount; i++)
	 		GUI::DrawIcon("VehicleConvertIcon.png", 0, Vec2f(8, 16), pos2d + Vec2f(i * 8 - 8, -4), 0.9f, blob.getTeamNum());
	 	for (int i = 1; i <= enemyCount; i++)
	 		GUI::DrawIcon("VehicleConvertIcon.png", 1, Vec2f(8, 16), pos2d + Vec2f(i * -8 - 8, -4), 0.9f);
	}
	else
	{
		//draw smaller capture bar if zoom is farthest
		pos2d.y -= 37;
		f32 padding = 2.0f;
 		s32 captureTime = blob.get_s16(counter_prop);
 		GUI::DrawProgressBar(Vec2f(pos2d.x - hwidth / 2, pos2d.y + hheight - 14 - padding),
 	                      	     Vec2f(pos2d.x + hwidth / 2, pos2d.y + hheight - padding),
 	                      	     1.0f - float(captureTime) / float(GetCaptureTime(blob)));
	}

}
