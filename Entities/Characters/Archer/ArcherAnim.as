// Archer animations

#include "ArcherCommon.as"
#include "FireParticle.as"
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "Accolades.as"


const f32 config_offset = -6.0f;
const string shiny_layer = "shiny bit";

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	int armour = PLAYER_ARMOUR_STANDARD;

	CPlayer@ p = this.getBlob().getPlayer();
	if (p !is null)
	{
		armour = p.getArmourSet();
		if (armour == PLAYER_ARMOUR_STANDARD)
		{
			Accolades@ acc = getPlayerAccolades(p.getUsername());
			if (acc.hasCape())
			{
				armour = PLAYER_ARMOUR_CAPE;
			}
		}
	}

	switch (armour)
	{
	case PLAYER_ARMOUR_STANDARD:
		ensureCorrectRunnerTexture(this, "archer", "Archer");
		break;
	case PLAYER_ARMOUR_CAPE:
		ensureCorrectRunnerTexture(this, "archer_cape", "ArcherCape");
		break;
	case PLAYER_ARMOUR_GOLD:
		ensureCorrectRunnerTexture(this, "archer_gold",  "ArcherGold");
		break;
	}


	string texname = getRunnerTextureName(this);

	this.RemoveSpriteLayer("frontarm");
	CSpriteLayer@ frontarm = this.addTexturedSpriteLayer("frontarm", texname , 32, 16);

	if (frontarm !is null)
	{
		Animation@ animcharge = frontarm.addAnimation("charge", 0, false);
		animcharge.AddFrame(16);
		animcharge.AddFrame(24);
		animcharge.AddFrame(32);
		Animation@ animshoot = frontarm.addAnimation("fired", 0, false);
		animshoot.AddFrame(40);
		Animation@ animnoarrow = frontarm.addAnimation("no_arrow", 0, false);
		animnoarrow.AddFrame(25);
		frontarm.SetOffset(Vec2f(-1.0f, 5.0f + config_offset));
		frontarm.SetAnimation("fired");
		frontarm.SetVisible(false);
	}

	this.RemoveSpriteLayer("backarm");
	CSpriteLayer@ backarm = this.addTexturedSpriteLayer("backarm", texname , 32, 16);

	if (backarm !is null)
	{
		Animation@ anim = backarm.addAnimation("default", 0, false);
		anim.AddFrame(17);
		backarm.SetOffset(Vec2f(-1.0f, 5.0f + config_offset));
		backarm.SetAnimation("default");
		backarm.SetVisible(false);
	}

	this.RemoveSpriteLayer("held arrow");
	CSpriteLayer@ arrow = this.addSpriteLayer("held arrow", "Arrow.png" , 16, 8, this.getBlob().getTeamNum(), 0);

	if (arrow !is null)
	{
		Animation@ anim = arrow.addAnimation("default", 0, false);
		anim.AddFrame(1); //normal
		anim.AddFrame(9); //water
		anim.AddFrame(8); //fire
		anim.AddFrame(14); //bomb
		arrow.SetOffset(Vec2f(-1.0f, 5.0f + config_offset));
		arrow.SetAnimation("default");
		arrow.SetVisible(false);
	}

	//quiver
	this.RemoveSpriteLayer("quiver");
	CSpriteLayer@ quiver = this.addTexturedSpriteLayer("quiver", texname , 16, 16);

	if (quiver !is null)
	{
		Animation@ anim = quiver.addAnimation("default", 0, false);
		anim.AddFrame(67);
		anim.AddFrame(66);
		quiver.SetOffset(Vec2f(-10.0f, 2.0f + config_offset));
		quiver.SetRelativeZ(-0.1f);
	}

	//grapple
	this.RemoveSpriteLayer("hook");
	CSpriteLayer@ hook = this.addTexturedSpriteLayer("hook", texname , 16, 8);

	if (hook !is null)
	{
		Animation@ anim = hook.addAnimation("default", 0, false);
		anim.AddFrame(178);
		hook.SetRelativeZ(2.0f);
		hook.SetVisible(false);
	}

	this.RemoveSpriteLayer("rope");
	CSpriteLayer@ rope = this.addTexturedSpriteLayer("rope", texname , 32, 8);

	if (rope !is null)
	{
		Animation@ anim = rope.addAnimation("default", 0, false);
		anim.AddFrame(81);
		rope.SetRelativeZ(-1.5f);
		rope.SetVisible(false);
	}

	// add shiny
	this.RemoveSpriteLayer(shiny_layer);
	CSpriteLayer@ shiny = this.addSpriteLayer(shiny_layer, "AnimeShiny.png", 16, 16, this.getBlob().getTeamNum(), 0);

	if (shiny !is null)
	{
		Animation@ anim = shiny.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		shiny.SetVisible(false);
		shiny.SetRelativeZ(8.0f);
	}
}

