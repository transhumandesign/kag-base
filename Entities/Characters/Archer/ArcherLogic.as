// Archer logic

#include "ArcherCommon.as"
#include "ActivationThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "RunnerCommon.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";
#include "RedBarrierCommon.as";
#include "StandardControlsCommon.as";

const int FLETCH_COOLDOWN = 45;
const int PICKUP_COOLDOWN = 15;
const int fletch_num_arrows = 1;
const int STAB_DELAY = 12;
const int STAB_TIME = 20;
// code for the following is a bit stupid, TODO: make it normal
// x = WEAKSHOT_CHARGE
const int WEAKSHOT_CHARGE = 11; // 12 (x+1) in reality
const int MIDSHOT_CHARGE = 13; // 24 (x+13) in reality
const int FULLSHOT_CHARGE = 25; // 36 (x+25) in reality
const int TRIPLESHOT_CHARGE = 89; // 100 (x+89) in reality 

void onInit(CBlob@ this)
{
	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("flesh");

	ControlsSwitch@ controls_switch = @onSwitch;
	this.set("onSwitch handle", @controls_switch);

	ControlsCycle@ controls_cycle = @onCycle;
	this.set("onCycle handle", @controls_cycle);

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
	this.getSprite().SetEmitSound("Entities/Characters/Archer/BowPull.ogg");
	this.addCommandID("play fire sound");
	this.addCommandID("pickup arrow");
	this.addCommandID("pickup arrow client");
	this.addCommandID("request shoot");
	this.addCommandID("arrow sync");
	this.addCommandID("arrow sync client");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.addCommandID(grapple_sync_cmd);

	SetHelp(this, "help self hide", "archer", getTranslatedString("Hide    $KEY_S$"), "", 1);
	SetHelp(this, "help self action2", "archer", getTranslatedString("$Grapple$ Grappling hook    $RMB$"), "", 3);

	//add a command ID for each arrow type
	for (uint i = 0; i < arrowTypeNames.length; i++)
	{
		this.addCommandID("pick " + arrowTypeNames[i]);
	}

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16, 16));
	}
}

