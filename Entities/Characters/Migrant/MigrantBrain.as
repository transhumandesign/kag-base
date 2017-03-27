// Migrant brain

#define SERVER_ONLY

#include "/Entities/Common/Emotes/EmotesCommon.as"
#include "MigrantCommon.as"
#include "HallCommon.as"

void onInit(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	blob.set_bool("justgo", false);
	blob.set_Vec2f("target spot", Vec2f_zero);
	blob.set_u8("strategy", XORRandom(2));
	this.getCurrentScript().removeIfTag = "dead";   //won't be removed if not bot cause it isnt run
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.getCurrentScript().tickFrequency = 60;
}

void onTick(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	if (blob.getTeamNum() > 10)
		return;

	const bool isStatic = blob.getShape().isStatic();

	if (isStatic)
	{
		this.getCurrentScript().tickFrequency = 60;
	}

	u8 strategy = 0;

	if (!isStatic)
	{
		strategy = blob.get_u8("strategy");

		// normal AI
		if (strategy != Strategy::runaway)
		{
			CBlob @target = this.getTarget();
			this.getCurrentScript().tickFrequency = target is null ? 60 : 30;

			if (target !is null)
			{
				const int state = this.getState();

				if (strategy != Strategy::idle)
				{
					GoToBlob(this, target);
				}

				// change strategy?

				//	printf("strategy " + strategy );
				if ((strategy == Strategy::find_teammate && (state == CBrain::stuck || state == CBrain::wrong_path)) || strategy == Strategy::idle || XORRandom(15) == 0)
				{
					@target = getOwner(blob);
					this.SetTarget(target);

					if (target !is null)
					{
						strategy = Strategy::find_teammate;
					}
					else
					{
						strategy = Strategy::idle;
					}
					// printf("strategy " + strategy);
					SetStrategy(blob, strategy);
				}


				// lose target if its killed (with random cooldown)
				if (target !is null)
					if (target.isInFlames() || target.isInWater() || (XORRandom(10) == 0 && target.hasTag("dead")))
					{
						this.SetTarget(null);
					}
			}
			else
			{
				this.SetTarget(getNewTarget(this, blob));
			}
		}
	}

	// attack?

	if (this.getCurrentScript().tickFrequency > 1 || XORRandom(15) == 0)
	{
		CBlob@ attacker = getAttacker(this, blob);
		if (attacker !is null)
		{
			DitchOwner(blob);

			//set brain param
			this.SetTarget(attacker);
			SetStrategy(blob, Strategy::runaway);
		}
	}

	if (!isStatic && strategy == Strategy::runaway)
	{
		this.getCurrentScript().tickFrequency = 1;
		DitchOwner(blob);

		if (!Runaway(this, blob, this.getTarget()) || XORRandom(50) == 0)
		{
			blob.set_u8("strategy", Strategy::idle);
			this.SetTarget(null);
			this.getCurrentScript().tickFrequency = 60;
		}
	}

	// water?

	if (!isStatic && blob.isInWater())
	{
		this.getCurrentScript().tickFrequency = 1;
		blob.setKeyPressed(key_up, true);
	}
}

void DitchOwner(CBlob@ blob)
{
	//un-owner
	CBlob@ owner = getOwner(blob);
	if (owner !is null)
	{
		returnWorker(owner, getHallsFor(owner, BASE_RADIUS), blob);
	}
	ResetWorker(blob);   //unstatic
}

void SetStrategy(CBlob@ blob, const u8 strategy)
{
	blob.set_u8("strategy", strategy);
	blob.Sync("strategy", true);
}

f32 getSeekTeamPriority(CBlob @this, CBlob @other)
{
	const string othername = other.getName();
	if (othername == "factory")
	{
		if (!isRoomFullOfMigrants(other))
			return 0.0f;
	}
	else
	{
		if (other.hasTag("migrant room"))
			return 1.0f;
		if (other.getPlayer() !is null)
			return 10.0f;
	}
	return 100.9f;
}

