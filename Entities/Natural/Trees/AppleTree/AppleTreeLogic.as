// Bushy tree Logic

#include "TreeSync.as";
#include "AppleCommon.as";

const string spritefile = "Entities/Natural/Trees/AppleTree/AppleTree.png";

const u8 APPLE_AMOUNT_LIMIT_PER_TREE = 4;
const u8 APPLE_AMOUNT_LIMIT_PER_MAP = 30;
const f32 APPLE_RADIUS_LIMIT = 8.0f;

void onInit(CBlob@ this)
{
	InitVars(this);

	s32 seed = 0;

	if (this.exists("tree_rand"))
	{
		seed = this.get_s32("tree_rand");
	}
	else
	{
		seed = this.getNetworkID() * 139 + getGameTime() * 7;
		if (isServer())
		{
			this.set_s32("tree_rand", seed);
			this.Sync("tree_rand", true);
		}
	}

	this.server_setTeamNum(-1);
	TreeVars vars;
	vars.r.Reset(seed);
	vars.growth_time = 250 + vars.r.NextRanged(30);
	vars.height = 0;
	vars.max_height = 3;
	vars.grown_times = 0;
	vars.max_grow_times = 50;
	vars.last_grew_time = getGameTime() - 1; //pretend we started a frame ago ;)
	this.SetFacingLeft(vars.r.NextRanged(300) > 150);
	InitTree(this, vars);
	this.set("TreeVars", vars);

	u8 icon_frame = 16;
	if (this.hasTag("startbig")) 
	{
		icon_frame = 18;
		this.Tag("growing apples");
	}
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", icon_frame, Vec2f(8, 32));
	this.SetMinimapRenderAlways(true);
	
	if (isServer())
	{
		this.set_u8("particle type", 0);	// 0: bushy, 1: pine
		this.Sync("particle type", true);
	}
}

void onTick(CBlob@ this)
{
	if (this.get_u16("grow check tick frequency") != 0 
		&& this.getTickSinceCreated() % this.get_u16("grow check tick frequency") == 0)
	{
		GrowCheck(this);
		
		if (this.hasTag("growing apples") 
			&& !this.exists("cut_down_time"))
		{
			GrowApples(this);
		}
	}

	if (this.exists("cut_down_time"))	 // tree is falling
	{
		LoseApples(this);
	}
	else if (this.get_u8("wiggly leaves count") > 0) // wiggly leaves exist
	{
		if (this.get_u16("leaf proximity check tick frequency") != 0
		&& this.getTickSinceCreated() % this.get_u16("leaf proximity check tick frequency") == 0)
		{
			LeafProximityCheck(this);
		}
		
		ProcessLeafWiggle(this);	
	}
}

void LoseApples(CBlob@ this)
{
	if (!isServer())	return;

	for (uint i = 0; i < APPLE_AMOUNT_LIMIT_PER_TREE; i++)
	{
		u16 netid = this.get_u16("slot" + i);
		CBlob@ blob = getBlobByNetworkID(netid);
		
		if (blob !is null && blob.hasTag("growing on tree"))
		{	
			if (blob.hasTag("apple growth"))	// still a small apple, unspawn it
			{
				blob.getSprite().Gib();
				blob.server_Die();
				continue;
			}
			
			blob.Tag("apply velocity");
			MakeNonStatic(blob);
		}
	}
}

void GrowApples(CBlob@ this)
{
	if (!isServer() || XORRandom(8) > 0)	return;
	
	CBlob@[] apples;
	getBlobsByName("apple", @apples);

	if (apples.length >= APPLE_AMOUNT_LIMIT_PER_MAP) 	return;
	
	for (uint i = 0; i < APPLE_AMOUNT_LIMIT_PER_TREE; i++)	// check if there are free slots
	{
		if (!this.exists("slot" + i)) // free slot, use it
		{
			GrowAppleInSlot(this, i);
			break;
		}
		else // slot is used
		{
			u16 netid = this.get_u16("slot" + i);
			CBlob@ blob = getBlobByNetworkID(netid);

			if (blob is null ||										// apple doesn't exist
				(blob !is null && !blob.hasTag("growing on tree")))	// or apple exists but not hanging on tree - use the slot
			{
				GrowAppleInSlot(this, i);
				break;
			}
		}
	}
}

void GrowAppleInSlot(CBlob@ this, uint slot)
{
	CMap@ m = getMap();
	float ts = m.tilesize;	
	Vec2f position_shift 	= Vec2f(-ts * 2.5f + XORRandom(ts * 5), -ts * 5 + XORRandom(ts * 3));
	Vec2f spawn_position	= this.getPosition() + position_shift;
	
	// don't spawn if close to other apple or inside walls
	if (m.isBlobInRadius("apple", spawn_position, APPLE_RADIUS_LIMIT)
		|| m.isTileSolid(spawn_position))	
	{
		return;
	}
	
	CBlob@ apple = server_CreateBlob("apple", 255, spawn_position);
	
	if (apple !is null)
	{
		apple.Tag("apple growth"); // causes Apple onTick() to run, which manages apple growth
		apple.RemoveScript("Eatable.as"); // not eatable until grown
		apple.server_setTeamNum(255);
		this.set_u16("slot" + slot, apple.getNetworkID());
		
		apple.Sync("apple growth", true);
	}
}

