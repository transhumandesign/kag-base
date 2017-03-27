#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	this.set_u32("liftoff", 0);
}

void onTick(CBlob@ this)
{
	u32 liftoff = this.get_u32("liftoff");
	liftoff++;
	if (liftoff > 0)
	{
		Vec2f pos = this.getPosition();
		CMap@ map = this.getMap();
		f32 ww = this.getWidth() * 0.5f;
		f32 hh = this.getHeight() * 0.5f;
		printf("liftoff " + liftoff);

		ShakeScreen(53.0f, 150, pos);

		if (liftoff < 100)
		{
			Vec2f p(-ww + (XORRandom(160)), hh + 3);
			map.SetTile(pos + p, CMap::tile_empty);
			MakeDustParticle(pos + p, "dust2.png");
		}
		else if (liftoff < 170)
		{
			Vec2f p(-ww + (XORRandom(160)), hh + 4);
			map.SetTile(pos + p, CMap::tile_empty);
			MakeDustParticle(pos + p, "dust2.png");
			p = Vec2f(-ww + (XORRandom(160)), hh + 12);
			map.SetTile(pos + p, CMap::tile_empty);
			MakeDustParticle(pos + p, "Smoke.png");
			p = Vec2f(-ww + 20 + XORRandom(130), hh + 20);
			map.SetTile(pos + p, CMap::tile_empty);
			MakeDustParticle(pos + p, "Smoke.png");
		}
		else
		{
			if (liftoff == 172)
			{
				this.getShape().SetStatic(false);
				this.getShape().getConsts().mapCollisions = true;
				this.getShape().getConsts().collidable = true;
				this.getShape().SetRotationsAllowed(false);

				Vec2f pos_off;
				{
					Vec2f[] shape = { Vec2f(9.0f,  44.0f),
					                  Vec2f(167.0f,  44.0f),
					                  Vec2f(167.0f,  54.0f),
					                  Vec2f(9.0f,  54.0f)
					                };
					this.getShape().SetShape(shape);
				}
			}

			if (pos.y > 250.0f)
			{
				this.setVelocity(Vec2f(0.0f, -0.85f));
			}
			else
			{
				this.setVelocity(Vec2f(-1.0f, -0.1f));
			}
		}
	}
	this.set_u32("liftoff", liftoff);
}