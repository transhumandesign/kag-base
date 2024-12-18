#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    if (isExplosionHitter(customData) && this is getLocalPlayerBlob() && getCamera() !is null)
    {
        Vec2f pos;
        if (hitterBlob !is null)
            pos = hitterBlob.getPosition();
        else
            pos = worldPoint;
        
        // screen shake intensity depending on damage
        // bombs do 3 damage
        ShakeScreen(50, damage * 4, pos);
    }

    return damage;
}