void ManageGrapple(CBlob@ this, ArcherInfo@ archer)
{
	CSprite@ sprite = this.getSprite();
	u8 charge_state = archer.charge_state;
	Vec2f pos = this.getPosition();

	const bool right_click = this.isKeyJustPressed(key_action2);

	// fletch arrows from tree
	if(this.isKeyPressed(key_action2)
		&& charge_state != ArcherParams::stabbing
		&& !archer.grappling
		&& this.isOnGround()
		&& !this.isKeyPressed(key_action1)
		&& !this.wasKeyPressed(key_action1))
	{
		Vec2f aimpos = this.getAimPos();
		CBlob@[] blobs;
		if(getMap().getBlobsInRadius(aimpos, 8.0f, blobs))
		{
			for (int i = 0; i < blobs.size(); i++)
			{
				CBlob@ target = blobs[i];
				string name = target.getName();

				if (target !is null
					&& (target.hasTag("tree") || name == "log" || name == "mat_wood")
					&& Vec2f(target.getPosition() - pos).Length() <= 24.0f)
				{
					this.set_u16("stabHitID",  target.getNetworkID());
					charge_state = ArcherParams::stabbing;
					archer.charge_time = 0;
					archer.stab_delay = 0;
					sprite.SetEmitSoundPaused(true);
					archer.charge_state = charge_state;
					break;
				}
			}

		}
	}

	if (right_click && charge_state != ArcherParams::stabbing)
	{
		// cancel charging
		if (charge_state != ArcherParams::not_aiming &&
		    charge_state != ArcherParams::fired) // allow grapple right after firing
		{
			charge_state = ArcherParams::not_aiming;
			archer.charge_time = 0;
			sprite.SetEmitSoundPaused(true);
			sprite.PlaySound("PopIn.ogg");
		}
		else if (canSend(this) || isServer()) //otherwise grapple
		{
			archer.grappling = true;
			archer.grapple_id = 0xffff;
			archer.grapple_pos = pos;

			archer.grapple_ratio = 1.0f; //allow fully extended

			Vec2f direction = this.getAimPos() - pos;

			//aim in direction of cursor
			f32 distance = direction.Normalize();
			if (distance > 1.0f)
			{
				archer.grapple_vel = direction * archer_grapple_throw_speed;
			}
			else
			{
				archer.grapple_vel = Vec2f_zero;
			}

			SyncGrapple(this);
		}

		archer.charge_state = charge_state;
	}

	if (archer.grappling)
	{
		//update grapple
		//TODO move to its own script?

		if (!this.isKeyPressed(key_action2))
		{
			if (canSend(this) || isServer())
			{
				archer.grappling = false;
				SyncGrapple(this);
			}
		}
		else
		{
			const f32 archer_grapple_range = archer_grapple_length * archer.grapple_ratio;
			const f32 archer_grapple_force_limit = this.getMass() * archer_grapple_accel_limit;

			CMap@ map = this.getMap();

			//reel in
			//TODO: sound
			if (archer.grapple_ratio > 0.2f)
				archer.grapple_ratio -= 1.0f / getTicksASecond();

			//get the force and offset vectors
			Vec2f force;
			Vec2f offset;
			f32 dist;
			{
				force = archer.grapple_pos - this.getPosition();
				dist = force.Normalize();
				f32 offdist = dist - archer_grapple_range;
				if (offdist > 0)
				{
					offset = force * Maths::Min(8.0f, offdist * archer_grapple_stiffness);
					force *= Maths::Min(archer_grapple_force_limit, Maths::Max(0.0f, offdist + archer_grapple_slack) * archer_grapple_force);
				}
				else
				{
					force.Set(0, 0);
				}
			}

			//left map? too long? close grapple
			if (archer.grapple_pos.x < 0 ||
			        archer.grapple_pos.x > (map.tilemapwidth)*map.tilesize ||
			        dist > archer_grapple_length * 3.0f)
			{
				if (canSend(this) || isServer())
				{
					archer.grappling = false;
					SyncGrapple(this);
				}
			}
			else if (archer.grapple_id == 0xffff) //not stuck
			{
				const f32 drag = map.isInWater(archer.grapple_pos) ? 0.7f : 0.90f;
				const Vec2f gravity(0, 1);

				archer.grapple_vel = (archer.grapple_vel * drag) + gravity - (force * (2 / this.getMass()));

				Vec2f next = archer.grapple_pos + archer.grapple_vel;
				next -= offset;

				Vec2f dir = next - archer.grapple_pos;
				f32 delta = dir.Normalize();
				bool found = false;
				const f32 step = map.tilesize * 0.5f;
				while (delta > 0 && !found) //fake raycast
				{
					if (delta > step)
					{
						archer.grapple_pos += dir * step;
					}
					else
					{
						archer.grapple_pos = next;
					}
					delta -= step;
					found = checkGrappleStep(this, archer, map, dist);
				}

			}
			else //stuck -> pull towards pos
			{

				//wallrun/jump reset to make getting over things easier
				//at the top of grapple
				if (this.isOnWall()) //on wall
				{
					//close to the grapple point
					//not too far above
					//and moving downwards
					Vec2f dif = pos - archer.grapple_pos;
					if (this.getVelocity().y > 0 &&
					        dif.y > -10.0f &&
					        dif.Length() < 24.0f)
					{
						//need move vars
						RunnerMoveVars@ moveVars;
						if (this.get("moveVars", @moveVars))
						{
							moveVars.walljumped_side = Walljump::NONE;
						}
					}
				}

				CBlob@ b = null;
				if (archer.grapple_id != 0)
				{
					@b = getBlobByNetworkID(archer.grapple_id);
					if (b is null)
					{
						archer.grapple_id = 0;
					}
				}

				if (b !is null)
				{
					archer.grapple_pos = b.getPosition();
					if (b.isKeyJustPressed(key_action1) ||
					        b.isKeyJustPressed(key_action2) ||
					        this.isKeyPressed(key_use))
					{
						if (canSend(this) || isServer())
						{
							archer.grappling = false;
							SyncGrapple(this);
						}
					}
				}
				else if (shouldReleaseGrapple(this, archer, map))
				{
					if (canSend(this) || isServer())
					{
						archer.grappling = false;
						SyncGrapple(this);
					}
				}

				this.AddForce(force);
				Vec2f target = (this.getPosition() + offset);
				if (!map.rayCastSolid(this.getPosition(), target) &&
					(this.getVelocity().Length() > 2 || !this.isOnMap()))
				{
					this.setPosition(target);
				}

				if (b !is null)
					b.AddForce(-force * (b.getMass() / this.getMass()));

			}
		}

	}

}