CBlob@ getNewTarget(CBrain@ this, CBlob @blob)
{
	const u8 strategy = blob.get_u8("strategy");
	Vec2f pos = blob.getPosition();

	CBlob@[] potentials;
	CBlob@[] blobsInRadius;
	if (blob.getMap().getBlobsInRadius(pos, SEEK_RANGE, @blobsInRadius))
	{
		if (strategy == Strategy::find_teammate || strategy == Strategy::idle)
		{
			// find players or campfires

			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (b !is blob && b.getTeamNum() == blob.getTeamNum() && !b.isInFlames() && !b.isInWater())
				{
					// omit full beds or when bot
					const string name = b.getName();
					if (name == "dorm" && (blob.getPlayer() !is null || isRoomFullOfMigrants(b)))
					{
						continue;
					}

					potentials.push_back(b);
				}
			}
		}

		// pick closest/best

		if (potentials.length > 0)
		{
			while (potentials.size() > 0)
			{
				f32 closestDist = 999999.9f;
				uint closestIndex = 999;

				for (uint i = 0; i < potentials.length; i++)
				{
					CBlob @b = potentials[i];
					Vec2f bpos = b.getPosition();
					f32 distToPlayer = (bpos - pos).getLength();
					f32 dist = distToPlayer * getSeekTeamPriority(blob, b);
					if (distToPlayer > 0.0f && dist < closestDist)
					{
						closestDist = dist;
						closestIndex = i;
					}
				}
				if (closestIndex >= 999)
				{
					break;
				}

				return potentials[closestIndex];
			}
		}
	}
	return null;
}

CBlob@ getAttacker(CBrain@ this, CBlob @blob)
{
	Vec2f pos = blob.getPosition();

	CBlob@[] potentials;
	CBlob@[] blobsInRadius;
	CMap@ map = blob.getMap();
	if (map.getBlobsInRadius(pos, ENEMY_RANGE, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is blob
			        && (((b.getTeamNum() != blob.getTeamNum() && b.hasTag("player") && !b.hasTag("migrant") && !b.hasTag("dead")) || (b.isInFlames() || b.hasTag("animal"))) 	// runaway from enemies and from burning stuff
			            && !map.rayCastSolid(pos, b.getPosition()))
			   )
			{
				potentials.push_back(b);
			}
		}
	}

	// pick closest/best

	if (potentials.length > 0)
	{
		CBlob@[] closest;
		while (potentials.size() > 0)
		{
			f32 closestDist = 999999.9f;
			uint closestIndex = 999;

			for (uint i = 0; i < potentials.length; i++)
			{
				CBlob @b = potentials[i];
				Vec2f bpos = b.getPosition();
				f32 dist = (bpos - pos).getLength();
				if (dist < closestDist)
				{
					closestDist = dist;
					closestIndex = i;
				}
			}
			if (closestIndex >= 999)
			{
				break;
			}
			return potentials[closestIndex];
		}
	}

	return null;
}

void Repath(CBrain@ this)
{
	this.SetPathTo(this.getTarget().getPosition(), false);
}

