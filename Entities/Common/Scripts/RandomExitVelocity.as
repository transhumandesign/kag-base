void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
    // allow blacklisting for random exit velocity
    if (!blob.hasTag("blacklist random exit vel " + this.getName()))
    {
		//RNG based on our id, their id, and the game time
		Random _r(this.getNetworkID() * 158 + blob.getNetworkID() * 997 + getGameTime() * 31);
    	//random either direction
        float x_speed = (_r.NextFloat() - 0.5) * 8.0;
    	// don't go into the ground, that's bad
        float y_speed = -(3.0 + _r.NextFloat() * 5.0);
        blob.setVelocity(Vec2f(x_speed, y_speed));
    }
}