void ManageBow(CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars)
{
	//are we responsible for this actor?
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer() && !ismyplayer)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			responsible = p.isBot();
		}
	}
	//
	CSprite@ sprite = this.getSprite();
	bool hasarrow = archer.has_arrow;
	bool hasnormal = hasArrows(this, ArrowType::normal);
	s8 charge_time = archer.charge_time;
	u8 charge_state = archer.charge_state;
	const bool pressed_action2 = this.isKeyPressed(key_action2);
	Vec2f pos = this.getPosition();

	if (responsible)
	{
		hasarrow = hasArrows(this);

		if (!hasarrow && hasnormal)
		{
			// set back to default
			archer.arrow_type = ArrowType::normal;
			ClientSendArrowState(this);
			hasarrow = hasnormal;

			if (ismyplayer)
			{
				Sound::Play("/CycleInventory.ogg");
			}
		}

		if (hasarrow != this.get_bool("has_arrow"))
		{
			this.set_bool("has_arrow", hasarrow);
			this.Sync("has_arrow", isServer());
		}

	}

	if (charge_state == ArcherParams::legolas_charging) // fast arrows
	{
		if (!hasarrow)
		{
			charge_state = ArcherParams::not_aiming;
			charge_time = 0;
		}
		else
		{
			charge_state = ArcherParams::legolas_ready;
		}
	}
	//charged - no else (we want to check the very same tick)
	if (charge_state == ArcherParams::legolas_ready) // fast arrows
	{
		moveVars.walkFactor *= 0.75f;

		archer.legolas_time--;
		if (!hasarrow || archer.legolas_time == 0)
		{
			bool pressed = this.isKeyPressed(key_action1);
			charge_state = pressed ? ArcherParams::readying : ArcherParams::not_aiming;
			charge_time = 0;
			//didn't fire
			if (archer.legolas_arrows == ArcherParams::legolas_arrows_count)
			{
				Sound::Play("/Stun", pos, 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
				setKnocked(this, 15);
			}
			else if (pressed)
			{
				sprite.RewindEmitSound();
				sprite.SetEmitSoundPaused(false);
			}
		}
		else if (this.isKeyJustPressed(key_action1) ||
		         (archer.legolas_arrows == ArcherParams::legolas_arrows_count &&
		          !this.isKeyPressed(key_action1) &&
		          this.wasKeyPressed(key_action1)))
		{
			ClientFire(this, charge_time, charge_state);

			charge_state = ArcherParams::legolas_charging;
			charge_time = ArcherParams::shoot_period - ArcherParams::legolas_charge_time;
			Sound::Play("FastBowPull.ogg", pos);
			archer.legolas_arrows--;

			if (archer.legolas_arrows == 0)
			{
				charge_state = ArcherParams::not_aiming;
				charge_time = 5;

				sprite.RewindEmitSound();
				sprite.SetEmitSoundPaused(false);
			}
		}

	}
	else if (this.isKeyPressed(key_action1))
	{
		moveVars.walkFactor *= 0.75f;
		moveVars.canVault = false;

		bool just_action1 = this.isKeyJustPressed(key_action1);

		//	printf("charge_state " + charge_state );
		if (hasarrow && charge_state == ArcherParams::no_arrows)
		{
			// (when key_action1 is down) reset charge state when:
			// * the player has picks up arrows when inventory is empty
			// * the player switches arrow type while charging bow
			charge_state = ArcherParams::not_aiming;
			just_action1 = true;
		}

		if ((just_action1 || this.wasKeyPressed(key_action2) || this.hasTag("redo charge") && !pressed_action2) &&
		        (charge_state == ArcherParams::not_aiming || charge_state == ArcherParams::fired || charge_state == ArcherParams::stabbing))
		{
			this.Untag("redo charge");
			charge_state = ArcherParams::readying;
			hasarrow = hasArrows(this);

			if (!hasarrow && hasnormal)
			{
				archer.arrow_type = ArrowType::normal;
				ClientSendArrowState(this);
				hasarrow = hasnormal;

				if (ismyplayer)
				{
					Sound::Play("/CycleInventory.ogg");
				}
			}

			if (responsible)
			{
				this.set_bool("has_arrow", hasarrow);
				this.Sync("has_arrow", isServer());
			}

			charge_time = 0;

			if (!hasarrow)
			{
				charge_state = ArcherParams::no_arrows;

				if (ismyplayer && !this.wasKeyPressed(key_action1))   // playing annoying no ammo sound
				{
					this.getSprite().PlaySound("Entities/Characters/Sounds/NoAmmo.ogg", 0.5);
				}

			}
			else
			{
				if (ismyplayer)
				{
					if (just_action1)
					{
						const u8 type = archer.arrow_type;

						if (type == ArrowType::water)
						{
							sprite.PlayRandomSound("/WaterBubble");
						}
						else if (type == ArrowType::fire)
						{
							sprite.PlaySound("SparkleShort.ogg");
						}
					}
				}

				sprite.RewindEmitSound();
				sprite.SetEmitSoundPaused(false);

				if (!ismyplayer)   // lower the volume of other players charging  - ooo good idea
				{
					sprite.SetEmitSoundVolume(0.5f);
				}
			}
		}
		else if (charge_state == ArcherParams::readying)
		{
			charge_time++;

			if (charge_time > ArcherParams::ready_time)
			{
				charge_time = 1;
				charge_state = ArcherParams::charging;
			}
		}
		else if (charge_state == ArcherParams::charging)
		{
			if(!hasarrow)
			{
				charge_state = ArcherParams::no_arrows;
				charge_time = 0;
				
				if (ismyplayer)   // playing annoying no ammo sound
				{
					this.getSprite().PlaySound("Entities/Characters/Sounds/NoAmmo.ogg", 0.5);
				}
			}
			else
			{
				charge_time++;
			}

			if (charge_time >= TRIPLESHOT_CHARGE)
			{
				// Legolas state

				Sound::Play("AnimeSword.ogg", pos, ismyplayer ? 1.3f : 0.7f);
				Sound::Play("FastBowPull.ogg", pos);
				charge_state = ArcherParams::legolas_charging;
				charge_time = ArcherParams::shoot_period - ArcherParams::legolas_charge_time;

				archer.legolas_arrows = ArcherParams::legolas_arrows_count;
				archer.legolas_time = ArcherParams::legolas_time;
			}

			if (charge_time >= ArcherParams::shoot_period)
			{
				sprite.SetEmitSoundPaused(true);
			}
		}
		else if (charge_state == ArcherParams::no_arrows)
		{
			if (charge_time < ArcherParams::ready_time)
			{
				charge_time++;
			}
		}
		else
		{
			charge_state = ArcherParams::not_aiming;
			charge_time = 0;
			this.Tag("redo charge");
		}
	}
	else
	{
		if (charge_state > ArcherParams::readying)
		{
			if (charge_state < ArcherParams::fired)
			{
				ClientFire(this, charge_time, charge_state);
				charge_time = ArcherParams::fired_time;
				charge_state = ArcherParams::fired;
			}
			else if(charge_state == ArcherParams::stabbing)
			{
				archer.stab_delay++;
				if (archer.stab_delay == STAB_DELAY)
				{
					// hit tree and get an arrow
					CBlob@ stabTarget = getBlobByNetworkID(this.get_u16("stabHitID"));
					if (stabTarget !is null)
					{
						if (stabTarget.getName() == "mat_wood")
						{
							u16 quantity = stabTarget.getQuantity();
							if (quantity > 4)
							{
								stabTarget.server_SetQuantity(quantity-4);
							}
							else
							{
								stabTarget.server_Die();

							}
							fletchArrow(this);
						}
						else
						{
							this.server_Hit(stabTarget, stabTarget.getPosition(), Vec2f_zero, 0.25f,  Hitters::stab);

						}

					}
				}
				else if(archer.stab_delay >= STAB_TIME)
				{
					charge_state = ArcherParams::not_aiming;
				}
			}
			else //fired..
			{
				charge_time--;

				if (charge_time <= 0)
				{
					charge_state = ArcherParams::not_aiming;
					charge_time = 0;
				}
			}
		}
		else
		{
			charge_state = ArcherParams::not_aiming;    //set to not aiming either way
			charge_time = 0;
		}

		sprite.SetEmitSoundPaused(true);
	}

	// safe disable bomb light

	if (this.wasKeyPressed(key_action1) && !this.isKeyPressed(key_action1))
	{
		const u8 type = archer.arrow_type;
		if (type == ArrowType::bomb)
		{
			BombFuseOff(this);
		}
	}

	// my player!

	if (responsible)
	{
		// set cursor
		if (ismyplayer && !getHUD().hasButtons())
		{
			int frame = 0;
			if (archer.charge_state != ArcherParams::readying && archer.charge_state != ArcherParams::charging && archer.charge_state != ArcherParams::legolas_charging && archer.charge_state != ArcherParams::legolas_ready)
			{
				frame = 0;
			}
			else if (archer.charge_state == ArcherParams::readying) // Charging weak shot
			{
				frame = 0 + int(archer.charge_time / 2);
			}
			else if (archer.charge_time > 0 && archer.charge_state == ArcherParams::charging)
			{
				if (archer.charge_time >= 1 && archer.charge_time <= 2) // Weakest shot charged (charge_time resets to 0 when that happens for some reason..)
				{
					frame = 6;
				}
				else if (archer.charge_state != ArcherParams::legolas_ready && archer.charge_time <= FULLSHOT_CHARGE) // Charging midshot & fullshot
				{
					frame = 6 + int((archer.charge_time - 1) / 2);
				}
				else if (archer.charge_state != ArcherParams::legolas_ready && archer.charge_time > FULLSHOT_CHARGE) // Charging 3x
				{
					frame = 18 + int((archer.charge_time - FULLSHOT_CHARGE) / 4);
				}
			}
			else // 3x charged
			{
				frame = 34;
			}
			getHUD().SetCursorFrame(frame);
		}

		// activate/throw

		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}

		// pick up arrow

		if (archer.fletch_cooldown > 0)
		{
			archer.fletch_cooldown--;
		}

		// pickup from ground
		// from clientside right now, could probably move to a simple call and
		// pray that fletch_cooldown is synced correctly

		if (isClient() && archer.fletch_cooldown == 0 && this.isKeyPressed(key_action2))
		{
			if (getPickupArrow(this) !is null)   // pickup arrow from ground
			{
				this.SendCommand(this.getCommandID("pickup arrow"));
				archer.fletch_cooldown = PICKUP_COOLDOWN;
			}
		}
	}

	archer.charge_time = charge_time;
	archer.charge_state = charge_state;
	archer.has_arrow = hasarrow;

}

