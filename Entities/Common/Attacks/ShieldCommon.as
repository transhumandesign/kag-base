
//shield common functions

shared class ShieldVars
{
	Vec2f direction;
	f32 angleTolerance;
	f32 breakingForce;
	f32 stopBlockingForce;
	bool enabled;
	bool forcedDown;
};

//put this in oninit
void addShieldVars(CBlob@ this, f32 shieldAngleSize = 30.0f, f32 breakForce = 1.0f, f32 stopBlockingForce = 5.0f)
{
	ShieldVars vars;
	vars.direction = Vec2f(0, 0);
	vars.angleTolerance = shieldAngleSize / 2;
	vars.breakingForce = breakForce;
	vars.stopBlockingForce = stopBlockingForce;
	vars.enabled = false;
	vars.forcedDown = false;
	this.set("shield vars", vars);
}

ShieldVars@ getShieldVars(CBlob@ this)
{
	ShieldVars@ vars;
	this.get("shield vars", @vars);
	return vars;
}

void setShieldDirection(CBlob@ this, Vec2f direction)
{
	ShieldVars@ vars = getShieldVars(this);
	if (vars is null) { return; }
	vars.direction = direction;
}

void setShieldAngle(CBlob@ this, float shieldAngleSize)
{
	ShieldVars@ vars = getShieldVars(this);
	if (vars is null) { return; }
	vars.angleTolerance = shieldAngleSize / 2;
}

void setShieldEnabled(CBlob@ this, bool enabled)
{
	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return; }

	if (!vars.forcedDown)
	{
		vars.enabled = enabled;

		if (enabled)
		{
			this.Tag("shielded");
		}
		else
		{
			this.Untag("shielded");
		}
	}
	else
	{
		vars.enabled = false;
		this.Untag("shielded");
	}
}

void knockShieldDown(CBlob@ this)
{
	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return; }

	vars.forcedDown = true;
	this.Untag("shielded");
}

void resetShieldKnockdown(CBlob@ this)
{
	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return; }

	vars.forcedDown = false;
}

bool canRaiseShield(CBlob@ this)
{
	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return false; }

	return !vars.forcedDown;
}

bool isShieldEnabled(CBlob@ this)
{
	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return false; }

	return vars.enabled;
}

bool blockAttack(CBlob@ this, Vec2f direction, f32 damage)
{
	if (this.hasTag("dead")) return false;

	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return false; }

	//shield isn't up
	if (!vars.enabled) { return false; }

	//zero direction = bypass shield
	if (direction.LengthSquared() < 0.001f) return false;

	//shield isn't blocking/strong enough
	f32 angle = Maths::Abs(vars.direction.AngleWith(direction));
	f32 angle_difference = 180.0f - angle;
	/*print( " SHIELD DEBUG: " );
	print( "               damage: "+damage );
	print( "            break dam: "+vars.breakingForce );
	print( "                angle: "+angle );
	print( " angle_diff(compared): "+angle_difference );
	print( "            tolerance: "+vars.angleTolerance );
	print( "     attack direction: "+direction.x+", "+direction.y );
	print( "     shield direction: "+vars.direction.x+", "+vars.direction.y );*/
	return ((angle_difference) < vars.angleTolerance && damage < vars.breakingForce);
}

bool exceedsShieldBreakForce(CBlob@ this, f32 damage)
{
	ShieldVars@ vars = getShieldVars(this);

	if (vars is null) { return false; }

	//print("dmg " + damage + "break " + vars.breakingForce);
	return damage >= vars.breakingForce;
}
