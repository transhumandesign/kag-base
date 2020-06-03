// Knight logic

#include "ThrowCommon.as"
#include "KnightCommon.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "ShieldCommon.as";
#include "KnockedCommon.as"
#include "Help.as";
#include "Requirements.as"


//attacks limited to the one time per-actor before reset.

void knight_actorlimit_setup(CBlob@ this)
{
	u16[] networkIDs;
	this.set("LimitedActors", networkIDs);
}

bool knight_has_hit_actor(CBlob@ this, CBlob@ actor)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.find(actor.getNetworkID()) >= 0;
}

u32 knight_hit_actor_count(CBlob@ this)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.length;
}

void knight_add_actor_limit(CBlob@ this, CBlob@ actor)
{
	this.push("LimitedActors", actor.getNetworkID());
}

void knight_clear_actor_limits(CBlob@ this)
{
	this.clear("LimitedActors");
}

void onInit(CBlob@ this)
{
	KnightInfo knight;

	knight.state = KnightStates::normal;
	knight.swordTimer = 0;
	knight.slideTime = 0;
	knight.doubleslash = false;
	knight.shield_down = getGameTime();
	knight.tileDestructionLimiter = 0;

	this.set("knightInfo", @knight);

	KnightState@[] states;
	states.push_back(NormalState());
	states.push_back(ShieldingState());
	states.push_back(ShieldGlideState());
	states.push_back(ShieldSlideState());
	states.push_back(SwordDrawnState());
	states.push_back(CutState(KnightStates::sword_cut_up));
	states.push_back(CutState(KnightStates::sword_cut_mid));
	states.push_back(CutState(KnightStates::sword_cut_mid_down));
	states.push_back(CutState(KnightStates::sword_cut_mid));
	states.push_back(CutState(KnightStates::sword_cut_down));
	states.push_back(SlashState(KnightStates::sword_power));
	states.push_back(SlashState(KnightStates::sword_power_super));
	states.push_back(ResheathState(KnightStates::resheathing_cut, KnightVars::resheath_cut_time));
	states.push_back(ResheathState(KnightStates::resheathing_slash, KnightVars::resheath_slash_time));

	this.set("knightStates", @states);
	this.set_s32("currentKnightState", 0);

	this.set_f32("gib health", -1.5f);
	addShieldVars(this, SHIELD_BLOCK_ANGLE, 2.0f, 5.0f);
	knight_actorlimit_setup(this);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.Tag("player");
	this.Tag("flesh");

	this.addCommandID("get bomb");

	this.push("names to activate", "keg");

	this.set_u8("bomb type", 255);
	for (uint i = 0; i < bombTypeNames.length; i++)
	{
		this.addCommandID("pick " + bombTypeNames[i]);
	}

	//centered on bomb select
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on inventory
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	SetHelp(this, "help self action", "knight", getTranslatedString("$Jab$Jab        $LMB$"), "", 4);
	SetHelp(this, "help self action2", "knight", getTranslatedString("$Shield$Shield    $KEY_HOLD$$RMB$"), "", 4);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 3, Vec2f(16, 16));
	}
}


