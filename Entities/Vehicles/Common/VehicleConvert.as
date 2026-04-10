/*
 * convertible if enemy outnumbers friends in radius
 */

const string counter_prop = "capture ticks";
const string raid_tag = "under raid";

const string capture_time_prop = "capture time";
const int capture_half_seconds = 30;

const string friendly_prop = "capture friendly count";
const string enemy_prop = "capture enemy count";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 15;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	if (!this.exists(capture_time_prop))
	{
		this.set_u16(capture_time_prop, capture_half_seconds);
	}

	if (isServer())
	{
		ResetProperties(this);
		SyncProperties(this);

		CMap@ map = getMap();
		if (map.getSector("capture zone "+this.getNetworkID()) is null)
		{
			//default capture zone
			Vec2f corner(this.getRadius() - 4.0f, this.getRadius() - 4.0f);
			map.server_AddMovingSector(corner*-1, corner, "capture zone "+this.getNetworkID(), this.getNetworkID());
		}
	}
}

void ResetProperties(CBlob@ this)
{
	this.set_u16(friendly_prop, 0);
	this.set_u16(enemy_prop, 0);
	this.set_u16(counter_prop, this.get_u16(capture_time_prop));
	this.Untag(raid_tag);
}

void SyncProperties(CBlob@ this)
{
	this.Sync(friendly_prop, true);
	this.Sync(enemy_prop, true);
	this.Sync(counter_prop, true);
	this.Sync(raid_tag, true);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!isServer()) return;

	if (this.isAttached() && this.hasTag(raid_tag))
	{
		ResetProperties(this);
		SyncProperties(this);
	}

	if (this.hasTag("convert on sit") && 
			attachedPoint.socket &&
	        attached.getTeamNum() != this.getTeamNum() &&
	        attached.hasTag("player"))
	{
		this.server_setTeamNum(attached.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	CMap@ map = getMap();
	CMap::Sector@ capture_zone = map.getSector("capture zone "+this.getNetworkID());
	if (capture_zone is null) return;

	u16 attackersCount = 0;
	u16 friendlyCount = 0;
	u8 attackerTeam = 255;

	CBlob@[] blobsInSector;
	if (map.getBlobsInSector(capture_zone, @blobsInSector))
	{
		// count friendlies and enemies
		for (uint i = 0; i < blobsInSector.length; i++)
		{
			CBlob@ b = blobsInSector[i];
			if (b !is this && b.hasTag("player") && !b.hasTag("dead"))
			{
				if (b.getTeamNum() != this.getTeamNum())
				{
					attackersCount++;
					attackerTeam = b.getTeamNum();
				}
				else
				{
					friendlyCount++;
				}
			}
		}
	}

	if (attackersCount > 0 || this.hasTag(raid_tag))
	{
		int ticks = this.get_u16(counter_prop);
		const u16 captureTime = this.get_u16(capture_time_prop);

		//convert
		if (attackersCount > friendlyCount)
		{
			ticks--;
		}
		//un-convert gradually
		else if (attackersCount < friendlyCount || attackersCount == 0)
		{
			ticks = Maths::Min(ticks + 1, captureTime);
		}

		this.set_u16(counter_prop, ticks);
		this.Tag(raid_tag);

		if (ticks <= 0)
		{
			this.server_setTeamNum(attackerTeam);
			ResetProperties(this);
		}
		else
		{
			this.set_u16(friendly_prop, friendlyCount);
			this.set_u16(enemy_prop, attackersCount);
			
			if (attackersCount == 0 && ticks >= captureTime)
			{
				this.Untag(raid_tag);
			}
		}

		SyncProperties(this);
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	ConvertAttachments(this);
	ConvertItems(this);

	if (this.getTeamNum() < 10)
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.PlaySound("/VehicleCapture");
		}
	}
}

const string[] convertPoints = { "VEHICLE", "BOW", "DOOR" };

void ConvertAttachments(CBlob@ this)
{
	if (!isServer()) return;

	AttachmentPoint@[] aps;
	if (!this.getAttachmentPoints(@aps)) return;

	for (u8 i = 0; i < aps.length; i++)
	{
		AttachmentPoint@ point = aps[i];
		CBlob@ blob = point.getOccupied();
		if (blob is null) continue;
		
		if (convertPoints.find(point.name) == -1) continue;
		
		blob.server_setTeamNum(this.getTeamNum());
	}
}

void ConvertItems(CBlob@ this)
{
	if (!isServer()) return;

	CInventory@ inventory = this.getInventory();
	for (uint i = 0; i < inventory.getItemsCount(); i++)
	{
		CBlob@ blob = inventory.getItem(i);
		if (blob is null || blob.getTeamNum() == 255) continue;
		blob.server_setTeamNum(this.getTeamNum());
	}
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

	const u16 friendlyCount = blob.get_u16(friendly_prop);
	const u16 enemyCount = blob.get_u16(enemy_prop);
	const f32 ticks = blob.get_u16(counter_prop);
	const f32 captureTime = blob.get_u16(capture_time_prop);

	const f32 hwidth = 45 + Maths::Max(0, Maths::Max(friendlyCount, enemyCount) - 3) * 8;
	const f32 hheight = 30;

	if (camera.targetDistance > 0.9) 			//draw bigger capture bar if zoomed in
	{
		pos2d.y -= 40;
	 	const f32 padding = 4.0f;
	 	const f32 shift = 29.0f;
	 	const f32 progress = (1.1f - ticks / captureTime)*(hwidth*2-13); //13 is a magic number used to perfectly align progress
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
		const f32 padding = 2.0f;
 		GUI::DrawProgressBar(Vec2f(pos2d.x - hwidth * 0.5f, pos2d.y + hheight - 14 - padding),
 	                      	     Vec2f(pos2d.x + hwidth * 0.5f, pos2d.y + hheight - padding),
 	                      	     1.0f - ticks / captureTime);
	}
}
