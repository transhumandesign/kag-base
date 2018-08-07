void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
    // allow blacklisting for random exit velocity
    if (!blob.hasTag("blacklist random exit vel " + this.getName()))
    {
        int x_speed = XORRandom(8) - 4;
        int y_speed = (XORRandom(5) + 3) * -1; // don't go into the ground, that's bad
        blob.setVelocity(Vec2f(x_speed, y_speed));
    }
}