void RunStateMachine(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
{
	KnightState@[]@ states;
	if (!this.get("knightStates", @states))
	{
		return;
	}

	s32 currentStateIndex = this.get_s32("currentKnightState");
	u8 state = knight.state;
	KnightState@ currentState = states[currentStateIndex];

	bool tickNext = false;
	tickNext = currentState.TickState(this, knight, moveVars);
	if (state != knight.state)
	{
		if (this.getPlayer().getUsername() == "Verrazano")
		{
			print(this.getPlayer().getUsername() + " oldState: " + state + " newState: " + knight.state);
			print("currentIndex: " + currentStateIndex);
		}

		for (s32 i = 0; i < states.size(); i++)
		{
			if (states[i].getStateValue() == knight.state)
			{
				s32 nextStateIndex = i;
				KnightState@ nextState = states[nextStateIndex];
				currentState.StateExited(this, knight, nextState.getStateValue());
				nextState.StateEntered(this, knight, currentState.getStateValue());
				this.set_s32("currentKnightState", nextStateIndex);
				if (tickNext)
				{
					RunStateMachine(this, knight, moveVars);

				}
				break;
			}
		}
	}
}

void onTick(CBlob@ this)
{
	bool knocked = isKnocked(this);
	CHUD@ hud = getHUD();

	//knight logic stuff
	//get the vars to turn various other scripts on/off
	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	KnightInfo@ knight;
	if (!this.get("knightInfo", @knight))
	{
		return;
	}

	if (this.isInInventory())
	{
		//prevent players from insta-slashing when exiting crates
		knight.state = 0;
		knight.swordTimer = 0;
		knight.slideTime = 0;
		knight.doubleslash = false;
		hud.SetCursorFrame(0);
		this.set_s32("currentKnightState", 0);
		return;
	}

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f aimpos = this.getAimPos();
	const bool inair = (!this.isOnGround() && !this.isOnLadder());

	Vec2f vec;

	const int direction = this.getAimDirection(vec);
	const f32 side = (this.isFacingLeft() ? 1.0f : -1.0f);
	bool shieldState = isShieldState(knight.state);
	bool specialShieldState = isSpecialShieldState(knight.state);
	bool swordState = isSwordState(knight.state);
	bool pressed_a1 = this.isKeyPressed(key_action1);
	bool pressed_a2 = this.isKeyPressed(key_action2);
	bool walking = (this.isKeyPressed(key_left) || this.isKeyPressed(key_right));

	const bool myplayer = this.isMyPlayer();

	if (getNet().isClient() && !this.isInInventory() && myplayer)  //Knight charge cursor
	{
		SwordCursorUpdate(this, knight);
	}

	if (knocked)// || myplayer && getHUD().hasMenus())
	{
		knight.state = KnightStates::normal; //cancel any attacks or shielding
		knight.swordTimer = 0;
		knight.slideTime = 0;
		knight.doubleslash = false;
		this.set_s32("currentKnightState", 0);

		pressed_a1 = false;
		pressed_a2 = false;
		walking = false;

	}
	else
	{
		RunStateMachine(this, knight, moveVars);

	}


	/* else if (!pressed_a1 && !swordState &&
	         (pressed_a2 || (specialShieldState)))
	{
		print("shielding");
		moveVars.jumpFactor *= 0.5f;
		moveVars.walkFactor *= 0.9f;
		knight.swordTimer = 0;

		if (!canRaiseShield(this))
		{
			if (knight.state != KnightStates::normal)
			{
				knight.shield_down = getGameTime() + 40;
			}

			knight.state = KnightStates::normal;

			if (pressed_a2 && ((knight.shield_down - getGameTime()) <= 0))
			{
				resetShieldKnockdown(this);   //re-put up the shield
			}
		}
		else
		{
			bool forcedrop = (vel.y > Maths::Max(Maths::Abs(vel.x), 2.0f) &&
			                  moveVars.fallCount > KnightVars::glide_down_time);

			if (pressed_a2 && inair && !this.isInWater())
			{
				if (direction == -1 && !forcedrop && !getMap().isInWater(pos + Vec2f(0, 16)) && !moveVars.wallsliding)
				{
					knight.state = KnightStates::shieldgliding;
				}
				else if (forcedrop || direction == 1)
				{
					knight.state = KnightStates::shielddropping;
					knight.slideTime = 0;
				}
				else //remove this for partial locking in mid air
				{
					knight.state = KnightStates::shielding;
				}
			}

			if (knight.state == KnightStates::shieldgliding && !this.isInWater() && !forcedrop)
			{
				moveVars.stoppingFactor *= 0.5f;

				f32 glide_amount = 1.0f - (moveVars.fallCount / f32(KnightVars::glide_down_time * 2));

				if (vel.y > -1.0f)
				{
					this.AddForce(Vec2f(0, -20.0f * glide_amount));
				}

				if (!inair || !pressed_a2)
				{
					knight.state = KnightStates::shielding;
				}
			}
			else if (knight.state == KnightStates::shielddropping)
			{
				if (this.isInWater())
				{
					if (vel.y > 1.5f && Maths::Abs(vel.x) * 3 > Maths::Abs(vel.y))
					{
						vel.y = Maths::Max(-Maths::Abs(vel.y) + 1.0f, -8.0);
						this.setVelocity(vel);
					}
					else
					{
						knight.state = KnightStates::shielding;
					}
				}

				// shield sliding and end of slide
				if ((!inair && this.getShape().vellen < 1.0f) || !pressed_a2)
				{
					knight.state = KnightStates::shielding;
				}
				else
				{
					// faster sliding
					if (!inair)
					{
						knight.slideTime++;
						if (knight.slideTime > 0)
						{
							if (knight.slideTime == 5)
							{
								this.getSprite().PlayRandomSound("/Scrape");
							}

							f32 factor = Maths::Max(1.0f, 2.2f / Maths::Sqrt(knight.slideTime));
							moveVars.walkFactor *= factor;

							//  printf("knight.slideTime = " + knight.slideTime  );
							if (knight.slideTime > 30)
							{
								moveVars.walkFactor *= 0.75f;
								if (knight.slideTime > 45)
								{
									knight.state = KnightStates::shielding;
								}
							}
							else if (XORRandom(3) == 0)
							{
								Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
								velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;
								ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);
							}
						}
					}
					else if (vel.y > 1.05f)
					{
						knight.slideTime = 0;
						//printf("vel.y  " + vel.y  );
					}
				}
			}
			else
			{
				knight.state = KnightStates::shielding;
			}
		}
	}
	else if ((pressed_a1 || swordState) && !moveVars.wallsliding)   //no attacking during a slide
	{
		if (getNet().isClient())
		{
			if (knight.swordTimer == KnightVars::slash_charge_level2)
			{
				Sound::Play("AnimeSword.ogg", pos, myplayer ? 1.3f : 0.7f);
			}
			else if (knight.swordTimer == KnightVars::slash_charge)
			{
				Sound::Play("SwordSheath.ogg", pos, myplayer ? 1.3f : 0.7f);
			}
		}

		if (knight.swordTimer >= KnightVars::slash_charge_limit)
		{
			Sound::Play("/Stun", pos, 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
			setKnocked(this, 15);
		}

		bool strong = (knight.swordTimer > KnightVars::slash_charge_level2);
		moveVars.jumpFactor *= (strong ? 0.6f : 0.8f);
		moveVars.walkFactor *= (strong ? 0.8f : 0.9f);

		if (!inair)
		{
			this.AddForce(Vec2f(vel.x * -5.0, 0.0f));   //horizontal slowing force (prevents SANICS)
		}

		// TODO: buffer inputs while resheathing so we don't go back to a shield state if jab spamming
		if ((knight.state == KnightStates::normal || shieldState) &&
		        this.isKeyJustPressed(key_action1))
		{
			print("start charging");
			knight.state = KnightStates::sword_drawn;
			knight.swordTimer = 0;
		}

		if (knight.state == KnightStates::sword_drawn && getNet().isServer())
		{
			knight_clear_actor_limits(this);
		}

		//responding to releases/noaction
		s32 delta = knight.swordTimer;
		print("delta: " + delta);
		if (knight.swordTimer < 128)
			knight.swordTimer++;

		if(knight.state == KnightStates::resheathing_cut && delta >= KnightVars::resheath_cut_time)
		{
			print("resheathed cut");
			delta = 0;
			knight.state = KnightStates::normal;
		}
		else if(knight.state == KnightStates::resheathing_slash && delta >= KnightVars::resheath_slash_time)
		{
			print("resheathed slash");
			delta = 0;
			knight.state = KnightStates::normal;
		}
		else if (this.isKeyJustReleased(key_action1) && knight.state == KnightStates::sword_drawn)
		{
			knight.swordTimer = 0;

			if (delta < KnightVars::slash_charge)
			{
				print("jabbing");
				if (direction == -1)
				{
					knight.state = KnightStates::sword_cut_up;
				}
				else if (direction == 0)
				{
					if (aimpos.y < pos.y)
					{
						knight.state = KnightStates::sword_cut_mid;
					}
					else
					{
						knight.state = KnightStates::sword_cut_mid_down;
					}
				}
				else
				{
					knight.state = KnightStates::sword_cut_down;
				}
			}
			else if (delta < KnightVars::slash_charge_level2)
			{
				print("slashing");
				knight.state = KnightStates::sword_power;
				Vec2f aiming_direction = vel;
				aiming_direction.y *= 2;
				aiming_direction.Normalize();
				knight.slash_direction = aiming_direction;
			}
			else if (delta < KnightVars::slash_charge_limit)
			{
				knight.state = KnightStates::sword_power_super;
				Vec2f aiming_direction = vel;
				aiming_direction.y *= 2;
				aiming_direction.Normalize();
				knight.slash_direction = aiming_direction;
			}
			else
			{
				//knock?
			}
		}
		else if (knight.state >= KnightStates::sword_cut_mid &&
		         knight.state <= KnightStates::sword_cut_down) // cut state
		{
			this.Tag("prevent crouch");

			if (delta == DELTA_BEGIN_ATTACK)
			{
				Sound::Play("/SwordSlash", this.getPosition());
			}

			if (delta > DELTA_BEGIN_ATTACK && delta < DELTA_END_ATTACK)
			{
				f32 attackarc = 90.0f;
				f32 attackAngle = getCutAngle(this, knight.state);

				if (knight.state == KnightStates::sword_cut_down)
				{
					attackarc *= 0.9f;
				}

				DoAttack(this, 1.0f, attackAngle, attackarc, Hitters::sword, delta, knight);
			}
			else if (delta >= 9)
			{
				print("jab finished");
				knight.swordTimer = 0;
				knight.state = KnightStates::resheathing_cut;
			}
		}
		else if (knight.state == KnightStates::sword_power ||
		         knight.state == KnightStates::sword_power_super)
		{
			this.Tag("prevent crouch");

			//setting double
			if (knight.state == KnightStates::sword_power_super &&
			        this.isKeyJustPressed(key_action1))
			{
				knight.doubleslash = true;
			}

			//attacking + noises
			if (delta == 2)
			{
				Sound::Play("/ArgLong", this.getPosition());
				Sound::Play("/SwordSlash", this.getPosition());
			}
			else if (delta > DELTA_BEGIN_ATTACK && delta < 10)
			{
				DoAttack(this, 2.0f, -(vec.Angle()), 120.0f, Hitters::sword, delta, knight);
			}
			else if (delta >= KnightVars::slash_time ||
			         (knight.doubleslash && delta >= KnightVars::double_slash_time))
			{
				knight.swordTimer = 0;

				if (knight.doubleslash)
				{
					knight_clear_actor_limits(this);
					knight.doubleslash = false;
					knight.state = KnightStates::sword_power;
				}
				else
				{
					print("finishing slash");
					knight.state = KnightStates::resheathing_slash;
				}
			}
		}

		//special slash movement

		if ((knight.state == KnightStates::sword_power ||
		        knight.state == KnightStates::sword_power_super) &&
		        delta < KnightVars::slash_move_time)
		{

			if (Maths::Abs(vel.x) < KnightVars::slash_move_max_speed &&
			        vel.y > -KnightVars::slash_move_max_speed)
			{
				Vec2f slash_vel =  knight.slash_direction * this.getMass() * 0.5f;
				this.AddForce(slash_vel);
			}
		}

		moveVars.canVault = false;

	}
	else if (this.isKeyJustReleased(key_action2) || this.isKeyJustReleased(key_action1) || this.get_u32("knight_timer") <= getGameTime())
	{
		knight.state = KnightStates::normal;
	}*/

	//throwing bombs

	if (myplayer)
	{
		// space

		if (this.isKeyJustPressed(key_action3))
		{
			CBlob@ carried = this.getCarriedBlob();
			bool holding = carried !is null;// && carried.hasTag("exploding");

			CInventory@ inv = this.getInventory();
			bool thrown = false;
			u8 bombType = this.get_u8("bomb type");
			if (bombType == 255)
			{
				SetFirstAvailableBomb(this);
				bombType = this.get_u8("bomb type");
			}
			if (bombType < bombTypeNames.length)
			{
				for (int i = 0; i < inv.getItemsCount(); i++)
				{
					CBlob@ item = inv.getItem(i);
					const string itemname = item.getName();
					if (!holding && bombTypeNames[bombType] == itemname)
					{
						if (bombType >= 2)
						{
							this.server_Pickup(item);
							client_SendThrowOrActivateCommand(this);
							thrown = true;
						}
						else
						{
							CBitStream params;
							params.write_u8(bombType);
							this.SendCommand(this.getCommandID("get bomb"), params);
							thrown = true;
						}
						break;
					}
				}
			}

			if (!thrown)
			{
				client_SendThrowOrActivateCommand(this);
				SetFirstAvailableBomb(this);
			}
		}

		// help

		if (this.isKeyJustPressed(key_action1) && getGameTime() > 150)
		{
			SetHelp(this, "help self action", "knight", getTranslatedString("$Slash$ Slash!    $KEY_HOLD$$LMB$"), "", 13);
		}
	}

	//setting the shield direction properly
	if (shieldState)
	{
		int horiz = this.isFacingLeft() ? -1 : 1;
		setShieldEnabled(this, true);

		setShieldAngle(this, SHIELD_BLOCK_ANGLE);

		if (specialShieldState)
		{
			if (knight.state == KnightStates::shieldgliding)
			{
				setShieldDirection(this, Vec2f(0, -1));
				setShieldAngle(this, SHIELD_BLOCK_ANGLE_GLIDING);
			}
			else //shield dropping
			{
				setShieldDirection(this, Vec2f(horiz, 2));
				setShieldAngle(this, SHIELD_BLOCK_ANGLE_SLIDING);
			}
			this.Tag("prevent crouch");
		}
		else if (walking)
		{
			if (direction == 0) //forward
			{
				setShieldDirection(this, Vec2f(horiz, 0));
			}
			else if (direction == 1)   //down
			{
				setShieldDirection(this, Vec2f(horiz, 3));
			}
			else
			{
				setShieldDirection(this, Vec2f(horiz, -3));
			}

			this.Tag("prevent crouch");
		}
		else
		{
			if (direction == 0)   //forward
			{
				setShieldDirection(this, Vec2f(horiz, 0));
			}
			else if (direction == 1)   //down
			{
				setShieldDirection(this, Vec2f(horiz, 3));
			}
			else //up
			{
				if (vec.y < -0.97)
				{
					setShieldDirection(this, Vec2f(0, -1));
				}
				else
				{
					setShieldDirection(this, Vec2f(horiz, -3));
				}
			}
		}

		// shield up = collideable

		if ((knight.state == KnightStates::shielding && direction == -1) ||
		        knight.state == KnightStates::shieldgliding)
		{
			if (!this.hasTag("shieldplatform"))
			{
				this.getShape().checkCollisionsAgain = true;
				this.Tag("shieldplatform");
			}
		}
		else
		{
			if (this.hasTag("shieldplatform"))
			{
				this.getShape().checkCollisionsAgain = true;
				this.Untag("shieldplatform");
			}
		}
	}
	else
	{
		setShieldEnabled(this, false);

		if (this.hasTag("shieldplatform"))
		{
			this.getShape().checkCollisionsAgain = true;
			this.Untag("shieldplatform");
		}
	}

	if (!swordState && getNet().isServer())
	{
		knight_clear_actor_limits(this);
	}


}

bool getInAir(CBlob@ this)
{
	bool inair = (!this.isOnGround() && !this.isOnLadder());
	return inair;

}

class NormalState : KnightState
{
	u8 getStateValue() { return KnightStates::normal; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight.swordTimer = 0;
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (this.isKeyPressed(key_action1) && !moveVars.wallsliding)
		{
			knight.state = KnightStates::sword_drawn;
			return true;
		}
		else if (this.isKeyPressed(key_action2))
		{
			if (canRaiseShield(this))
			{
				knight.state = KnightStates::shielding;
				return true;
			}
			else
			{
				resetShieldKnockdown(this);
			}

		}

		return false;
	}
}

void ShieldMovement(RunnerMoveVars@ moveVars)
{
	moveVars.jumpFactor *= 0.5f;
	moveVars.walkFactor *= 0.9f;
}

bool getForceDrop(CBlob@ this, RunnerMoveVars@ moveVars)
{
	Vec2f vel = this.getVelocity();
	bool forcedrop = (vel.y > Maths::Max(Maths::Abs(vel.x), 2.0f) &&
					  moveVars.fallCount > KnightVars::glide_down_time);
	return forcedrop;
}

class ShieldingState : KnightState
{
	u8 getStateValue() { return KnightStates::shielding; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight.swordTimer = 0;
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (this.isKeyPressed(key_action1))
		{
			knight.state = KnightStates::sword_drawn;
			return true;
		}
		else if (!this.isKeyPressed(key_action2))
		{
			knight.state = KnightStates::normal;
			return false;
		}

		Vec2f pos = this.getPosition();
		bool forcedrop = getForceDrop(this, moveVars);

		bool inair = getInAir(this);
		if (inair && !this.isInWater())
		{
			Vec2f vec;
			const int direction = this.getAimDirection(vec);
			if (direction == -1 && !forcedrop && !getMap().isInWater(pos + Vec2f(0, 16)) && !moveVars.wallsliding)
			{
				knight.state = KnightStates::shieldgliding;
				return true;
			}
			else if (forcedrop || direction == 1)
			{
				knight.state = KnightStates::shielddropping;
				return true;
			}
		}

		ShieldMovement(moveVars);

		return false;
	}
}

class ShieldGlideState : KnightState
{
	u8 getStateValue() { return KnightStates::shieldgliding; }
	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (this.isKeyPressed(key_action1))
		{
			knight.state = KnightStates::sword_drawn;
			return true;
		}

		ShieldMovement(moveVars);

		Vec2f pos = this.getPosition();
		bool forcedrop = getForceDrop(this, moveVars);

		if (this.isInWater() || forcedrop)
		{
			knight.state = KnightStates::shielding;
		}
		else
		{
			Vec2f vel = this.getVelocity();
			bool inair = getInAir(this);

			moveVars.stoppingFactor *= 0.5f;
			f32 glide_amount = 1.0f - (moveVars.fallCount / f32(KnightVars::glide_down_time * 2));

			if (vel.y > -1.0f)
			{
				this.AddForce(Vec2f(0, -20.0f * glide_amount));
			}

			if ( !this.isKeyPressed(key_action2) )
			{
				knight.state = KnightStates::normal;

			}
			else if (!inair)
			{
				knight.state = KnightStates::shielding;
			}

		}

		return false;
	}
}