void GrowSprite(CSprite@ this, TreeVars@ vars)
{
	CBlob@ blob = this.getBlob();
	if (vars is null)
		return;

	if (vars.height == 0)
	{
		this.animation.frame = 0;
	}
	else //vanish
	{
		this.animation.frame = 1;
	}

	TreeSegment[]@ segments;
	blob.get("TreeSegments", @segments);
	if (segments is null)
		return;
	for (uint i = 0; i < segments.length; i++)
	{
		TreeSegment@ segment = segments[i];

		if (segment !is null && !segment.gotsprites)
		{
			segment.gotsprites = true;

			if (segment.grown_times == 1)
			{
				CSpriteLayer@ newsegment = this.addSpriteLayer("segment " + i, spritefile, 32, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(18);
					animGrow.AddFrame(18);

					if (i == 0)
					{
						animGrow.AddFrame(6);
						animGrow.AddFrame(12);

						if (segment.r.NextRanged(2) == 0)
						{
							animGrow.AddFrame(25);
						}
						else
						{
							animGrow.AddFrame(31);
						}
					}
					else
					{
						animGrow.AddFrame(24);

						if (i == vars.max_height - 1)
						{
							animGrow.AddFrame(7);
							animGrow.AddFrame(13);
						}
						else
						{
							animGrow.AddFrame(30);
							animGrow.AddFrame(19);
						}
					}

					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-100.0f - vars.height);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));

					newsegment.SetFacingLeft(segment.flip);

					Vec2f offset = segment.start_pos + Vec2f(-8, 0);
					newsegment.SetOffset(offset);
				}
			}
			else if (segment.grown_times == 3 && i > 0 && i != vars.max_height - 1)
			{
				f32 scalex = 1.0f;

				if (segment.flip)
				{
					scalex = -1.0f;
				}

				for (int spriteindex = 0; spriteindex < 3; spriteindex++)
				{
					string layerName = "leaves " + i + " " + spriteindex;
					CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						float z = -550.0f - (vars.height / 100.0f);

						if ((i < 2 && segment.r.NextRanged(2) == 0) || spriteindex != 2)
						{
							animGrow.AddFrame(8);
						}
						else
						{
							SaveWigglyLeaf(blob, layerName);
							animGrow.AddFrame(9);
							z =  510.0f + (vars.height * 10.0f);
						}

						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(z);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						Vec2f offset = Vec2f(5 * scalex, -8);

						if (spriteindex == 1)
						{
							offset = Vec2f(-10 * scalex, 0);
						}
						else if (spriteindex == 2)
						{
							offset = Vec2f(16 * scalex, -4);
						}

						newsegment.TranslateBy(segment.start_pos + offset);
					}
				}
			}
			else if (i == 0 && segment.grown_times == 4) //add roots
			{
				f32 flipsign = 1.0f;
				CSpriteLayer@ newsegment = this.addSpriteLayer("roots", spritefile, 32, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame((segment.r.NextRanged(2) == 0 ? 2 : 8));

					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-80.0f);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					newsegment.SetOffset(segment.start_pos + Vec2f(0, 8.0f));

					newsegment.SetFacingLeft(segment.flip);
				}
			}
			else if (segment.grown_times == 4 && i == vars.max_height - 1) //top of the tree
			{
				string layerName = "extra leaves top";
				CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					float z = -550.0f;
					SaveWigglyLeaf(blob, layerName);
					animGrow.AddFrame(9);
					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(z);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					Vec2f offset = Vec2f(0, -10);
					newsegment.TranslateBy(segment.start_pos + offset);
				}
			}
			else if (segment.grown_times == 5 && i == vars.max_height - 1) //top of the tree
			{			
				f32 scalex = 1.0f;
				if (segment.r.NextRanged(2) == 0)
				{
					scalex = -1.0f;
				}

				for (int spriteindex = 0; spriteindex < 3; spriteindex++)
				{
					string layerName = "leaves " + i + " " + spriteindex;
					CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						float z = -550.0f - (vars.height * 10.0f);

						if (spriteindex == 0)
						{
							animGrow.AddFrame(8);
						}
						else
						{
							SaveWigglyLeaf(blob, layerName);
							animGrow.AddFrame(9);
							z =  500.0f + (vars.height * 10.0f);
						}

						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(z);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						Vec2f offset = Vec2f(16 * scalex, 4);

						if (spriteindex == 1)
						{
							offset = Vec2f(-16 * scalex, -4);
						}
						else if (spriteindex == 2)
						{
							offset = Vec2f(22 * scalex, -12);
						}

						newsegment.TranslateBy(segment.start_pos + offset);
					}
				}

				{
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + 3, spritefile, 64, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(2);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(550.1f);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						newsegment.TranslateBy(segment.end_pos);
					}
				}

				{
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + 4, spritefile, 64, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(5);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(-550.0f - (i * 5.0f));
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						newsegment.TranslateBy(segment.end_pos);
					}
				}
				
				blob.Tag("growing apples");
			}

			if (segment.grown_times < 5)
			{
				CSpriteLayer@ segmentlayer = this.getSpriteLayer("segment " + i);

				if (segmentlayer !is null)
				{
					segmentlayer.animation.frame++;

					if (i == vars.max_height - 1 && segment.grown_times == 3)
					{
						segmentlayer.SetOffset(segmentlayer.getOffset() + Vec2f(8, 0));
					}
				}
			}
		}
	}
}

void UpdateMinimapIcon(CBlob@ this, TreeVars@ vars)
{
	if (vars.grown_times < 6)
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 16, Vec2f(8, 32));
	}
	else
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 17, Vec2f(8, 32));
	}
	// not all sprites used, due to apple tree being short
}