void onTick(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	if (isKnocked(this) || this.isInInventory())
	{
		archer.grappling = false;
		archer.charge_state = 0;
		archer.charge_time = 0;
		this.getSprite().SetEmitSoundPaused(true);
		getHUD().SetCursorFrame(0);
		return;
	}

	ManageGrapple(this, archer);

	//print("state before: " + archer.charge_state);

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	ManageBow(this, archer, moveVars);

	//print("state after: " + archer.charge_state);
}

bool checkGrappleBarrier(Vec2f pos)
{
	CRules@ rules = getRules();
	if (!shouldBarrier(@rules)) { return false; }

	Vec2f tl, br;
	getBarrierRect(@rules, tl, br);

	return (pos.x > tl.x && pos.x < br.x);
}

bool checkGrappleStep(CBlob@ this, ArcherInfo@ archer, CMap@ map, const f32 dist)
{
	if (checkGrappleBarrier(archer.grapple_pos)) // red barrier
	{
		if (canSend(this) || isServer())
		{
			archer.grappling = false;
			SyncGrapple(this);
		}
	}
	else if (grappleHitMap(archer, map, dist))
	{
		archer.grapple_id = 0;

		archer.grapple_ratio = Maths::Max(0.2, Maths::Min(archer.grapple_ratio, dist / archer_grapple_length));

		archer.grapple_pos.y = Maths::Max(0.0, archer.grapple_pos.y);

		if (canSend(this) || isServer()) SyncGrapple(this);

		return true;
	}
	else
	{
		CBlob@ b = map.getBlobAtPosition(archer.grapple_pos);
		if (b !is null)
		{
			if (b is this)
			{
				//can't grapple self if not reeled in
				if (archer.grapple_ratio > 0.5f)
					return false;

				if (canSend(this) || isServer())
				{
					archer.grappling = false;
					SyncGrapple(this);
				}

				return true;
			}
			else if (b.isCollidable() && b.getShape().isStatic() && !b.hasTag("ignore_arrow"))
			{
				//TODO: Maybe figure out a way to grapple moving blobs
				//		without massive desync + forces :)

				archer.grapple_ratio = Maths::Max(0.2, Maths::Min(archer.grapple_ratio, b.getDistanceTo(this) / archer_grapple_length));

				archer.grapple_id = b.getNetworkID();
				if (canSend(this) || isServer())
				{
					SyncGrapple(this);
				}

				return true;
			}
		}
	}

	return false;
}