class ShieldSlideState : KnightState
{
	u8 getStateValue() { return KnightStates::shielddropping; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight.slideTime = 0;
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (this.isKeyPressed(key_action1))
		{
			knight.state = KnightStates::sword_drawn;
			return true;
		}

		ShieldMovement(moveVars);

		Vec2f vel = this.getVelocity();

		if (this.isInWater())
		{
			if (vel.y > 1.5f && Maths::Abs(vel.x) * 3 > Maths::Abs(vel.y))
			{
				vel.y = Maths::Max(-Maths::Abs(vel.y) + 1.0f, -8.0);
				this.setVelocity(vel);
			}
			else
			{
				knight.state = KnightStates::shielding;
			}
		}

		bool inair = getInAir(this);

		if (!this.isKeyPressed(key_action2))
		{
			knight.state = KnightStates::normal;
		}
		else if (!inair && this.getShape().vellen < 1.0f)
		{
			knight.state = KnightStates::shielding;
		}
		else
		{
			// faster sliding
			if (!inair)
			{
				knight.slideTime++;
				if (knight.slideTime > 0)
				{
					if (knight.slideTime == 5)
					{
						this.getSprite().PlayRandomSound("/Scrape");
					}

					f32 factor = Maths::Max(1.0f, 2.2f / Maths::Sqrt(knight.slideTime));
					moveVars.walkFactor *= factor;

					if (knight.slideTime > 30)
					{
						moveVars.walkFactor *= 0.75f;
						if (knight.slideTime > 45)
						{
							knight.state = KnightStates::shielding;
						}
					}
					else if (XORRandom(3) == 0)
					{
						Vec2f pos = this.getPosition();
						Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
						velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;
						ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);
					}
				}
			}
			else if (vel.y > 1.05f)
			{
				knight.slideTime = 0;
			}

		}

