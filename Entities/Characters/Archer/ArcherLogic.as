// Archer logic

#include "ArcherCommon.as"
#include "ThrowCommon.as"
#include "Knocked.as"
#include "Hitters.as"
#include "RunnerCommon.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";

const int FLETCH_COOLDOWN = 45;
const int PICKUP_COOLDOWN = 15;
const int fletch_num_arrows = 1;
const int STAB_DELAY = 10;
const int STAB_TIME = 22;

void onInit(CBlob@ this)
{
	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.set_s8("charge_time", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);
	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("flesh");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
	this.getSprite().SetEmitSound("Entities/Characters/Archer/BowPull.ogg");
	this.addCommandID("shoot arrow");
	this.addCommandID("pickup arrow");
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
	if (right_click)
	{
		// cancel charging
		if (charge_state != ArcherParams::not_aiming)
		{
			charge_state = ArcherParams::not_aiming;
			archer.charge_time = 0;
			sprite.SetEmitSoundPaused(true);
			sprite.PlaySound("PopIn.ogg");
		}
		else if (canSend(this)) //otherwise grapple
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
			if (canSend(this))
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
				if (canSend(this))
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
							moveVars.wallrun_start = pos.y;
							moveVars.wallrun_current = pos.y;
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
						if (canSend(this))
						{
							archer.grappling = false;
							SyncGrapple(this);
						}
					}
				}
				else if (shouldReleaseGrapple(this, archer, map))
				{
					if (canSend(this))
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
		if ((getGameTime() + this.getNetworkID()) % 10 == 0)
		{
			hasarrow = hasArrows(this);

			if (!hasarrow && hasnormal)
			{
				// set back to default
				archer.arrow_type = ArrowType::normal;
				hasarrow = hasnormal;
			}
		}

		this.set_bool("has_arrow", hasarrow);
		this.Sync("has_arrow", isServer());

		archer.stab_delay = 0;
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
				SetKnocked(this, 15);
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
			ClientFire(this, charge_time, hasarrow, archer.arrow_type, true);
			charge_state = ArcherParams::legolas_charging;
			charge_time = ArcherParams::shoot_period - ArcherParams::legolas_charge_time;
			Sound::Play("FastBowPull.ogg", pos);
			archer.legolas_arrows--;

			if (archer.legolas_arrows == 0)
			{
				charge_state = ArcherParams::readying;
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

		const bool just_action1 = this.isKeyJustPressed(key_action1);

		//	printf("charge_state " + charge_state );

		if ((just_action1 || this.wasKeyPressed(key_action2) && !pressed_action2) &&
		        (charge_state == ArcherParams::not_aiming || charge_state == ArcherParams::fired))
		{
			charge_state = ArcherParams::readying;
			hasarrow = hasArrows(this);

			if (!hasarrow && hasnormal)
			{
				archer.arrow_type = ArrowType::normal;
				hasarrow = hasnormal;

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
					Sound::Play("Entities/Characters/Sounds/NoAmmo.ogg");
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
			charge_time++;

			if (charge_time >= ArcherParams::legolas_period)
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
	}
	else
	{
		if (charge_state > ArcherParams::readying)
		{
			if (charge_state < ArcherParams::fired)
			{
				ClientFire(this, charge_time, hasarrow, archer.arrow_type, false);

				charge_time = ArcherParams::fired_time;
				charge_state = ArcherParams::fired;
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
			//	print("archer.charge_time " + archer.charge_time + " / " + ArcherParams::shoot_period );
			if (archer.charge_state == ArcherParams::readying)
			{
				frame = 1 + float(archer.charge_time) / float(ArcherParams::shoot_period + ArcherParams::ready_time) * 7;
			}
			else if (archer.charge_state == ArcherParams::charging)
			{
				if (archer.charge_time <= ArcherParams::shoot_period)
				{
					frame = float(ArcherParams::ready_time + archer.charge_time) / float(ArcherParams::shoot_period) * 7;
				}
				else
					frame = 9;
			}
			else if (archer.charge_state == ArcherParams::legolas_ready)
			{
				frame = 10;
			}
			else if (archer.charge_state == ArcherParams::legolas_charging)
			{
				frame = 9;
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

		if (archer.fletch_cooldown == 0 && this.isKeyPressed(key_action2))
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

	if (getKnocked(this) > 0)
	{
		archer.grappling = false;
		archer.charge_state = 0;
		archer.charge_time = 0;
		return;
	}

	ManageGrapple(this, archer);

	if (this.isInInventory()) return;

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	ManageBow(this, archer, moveVars);
}

bool checkGrappleStep(CBlob@ this, ArcherInfo@ archer, CMap@ map, const f32 dist)
{
	if (map.getSectorAtPosition(archer.grapple_pos, "barrier") !is null)  //red barrier
	{
		if (canSend(this))
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

		if (canSend(this)) SyncGrapple(this);

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

				if (canSend(this))
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
				if (canSend(this))
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

void ClientFire(CBlob@ this, const s8 charge_time, const bool hasarrow, const u8 arrow_type, const bool legolas)
{
	//time to fire!
	if (hasarrow && canSend(this))  // client-logic
	{
		f32 arrowspeed;

		if (charge_time < ArcherParams::ready_time / 2 + ArcherParams::shoot_period_1)
		{
			arrowspeed = ArcherParams::shoot_max_vel * (1.0f / 3.0f);
		}
		else if (charge_time < ArcherParams::ready_time / 2 + ArcherParams::shoot_period_2)
		{
			arrowspeed = ArcherParams::shoot_max_vel * (4.0f / 5.0f);
		}
		else
		{
			arrowspeed = ArcherParams::shoot_max_vel;
		}

		ShootArrow(this, this.getPosition() + Vec2f(0.0f, -2.0f), this.getAimPos() + Vec2f(0.0f, -2.0f), arrowspeed, arrow_type, legolas);
	}
}

void ShootArrow(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed, const u8 arrow_type, const bool legolas = true)
{
	if (canSend(this))
	{
		// player or bot
		Vec2f arrowVel = (aimpos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		//print("arrowspeed " + arrowspeed);
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);
		params.write_u8(arrow_type);
		params.write_bool(legolas);

		this.SendCommand(this.getCommandID("shoot arrow"), params);
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
			if (b.getName() == "arrow")
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot arrow"))
	{
		Vec2f arrowPos = params.read_Vec2f();
		Vec2f arrowVel = params.read_Vec2f();
		u8 arrowType = params.read_u8();
		bool legolas = params.read_bool();

		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer))
		{
			return;
		}

		archer.arrow_type = arrowType;

		// return to normal arrow - server didnt have this synced
		if (!hasArrows(this, arrowType))
		{
			return;
		}

		if (legolas)
		{
			int r = 0;
			for (int i = 0; i < ArcherParams::legolas_arrows_volley; i++)
			{
				if (getNet().isServer())
				{
					CBlob@ arrow = CreateArrow(this, arrowPos, arrowVel, arrowType);
					if (i > 0 && arrow !is null)
					{
						arrow.Tag("shotgunned");
					}
				}
				this.TakeBlob(arrowTypeNames[ arrowType ], 1);
				arrowType = ArrowType::normal;

				//don't keep firing if we're out of arrows
				if (!hasArrows(this, arrowType))
					break;

				r = r > 0 ? -(r + 1) : (-r) + 1;

				arrowVel = arrowVel.RotateBy(ArcherParams::legolas_arrows_deviation * r, Vec2f());
				if (i == 0)
				{
					arrowVel *= 0.9f;
				}
			}
			this.getSprite().PlaySound("Entities/Characters/Archer/BowFire.ogg");
		}
		else
		{
			if (getNet().isServer())
			{
				CreateArrow(this, arrowPos, arrowVel, arrowType);
			}

			this.getSprite().PlaySound("Entities/Characters/Archer/BowFire.ogg");
			this.TakeBlob(arrowTypeNames[ arrowType ], 1);
		}

		archer.fletch_cooldown = FLETCH_COOLDOWN; // just don't allow shoot + make arrow
	}
	else if (cmd == this.getCommandID("pickup arrow"))
	{
		CBlob@ arrow = getPickupArrow(this);
		bool spriteArrow = canPickSpriteArrow(this, false); // unnecessary

		if (arrow !is null || spriteArrow)
		{
			if (arrow !is null)
			{
				ArcherInfo@ archer;
				if (!this.get("archerInfo", @archer))
				{
					return;
				}
				const u8 arrowType = archer.arrow_type;
				if (arrowType == ArrowType::bomb)
				{
					arrow.set_u16("follow", 0); //this is already synced, its in command.
					arrow.setPosition(this.getPosition());
					return;
				}
			}

			if (getNet().isServer())
			{
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
						canPickSpriteArrow(this, true);
					}
				}
			}

			this.getSprite().PlaySound("Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg");
		}
	}
	else if (cmd == this.getCommandID(grapple_sync_cmd))
	{
		HandleGrapple(this, params, !canSend(this));
	}
	else if (cmd == this.getCommandID("cycle"))  //from standardcontrols
	{
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
			if (this.getBlobCount(arrowTypeNames[type]) > 0)
			{
				archer.arrow_type = type;
				if (this.isMyPlayer())
				{
					Sound::Play("/CycleInventory.ogg");
				}
				break;
			}
		}
	}
	else
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
				archer.arrow_type = i;
				break;
			}
		}
	}
}

// arrow pick menu
void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
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
			string matname = arrowTypeNames[i];
			CGridButton @button = menu.AddButton(arrowIcons[i], getTranslatedString(arrowNames[i]), this.getCommandID("pick " + matname));

			if (button !is null)
			{
				bool enabled = this.getBlobCount(arrowTypeNames[i]) > 0;
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
			}
		}
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (customData == Hitters::stab)
	{
		if (damage > 0.0f)
		{

			// fletch arrow
			if (hitBlob.hasTag("tree"))	// make arrow from tree
			{
				if (getNet().isServer())
				{
					CBlob@ mat_arrows = server_CreateBlobNoInit('mat_arrows');
					if (mat_arrows !is null)
					{
						mat_arrows.Tag('custom quantity');
						mat_arrows.Init();

						mat_arrows.server_SetQuantity(fletch_num_arrows);

						if (not this.server_PutInInventory(mat_arrows))
						{
							mat_arrows.setPosition(this.getPosition());
						}
					}
				}
				this.getSprite().PlaySound("Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg");
			}
			else
				this.getSprite().PlaySound("KnifeStab.ogg");
		}

		if (blockAttack(hitBlob, velocity, 0.0f))
		{
			this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
			SetKnocked(this, 30);
		}
	}
}

