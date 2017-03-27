//attacks limited to the one time per-actor before reset.

void LimitedAttack_setup(CBlob@ this)
{
	u16[] networkIDs;
	this.set("LimitedActors", networkIDs);
}

bool LimitedAttack_has_hit_actor(CBlob@ this, CBlob@ actor)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.find(actor.getNetworkID()) >= 0;
}

void LimitedAttack_add_actor(CBlob@ this, CBlob@ actor)
{
	this.push("LimitedActors", actor.getNetworkID());
}

void LimitedAttack_clear(CBlob@ this)
{
	this.clear("LimitedActors");
}