		return false;

	}
}

s32 getSwordTimerDelta(KnightInfo@ knight)
{
	s32 delta = knight.swordTimer;
	if (knight.swordTimer < 128)
	{
		knight.swordTimer++;
	}
	return delta;
}

void AttackMovement(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
{
	Vec2f vel = this.getVelocity();

	bool strong = (knight.swordTimer > KnightVars::slash_charge_level2);
	moveVars.jumpFactor *= (strong ? 0.6f : 0.8f);
	moveVars.walkFactor *= (strong ? 0.8f : 0.9f);

	bool inair = getInAir(this);
	if (!inair)
	{
		this.AddForce(Vec2f(vel.x * -5.0, 0.0f));   //horizontal slowing force (prevents SANICS)
	}
}

class SwordDrawnState : KnightState
{
	u8 getStateValue() { return KnightStates::sword_drawn; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight.swordTimer = 0;
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (moveVars.wallsliding)
		{
			knight.state = KnightStates::normal;
			return false;

		}

		Vec2f pos = this.getPosition();

		if (getNet().isClient())
		{
			const bool myplayer = this.isMyPlayer();
			if (knight.swordTimer == KnightVars::slash_charge_level2)
			{
				Sound::Play("AnimeSword.ogg", pos, myplayer ? 1.3f : 0.7f);
			}
			else if (knight.swordTimer == KnightVars::slash_charge)
			{
				Sound::Play("SwordSheath.ogg", pos, myplayer ? 1.3f : 0.7f);
			}
		}

		if (knight.swordTimer >= KnightVars::slash_charge_limit)
		{
			Sound::Play("/Stun", pos, 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
			setKnocked(this, 15);
			knight.state = KnightStates::normal;
		}

		AttackMovement(this, knight, moveVars);
		s32 delta = getSwordTimerDelta(knight);

		if (this.isKeyJustReleased(key_action1))
		{
			if (delta < KnightVars::slash_charge)
			{
				Vec2f vec;
				const int direction = this.getAimDirection(vec);

				if (direction == -1)
				{
					knight.state = KnightStates::sword_cut_up;
				}
				else if (direction == 0)
				{
					Vec2f aimpos = this.getAimPos();
					Vec2f pos = this.getPosition();
					if (aimpos.y < pos.y)
					{
						knight.state = KnightStates::sword_cut_mid;
					}
					else
					{
						knight.state = KnightStates::sword_cut_mid_down;
					}
				}
				else
				{
					knight.state = KnightStates::sword_cut_down;
				}
			}
			else if (delta < KnightVars::slash_charge_level2)
			{
				knight.state = KnightStates::sword_power;
			}
			else if(delta < KnightVars::slash_charge_limit)
			{
				knight.state = KnightStates::sword_power_super;
			}
		}

		return false;
	}
}

class CutState : KnightState
{
	u8 state;
	CutState(u8 s) { state = s; }
	u8 getStateValue() { return state; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight_clear_actor_limits(this);
		knight.swordTimer = 0;
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (moveVars.wallsliding)
		{
			knight.state = KnightStates::normal;
			return false;

		}

		this.Tag("prevent crouch");

		AttackMovement(this, knight, moveVars);
		s32 delta = getSwordTimerDelta(knight);

		if (delta == DELTA_BEGIN_ATTACK)
		{
			Sound::Play("/SwordSlash", this.getPosition());
		}
		else if (delta > DELTA_BEGIN_ATTACK && delta < DELTA_END_ATTACK)
		{
			f32 attackarc = 90.0f;
			f32 attackAngle = getCutAngle(this, knight.state);

			if (knight.state == KnightStates::sword_cut_down)
			{
				attackarc *= 0.9f;
			}

			DoAttack(this, 1.0f, attackAngle, attackarc, Hitters::sword, delta, knight);
		}
		else if (delta >= 9)
		{
			knight.state = KnightStates::resheathing_cut;
		}

		return false;

	}
}

Vec2f getSlashDirection(CBlob@ this)
{
	Vec2f vel = this.getVelocity();
	Vec2f aiming_direction = vel;
	aiming_direction.y *= 2;
	aiming_direction.Normalize();

	return aiming_direction;
}

class SlashState : KnightState
{
	u8 state;
	SlashState(u8 s) { state = s; }
	u8 getStateValue() { return state; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight_clear_actor_limits(this);
		knight.swordTimer = 0;
		knight.slash_direction = getSlashDirection(this);
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (moveVars.wallsliding)
		{
			knight.state = KnightStates::normal;
			return false;

		}

		this.Tag("prevent crouch");

		AttackMovement(this, knight, moveVars);
		s32 delta = getSwordTimerDelta(knight);

		if (knight.state == KnightStates::sword_power_super
			&& this.isKeyJustPressed(key_action1))
		{
			knight.doubleslash = true;
		}

		if (delta == 2)
		{
			Sound::Play("/ArgLong", this.getPosition());
			Sound::Play("/SwordSlash", this.getPosition());
		}
		else if (delta > DELTA_BEGIN_ATTACK && delta < 10)
		{
			Vec2f vec;
			this.getAimDirection(vec);

			DoAttack(this, 2.0f, -(vec.Angle()), 120.0f, Hitters::sword, delta, knight);
		}
		else if (delta >= KnightVars::slash_time
			|| (knight.doubleslash && delta >= KnightVars::double_slash_time))
		{
			if (knight.doubleslash)
			{
				knight.doubleslash = false;
				knight.state = KnightStates::sword_power;
			}
			else
			{
				knight.state = KnightStates::resheathing_slash;
			}
		}

		Vec2f vel = this.getVelocity();
		if ((knight.state == KnightStates::sword_power ||
				knight.state == KnightStates::sword_power_super) &&
				delta < KnightVars::slash_move_time)
		{

			if (Maths::Abs(vel.x) < KnightVars::slash_move_max_speed &&
					vel.y > -KnightVars::slash_move_max_speed)
			{
				Vec2f slash_vel =  knight.slash_direction * this.getMass() * 0.5f;
				this.AddForce(slash_vel);
			}
		}

		moveVars.canVault = false;

		return false;

	}
}

class ResheathState : KnightState
{
	u8 state;
	s32 time;
	ResheathState(u8 s, s32 t) { state = s; time = t; }
	u8 getStateValue() { return state; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state)
	{
		knight.swordTimer = 0;
	}

	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars)
	{
		if (moveVars.wallsliding)
		{
			knight.state = KnightStates::normal;
			return false;

		}

		AttackMovement(this, knight, moveVars);
		s32 delta = getSwordTimerDelta(knight);

		if (delta >= time)
		{
			knight.state = KnightStates::normal;
		}

		return false;
	}
}

void SwordCursorUpdate(CBlob@ this, KnightInfo@ knight)
{
		if (knight.swordTimer >= KnightVars::slash_charge_level2 || knight.doubleslash || knight.state == KnightStates::sword_power_super)
		{
			getHUD().SetCursorFrame(19);
		}
		else if (knight.swordTimer >= KnightVars::slash_charge)
		{
			int frame = 1 + int((float(knight.swordTimer - KnightVars::slash_charge) / (KnightVars::slash_charge_level2 - KnightVars::slash_charge)) * 9) * 2;
			getHUD().SetCursorFrame(frame);
		}
		// the yellow circle stays for the duration of a slash, helpful for newplayers (note: you cant attack while its yellow)
		else if (knight.state == KnightStates::normal) // disappear after slash is done
		// the yellow circle dissapears after mouse button release, more intuitive for improving slash timing
		// else if (knight.swordTimer == 0) (disappear right after mouse release)
		{
			getHUD().SetCursorFrame(0);
		}
		else if (knight.swordTimer < KnightVars::slash_charge && knight.state == KnightStates::sword_drawn)
		{
			int frame = 2 + int((float(knight.swordTimer) / KnightVars::slash_charge) * 8) * 2;
			if (knight.swordTimer <= KnightVars::resheath_cut_time) //prevent from appearing when jabbing/jab spamming
			{
				getHUD().SetCursorFrame(0);
			}
			else
			{
				getHUD().SetCursorFrame(frame);
			}
		}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("get bomb"))
	{
		const u8 bombType = params.read_u8();
		if (bombType >= bombTypeNames.length)
			return;

		const string bombTypeName = bombTypeNames[bombType];
		this.Tag(bombTypeName + " done activate");
		if (hasItem(this, bombTypeName))
		{
			if (bombType == 0)
			{
				if (getNet().isServer())
				{
					CBlob @blob = server_CreateBlob("bomb", this.getTeamNum(), this.getPosition());
					if (blob !is null)
					{
						TakeItem(this, bombTypeName);
						this.server_Pickup(blob);
					}
				}
			}
			else if (bombType == 1)
			{
				if (getNet().isServer())
				{
					CBlob @blob = server_CreateBlob("waterbomb", this.getTeamNum(), this.getPosition());
					if (blob !is null)
					{
						TakeItem(this, bombTypeName);
						this.server_Pickup(blob);
						blob.set_f32("map_damage_ratio", 0.0f);
						blob.set_f32("explosive_damage", 0.0f);
						blob.set_f32("explosive_radius", 92.0f);
						blob.set_bool("map_damage_raycast", false);
						blob.set_string("custom_explosion_sound", "/GlassBreak");
						blob.set_u8("custom_hitter", Hitters::water);
                        blob.Tag("splash ray cast");

					}
				}
			}
			else
			{
			}

			SetFirstAvailableBomb(this);
		}
	}
	else if (cmd == this.getCommandID("cycle"))  //from standardcontrols
	{
		// cycle arrows
		u8 type = this.get_u8("bomb type");
		int count = 0;
		while (count < bombTypeNames.length)
		{
			type++;
			count++;
			if (type >= bombTypeNames.length)
				type = 0;
			if (this.getBlobCount(bombTypeNames[type]) > 0)
			{
				this.set_u8("bomb type", type);
				if (this.isMyPlayer())
				{
					Sound::Play("/CycleInventory.ogg");
				}
				break;
			}
		}
	}
	else if (cmd == this.getCommandID("activate/throw"))
	{
		SetFirstAvailableBomb(this);
	}
	else
	{
		for (uint i = 0; i < bombTypeNames.length; i++)
		{
			if (cmd == this.getCommandID("pick " + bombTypeNames[i]))
			{
				this.set_u8("bomb type", i);
				break;
			}
		}
	}
}