bool grappleHitMap(ArcherInfo@ archer, CMap@ map, const f32 dist = 16.0f)
{
	return  map.isTileSolid(archer.grapple_pos + Vec2f(0, -3)) ||			//fake quad
	        map.isTileSolid(archer.grapple_pos + Vec2f(3, 0)) ||
	        map.isTileSolid(archer.grapple_pos + Vec2f(-3, 0)) ||
	        map.isTileSolid(archer.grapple_pos + Vec2f(0, 3)) ||
	        (dist > 10.0f && map.getSectorAtPosition(archer.grapple_pos, "tree") !is null);   //tree stick
}

bool shouldReleaseGrapple(CBlob@ this, ArcherInfo@ archer, CMap@ map)
{
	return !grappleHitMap(archer, map) || this.isKeyPressed(key_use);
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ClientFire(CBlob@ this, s8 charge_time, u8 charge_state)
{
	//time to fire!
	if (canSend(this))  // client-logic
	{
		CBitStream params;
		params.write_s8(charge_time);
		params.write_u8(charge_state);

		this.SendCommand(this.getCommandID("request shoot"), params);
	}
}

CBlob@ getPickupArrow(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getName() == "arrow" && b.getShape().isStatic())
			{
				return b;
			}
		}
	}
	return null;
}

