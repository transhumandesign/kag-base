// Knight animations

#include "KnightCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "Accolades.as"
#include "ShieldCommon.as"
#include "CrouchCommon.as";

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
		ensureCorrectRunnerTexture(this, "knight", "Knight");
		break;
	case PLAYER_ARMOUR_CAPE:
		ensureCorrectRunnerTexture(this, "knight_cape", "KnightCape");
		break;
	case PLAYER_ARMOUR_GOLD:
		ensureCorrectRunnerTexture(this, "knight_gold", "KnightGold");
		break;
	}

	string texname = getRunnerTextureName(this);

	// add blade
	this.RemoveSpriteLayer("chop");
	CSpriteLayer@ chop = this.addTexturedSpriteLayer("chop", this.getTextureName(), 32, 32);

	if (chop !is null)
	{
		Animation@ anim = chop.addAnimation("default", 0, true);
		anim.AddFrame(35);
		anim.AddFrame(43);
		anim.AddFrame(63);
		chop.SetVisible(false);
		chop.SetRelativeZ(1000.0f);
	}

	// add shiny
	this.RemoveSpriteLayer(shiny_layer);
	CSpriteLayer@ shiny = this.addSpriteLayer(shiny_layer, "AnimeShiny.png", 16, 16);

	if (shiny !is null)
	{
		Animation@ anim = shiny.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		shiny.SetVisible(false);
		shiny.SetRelativeZ(1.0f);
	}
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f aimpos;

	KnightInfo@ knight;
	if (!blob.get("knightInfo", @knight))
	{
		return;
	}

	bool knocked = isKnocked(blob);

	bool shieldState = isShieldState(knight.state);
	bool specialShieldState = isSpecialShieldState(knight.state);
	bool swordState = isSwordState(knight.state);

	bool pressed_a1 = blob.isKeyPressed(key_action1);
	bool pressed_a2 = blob.isKeyPressed(key_action2);

	bool walking = (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right));
	bool crouching = isCrouching(blob);

	aimpos = blob.getAimPos();
	bool inair = (!blob.isOnGround() && !blob.isOnLadder());

	Vec2f vel = blob.getVelocity();

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.RemoveSpriteLayer(shiny_layer);
			this.SetAnimation("dead");
		}
		Vec2f oldvel = blob.getOldVelocity();

		//TODO: trigger frame one the first time we server_Die()()
		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(1);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(3);
		}
		else
		{
			this.SetFrameIndex(2);
		}

		CSpriteLayer@ chop = this.getSpriteLayer("chop");

		if (chop !is null)
		{
			chop.SetVisible(false);
		}

		return;
	}

	// get the angle of aiming with mouse
	Vec2f vec;
	int direction = blob.getAimDirection(vec);

	// set facing
	bool facingLeft = this.isFacingLeft();
	// animations
	bool ended = this.isAnimationEnded() || this.isAnimation("shield_raised") || this.isAnimation("shield_crouched");
	bool wantsChopLayer = false;
	s32 chopframe = 0;
	f32 chopAngle = 0.0f;

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	bool shinydot = false;

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
		this.SetAnimation("crouch");
	}
	else
	{
		switch(knight.state)
		{
			case KnightStates::shieldgliding:
				this.SetAnimation("shield_glide");
			break;

			case KnightStates::shielddropping:
				this.SetAnimation("shield_drop");
			break;

			case KnightStates::resheathing_slash:
				this.SetAnimation("resheath_slash");
			break;
			
			case KnightStates::resheathing_cut:
				this.SetAnimation(crouching ? "draw_sword_crouched" : "draw_sword");
			break;

			case KnightStates::sword_cut_mid:
				this.SetAnimation("strike_mid");
			break;

			case KnightStates::sword_cut_mid_down:
				this.SetAnimation("strike_mid_down");
			break;

			case KnightStates::sword_cut_up:
				this.SetAnimation("strike_up");
			break;

			case KnightStates::sword_cut_down:
				this.SetAnimation("strike_down");
			break;

			case KnightStates::sword_power:
			case KnightStates::sword_power_super:
			{
				this.SetAnimation("strike_power");

				if (knight.swordTimer <= 1)
					this.animation.SetFrameIndex(0);

				u8 mintime = 6;
				u8 maxtime = 8;
				if (knight.swordTimer >= mintime && knight.swordTimer <= maxtime)
				{
					wantsChopLayer = true;
					chopframe = knight.swordTimer - mintime;
					chopAngle = -vec.Angle();
				}
			}
			break;

			case KnightStates::sword_drawn:
			{
				if (knight.swordTimer < KnightVars::slash_charge)
				{
					this.SetAnimation(crouching ? "draw_sword_crouched" : "draw_sword");
				}
				else if (knight.swordTimer < KnightVars::slash_charge_level2)
				{
					this.SetAnimation(crouching ? "strike_power_ready_crouched" : "strike_power_ready");
					this.animation.frame = 0;
				}
				else if (knight.swordTimer < KnightVars::slash_charge_limit)
				{
					this.SetAnimation(crouching ? "strike_power_ready_crouched" : "strike_power_ready");
					this.animation.frame = 1;
					shinydot = true;
				}
				else
				{
					this.SetAnimation(crouching ? "draw_sword_crouched" : "draw_sword");
				}
			}
			break;

			case KnightStates::shielding:
			{
				if (!isShieldEnabled(blob))
					break;

				if (walking)
				{
					if (direction == 0)
					{
						this.SetAnimation("shield_run");
					}
					else if (direction == -1)
					{
						this.SetAnimation("shield_run_up");
					}
					else if (direction == 1)
					{
						this.SetAnimation("shield_run_down");
					}
				}
				else
				{
					this.SetAnimation(crouching ? "shield_crouched" : "shield_raised");

					if (direction == 1)
					{
						this.animation.frame = 2;
					}
					else if (direction == -1)
					{
						if (vec.y > -0.97)
						{
							this.animation.frame = 1;
						}
						else
						{
							this.animation.frame = 3;
						}
					}
					else
					{
						this.animation.frame = 0;
					}
				}
			}
			break;

			default:
			{
				if (inair)
				{
					RunnerMoveVars@ moveVars;
					if (!blob.get("moveVars", @moveVars))
					{
						return;
					}
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
				else if (walking || 
					(blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down))))
				{
					this.SetAnimation("run");
				}
				else
				{
					defaultIdleAnim(this, blob, direction);
				}
			}
		}
	}

	CSpriteLayer@ chop = this.getSpriteLayer("chop");

	if (chop !is null)
	{
		chop.SetVisible(wantsChopLayer);
		if (wantsChopLayer)
		{
			f32 choplength = 5.0f;

			chop.animation.frame = chopframe;
			Vec2f offset = Vec2f(choplength, 0.0f);
			offset.RotateBy(chopAngle, Vec2f_zero);
			if (!this.isFacingLeft())
				offset.x *= -1.0f;
			offset.y += this.getOffset().y * 0.5f;

			chop.SetOffset(offset);
			chop.ResetTransform();
			if (this.isFacingLeft())
				chop.RotateBy(180.0f + chopAngle, Vec2f());
			else
				chop.RotateBy(chopAngle, Vec2f());
		}
	}

	//set the shiny dot on the sword

	CSpriteLayer@ shiny = this.getSpriteLayer(shiny_layer);

	if (shiny !is null)
	{
		shiny.SetVisible(shinydot);
		if (shinydot)
		{
			f32 range = (KnightVars::slash_charge_limit - KnightVars::slash_charge_level2);
			f32 count = (knight.swordTimer - KnightVars::slash_charge_level2);
			f32 ratio = count / range;
			shiny.RotateBy(10, Vec2f());
			shiny.SetOffset(Vec2f(12, -2 + ratio * 8));
		}
	}

	//set the head anim
	if (knocked)
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
	CParticle@ Body     = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}


// render cursors

void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	if (position == Vec2f_zero) return;
	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));
	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

const string cursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (blob.isKeyPressed(key_action1))
	{
		CMap@ map = blob.getMap();
		Vec2f position = blob.getPosition();
		Vec2f cursor_position = blob.getAimPos();
		Vec2f surface_position;
		map.rayCastSolid(position, cursor_position, surface_position);
		Vec2f vector = surface_position - position;
		f32 distance = vector.getLength();
		Tile tile = map.getTile(surface_position);

		if ((map.isTileSolid(tile) || map.isTileGrass(tile.type)) && map.getSectorAtPosition(surface_position, "no build") is null && distance < 16.0f)
		{
			DrawCursorAt(surface_position, cursorTexture);
		}
	}
}