/////////////////////////////////////////////////

bool isJab(f32 damage)
{
	return damage < 1.5f;
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type, int deltaInt, KnightInfo@ info)
{
	if (!getNet().isServer())
	{
		return;
	}

	if (aimangle < 0.0f)
	{
		aimangle += 360.0f;
	}

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateBy(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 attack_distance = Maths::Min(DEFAULT_ATTACK_DISTANCE + Maths::Max(0.0f, 1.75f * this.getShape().vellen * (vel * thinghy)), MAX_ATTACK_DISTANCE);

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;
	const bool jab = isJab(damage);

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null && !dontHitMore) // blob
			{
				if (b.hasTag("ignore sword")) continue;

				//big things block attacks
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

				if (!canHit(this, b))
				{
					// no TK
					if (large)
						dontHitMore = true;

					continue;
				}

				if (knight_has_hit_actor(this, b))
				{
					if (large)
						dontHitMore = true;

					continue;
				}

				knight_add_actor_limit(this, b);
				if (!dontHitMore)
				{
					Vec2f velocity = b.getPosition() - pos;
					this.server_Hit(b, hi.hitpos, velocity, damage, type, true);  // server_Hit() is server-side only

					// end hitting if we hit something solid, don't if its flesh
					if (large)
					{
						dontHitMore = true;
					}
				}
			}
			else  // hitmap
				if (!dontHitMoreMap && (deltaInt == DELTA_BEGIN_ATTACK + 1))
				{
					bool ground = map.isTileGround(hi.tile);
					bool dirt_stone = map.isTileStone(hi.tile);
					bool gold = map.isTileGold(hi.tile);
					bool wood = map.isTileWood(hi.tile);
					if (ground || wood || dirt_stone || gold)
					{
						Vec2f tpos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
						Vec2f offset = (tpos - blobPos);
						f32 tileangle = offset.Angle();
						f32 dif = Maths::Abs(exact_aimangle - tileangle);
						if (dif > 180)
							dif -= 360;
						if (dif < -180)
							dif += 360;

						dif = Maths::Abs(dif);
						//print("dif: "+dif);

						if (dif < 20.0f)
						{
							//detect corner

							int check_x = -(offset.x > 0 ? -1 : 1);
							int check_y = -(offset.y > 0 ? -1 : 1);
							if (map.isTileSolid(hi.hitpos - Vec2f(map.tilesize * check_x, 0)) &&
							        map.isTileSolid(hi.hitpos - Vec2f(0, map.tilesize * check_y)))
								continue;

							bool canhit = true; //default true if not jab
							if (jab) //fake damage
							{
								info.tileDestructionLimiter++;
								canhit = ((info.tileDestructionLimiter % ((wood || dirt_stone) ? 3 : 2)) == 0);
							}
							else //reset fake dmg for next time
							{
								info.tileDestructionLimiter = 0;
							}

							//dont dig through no build zones
							canhit = canhit && map.getSectorAtPosition(tpos, "no build") is null;

							dontHitMoreMap = true;
							if (canhit)
							{
								map.server_DestroyTile(hi.hitpos, 0.1f, this);
								if (gold)
								{
									// Note: 0.1f damage doesn't harvest anything I guess
									// This puts it in inventory - include MaterialCommon
									//Material::fromTile(this, hi.tile, 1.f);

									CBlob@ ore = server_CreateBlobNoInit("mat_gold");
									if (ore !is null)
									{
										ore.Tag('custom quantity');
	     								ore.Init();
	     								ore.setPosition(pos);
	     								ore.server_SetQuantity(4);
	     							}
								}
							}
						}
					}
				}
		}
	}

	// destroy grass

	if (((aimangle >= 0.0f && aimangle <= 180.0f) || damage > 1.0f) &&    // aiming down or slash
	        (deltaInt == DELTA_BEGIN_ATTACK + 1)) // hit only once
	{
		f32 tilesize = map.tilesize;
		int steps = Maths::Ceil(2 * radius / tilesize);
		int sign = this.isFacingLeft() ? -1 : 1;

		for (int y = 0; y < steps; y++)
			for (int x = 0; x < steps; x++)
			{
				Vec2f tilepos = blobPos + Vec2f(x * tilesize * sign, y * tilesize);
				TileType tile = map.getTile(tilepos).type;

				if (map.isTileGrass(tile))
				{
					map.server_DestroyTile(tilepos, damage, this);

					if (damage <= 1.0f)
					{
						return;
					}
				}
			}
	}
}