void setArmValues(CSpriteLayer@ arm, bool visible, f32 angle, f32 relativeZ, string anim, Vec2f around, Vec2f offset)
{
	if (arm !is null)
	{
		arm.SetVisible(visible);

		if (visible)
		{
			if (!arm.isAnimation(anim))
			{
				arm.SetAnimation(anim);
			}

			arm.SetOffset(offset);
			arm.ResetTransform();
			arm.SetRelativeZ(relativeZ);
			arm.RotateBy(angle, around);
		}
	}
}

// stuff for shiny - global cause is used by a couple functions in a tick
bool needs_shiny = false;
Vec2f shiny_offset;
f32 shiny_angle = 0.0f;

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
			this.RemoveSpriteLayer("frontarm");
			this.RemoveSpriteLayer("backarm");
			this.RemoveSpriteLayer("held arrow");
			this.RemoveSpriteLayer(shiny_layer);
		}

		doQuiverUpdate(this, false, true);
		doRopeUpdate(this, null, null);

		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(1);
		}
		else
		{
			this.SetFrameIndex(2);
		}

		return;
	}

	ArcherInfo@ archer;
	if (!blob.get("archerInfo", @archer))
	{
		return;
	}

	doRopeUpdate(this, blob, archer);

	// animations
	const bool firing = IsFiring(blob);
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	bool legolas = archer.charge_state == ArcherParams::legolas_ready || archer.charge_state == ArcherParams::legolas_charging;
	needs_shiny = false;
	bool crouch = false;

	bool knocked = isKnocked(blob);
	Vec2f pos = blob.getPosition() + Vec2f(0, -2);
	Vec2f aimpos = blob.getAimPos();
	pos.x += this.isFacingLeft() ? 2 : -2;

	// get the angle of aiming with mouse
	Vec2f vec = aimpos - pos;
	f32 angle = vec.Angle();

	if (knocked)
	{
		if (inair)
		{
			this.SetAnimation("knocked_air");
		}
		else
		{
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag("seated"))
	{
		this.SetAnimation("default");
	}
	else if(archer.charge_state == ArcherParams::stabbing)
	{
		this.SetAnimation("stab");
	}
	else if (firing || legolas)
	{
		if (inair)
		{
			this.SetAnimation("shoot_jump");
		}
		else if ((left || right) ||
		         (blob.isOnLadder() && (up || down)))
		{
			this.SetAnimation("shoot_run");
		}
		else
		{
			this.SetAnimation("shoot");
		}
	}
	else if (inair)
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		Vec2f vel = blob.getVelocity();
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fall");
			this.animation.timer = 0;
			bool inwater = blob.isInWater();

			if (vy < -1.5 * (inwater ? 0.7 : 1))
			{
				this.animation.frame = 0;
			}
			else if (vy > 1.5 * (inwater ? 0.7 : 1))
			{
				this.animation.frame = 2;
			}
			else
			{
				this.animation.frame = 1;
			}
		}
	}
	else if ((left || right) ||
	         (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		if (down && this.isAnimationEnded())
			crouch = true;

		int direction;

		if ((angle > 330 && angle < 361) || (angle > -1 && angle < 30) ||
		        (angle > 150 && angle < 210))
		{
			direction = 0;
		}
		else if (aimpos.y < pos.y)
		{
			direction = -1;
		}
		else
		{
			direction = 1;
		}

		defaultIdleAnim(this, blob, direction);
	}

	//arm anims
	Vec2f armOffset = Vec2f(-1.0f, 4.0f + config_offset);
	const u8 arrowType = getArrowType(blob);

	if (firing || legolas)
	{
		f32 armangle = -angle;

		if (this.isFacingLeft())
		{
			armangle = 180.0f - angle;
		}

		while (armangle > 180.0f)
		{
			armangle -= 360.0f;
		}

		while (armangle < -180.0f)
		{
			armangle += 360.0f;
		}

		DrawBow(this, blob, archer, armangle, arrowType, armOffset);
	}
	else
	{
		setArmValues(this.getSpriteLayer("frontarm"), false, 0.0f, 0.1f, "fired", Vec2f(0, 0), armOffset);
		setArmValues(this.getSpriteLayer("backarm"), false, 0.0f, -0.1f, "default", Vec2f(0, 0), armOffset);
		setArmValues(this.getSpriteLayer("held arrow"), false, 0.0f, 0.5f, "default", Vec2f(0, 0), armOffset);
	}

	//set the shiny dot on the arrow

	CSpriteLayer@ shiny = this.getSpriteLayer(shiny_layer);
	if (shiny !is null)
	{
		shiny.SetVisible(needs_shiny);
		if (needs_shiny)
		{
			shiny.RotateBy(10, Vec2f());

			shiny_offset.RotateBy(this.isFacingLeft() ?  shiny_angle : -shiny_angle, Vec2f(3, -2));
			shiny.SetOffset(shiny_offset);
		}
	}

	DrawBowEffects(this, blob, archer, arrowType);

	//set the head anim
	if (knocked || crouch)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action1))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}


}

