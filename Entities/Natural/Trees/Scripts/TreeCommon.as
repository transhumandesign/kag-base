#include "Hitters.as"
#include "KnockedCommon.as"

shared class TreeSegment
{
	f32 angle;
	f32 length;
	Vec2f start_pos;
	Vec2f end_pos;

	u8 height;
	u8 grown_times;

	bool flip;

	bool gotsprites;

	Random r;

};

shared class TreeVars
{
	s32 growth_time;
	u8 height;
	u16 seed;
	u8 max_height;
	u8 grown_times;
	u8 max_grow_times;
	s32 last_grew_time;

	Random r;
};

TreeSegment@ getLastSegment(CBlob@ this)
{
	TreeSegment[]@ segments;
	this.get("TreeSegments", @segments);

	if (segments is null || segments.length < 1)
	{
		return null;
	}

	return segments[segments.length - 1];
}

void GrowSegments(CBlob@ this, TreeVars@ vars)
{
	TreeSegment[]@ segments;
	this.get("TreeSegments", @segments);
	if (segments is null)
	{
		return;
	}

	for (uint i = 0; i < segments.length; i++)
	{
		TreeSegment@ segment = segments[i];

		if (segment !is null && segment.grown_times < vars.max_grow_times)
		{
			segment.grown_times++;
			segment.gotsprites = false; //ask for more sprites :)
		}
	}
}

//returns if the segments are overlapping terrain
bool CollapseToGround(CBlob@ this, f32 angle)
{
	if (!this.exists("tree_fall_angle"))
	{
		this.set_f32("tree_fall_angle", angle);
	}
	else
	{
		this.set_f32("tree_fall_angle", angle + this.get_f32("tree_fall_angle"));
	}

	CSprite@ sprite = this.getSprite();
	Vec2f rotateAround = Vec2f(0.0f, -this.getHeight() * 0.5f);
	sprite.RotateAllBy(angle, rotateAround);
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	TreeSegment[]@ segments;
	this.get("TreeSegments", @segments);
	if (segments is null)
		return false;

	// rotate all
	Vec2f segRotateAround = rotateAround * -1;

	for (uint i = 0; i < segments.length; i++)
	{
		TreeSegment@ segment = segments[i];

		if (segment !is null)
		{
			segment.start_pos.RotateBy(angle, segRotateAround);
			segment.end_pos.RotateBy(angle, segRotateAround);
		}
	}

	// collide with map and blobs
	if (segments.length > 2)
	{
		// offset the raycast angle so it doesnt look like it falls into the ground
		if (angle > 0.0f)
		{
			angle += 5;
		}
		else
		{
			angle -= 5;
		}

		bool hitsomething = false;
		Vec2f start_pos = segments[0].start_pos;
		Vec2f end_pos = segments[segments.length - 1].end_pos;
		Vec2f vector = (end_pos - start_pos);
		// HIT //
		Vec2f worldpos = pos + rotateAround * -0.8f;
		HitInfo@[] hitInfos;
		//printf("segRotateAround " + segRotateAround.x + " " + segRotateAround.y + " v " + vector.Length() + " a " + (-90 + this.get_f32("tree_fall_angle") + angle)  );

		const f32 hitAngle = -90 + this.get_f32("tree_fall_angle") + angle;
		//  printf("hit " + hitAngle );
		if (hitAngle < -360.0f || hitAngle > 360.0f)
			return true;

		if (map.getHitInfosFromArc(worldpos, hitAngle, 25.0f, vector.Length(), this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];

				if (hi.blob !is null && hi.blob.hasTag("flesh")) // blob
				{
					f32 dist = (worldpos - hi.blob.getPosition()).Length();

					if (dist > 24.0f && angle > 20.0f)
					{
						hitsomething = true;
						setKnocked(hi.blob, 15);
					}
				}
				else // map
					if (hi.blob is null)
					{
						hitsomething = true;
					}
			}
		}

		return hitsomething;
	}

	// too small to collpase - kill
	return true;
}

bool DoCollapseWhenBelow(CBlob@ this, f32 hp)
{
	if (this.getHealth() <= hp && !this.exists("felldown"))
	{
		this.set_u16("grow check tick frequency", 1);

		f32 COLLAPSE_TIME = 200000.0f;
		u32 fell_time;
		bool fall_switch;

		if (!this.exists("cut_down_time"))
		{
			// START COLLAPSE
			fell_time = getGameTime();
			this.set_u32("cut_down_time", fell_time);
			fall_switch = this.get_bool("cut_down_fall_side");
			// sound
			this.getSprite().SetEmitSound("TreeFall.ogg");
			this.getSprite().SetEmitSoundPaused(false);
			//remove sectors
			CMap@ map = getMap();
			Vec2f pos = this.getPosition();
			map.RemoveSectorsAtPosition(pos, "no build", this.getNetworkID());
			map.RemoveSectorsAtPosition(pos, "tree", this.getNetworkID());
		}
		else
		{	
			fell_time = this.get_u32("cut_down_time");
			fall_switch = this.get_bool("cut_down_fall_side");
		}

		f32 time_diff = (getGameTime() - fell_time);
		f32 rate = (time_diff * time_diff) / COLLAPSE_TIME;
		// END COLLAPSE
		bool hitground = CollapseToGround(this, (fall_switch ? -1 : 1) * 90.0f * rate);

		if (hitground)
		{
			this.getSprite().PlaySound("TreeDestruct.ogg");
			this.getSprite().SetEmitSoundPaused(true);
			this.Tag("felldown"); // so client stops falling tree and playing sound

			if (isServer())
			{
				this.server_SetHealth(-1.0f);
				this.server_Die();                      // Tree dying too early? Did it spawn a bit underground?
			}
		}

		return true;
	}

	return false;
}

