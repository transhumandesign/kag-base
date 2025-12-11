// Runner Movement Walking

#include "RunnerCommon.as"
#include "MakeDustParticle.as";
#include "FallDamageCommon.as";
#include "KnockedCommon.as";

void onInit(CMovement@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	RunnerMoveVars@ moveVars;
	if (!blob.get("moveVars", @moveVars))
	{
		return;
	}

	if (//(ultimately in charge of this blob's movement)
		(blob.isMyPlayer()) ||
		(blob.isBot() && isServer())
	) {
		HandleStuckAtTop(blob);
	}

	const bool left		= blob.isKeyPressed(key_left);
	const bool right	= blob.isKeyPressed(key_right);
	const bool up		= blob.isKeyPressed(key_up);
	const bool down		= blob.isKeyPressed(key_down);

	const bool isknocked = isKnocked(blob);

	const bool is_client = getNet().isClient();

	CMap@ map = blob.getMap();
	Vec2f vel = blob.getVelocity();
	Vec2f pos = blob.getPosition();
	CShape@ shape = blob.getShape();

	const f32 vellen = shape.vellen;
	const bool onground = blob.isOnGround() || blob.isOnLadder();

	if (is_client && getGameTime() % 3 == 0)
	{
		const string fallscreamtag = "_fallingscream";
		if (vel.y > 0.2f)
		{
			if (vel.y > BaseFallSpeed() * 1.8f && !blob.isInInventory())
			{
				if (!blob.hasTag(fallscreamtag))
				{
					blob.Tag(fallscreamtag);
					Sound::Play("man_scream.ogg", pos);
				}
			}
		}
		else
		{
			blob.Untag(fallscreamtag);
		}

		/* unfortunately, this doesn't work with archer bow draw stuff;
			might need to bind separate sounds cause this solution is much better.

			if (vel.y > BaseFallSpeed() * 1.1f)
			{
				if (!blob.hasTag(fallscreamtag))
				{
					blob.Tag(fallscreamtag);

					CSprite@ sprite = blob.getSprite();

					sprite.SetEmitSoundVolume(1.0f);
					sprite.SetEmitSound( "man_scream.ogg" );
					sprite.SetEmitSoundPaused( false );
					sprite.RewindEmitSound();
				}
			}
		}
		else
		{
			blob.Untag(fallscreamtag);
			CSprite@ sprite = blob.getSprite();

			sprite.SetEmitSoundPaused( true );
		}*/
	}

	u8 crouch_through = blob.get_u8("crouch_through");
	if (crouch_through > 0)
	{
		crouch_through--;
		blob.set_u8("crouch_through", crouch_through);
	}

	if (onground || blob.isInWater())  //also reset when vaulting
	{
		moveVars.walljumped_side = Walljump::NONE;
		moveVars.fallCount = -1;
	}

	// ladder - overrides other movement completely
	if (blob.isOnLadder() && !blob.isAttached() && !blob.isOnGround() && !isknocked)
	{
		shape.SetGravityScale(0.0f);
		Vec2f ladderforce;

		if (up)
		{
			ladderforce.y -= 1.0f;
		}

		if (down)
		{
			ladderforce.y += 1.2f;
		}

		if (left)
		{
			ladderforce.x -= 1.0f;
		}

		if (right)
		{
			ladderforce.x += 1.0f;
		}

		blob.AddForce(ladderforce * moveVars.overallScale * 100.0f);
		//damp vel
		Vec2f vel = blob.getVelocity();
		vel *= 0.05f;
		blob.setVelocity(vel);

		moveVars.jumpCount = -1;
		moveVars.fallCount = -1;

		CleanUp(this, blob, moveVars);
		return;
	}

	shape.SetGravityScale(1.0f);
	shape.getVars().onladder = false;

	//swimming - overrides other movement partially
	if (blob.isInWater() && !isknocked)
	{
		CMap@ map = getMap();

		const f32 swimspeed = moveVars.swimspeed;
		const f32 swimforce = moveVars.swimforce;
		const f32 edgespeed = moveVars.swimspeed * moveVars.swimEdgeScale;

		Vec2f waterForce;

		moveVars.jumpCount = 50;

		//up and down
		if (up)
		{
			if (vel.y > -swimspeed)
			{
				if (!map.isInWater(pos + Vec2f(0, -8)))
				{
					waterForce.y -= 0.6f;
				}
				else
				{
					waterForce.y -= 0.8f;
				}
			}

			// more push near ledge
			if (vel.y > -(swimspeed * 3.3))
			{
				if (blob.isOnWall())
				{
					moveVars.jumpCount = 0;

					if (blob.isOnMap())
					{
						waterForce.y -= 2.0f;
					}
					else
					{
						waterForce.y -= 1.5f;
					}
				}
			}
		}

		if (down && vel.y < swimspeed)
		{
			waterForce.y += 1;
		}

		//left and right
		if (left && vel.x > -swimspeed)
		{
			waterForce.x -= 1;
		}

		if (right && vel.x < swimspeed)
		{
			waterForce.x += 1;
		}

		waterForce *= swimforce * moveVars.overallScale;
		blob.AddForce(waterForce);


		if (!blob.isOnGround() && !blob.isOnLadder())
		{
			CleanUp(this, blob, moveVars);
			return;				//done for swimming -----------------------

		}
		else
		{
			moveVars.walkFactor *= 0.2f;
			moveVars.jumpFactor *= 0.5f;
		}
	}

	//otherwise, do normal movement :)

	//walljumping, wall running and wall sliding

	if (vel.y > 5.0f)
	{
		//moveVars.walljumped_side = Walljump::BOTH;
	}
	else if (vel.y > 4.0f)
	{
		if (moveVars.walljumped_side == Walljump::JUMPED_LEFT)
			moveVars.walljumped_side = Walljump::LEFT;

		if (moveVars.walljumped_side == Walljump::JUMPED_RIGHT)
			moveVars.walljumped_side = Walljump::RIGHT;
	}

	if (!blob.isOnCeiling() && !isknocked &&
	        !blob.isOnLadder() && (up || left || right || down))  //key pressed
	{
		//check solid tiles
		const f32 ts = map.tilesize;
		const f32 y_ts = ts * 0.2f;
		const f32 x_ts = ts * 1.4f;

		bool surface_left = map.isTileSolid(pos + Vec2f(-x_ts, y_ts - map.tilesize)) ||
		                    map.isTileSolid(pos + Vec2f(-x_ts, y_ts));
		if (!surface_left)
		{
			surface_left = checkForSolidMapBlob(map, pos + Vec2f(-x_ts, y_ts - map.tilesize), blob) ||
			               checkForSolidMapBlob(map, pos + Vec2f(-x_ts, y_ts), blob);
		}

		bool surface_right = map.isTileSolid(pos + Vec2f(x_ts, y_ts - map.tilesize)) ||
		                     map.isTileSolid(pos + Vec2f(x_ts, y_ts));
		if (!surface_right)
		{
			surface_right = checkForSolidMapBlob(map, pos + Vec2f(x_ts, y_ts - map.tilesize), blob) ||
			                checkForSolidMapBlob(map, pos + Vec2f(x_ts, y_ts), blob);
		}

		//not checking blobs for this - perf
		bool surface_above = map.isTileSolid(pos + Vec2f(y_ts, -x_ts)) || map.isTileSolid(pos + Vec2f(-y_ts, -x_ts));
		bool surface_below = map.isTileSolid(pos + Vec2f(y_ts, x_ts)) || map.isTileSolid(pos + Vec2f(-y_ts, x_ts));

		bool surface = surface_left || surface_right;

		const f32 slidespeed = 2.45f;

		// crouch through platforms and crates
		if (down && !onground && this.getVars().aircount > 2)
		{
			blob.set_u8("crouch_through", 3);
		}

		if (blob.isKeyJustPressed(key_down))
		{
			int touching = blob.getTouchingCount();
			for (int i = 0; i < touching; i++)
			{
				CBlob@ b = blob.getTouchingByIndex(i);
				if ((b.isPlatform() && b.getAngleDegrees() == 0.0f) || b.getName() == "crate")
				{
					b.getShape().checkCollisionsAgain = true;
					blob.getShape().checkCollisionsAgain = true;
					blob.set_u8("crouch_through", 3);
				}
			}

			Vec2f pos = blob.getPosition() + Vec2f(0, 12);
			CBlob@[] blobs;
			if (getMap().getBlobsInRadius(pos, 4, blobs))
			{
				for (int i = 0; i < blobs.size(); i++)
				{
					CBlob@ b = blobs[i];
					if ((b.isPlatform() && b.getAngleDegrees() == 0.0f) || b.getName() == "crate")
					{
						b.getShape().checkCollisionsAgain = true;
						blob.getShape().checkCollisionsAgain = true;
						blob.set_u8("crouch_through", 3);
					}
				}
			}

		}

		// cancel any further walljump if not pressing up
		if (!up)
		{
			moveVars.wallrun_count = 1000;
		}

		//wall jumping/running
		if (up && surface && 									//only on surface
		        moveVars.walljumped_side != Walljump::BOTH &&		//do nothing if jammed
		        !(left && right) &&									//do nothing if pressing both sides
		        !onground)
		{
			bool wasNONE = (moveVars.walljumped_side == Walljump::NONE);

			bool jumpedLEFT = (moveVars.walljumped_side == Walljump::JUMPED_LEFT);
			bool jumpedRIGHT = (moveVars.walljumped_side == Walljump::JUMPED_RIGHT);

			bool dust = false;

			if (moveVars.jumpCount > 3) //wait some time to be properly in the air
			{
				//set contact point
				bool set_contact = false;
				bool set_contact_candidate = false;

				// only initiate a contact IF the player is not going to waste boosting if it was the first walljump attempt
				// this has the unfortunate side effect that when wanting to climb 2 air gap large towers the walljump
				// would ideally be initiated earlier.

				// players can avoid this by tapping up shortly to make a small jump, which will make them reach minimal
				// velocity faster.

				// to mitigate part of this we also ensure this is only done for the first jump.
				// this should assist with newbies climbing walls, while letting more advanced players begin walljumps as
				// early as they want

				if (left && surface_left && (moveVars.walljumped_side == Walljump::RIGHT || jumpedRIGHT || wasNONE))
				{
					set_contact_candidate = true;
				}
				if (right && surface_right && (moveVars.walljumped_side == Walljump::LEFT || jumpedLEFT || wasNONE))
				{
					set_contact_candidate = true;
				}

				if (set_contact_candidate)
				{
					// print("contact candidate @" + getGameTime() + ": side was " + moveVars.walljumped_side);

					// are we starting to hit the wall?
					// then we want our first climb to be a contact
					moveVars.wallrun_count = 1000;
				}

				// set contact immediately if jumping at the wall from an angle; not immediately if hugging wall
                if (set_contact_candidate && ((vel.y >= -0.0f && vel.y < slidespeed && Maths::Abs(blob.getOldVelocity().x) == 0) || Maths::Abs(blob.getOldVelocity().x) > 0 || !wasNONE))
				{
					// print("candidate passes, & our velocity is " + vel.y);

					// ready to hit the wall, and conditions align?
					// reset wallclimb counters and let's start
					moveVars.walljumped_side = left ? Walljump::LEFT : Walljump::RIGHT;
					moveVars.wallrun_count = 0;
					set_contact = true;
				}

				// wallrun: is the player still trying to climb up, and is he not falling too fast to allow it
				if (vel.y < slidespeed &&
				        ((left && surface_left && !jumpedLEFT) || (right && surface_right && !jumpedRIGHT) || set_contact))
				{
					// allow 1st climb "unconditionally" (there were checks above)
					// allow next climbs depending on a velocity condition
					const bool should_trigger_climb = set_contact || (!set_contact_candidate && vel.y >= -2.0f);

					// limit climbs to an arbitrarily choosen number
					if (should_trigger_climb && moveVars.wallrun_count < 2)
					{
						vel.Set(0, -moveVars.jumpMaxVel * 1.4f);
						blob.setVelocity(vel);

						// reduce sound spam, especially when climbing 2 air gap large towers
						if (!set_contact) { blob.getSprite().PlayRandomSound("/StoneJump"); }
						dust = true;

						++moveVars.wallrun_count;
						moveVars.walljumped = true;
					}
					else
					{
						moveVars.walljumped = false;
					}
				}
				//walljump
				else if (vel.y < slidespeed &&
				         ((left && surface_right) || (right && surface_left)) &&
				         !surface_below && !jumpedLEFT && !jumpedRIGHT)
				{
					f32 walljumpforce = 4.0f;
					vel.Set(surface_right ? -walljumpforce : walljumpforce, -2.0f);
					blob.setVelocity(vel);

					dust = true;

					moveVars.jumpCount = 0;

					if (right)
					{
						moveVars.walljumped_side = Walljump::JUMPED_LEFT;
					}
					else
					{
						moveVars.walljumped_side = Walljump::JUMPED_RIGHT;
					}
				}

				if (surface_above)
				{
					// prevent any new walljump on that wall if a wall is blocking us above
					// but allow one to happen (as the code above will have run)
					moveVars.wallrun_count = 1000;
				}
			}

			if (dust)
			{
				Vec2f dust_pos = (Vec2f(right ? 4.0f : -4.0f, 0.0f) + pos);
				MakeDustParticle(dust_pos, "Smoke.png");
			}
		}
		else
		{
			moveVars.walljumped = false;
		}

		//wall sliding
		{
			Vec2f groundNormal = blob.getGroundNormal();
			if (
			    (left || right) && // require direction key hold
			    Maths::Abs(groundNormal.y) <= 0.01f) //sliding on wall
			{
				Vec2f force;

				Vec2f vel = blob.getVelocity();
				if (vel.y >= slidespeed && (blob.isFacingLeft() ? groundNormal.x > 0 : groundNormal.x < 0))
				{
					f32 temp = vel.y * 0.9f;
					Vec2f new_vel(vel.x * 0.9f, temp < slidespeed ? slidespeed : temp);
					blob.setVelocity(new_vel);

					if (is_client) // effect
					{
						if (!moveVars.wallsliding)
						{
							blob.getSprite().PlayRandomSound("/Scrape");
						}

						//falling for almost a second so add effects
						if (moveVars.jumpCount > 20)
						{
							int gametime = getGameTime();
							if (gametime % (uint(Maths::Max(0, 7 - int(Maths::Abs(vel.y)))) + 3) == 0)
							{
								MakeDustParticle(pos, "/dust2.png");
								blob.getSprite().PlayRandomSound("/Scrape");
							}
						}
					}

					moveVars.wallsliding = true;
				}
			}
		}
	}

	// vaulting

	if (blob.isKeyPressed(key_up) && moveVars.canVault)
	{
		// boost over corner
		Vec2f groundNormal = blob.getGroundNormal();
		bool onMap = blob.isOnMap();
		bool canFreeVault = !onMap && moveVars.jumpCount < 5;
		groundNormal.Normalize();
		bool sidekeypressed = ((left && (groundNormal.x > 0.1f || canFreeVault)) ||
		                       (right && (groundNormal.x < -0.1f || canFreeVault)));

		if (sidekeypressed)
		{
			bool vault = false;

			if (left)
			{
				f32 movingside = -1.0f;

				if (canVault(blob, map, movingside))
				{
					vault = true;
				}
			}

			if (right)
			{
				f32 movingside = 1.0f;

				if (canVault(blob, map, movingside))
				{
					vault = true;
				}
			}

			if (vault)
			{
				moveVars.jumpCount = -3;

				moveVars.walljumped_side = Walljump::NONE;
				moveVars.wallrun_count = 1000;
			}
		}
	}

	//jumping

	if (moveVars.jumpFactor > 0.01f && !isknocked)
	{

		if (onground)
		{
			moveVars.jumpCount = 0;
		}
		else
		{
			moveVars.jumpCount++;
		}

		if (up && vel.y > -moveVars.jumpMaxVel)
		{
			moveVars.jumpStart = 0.7f;
			moveVars.jumpMid = 0.2f;
			moveVars.jumpEnd = 0.1f;
			bool crappyjump = false;

			//todo what constitutes a crappy jump? maybe carrying heavy?
			if (crappyjump)
			{
				moveVars.jumpStart *= 0.79f;
				moveVars.jumpMid *= 0.69f;
				moveVars.jumpEnd *= 0.59f;
			}

			Vec2f force = Vec2f(0, 0);
			f32 side = 0.0f;

			if (blob.isFacingLeft() && left)
			{
				side = -1.0f;
			}
			else if (!blob.isFacingLeft() && right)
			{
				side = 1.0f;
			}

			// jump
			if (moveVars.jumpCount <= 0)
			{
				force.y -= 1.5f;
			}
			else if (moveVars.jumpCount < 3)
			{
				force.y -= moveVars.jumpStart;
				//force.x += side * moveVars.jumpMid;
			}
			else if (moveVars.jumpCount < 6)
			{
				force.y -= moveVars.jumpMid;
				//force.x += side * moveVars.jumpEnd;
			}
			else if (moveVars.jumpCount < 8)
			{
				force.y -= moveVars.jumpEnd;
			}

			//if (blob.isOnWall()) {
			//  force.y *= 1.1f;
			//}

			force *= moveVars.jumpFactor * moveVars.overallScale * 60.0f;


			blob.AddForce(force);

			// sound

			if (moveVars.jumpCount == 1 && is_client)
			{
				TileType tile = blob.getMap().getTile(blob.getPosition() + Vec2f(0.0f, blob.getRadius() + 4.0f)).type;

				if (blob.getMap().isTileGroundStuff(tile))
				{
					blob.getSprite().PlayRandomSound("/EarthJump");
				}
				else
				{
					blob.getSprite().PlayRandomSound("/StoneJump");
				}
			}
		}
	}

	//walking & stopping

	bool stop = true;
	if (!onground)
	{
		if (isknocked)
			stop = false;
		else if (blob.hasTag("dont stop til ground"))
			stop = false;
	}
	else
	{
		blob.Untag("dont stop til ground");
	}

	bool left_or_right = (left || right);
	{
		// carrying heavy
		CBlob@ carryBlob = blob.getCarriedBlob();
		if (carryBlob !is null)
		{
			if (carryBlob.hasTag("medium weight"))
			{
				moveVars.walkFactor *= 0.8f;
				moveVars.jumpFactor *= 0.8f;
			}
			else if (carryBlob.hasTag("heavy weight"))
			{
				moveVars.walkFactor *= 0.6f;
				moveVars.jumpFactor *= 0.5f;
			}
		}

		bool facingleft = blob.isFacingLeft();
		bool stand = blob.isOnGround() || blob.isOnLadder();
		Vec2f walkDirection;
		const f32 turnaroundspeed = 1.3f;
		const f32 normalspeed = 1.0f;
		const f32 backwardsspeed = 0.8f;

		if (right)
		{
			if (vel.x < -0.1f)
			{
				walkDirection.x += turnaroundspeed;
			}
			else if (facingleft)
			{
				walkDirection.x += backwardsspeed;
			}
			else
			{
				walkDirection.x += normalspeed;
			}
		}

		if (left)
		{
			if (vel.x > 0.1f)
			{
				walkDirection.x -= turnaroundspeed;
			}
			else if (!facingleft)
			{
				walkDirection.x -= backwardsspeed;
			}
			else
			{
				walkDirection.x -= normalspeed;
			}
		}

		f32 force = 1.0f;

		f32 lim = 0.0f;

		{
			if (left_or_right)
			{
				lim = moveVars.walkSpeed;
				if (!onground)
				{
					lim = moveVars.walkSpeedInAir;
				}

				lim *= moveVars.walkFactor * Maths::Abs(walkDirection.x);
			}

			Vec2f stop_force;

			bool greater = vel.x > 0;
			f32 absx = greater ? vel.x : -vel.x;

			if (moveVars.walljumped)
			{
				moveVars.stoppingFactor *= 0.5f;
				moveVars.walkFactor *= 0.6f;

				//hack - fix gliding
				if (vel.y > 0 && blob.hasTag("shielded"))
					moveVars.walkFactor *= 0.6f;
			}

			bool stopped = false;
			if (absx > lim)
			{
				if (stop) //stopping
				{
					stopped = true;
					stop_force.x -= (absx - lim) * (greater ? 1 : -1);

					stop_force.x *= moveVars.overallScale * 30.0f * moveVars.stoppingFactor *
					                (onground ? moveVars.stoppingForce : moveVars.stoppingForceAir);

					if (absx > 3.0f)
					{
						f32 extra = (absx - 3.0f);
						f32 scale = (1.0f / ((1 + extra) * 2));
						stop_force.x *= scale;
					}

					blob.AddForce(stop_force);
				}
			}

			if (!isknocked && ((absx < lim) || left && greater || right && !greater))
			{
				force *= moveVars.walkFactor * moveVars.overallScale * 30.0f;
				if (Maths::Abs(force) > 0.01f)
				{
					blob.AddForce(walkDirection * force);
				}
			}
		}

	}

	//falling count
	if (!onground && vel.y > 0.1f)
	{
		moveVars.fallCount++;
	}
	else
	{
		moveVars.fallCount = 0;
	}

	CleanUp(this, blob, moveVars);
}

