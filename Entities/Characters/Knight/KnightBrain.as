// Knight brain

#define SERVER_ONLY

#include "BrainCommon.as"


void onInit(CBrain@ this)
{
	InitBrain(this);
}

void onTick(CBrain@ this)
{
	SearchTarget(this, false, true);

	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();
	//if (sv_test)
	//	return;
	//	 blob.setKeyPressed( key_action2, true );
	//	return;
	// logic for target

	this.getCurrentScript().tickFrequency = 29;
	if (target !is null)
	{
		this.getCurrentScript().tickFrequency = 1;

		u8 strategy = blob.get_u8("strategy");

		f32 distance;
		const bool visibleTarget = isVisible(blob, target, distance);
		if (visibleTarget && distance < 50.0f)
		{
			strategy = Strategy::attacking;
		}

		if (strategy == Strategy::idle)
		{
			strategy = Strategy::chasing;
		}
		else if (strategy == Strategy::chasing)
		{
		}
		else if (strategy == Strategy::attacking)
		{
			if (!visibleTarget || distance > 120.0f)
			{
				strategy = Strategy::chasing;
			}
		}

		UpdateBlob(blob, target, strategy);

		// lose target if its killed (with random cooldown)

		if (LoseTarget(this, target))
		{
			strategy = Strategy::idle;
		}

		blob.set_u8("strategy", strategy);
	}

	FloatInWater(blob);
}

void UpdateBlob(CBlob@ blob, CBlob@ target, const u8 strategy)
{
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	if (strategy == Strategy::chasing)
	{
		DefaultChaseBlob(blob, target);
	}
	else if (strategy == Strategy::attacking)
	{
		AttackBlob(blob, target);
	}
}


void AttackBlob(CBlob@ blob, CBlob @target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	Vec2f targetVector = targetPos - mypos;
	f32 targetDistance = targetVector.Length();
	const s32 difficulty = blob.get_s32("difficulty");

	if (targetDistance > blob.getRadius() + 15.0f)
	{
		if (!isFriendAheadOfMe(blob, target))
		{
			Chase(blob, target);
		}
	}

	JumpOverObstacles(blob);

	// aim always at enemy
	blob.setAimPos(targetPos);

	const u32 gametime = getGameTime();

	bool shieldTime = gametime - blob.get_u32("shield time") < uint(8 + difficulty * 1.33f + XORRandom(20));
	bool backOffTime = gametime - blob.get_u32("backoff time") < uint(1 + XORRandom(20));

	if (target.isKeyPressed(key_action1))   // enemy is attacking me
	{
		int r = XORRandom(35);
		if (difficulty > 2 && r < 2 && (!backOffTime || difficulty > 4))
		{
			blob.set_u32("shield time", gametime);
			shieldTime = true;
		}
		else if (difficulty > 1 && r > 32 && !shieldTime)
		{
			// raycast to check if there is a hole behind

			Vec2f raypos = mypos;
			raypos.x += targetPos.x < mypos.x ? 32.0f : -32.0f;
			Vec2f col;
			if (getMap().rayCastSolid(raypos, raypos + Vec2f(0.0f, 32.0f), col))
			{
				blob.set_u32("backoff time", gametime);								    // base on difficulty
				backOffTime = true;
			}
		}
	}
	else
	{
		// start attack
		if (XORRandom(Maths::Max(3, 30 - (difficulty + 4) * 2)) == 0 && (getGameTime() - blob.get_u32("attack time")) > 10)
		{

			// base on difficulty
			blob.set_u32("attack time", gametime);
		}
	}

	if (shieldTime)   // hold shield for a while
	{
		blob.setKeyPressed(key_action2, true);
	}
	else if (backOffTime)   // back off for a bit
	{
		Runaway(blob, target);
	}
	else if (targetDistance < 40.0f && getGameTime() - blob.get_u32("attack time") < (Maths::Min(13, difficulty + 3))) // release and attack when appropriate
	{
		if (!target.isKeyPressed(key_action1))
		{
			blob.setKeyPressed(key_action2, false);
		}

		blob.setKeyPressed(key_action1, true);
	}
}