bool isSliding(KnightInfo@ knight)
{
	return (knight.slideTime > 0 && knight.slideTime < 45);
}

// shieldbash

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	//return if we didn't collide or if it's teamie
	if (blob is null || !solid || this.getTeamNum() == blob.getTeamNum())
	{
		return;
	}

	const bool onground = this.isOnGround();
	if (this.getShape().vellen > SHIELD_KNOCK_VELOCITY || onground)
	{
		KnightInfo@ knight;
		if (!this.get("knightInfo", @knight))
		{
			return;
		}

		//printf("knight.stat " + knight.state );
		if (knight.state == KnightStates::shielddropping &&
		        (!onground || isSliding(knight)) &&
		        (blob.getShape() !is null && !blob.getShape().isStatic()) &&
		        !isKnocked(blob))
		{
			Vec2f pos = this.getPosition();
			Vec2f vel = this.getOldVelocity();
			vel.Normalize();

			//printf("nor " + vel * normal );
			if (vel * normal < 0.0f && knight_hit_actor_count(this) == 0) //only bash one thing per tick
			{
				ShieldVars@ shieldVars = getShieldVars(this);
				//printf("shi " + shieldVars.direction * normal );
				if (shieldVars.direction * normal < 0.0f)
				{
					knight_add_actor_limit(this, blob);
					this.server_Hit(blob, pos, vel, 0.0f, Hitters::shield);

					Vec2f force = Vec2f(shieldVars.direction.x * this.getMass(), -this.getMass()) * 3.0f;

					blob.AddForce(force);
					this.AddForce(Vec2f(-force.x, force.y));
				}
			}
		}
	}
}