bool canPickSpriteArrow(CBlob@ this, bool takeout)
{
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			{
				CSprite@ sprite = b.getSprite();
				if (sprite.getSpriteLayer("arrow") !is null)
				{
					if (takeout)
						sprite.RemoveSpriteLayer("arrow");
					return true;
				}
			}
		}
	}
	return false;
}

CBlob@ CreateArrow(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel, u8 arrowType)
{
	CBlob@ arrow = server_CreateBlobNoInit("arrow");
	if (arrow !is null)
	{
		// fire arrow?
		arrow.set_u8("arrow type", arrowType);
		arrow.SetDamageOwnerPlayer(this.getPlayer());
		arrow.Init();

		arrow.IgnoreCollisionWhileOverlapped(this);
		arrow.server_setTeamNum(this.getTeamNum());
		arrow.setPosition(arrowPos);
		arrow.setVelocity(arrowVel);
	}
	return arrow;
}

// clientside
void onCycle(CBitStream@ params)
{
	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	if (arrowTypeNames.length == 0) return;

	// cycle arrows
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}
	u8 type = archer.arrow_type;

	int count = 0;
	while (count < arrowTypeNames.length)
	{
		type++;
		count++;
		if (type >= arrowTypeNames.length)
		{
			type = 0;
		}
		if (hasArrows(this, type))
		{
			CycleToArrowType(this, archer, type);
			break;
		}
	}
}

void onSwitch(CBitStream@ params)
{
	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	if (arrowTypeNames.length == 0) return;

	u8 type;
	if (!params.saferead_u8(type)) return;

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	if (hasArrows(this, type))
	{
		CycleToArrowType(this, archer, type);
	}
}

