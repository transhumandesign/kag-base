// this is a simple box collision for boat vs boat because box2d sucks at this

#include "TeamChecking.as"

void onInit(CBlob@ this)
{
	this.Tag("fake boat collision");
}

void onTick(CBlob@ this)
{
	const f32 buffer = -6.0f;
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f tl, br;
	CShape@ shape = this.getShape();
	shape.getBoundingRect(tl, br);
	bool change = false;
	const f32 vellen = shape.vellen;

	// keep boat from BUG sinking

	//if (!shape.isRotationsAllowed())
	//{
	//	CMap@ map = this.getMap();
	//	const f32 r = map.tilesize / 2.0f;
	//	Vec2f opos = shape.getOffsettedPosition();
	//	opos.y += r*1.0f;
	//	const bool aboveInWater = map.isInWater( opos + Vec2f(0.0f, -1.0f*r));
	//	const bool belowInWater = map.isInWater( opos + Vec2f(0.0f, 1.0f*r));
	//	if (!aboveInWater && belowInWater)
	//	{
	//		printf(this.getName() + " in water");
	//		this.set_f32("water y", opos.y );
	//		this.set_u32("water time", getGameTime() );
	//	}
	//	if (this.exists("water y") && this.get_u32("water time") + 190 > getGameTime())
	//	{
	//		printf(this.getName() + " set");
	//		f32 diff = opos.y - this.get_f32("water y");
	//		pos.y -= diff;
	//		this.setPosition( pos );
	//	}
	//}

	CBlob@[] blobsInRadius;
	this.getMap().getBlobsInRadius(pos, this.getRadius() + buffer, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob @blob = blobsInRadius[i];
		if (blob !is this && vellen > blob.getShape().vellen && blob.hasTag("fake boat collision") && isDifferentTeam(blob, this))
		{
			Vec2f other_tl, other_br;
			CShape@ other_shape = blob.getShape();
			other_shape.getBoundingRect(other_tl, other_br);
			Vec2f other_vel = blob.getVelocity();

			if (pos.y > other_tl.y && pos.y < other_br.y)
			{
				if (pos.x > other_br.x && tl.x < other_br.x)   // from right
				{
					f32 diff = other_br.x - tl.x;
					pos.x += diff * 0.5f;
					vel.x *= -0.5f;
					change = true;
				}
				else if (pos.x < other_br.x && br.x > other_tl.x) // from left
				{
					f32 diff = br.x - other_tl.x;
					pos.x -= diff * 0.5f;
					vel.x *= -0.5f;
					change = true;
				}
			}
		}
	}

	if (change)
	{
		this.setPosition(pos);
		this.setVelocity(vel);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("fake boat collision") || isDifferentTeam(blob, this);
}