//a little push forward

void pushForward(CBlob@ this, f32 normalForce, f32 pushingForce, f32 verticalForce)
{
	f32 facing_sign = this.isFacingLeft() ? -1.0f : 1.0f ;
	bool pushing_in_facing_direction =
	    (facing_sign < 0.0f && this.isKeyPressed(key_left)) ||
	    (facing_sign > 0.0f && this.isKeyPressed(key_right));
	f32 force = normalForce;

	if (pushing_in_facing_direction)
	{
		force = pushingForce;
	}

	this.AddForce(Vec2f(force * facing_sign , verticalForce));
}

//bomb management

bool hasItem(CBlob@ this, const string &in name)
{
	CBitStream reqs, missing;
	AddRequirement(reqs, "blob", name, "Bombs", 1);
	CInventory@ inv = this.getInventory();

	if (inv !is null)
	{
		return hasRequirements(inv, reqs, missing);
	}
	else
	{
		warn("our inventory was null! KnightLogic.as");
	}

	return false;
}

void TakeItem(CBlob@ this, const string &in name)
{
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null)
	{
		if (carried.getName() == name)
		{
			carried.server_Die();
			return;
		}
	}

	CBitStream reqs, missing;
	AddRequirement(reqs, "blob", name, "Bombs", 1);
	CInventory@ inv = this.getInventory();

	if (inv !is null)
	{
		if (hasRequirements(inv, reqs, missing))
		{
			server_TakeRequirements(inv, reqs);
		}
		else
		{
			warn("took a bomb even though we dont have one! KnightLogic.as");
		}
	}
	else
	{
		warn("our inventory was null! KnightLogic.as");
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	KnightInfo@ knight;
	if (!this.get("knightInfo", @knight))
	{
		return;
	}

	if (customData == Hitters::sword &&
	        ( //is a jab - note we dont have the dmg in here at the moment :/
	            knight.state == KnightStates::sword_cut_mid ||
	            knight.state == KnightStates::sword_cut_mid_down ||
	            knight.state == KnightStates::sword_cut_up ||
	            knight.state == KnightStates::sword_cut_down
	        )
	        && blockAttack(hitBlob, velocity, 0.0f))
	{
		this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
		setKnocked(this, 30, true);
	}

	if (customData == Hitters::shield)
	{
		setKnocked(hitBlob, 20, true);
		this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
	}
}



