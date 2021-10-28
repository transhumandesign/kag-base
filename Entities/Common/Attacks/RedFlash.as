
//Does the good old "red screen flash" when hit - put just before your script that actually does the hitting
//onHit temporarily not working here
/*
f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (this.isMyPlayer() && damage > 0)
    {
        SetScreenFlash( 90, 120, 0, 0 );
        ShakeScreen( 9, 2, this.getPosition() );
    }

    return damage;
}*/

void onHealthChange( CBlob@ this, f32 oldHealth )
{
	if (this.isMyPlayer() && this.getHealth() < oldHealth)
    {
        SetScreenFlash( 90, 120, 0, 0);
        ShakeScreen( 9, 2, this.getPosition() );
    }
}