void ShootArrow(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	u8 arrow_type = archer.arrow_type;

	if (arrow_type >= arrowTypeNames.length) return;

	if (!hasArrows(this, arrow_type)) return; 
	
	s8 charge_time = archer.charge_time;
	u8 charge_state = archer.charge_state;

	f32 arrowspeed;

	if (charge_time < MIDSHOT_CHARGE)
	{
		arrowspeed = ArcherParams::shoot_max_vel * (1.0f / 3.0f);
	}
	else if (charge_time < FULLSHOT_CHARGE)
	{
		arrowspeed = ArcherParams::shoot_max_vel * (4.0f / 5.0f);
	}
	else
	{
		arrowspeed = ArcherParams::shoot_max_vel;
	}

	Vec2f offset(this.isFacingLeft() ? 2 : -2, -2);

	Vec2f arrowPos = this.getPosition() + offset;
	Vec2f aimpos = this.getAimPos();
	Vec2f arrowVel = (aimpos - arrowPos);
	arrowVel.Normalize();
	arrowVel *= arrowspeed;

	bool legolas = false;
	if (charge_state == ArcherParams::legolas_ready) legolas = true;

	if (legolas)
	{
		int r = 0;
		for (int i = 0; i < ArcherParams::legolas_arrows_volley; i++)
		{
			CBlob@ arrow = CreateArrow(this, arrowPos, arrowVel, arrow_type);
			if (i > 0 && arrow !is null)
			{
				arrow.Tag("shotgunned");
			}

			this.TakeBlob(arrowTypeNames[ arrow_type ], 1);
			arrow_type = ArrowType::normal;

			//don't keep firing if we're out of arrows
			if (!hasArrows(this, arrow_type))
				break;

			r = r > 0 ? -(r + 1) : (-r) + 1;

			arrowVel = arrowVel.RotateBy(ArcherParams::legolas_arrows_deviation * r, Vec2f());
			if (i == 0)
			{
				arrowVel *= 0.9f;
			}
		}

		this.SendCommand(this.getCommandID("play fire sound"));
	}
	else
	{
		CreateArrow(this, arrowPos, arrowVel, arrow_type);

		this.SendCommand(this.getCommandID("play fire sound"));
		this.TakeBlob(arrowTypeNames[ arrow_type ], 1);

		archer.fletch_cooldown = FLETCH_COOLDOWN; // just don't allow shoot + make arrow
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ params)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer)) { return; }

	params.write_u8(archer.arrow_type);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ params)
{
	return ReceiveArrowState(this, params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("play fire sound") && isClient())
	{
		this.getSprite().PlaySound("Entities/Characters/Archer/BowFire.ogg");
	}
	else if (cmd == this.getCommandID("request shoot") && isServer())
	{
		s8 charge_time;
		if (!params.saferead_u8(charge_time)) { return; }

		u8 charge_state;
		if (!params.saferead_u8(charge_state)) { return; }

		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer)) { return; }

		archer.charge_time = charge_time;
		archer.charge_state = charge_state;

		ShootArrow(this);
	}
	else if (cmd == this.getCommandID("arrow sync") && isServer())
	{
		ReceiveArrowState(this, params);
	}
	else if (cmd == this.getCommandID("arrow sync client") && isClient())
	{
		ReceiveArrowState(this, params);
	}
	else if (cmd == this.getCommandID("pickup arrow") && isServer())
	{
		// TODO: missing cooldown check
		CBlob@ arrow = getPickupArrow(this);
		// bool spriteArrow = canPickSpriteArrow(this, false); // unnecessary

		if (arrow !is null/* || spriteArrow*/)
		{
			ArcherInfo@ archer;
			if (!this.get("archerInfo", @archer))
			{
				return;
			}
			const u8 arrowType = archer.arrow_type;
			if (arrowType == ArrowType::bomb)
			{
				arrow.setPosition(this.getPosition());
				return;
			}

			CBlob@ mat_arrows = server_CreateBlobNoInit('mat_arrows');

			if (mat_arrows !is null)
			{
				mat_arrows.Tag('custom quantity');
				mat_arrows.Init();

				mat_arrows.server_SetQuantity(1); // unnecessary

				if (not this.server_PutInInventory(mat_arrows))
				{
					mat_arrows.setPosition(this.getPosition());
				}

				if (arrow !is null)
				{
					arrow.server_Die();
				}
				else
				{
					// canPickSpriteArrow(this, true);
				}
			}

			this.SendCommand(this.getCommandID("pickup arrow client"));
		}
	}
	else if (cmd == this.getCommandID("pickup arrow client") && isClient())
	{
		this.getSprite().PlaySound("Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg");
	}
	else if (cmd == this.getCommandID(grapple_sync_cmd) && isClient())
	{
		HandleGrapple(this, params, !canSend(this));
	}
	else if (isServer())
	{
		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer))
		{
			return;
		}
		for (uint i = 0; i < arrowTypeNames.length; i++)
		{
			if (cmd == this.getCommandID("pick " + arrowTypeNames[i]))
			{
				CBitStream params;
				params.write_u8(i);
				archer.arrow_type = i;
				this.SendCommand(this.getCommandID("arrow sync client"), params);
				break;
			}
		}
	}
}

