//TODO: powerful items that insta-kill shouldnt have an assist (keg, mine)

CPlayer@ getAssistPlayer(CPlayer@ victim, CPlayer@ killer)
{
	//no assist if teamkill
	if (victim is null || killer is null || victim.getTeamNum() == killer.getTeamNum())
	{
		return null;
	}

	//get victim blob
	CBlob@ victimBlob = victim.getBlob();
	if (victimBlob is null)
	{
		return null;
	}

	//damage criteria for assist
	f32 assistDamage = victimBlob.getInitialHealth() / 2.0f;

	//get info used to determine assist
	CPlayer@[] hitters;
	f32[] damages;
	victimBlob.getPlayersOfDamage(@hitters);
	victimBlob.getAmountsOfDamage(damages);

	//why does the server only have the final hit?
	if (isServer())
	{
		hitters.removeLast();
		damages.removeLast();
	}

	//at this point, the arrays have all hits except the final hit

	//no hitters if victim is killed in one hit
	if (hitters.length == 0)
	{
		return null;
	}

	//subtract amount healed from damage
	f32 healed = victimBlob.get_f32("heal amount");
	for (uint i = 0; i < damages.length; i++)
	{
		f32 sub = Maths::Min(healed, damages[i]);
		damages[i] -= sub;
		healed -= sub;

		//no more healing left
		if (healed == 0.0f)
		{
			break;
		}
	}

	//reverse arrays to loop from newest to oldest
	hitters.reverse();
	damages.reverse();

	for (uint i = 0; i < hitters.length; i++)
	{
		CPlayer@ origHitter = hitters[i];
		f32 totalDamage = 0;

		for (uint j = i; j < hitters.length; j++)
		{
			CPlayer@ hitter = hitters[j];
			f32 damage = damages[j];

			//healed away the damage from here onwards
			if (damage == 0.0f)
			{
				break;
			}

			//get sum of damage from hitter
			if (hitter is origHitter)
			{
				totalDamage += damage;
			}
		}

		//check if damage is enough for assist
		if (totalDamage >= assistDamage)
		{
			//killer cannot assist their own kill
			//helper needs to be from a different team
			if (origHitter is killer || victim.getTeamNum() == origHitter.getTeamNum())
			{
				return null;
			}

			//so close, yet so far. give this player some recognition!
			return origHitter;
		}
	}

	return null;
}
