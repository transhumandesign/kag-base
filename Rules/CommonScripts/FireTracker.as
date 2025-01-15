#define CLIENT_ONLY

#include "ParticlesCommon.as"

uint[] active_positions;

Vec2f offsetToWorldspace(uint offset) {
    CMap@ map = @getMap();
    int X = offset % map.tilemapwidth;
	int Y = offset / map.tilemapwidth;

	Vec2f pos = Vec2f(X, Y);
	float ts = map.tilesize;

    return pos * ts;
}

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
    if (map.isInFire(offsetToWorldspace(offset)))
	{
        if (active_positions.find(offset) >= 0)
        {
            return;
        }


        active_positions.insertLast(offset);
	}
    else
    {
        int index = active_positions.find(offset);
        if (index >= 0)
        {
            active_positions.removeAt(index);
        }
    }

    col = col;
}

void onRestart(CRules@ rules)
{
    active_positions.clear();
    getMap().AddScript("firetracker");
}

void onInit(CRules@ rules)
{
    onRestart(@rules);
}

void onTick(CRules@ rules)
{
    Random r(XORRandom(9999));
    CMap@ map = getMap();

    Vec2f half_tile = Vec2f(map.tilesize, map.tilesize) * 0.5;
    SColor fire_color(255, 120, 15, 0);

    for (int i = 0; i < active_positions.length; ++i)
    {
        if (XORRandom(3) == 0)
        {
            MakeBasicLightParticle(
                offsetToWorldspace(active_positions[i]) + half_tile,
                Vec2f(0.0f, -0.8f - r.NextFloat() * 1.6f),
                SColor(255, 120, 10, 0),
                0.97f,
                0.3f,
                45
            );
        }
    }
}