void DrawBow(CSprite@ this, CBlob@ blob, ArcherInfo@ archer, f32 armangle, const u8 arrowType, Vec2f armOffset)
{
	f32 sign = (this.isFacingLeft() ? 1.0f : -1.0f);
	CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");
	CSpriteLayer@ arrow = this.getSpriteLayer("held arrow");

	if (!archer.has_arrow || archer.charge_state == ArcherParams::no_arrows || archer.charge_state == ArcherParams::legolas_charging)
	{
		string animname = "no_arrow";

		if (archer.charge_time == ArcherParams::ready_time)
		{
			animname = "fired";
		}

		if (archer.charge_state != ArcherParams::legolas_charging)
		{
			u16 frontframe = 0;
			f32 temp = Maths::Min(archer.charge_time, ArcherParams::ready_time);
			f32 ready_tween = temp / ArcherParams::ready_time;
			armangle = armangle * ready_tween;
			armOffset = Vec2f(-1.0f, 4.0f + config_offset + 2.0f * (1.0f - ready_tween));
			setArmValues(frontarm, true, armangle, 0.1f, animname, Vec2f(-4.0f * sign, 0.0f), armOffset);
			frontarm.animation.frame = frontframe;

			setArmValues(arrow, false, 0, 0, "default", Vec2f(), Vec2f());
		}
	}
	else if (archer.charge_state == ArcherParams::readying)
	{
		u16 frontframe = 0;
		f32 temp = archer.charge_time;
		f32 ready_tween = temp / ArcherParams::ready_time;
		armangle = armangle * ready_tween;
		armOffset = Vec2f(-1.0f, 4.0f + config_offset + 2.0f * (1.0f - ready_tween));
		setArmValues(frontarm, true, armangle, 0.1f, "charge", Vec2f(-4.0f * sign, 0.0f), armOffset);
		frontarm.animation.frame = frontframe;
		f32 offsetChange = -5 + ready_tween * 5;

		setArmValues(arrow, true, armangle, 0.05f, "default", Vec2f((-12.0f)*sign, 0), armOffset + Vec2f(-8 + offsetChange, 0));
		arrow.animation.frame = arrowType;
	}
	else if (archer.charge_state != ArcherParams::fired || archer.charge_state == ArcherParams::legolas_ready)
	{
		u16 frontframe = Maths::Min((archer.charge_time / (ArcherParams::shoot_period_1 + 1)), 2);
		setArmValues(frontarm, true, armangle, 0.1f, "charge", Vec2f(-4.0f * sign, 0.0f), armOffset);
		frontarm.animation.frame = frontframe;

		const f32 arrowangle = (archer.charge_time > ArcherParams::shoot_period_2) ? armangle + -2.5f + float(XORRandom(500)) / 100.0f : armangle; // shiver arrow when fully charged
		const f32 frameOffset = 1.5f * float(frontframe);

		setArmValues(arrow, true, arrowangle, 0.05f, "default", Vec2f(-(12.0f - frameOffset)*sign, 0.0f), armOffset + Vec2f(-8 + frameOffset, 0));
		arrow.animation.frame = arrowType;

		if (archer.charge_state == ArcherParams::legolas_ready)
		{
			needs_shiny = true;
			shiny_offset = Vec2f(-13.0f, -2.5f);
			shiny_angle = arrowangle;
		}
	}
	else
	{
		setArmValues(frontarm, true, armangle, 0.1f, "fired", Vec2f(-4.0f * sign, 0.0f), armOffset);
		setArmValues(arrow, false, 0.0f, 0.5f, "default", Vec2f(0, 0), armOffset);
	}

	frontarm.SetRelativeZ(1.5f);
	arrow.SetRelativeZ(1.4f);
	setArmValues(this.getSpriteLayer("backarm"), true, armangle, -0.1f, "default", Vec2f(-4.0f * sign, 0.0f), armOffset);

	// fire arrow particles

	if (arrowType == ArrowType::fire && hasArrows(blob) && getGameTime() % 6 == 0)
	{
		Vec2f offset = Vec2f(12.0f, 0.0f);

		if (this.isFacingLeft())
		{
			offset.x = -offset.x;
		}

		offset.RotateBy(armangle);
		makeFireParticle(frontarm.getWorldTranslation() + offset, 4);
	}
}