// bomb pick menu

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	if (bombTypeNames.length == 0)
	{
		return;
	}

	this.ClearGridMenusExceptInventory();
	Vec2f pos(gridmenu.getUpperLeftPosition().x + 0.5f * (gridmenu.getLowerRightPosition().x - gridmenu.getUpperLeftPosition().x),
	          gridmenu.getUpperLeftPosition().y - 32 * 1 - 2 * 24);
	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(bombTypeNames.length, 2), getTranslatedString("Current bomb"));
	u8 weaponSel = this.get_u8("bomb type");

	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		for (uint i = 0; i < bombTypeNames.length; i++)
		{
			string matname = bombTypeNames[i];
			CGridButton @button = menu.AddButton(bombIcons[i], getTranslatedString(bombNames[i]), this.getCommandID("pick " + matname));

			if (button !is null)
			{
				bool enabled = this.getBlobCount(bombTypeNames[i]) > 0;
				button.SetEnabled(enabled);
				button.selectOneOnClick = true;
				if (weaponSel == i)
				{
					button.SetSelected(1);
				}
			}
		}
	}
}


void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @ap)
{
	for (uint i = 0; i < bombTypeNames.length; i++)
	{
		if (attached.getName() == bombTypeNames[i])
		{
			this.set_u8("bomb type", i);
			break;
		}
	}

	if (!ap.socket) {
		KnightInfo@ knight;
		if (!this.get("knightInfo", @knight))
		{
			return;
		}

		knight.state = KnightStates::normal; //cancel any attacks or shielding
		knight.swordTimer = 0;
		knight.doubleslash = false;
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	const string itemname = blob.getName();
	if (this.isMyPlayer() && this.getInventory().getItemsCount() > 1)
	{
		for (uint j = 1; j < bombTypeNames.length; j++)
		{
			if (itemname == bombTypeNames[j])
			{
				SetHelp(this, "help inventory", "knight", "$Help_Bomb1$$Swap$$Help_Bomb2$         $KEY_TAP$$KEY_F$", "", 2);
				break;
			}
		}
	}

	if (this.getInventory().getItemsCount() == 0 || itemname == "mat_bombs")
	{
		for (uint j = 0; j < bombTypeNames.length; j++)
		{
			if (itemname == bombTypeNames[j])
			{
				this.set_u8("bomb type", j);
				return;
			}
		}
	}
}

void SetFirstAvailableBomb(CBlob@ this)
{
	u8 type = 255;
	if (this.exists("bomb type"))
		type = this.get_u8("bomb type");

	CInventory@ inv = this.getInventory();

	bool typeReal = (uint(type) < bombTypeNames.length);
	if (typeReal && inv.getItem(bombTypeNames[type]) !is null)
		return;

	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		const string itemname = inv.getItem(i).getName();
		for (uint j = 0; j < bombTypeNames.length; j++)
		{
			if (itemname == bombTypeNames[j])
			{
				type = j;
				break;
			}
		}

		if (type != 255)
			break;
	}

	this.set_u8("bomb type", type);
}

// Blame Fuzzle.
bool canHit(CBlob@ this, CBlob@ b)
{

	if (b.hasTag("invincible"))
		return false;

	// Don't hit temp blobs and items carried by teammates.
	if (b.isAttached())
	{

		CBlob@ carrier = b.getCarriedBlob();

		if (carrier !is null)
			if (carrier.hasTag("player")
			        && (this.getTeamNum() == carrier.getTeamNum() || b.hasTag("temp blob")))
				return false;

	}

	if (b.hasTag("dead"))
		return true;

	return b.getTeamNum() != this.getTeamNum();

}