//some specific helpers

const f32 offsetheight = -1.2f;
bool canVault(CBlob@ blob, CMap@ map, f32 movingside)
{
	Vec2f pos = blob.getPosition();

	f32 tilesize = map.tilesize;
	if (!map.isTileSolid(Vec2f(pos.x + movingside * tilesize, pos.y + tilesize * (offsetheight))) &&
	        !map.isTileSolid(Vec2f(pos.x + movingside * tilesize, pos.y + tilesize * (offsetheight + 1))) &&
	        map.isTileSolid(Vec2f(pos.x + movingside * tilesize, pos.y + tilesize * (offsetheight + 2))))
	{

		bool hasRayFace = map.rayCastSolid(pos + Vec2f(0, -6), pos + Vec2f(movingside * 12, -6));
		if (hasRayFace)
			return false;

		bool hasRayFeet = map.rayCastSolid(pos + Vec2f(0, 6), pos + Vec2f(movingside * 12, 6));

		if (hasRayFeet)
			return true;

		//TODO: fix flags sync and hitting so we dont have to do this
		{
			return !checkForSolidMapBlob(map, pos + Vec2f(movingside * 12, -6)) &&
			       checkForSolidMapBlob(map, pos + Vec2f(movingside * 12, 6));
		}
	}
	return false;
}