void GoToBlob(CBrain@ this, CBlob @target)
{
	CBlob @blob = this.getBlob();
	Vec2f mypos = blob.getPosition();
	Vec2f targetpos = target.getPosition();
	Vec2f targetVector = targetpos - blob.getPosition();
	f32 targetDistance = targetVector.Length();
	// check if we have a clear area to the target
	bool justGo = false;

	if (targetDistance < 40.0f && target.hasTag("player")) // keep distance from player
	{
		return;
	}

	if (targetDistance < 80.0f)
	{
		Vec2f col;
		if (!getMap().rayCastSolid(mypos, targetpos, col))
		{
			justGo = true;
		}
	}

	// repath if no clear path after going at it
	if (!justGo && blob.get_bool("justgo"))
	{
		Repath(this);
	}
	else // occasionally repath when target is off of our spot
		if (XORRandom(50) == 0 && (blob.get_Vec2f("target spot") - targetpos).getLength() > 50.0f)
		{
			Repath(this);
		}

	//printf("targetDistance " + targetDistance );
	blob.set_bool("justgo", justGo);

	const bool stuck = this.getState() == CBrain::stuck;

	if (justGo)
	{
		if (!stuck || XORRandom(100) < 10)
		{
			JustGo(this, target);
			if (!stuck)
			{
				blob.set_u8("emote", Emotes::off);
			}
		}
		else
			justGo = false;
	}

	if (!justGo)
	{
		// printInt("state", this.getState() );
		switch (this.getState())
		{
			case CBrain::idle:
				Repath(this);
				break;

			case CBrain::searching:
				//if (XORRandom(100) == 0)
				//	set_emote( blob, Emotes::dots );
				break;

			case CBrain::has_path:
				this.SetSuggestedKeys();  // set walk keys here
				break;

			case CBrain::stuck:
				Repath(this);
				if (XORRandom(100) == 0)
				{
					set_emote(blob, Emotes::frown);
					f32 dist = Maths::Abs(targetpos.x - mypos.x);
					if (dist > 20.0f)
					{
						if (dist < 50.0f)
							set_emote(blob, targetpos.y > mypos.y ? Emotes::down : Emotes::up);
						else
							set_emote(blob, targetpos.x > mypos.x ? Emotes::right : Emotes::left);
					}
				}
				break;

			case CBrain::wrong_path:
				Repath(this);
				if (XORRandom(100) == 0)
				{
					if (Maths::Abs(targetpos.x - mypos.x) < 50.0f)
						set_emote(blob, targetpos.y > mypos.y ? Emotes::down : Emotes::up);
					else
						set_emote(blob, targetpos.x > mypos.x ? Emotes::right : Emotes::left);
				}
				break;
		}
	}

	// face the enemy
	blob.setAimPos(targetpos);

	// jump over small blocks

	JumpOverObstacles(blob);
}

void JumpOverObstacles(CBlob@ blob)
{
	Vec2f pos = blob.getPosition();
	if (!blob.isOnLadder())
		if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * blob.getRadius(), blob.getRadius()) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		        (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * blob.getRadius(), blob.getRadius()) * 1.0f) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}
}

bool JustGo(CBrain@ this, CBlob@ target)
{
	CBlob @blob = this.getBlob();
	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();
	const f32 horiz_distance = Maths::Abs(point.x - mypos.x);

	if (horiz_distance > blob.getRadius() * 0.75f)
	{
		if (point.x < mypos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (point.y + getMap().tilesize * 0.7f < mypos.y && (target.isOnGround() || target.getShape().isStatic()))  	 // dont hop with me
		{
			blob.setKeyPressed(key_up, true);
		}

		if (blob.isOnLadder() && point.y > mypos.y)
		{
			blob.setKeyPressed(key_down, true);
		}

		return true;
	}

	return false;
}


bool Runaway(CBrain@ this, CBlob@ blob, CBlob@ attacker)
{
	if (attacker is null)
		return false;

	Vec2f mypos = blob.getPosition();
	Vec2f hispos = attacker.getPosition();
	const f32 horiz_distance = Maths::Abs(hispos.x - mypos.x);

	if (hispos.x > mypos.x)
	{
		blob.setKeyPressed(key_left, true);
		blob.setAimPos(mypos + Vec2f(-10.0f, 0.0f));
	}
	else
	{
		blob.setKeyPressed(key_right, true);
		blob.setAimPos(mypos + Vec2f(10.0f, 0.0f));
	}

	if (hispos.y - getMap().tilesize > mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}

	JumpOverObstacles(blob);

	// end

	//out of sight?
	if ((mypos - hispos).getLength() > 200.0f)
	{
		return false;
	}

	return true;
}