void CycleToArrowType(CBlob@ this, ArcherInfo@ archer, u8 arrowType)
{
	archer.arrow_type = arrowType;
	if (this.isMyPlayer())
	{
		Sound::Play("/CycleInventory.ogg");
	}
	ClientSendArrowState(this);
}

void Callback_PickArrow(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	CBlob@ blob = player.getBlob();
	if (blob is null) return;

	u8 arrow_id;
	if (!params.saferead_u8(arrow_id)) return;

	ArcherInfo@ archer;
	if (!blob.get("archerInfo", @archer))
	{
		return;
	}

	archer.arrow_type = arrow_id;

	string matname = arrowTypeNames[arrow_id];
	blob.SendCommand(blob.getCommandID("pick " + matname));
}

// arrow pick menu
void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	AddIconToken("$Arrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 0, this.getTeamNum());
	AddIconToken("$WaterArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 1, this.getTeamNum());
	AddIconToken("$FireArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 2, this.getTeamNum());
	AddIconToken("$BombArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 3, this.getTeamNum());
	
	if (arrowTypeNames.length == 0)
	{
		return;
	}

	this.ClearGridMenusExceptInventory();
	Vec2f pos(gridmenu.getUpperLeftPosition().x + 0.5f * (gridmenu.getLowerRightPosition().x - gridmenu.getUpperLeftPosition().x),
	          gridmenu.getUpperLeftPosition().y - 32 * 1 - 2 * 24);
	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(arrowTypeNames.length, 2), getTranslatedString("Current arrow"));

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}
	const u8 arrowSel = archer.arrow_type;

	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		for (uint i = 0; i < arrowTypeNames.length; i++)
		{
			CBitStream params;
			params.write_u8(i);
			CGridButton @button = menu.AddButton(arrowIcons[i], getTranslatedString(arrowNames[i]), "ArcherLogic.as", "Callback_PickArrow", params);

			if (button !is null)
			{
				bool enabled = hasArrows(this, i);
				button.SetEnabled(enabled);
				button.selectOneOnClick = true;

				//if (enabled && i == ArrowType::fire && !hasReqs(this, i))
				//{
				//	button.hoverText = "Requires a fire source $lantern$";
				//	//button.SetEnabled( false );
				//}

				if (arrowSel == i)
				{
					button.SetSelected(1);
				}
			}
		}
	}
}

// auto-switch to appropriate arrow when picked up
void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	string itemname = blob.getName();
	if (this.isMyPlayer())
	{
		for (uint j = 0; j < arrowTypeNames.length; j++)
		{
			if (itemname == arrowTypeNames[j])
			{
				SetHelp(this, "help self action", "archer", getTranslatedString("$arrow$Fire arrow   $KEY_HOLD$$LMB$"), "", 3);
				if (j > 0 && this.getInventory().getItemsCount() > 1)
				{
					SetHelp(this, "help inventory", "archer", "$Help_Arrow1$$Swap$$Help_Arrow2$         $KEY_TAP$$KEY_F$", "", 2);
				}
				break;
			}
		}
	}

	CInventory@ inv = this.getInventory();
	if (inv.getItemsCount() == 0)
	{
		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer))
		{
			return;
		}

		for (uint i = 0; i < arrowTypeNames.length; i++)
		{
			if (itemname == arrowTypeNames[i])
			{
				archer.arrow_type = i;
				ClientSendArrowState(this);
				if (this.isMyPlayer())
				{
					Sound::Play("/CycleInventory.ogg");
				}
			}
		}
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (customData == Hitters::stab)
	{
		fletchArrow(this);
	}
}

void fletchArrow(CBlob@ this)
{
	// fletch arrow
	if (getNet().isServer())
	{
		CBlob@ mat_arrows = server_CreateBlobNoInit("mat_arrows");
		if (mat_arrows !is null)
		{
			mat_arrows.Tag("custom quantity");
			mat_arrows.Init();

			mat_arrows.server_SetQuantity(fletch_num_arrows);

			if (!this.server_PutInInventory(mat_arrows))
			{
				mat_arrows.setPosition(this.getPosition());
			}
		}
	}
	this.getSprite().PlaySound("Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	if (this.isAttached() && (canSend(this) || isServer()))
	{
		archer.grappling = false;
		SyncGrapple(this);
	}
}