//cleanup all vars here - reset clean slate for next frame

void CleanUp(CMovement@ this, CBlob@ blob, RunnerMoveVars@ moveVars)
{
	//reset all the vars here
	moveVars.jumpFactor = 1.0f;
	moveVars.walkFactor = 1.0f;
	moveVars.stoppingFactor = 1.0f;
	moveVars.wallsliding = false;
	moveVars.canVault = true;
}

//TODO: fix flags sync and hitting so we dont need this
// blob is an optional parameter to check collisions for, e.g. you don't want enemies to climb a trapblock
bool checkForSolidMapBlob(CMap@ map, Vec2f pos, CBlob@ blob = null)
{
	CBlob@ _tempBlob; CShape@ _tempShape;
	@_tempBlob = map.getBlobAtPosition(pos);
	if (_tempBlob !is null && _tempBlob.isCollidable())
	{
		@_tempShape = _tempBlob.getShape();
		if (_tempShape.isStatic())
		{
			if (blob !is null && (_tempBlob.getName() == "wooden_platform" || _tempBlob.getName() == "bridge"))
			{
				f32 angle = _tempBlob.getAngleDegrees();
				Vec2f runnerPos = blob.getPosition();
				Vec2f platPos = _tempBlob.getPosition();

				if (angle == 90.0f && runnerPos.x > platPos.x && (blob.isKeyPressed(key_left) || blob.wasKeyPressed(key_left)))
				{
					// platform is facing right
					return true;

				}
				else if(angle == 270.0f && runnerPos.x < platPos.x && (blob.isKeyPressed(key_right) || blob.wasKeyPressed(key_right)))
				{
					// platform is facing left
					return true;
				}

				return false;
			}

			if (blob !is null && !blob.doesCollideWithBlob(_tempBlob))
			{
				return false;
			}

			return true;
		}
	}

	return false;
}

//move us if we're stuck at the top of the map
void HandleStuckAtTop(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	//at top of map
	if (pos.y < 16.0f)
	{
		CMap@ map = getMap();
		float y = 2.5f * map.tilesize;
		//solid underneath
		if (map.isTileSolid(Vec2f(pos.x, y)))
		{
			//"stuck"; check left and right
			int rad = 10;
			bool found = false;
			float tx = pos.x;
			for (int i = 0; i < rad && !found; i++)
			{
				for (int dir = -1; dir <= 1 && !found; dir += 2)
				{
					tx = pos.x + (dir * i) * map.tilesize;
					if (!map.isTileSolid(Vec2f(tx, y)))
					{
						found = true;
					}
				}
			}
			if (found)
			{
				Vec2f towards(tx - pos.x, -1);
				towards.Normalize();
				this.setPosition(pos + towards * 0.5f);
				this.AddForce(towards * 10.0f);
			}
		}
	}
}