void ProcessLeafWiggle(CBlob@ this)
{	
	if (!isClient() || this is null || v_fastrender)	return;

	CSprite@ s = this.getSprite();
	
	if (s is null)	return;

	u8 wiggly_leaf_count = this.get_u8("wiggly leaves count");
	
	for (u8 j = 1; j <= wiggly_leaf_count; j++)
	{
		if (!this.exists("wiggly leaf " + j))	break;
		
		string layerName = this.get_string("wiggly leaf " + j);
		CSpriteLayer@ layer = s.getSpriteLayer(layerName);
		
		if (layer !is null 
			&& this.exists("wiggly leaf duration " + j)
			&& this.get_u8("wiggly leaf duration " + j) > 0)
		{	
			u8 wiggle_duration = this.get_u8("wiggly leaf duration " + j);
			Vec2f offset = layer.getOffset();

			if (wiggle_duration > 1)
			{
				bool rand = (getGameTime() % 4 == 0);
								
				int yshift = rand ? 1 : 0;
				layer.SetOffset(Vec2f(offset.x, Maths::Min(offset.y + yshift, 2)));
				
			}
			else 
			{
				layer.SetOffset(Vec2f(offset.x, 0));
			}
			wiggle_duration--;
			this.set_u8("wiggly leaf duration " + j, wiggle_duration);
		}
	}
}

void LeafProximityCheck(CBlob@ this)
{
	if (!isClient() || this is null || v_fastrender)	return;

	CSprite@ s = this.getSprite();
	
	if (s is null)	return;

	TreeVars@ vars;
	this.get("TreeVars", @vars);

	CMap@ m = getMap();
	float ts = m.tilesize;	
	Vec2f pos = this.getPosition();
	Vec2f tl = Vec2f(pos.x - 5 * ts, pos.y - (2 + vars.height * 2) * ts);
	Vec2f br = Vec2f(pos.x + 5 * ts, pos.y + 1 * ts);

	CBlob@[] nearby_blobs;
	m.getBlobsInBox(tl, br, @nearby_blobs);
	
	// make this function tick often if player is close
	u8 proximity_ticks = 10;
	for (u16 i = 0; i < nearby_blobs.length; i++)
	{
		CBlob@ b = nearby_blobs[i];
		
		if (b is null)	continue;
		
		if (b.hasTag("player")) // player is near
		{
			proximity_ticks = 1;
		}
	}
	this.set_u16("leaf proximity check tick frequency", proximity_ticks);
	
	// check if players are touching leaves
	u8 wiggly_leaf_count = this.get_u8("wiggly leaves count");
	for (u8 j = 1; j <= wiggly_leaf_count; j++)
	{
		if (!this.exists("wiggly leaf " + j))	break;
		
		string layerName = this.get_string("wiggly leaf " + j);
		CSpriteLayer@ layer = s.getSpriteLayer(layerName);
		if (layer !is null 
			&& layer.isAnimationEnded()) // only shake fully grown leaf parts
		{
			Vec2f layerPos = layer.getWorldTranslation();
		
			CBlob@[] overlapped;
			m.getBlobsInRadius(layerPos, 4.0f, @overlapped);
			
			for (u16 k = 0; k < overlapped.length; k++)
			{
				CBlob@ b = overlapped[k];
				
				if (b is null)	continue;
				
				if (b.hasTag("player") 
					&& b.getShape().vellen > 1)
				{
					if (this.get_u8("wiggly leaf duration" + j) == 0)
					{
						this.set_u8("wiggly leaf duration " + j, 6);
						
						if (XORRandom(5) == 0)
						{
							this.getSprite().PlayRandomSound("LeafRustle");

							CParticle@ p;
							
							if (this.get_u8("particle type") == 0)
							{
								@p = makeGibParticle("GenericGibs", layerPos, getRandomVelocity(100, 1 , 270), 
								7, 3 + XORRandom(4), Vec2f(8, 8), 1.0f, 0, "", 0);
							}
							else
							{
								@p = makeGibParticle("grassparts", layerPos, getRandomVelocity(100, 1 , 270), 
								0, XORRandom(5), Vec2f(4, 4), 1.0f, 0, "", 0);
							}
							
							if (p !is null)
							{
								p.gravity = Vec2f(0, 0.1f);
							}
						}
					}
				}
			}
		}
	}
}

void SaveWigglyLeaf(CBlob@ this, string layerName)
{
	u8 wiggly_leaf_count = this.get_u8("wiggly leaves count") + 1;
	this.set_u8("wiggly leaves count", wiggly_leaf_count);
	this.set_string("wiggly leaf " + wiggly_leaf_count, layerName); // save reference to spritelayer
}