void DrawBowEffects(CSprite@ this, CBlob@ blob, ArcherInfo@ archer, const u8 arrowType)
{
	// set fire light

	if (arrowType == ArrowType::fire)
	{
		if (IsFiring(blob) && hasArrows(blob))
		{
			blob.SetLight(true);
			blob.SetLightRadius(blob.getRadius() * 2.0f);
		}
		else
		{
			blob.SetLight(false);
		}
	}

	//quiver
	bool has_arrows = hasAnyArrows(blob);
	doQuiverUpdate(this, has_arrows, true);
}

bool IsFiring(CBlob@ blob)
{
	return blob.isKeyPressed(key_action1);
}

void doRopeUpdate(CSprite@ this, CBlob@ blob, ArcherInfo@ archer)
{
	CSpriteLayer@ rope = this.getSpriteLayer("rope");
	CSpriteLayer@ hook = this.getSpriteLayer("hook");

	bool visible = archer !is null && archer.grappling;

	rope.SetVisible(visible);
	hook.SetVisible(visible);
	if (!visible)
	{
		return;
	}

	Vec2f adjusted_pos = Vec2f(archer.grapple_pos.x, Maths::Max(0.0, archer.grapple_pos.y));
	Vec2f off = adjusted_pos - blob.getPosition();

	f32 ropelen = Maths::Max(0.1f, off.Length() / 32.0f);
	if (ropelen > 200.0f)
	{
		rope.SetVisible(false);
		hook.SetVisible(false);
		return;
	}

	rope.ResetTransform();
	rope.ScaleBy(Vec2f(ropelen, 1.0f));

	rope.TranslateBy(Vec2f(ropelen * 16.0f, 0.0f));

	rope.RotateBy(-off.Angle() , Vec2f());

	hook.ResetTransform();
	if (archer.grapple_id == 0xffff) //still in air
	{
		archer.cache_angle = -archer.grapple_vel.Angle();
	}
	hook.RotateBy(archer.cache_angle , Vec2f());

	hook.TranslateBy(off);
	hook.SetIgnoreParentFacing(true);
	hook.SetFacingLeft(false);

	//GUI::DrawLine(blob.getPosition(), archer.grapple_pos, SColor(255,255,255,255));
}

void doQuiverUpdate(CSprite@ this, bool has_arrows, bool quiver)
{
	CSpriteLayer@ quiverLayer = this.getSpriteLayer("quiver");
	CBlob@ blob = this.getBlob();

	if (quiverLayer !is null)
	{
		if (not this.isVisible()) {
			quiverLayer.SetVisible(false);
			return;
		}
		quiverLayer.SetVisible(true);

		if (quiver)
		{
			quiverLayer.SetVisible(true);
			f32 quiverangle = -45.0f;

			if (this.isFacingLeft())
			{
				quiverangle *= -1.0f;
			}

			//face the same way (force)
			quiverLayer.SetIgnoreParentFacing(true);
			quiverLayer.SetFacingLeft(this.isFacingLeft());

			int layer = 0;
			Vec2f head_offset = getHeadOffset(blob, -1, layer);

			bool down = (this.isAnimation("crouch") || this.isAnimation("dead"));
			bool easy = false;
			Vec2f off;
			if (layer != 0)
			{
				easy = true;
				off.Set(this.getFrameWidth() / 2, -this.getFrameHeight() / 2);
				off += this.getOffset();
				off += Vec2f(-head_offset.x, head_offset.y);


				f32 y = (down ? 3.0f : 7.0f);
				f32 x = (down ? 5.0f : 4.0f);
				off += Vec2f(x, y + config_offset);
			}

			if (easy)
			{
				quiverLayer.SetOffset(off);
			}

			quiverLayer.ResetTransform();
			quiverLayer.RotateBy(quiverangle, Vec2f(0.0f, 0.0f));

			if (has_arrows)
			{
				quiverLayer.animation.frame = 1;
			}
			else
			{
				quiverLayer.animation.frame = 0;
			}
		}
		else
		{
			quiverLayer.SetVisible(false);
		}
	}
}

void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}
