namespace Trampoline
{
	const string TIMER = "trampoline_timer";
	const u16 COOLDOWN = 7;
	const u8 SCALAR = 10;
	const bool SAFETY = true;
	const int COOLDOWN_LIMIT = 8;
}

class TrampolineCooldown{
	u16 netid;
	u32 timer;
	TrampolineCooldown(u16 netid, u16 timer){this.netid = netid; this.timer = timer;}
};

void onInit(CBlob@ this)
{
	TrampolineCooldown @[] cooldowns;
	this.set(Trampoline::TIMER, cooldowns);
	this.getShape().getConsts().collideWhenAttached = true;

	this.Tag("no falldamage");
	this.Tag("medium weight");
	// Because BlobPlacement.as is *AMAZING*
	this.Tag("place norotate");

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	point.SetKeysToTake(key_action1 | key_action2);

	this.getCurrentScript().runFlags |= Script::tick_attached;
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	Vec2f ray = holder.getAimPos() - this.getPosition();
	ray.Normalize();
	
	f32 angle = ray.Angle();

	if (point.isKeyPressed(key_action2))
	{
		// set angle to what was on previous tick
		angle = this.get_f32("old angle");
		this.setAngleDegrees(angle);
	}
	else if (point.isKeyPressed(key_action1))
	{
		// rotate in 45 degree steps
		angle = Maths::Floor((angle - 67.5f) / 45) * 45;
		this.setAngleDegrees(-angle);
	}
	else
	{
		// follow cursor normally
		this.setAngleDegrees(-angle + 90);
	}
	
	this.set_f32("old angle", this.getAngleDegrees());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob is null || blob.isAttached() || blob.getShape().isStatic()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();

	//choose whether to jump on team trampolines
	if (blob.hasTag("player") && blob.isKeyPressed(key_down) && this.getTeamNum() == blob.getTeamNum()) return;

	//cant bounce holder
	if (holder is blob) return;

	//cant bounce while held by something attached to something else
	if (holder !is null && holder.isAttached()) return;

	//prevent knights from flying using trampolines

	//get angle difference between entry angle and the facing angle
	Vec2f pos_delta = (blob.getPosition() - this.getPosition()).RotateBy(90);
	float delta_angle = Maths::Abs(-pos_delta.Angle() - this.getAngleDegrees());
	if (delta_angle > 180)
	{
		delta_angle = 360 - delta_angle;
	}
	//if more than 90 degrees out, no bounce
	if (delta_angle > 90)
	{
		return;
	}

	TrampolineCooldown@[]@ cooldowns;
	if (!this.get(Trampoline::TIMER, @cooldowns)) return;

	//shred old cooldown if we have too many
	if (Trampoline::SAFETY && cooldowns.length > Trampoline::COOLDOWN_LIMIT) cooldowns.removeAt(0);

	u16 netid = blob.getNetworkID();
	bool block = false;
	for(int i = 0; i < cooldowns.length; i++)
	{
		if (cooldowns[i].timer < getGameTime())
		{
			cooldowns.removeAt(i);
			i--;
		}
		else if (netid == cooldowns[i].netid)
		{
			block = true;
			break;
		}
	}
	if (!block)
	{
		Vec2f velocity_old = blob.getOldVelocity();
		if (velocity_old.Length() < 1.0f) return;

		float angle = this.getAngleDegrees();

		Vec2f direction = Vec2f(0.0f, -1.0f);
		direction.RotateBy(angle);

		float velocity_angle = direction.AngleWith(velocity_old);

		if (Maths::Abs(velocity_angle) > 90)
		{
			TrampolineCooldown cooldown(netid, getGameTime() + Trampoline::COOLDOWN);
			cooldowns.push_back(cooldown);

			Vec2f velocity = Vec2f(0, -Trampoline::SCALAR);
			velocity.RotateBy(angle);

			blob.setVelocity(velocity);

			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.SetAnimation("default");
				sprite.SetAnimation("bounce");
				sprite.PlaySound("TrampolineJump.ogg");
			}
		}
	}
}

// for help text
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!attached.hasTag("player")) return;

	this.set_s32("attachtime", getGameTime());
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("no pickup");
}

void onRender(CSprite@ this)
{
	if (g_videorecording) return;

	CBlob@ blob = this.getBlob();

	if (!blob.isAttached()) return;

	CAttachment@ attachment = blob.getAttachments();

	AttachmentPoint@ ap = attachment.getAttachmentPointByName("PICKUP");

	CBlob@ playerblob = ap.getOccupied();

	CControls@ controls = playerblob.getControls();

	if (controls is null) return;

	GUI::SetFont("menu");

	string lmb = getTranslatedString(controls.getActionKeyKeyName(AK_ACTION1));
	string rmb = getTranslatedString(controls.getActionKeyKeyName(AK_ACTION2));
	string help_text = getTranslatedString(
		"Hold {KEY1} to lock trampoline rotation to 45 degree steps\n\nHold {KEY2} to lock angle")
	.replace("{KEY1}", lmb).replace("{KEY2}", rmb);

	Vec2f text_dim;
	GUI::GetTextDimensions(help_text, text_dim);

	Vec2f offset = Vec2f(20, 80);
	float x = getScreenWidth() / 3 + offset.x;
	float y = getScreenHeight() - offset.y;

	Vec2f drawpos = getDriver().getScreenCenterPos() - Vec2f(0, 240);

	drawpos = Vec2f(x, y);

	int ticks_since_pickup = getGameTime() - this.getBlob().get_s32("attachtime");

	int alpha = 255;

	if (ticks_since_pickup >= 5 * getTicksASecond())
	{
		alpha = Maths::Max(0, alpha - Maths::Pow((ticks_since_pickup - 5 * getTicksASecond()), 1.75));
	}

	SColor color_text = SColor(alpha, 255, 255, 255);
	SColor color_pane = SColor(alpha, 200, 200, 200);

	GUI::DrawPane(
		Vec2f(drawpos.x - text_dim.x / 2 - 5, drawpos.y - text_dim.y / 2 - 5), 
		Vec2f(drawpos.x + text_dim.x / 2 + 5, drawpos.y + text_dim.y / 2 + 5),
		color_pane);

	GUI::DrawTextCentered(help_text,
			              drawpos,
			              color_text);

}