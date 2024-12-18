// brain

#include "/Entities/Common/Emotes/EmotesCommon.as"

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		chasing,
		attacking,
		retreating
	}
}

void InitBrain(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	blob.set_Vec2f("last pathing pos", Vec2f_zero);
	blob.set_u8("strategy", Strategy::idle);
	this.getCurrentScript().removeIfTag = "dead";   //won't be removed if not bot cause it isnt run

	if (!blob.exists("difficulty"))
	{
		blob.set_s32("difficulty", 15); // max
	}
}

CBlob@ getNewTarget(CBrain@ this, CBlob @blob, const bool seeThroughWalls = false, const bool seeBehindBack = false)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f pos = blob.getPosition();
	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();
		const bool isBot = blob.getPlayer() !is null && blob.getPlayer().isBot();
		if (potential !is blob && blob.getTeamNum() != potential.getTeamNum()
		        && (pos2 - pos).getLength() < 600.0f
		        && (isBot || seeBehindBack || Maths::Abs(pos.x - pos2.x) < 40.0f || (blob.isFacingLeft() && pos.x > pos2.x) || (!blob.isFacingLeft() && pos.x < pos2.x))
		        && (isBot || seeThroughWalls || isVisible(blob, potential))
		        && !potential.hasTag("dead") && !potential.hasTag("migrant")
		   )
		{
			blob.set_Vec2f("last pathing pos", potential.getPosition());
			return potential;
		}
	}
	return null;
}

void Repath(CBrain@ this)
{
	this.SetPathTo(this.getTarget().getPosition(), false);
}

bool isVisible(CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
}

bool isVisible(CBlob@ blob, CBlob@ target, f32 &out distance)
{
	Vec2f col;
	bool visible = !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
	distance = (blob.getPosition() - col).getLength();
	return visible;
}

bool JustGo(CBlob@ blob, CBlob@ target)
{
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

void JumpOverObstacles(CBlob@ blob)
{
	Vec2f pos = blob.getPosition();
	const f32 radius = blob.getRadius();

	if (blob.isOnWall())
	{
		blob.setKeyPressed(key_up, true);
	}
	else if (!blob.isOnLadder())
		if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		        (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}
}

void DefaultChaseBlob(CBlob@ blob, CBlob @target)
{
	CBrain@ brain = blob.getBrain();
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	Vec2f targetVector = targetPos - myPos;
	f32 targetDistance = targetVector.Length();
	// check if we have a clear area to the target
	bool justGo = false;

	if (targetDistance < 120.0f)
	{
		Vec2f col;
		if (isVisible(blob, target))
		{
			justGo = true;
		}
	}

	// repath if no clear path after going at it
	if (XORRandom(50) == 0 && (blob.get_Vec2f("last pathing pos") - targetPos).getLength() > 50.0f)
	{
		Repath(brain);
		blob.set_Vec2f("last pathing pos", targetPos);
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		if (!isFriendAheadOfMe(blob, target))
		{
			if (state == CBrain::has_path)
			{
				brain.SetSuggestedKeys();  // set walk keys here
			}
			else
			{
				JustGo(blob, target);
			}
		}

		// printInt("state", this.getState() );
		switch (state)
		{
			case CBrain::idle:
				Repath(brain);
				break;

			case CBrain::searching:
				//if (sv_test)
				//	set_emote( blob, "dots" );
				break;

			case CBrain::stuck:
				Repath(brain);
				break;

			case CBrain::wrong_path:
				Repath(brain);
				break;
		}
	}

	// face the enemy
	blob.setAimPos(target.getPosition());

	// jump over small blocks
	JumpOverObstacles(blob);
}

bool DefaultRetreatBlob(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();
	if (point.x > mypos.x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}

	if (mypos.y - blob.getRadius() > point.y)
	{
		blob.setKeyPressed(key_up, true);
	}

	if (blob.isOnLadder() && point.y < mypos.y)
	{
		blob.setKeyPressed(key_down, true);
	}

	JumpOverObstacles(blob);

	return true;
}

void SearchTarget(CBrain@ this, const bool seeThroughWalls = false, const bool seeBehindBack = true)
{
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// search target if none

	if (target is null)
	{
		CBlob@ oldTarget = target;
		@target = getNewTarget(this, blob, seeThroughWalls, seeBehindBack);
		this.SetTarget(target);

		if (target !is oldTarget)
		{
			onChangeTarget(blob, target, oldTarget);
		}
	}
}

void onChangeTarget(CBlob@ blob, CBlob@ target, CBlob@ oldTarget)
{
	// !!!
	if (oldTarget is null)
	{
		set_emote(blob, "attn", 1);
	}
}

bool LoseTarget(CBrain@ this, CBlob@ target)
{
	if (XORRandom(5) == 0 && target.hasTag("dead"))
	{
		@target = null;
		this.SetTarget(target);
		return true;
	}
	return false;
}

void Runaway(CBlob@ blob, CBlob@ target)
{
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (target.getPosition().x > blob.getPosition().x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}
}

void Chase(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (targetPos.x < mypos.x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}

	if (targetPos.y + getMap().tilesize < mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

bool isFriendAheadOfMe(CBlob @blob, CBlob @target, const f32 spread = 70.0f)
{
	// optimization
	if ((getGameTime() + blob.getNetworkID()) % 10 > 0 && blob.exists("friend ahead of me"))
	{
		return blob.get_bool("friend ahead of me");
	}

	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f pos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();
		if (potential !is blob && blob.getTeamNum() == potential.getTeamNum()
		        && (pos2 - pos).getLength() < spread
		        && (blob.isFacingLeft() && pos.x > pos2.x && pos2.x > targetPos.x) || (!blob.isFacingLeft() && pos.x < pos2.x && pos2.x < targetPos.x)
		        && !potential.hasTag("dead") && !potential.hasTag("migrant")
		   )
		{
			blob.set_bool("friend ahead of me", true);
			return true;
		}
	}
	blob.set_bool("friend ahead of me", false);
	return false;
}

void FloatInWater(CBlob@ blob)
{
	if (blob.isInWater())
	{
		blob.setKeyPressed(key_up, true);
	}
}

void RandomTurn(CBlob@ blob)
{
	if (XORRandom(4) == 0)
	{
		CMap@ map = getMap();
		blob.setAimPos(Vec2f(XORRandom(int(map.tilemapwidth * map.tilesize)), XORRandom(int(map.tilemapheight * map.tilesize))));
	}
}
