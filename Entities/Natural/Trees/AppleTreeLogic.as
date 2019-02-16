// Apple tree Logic

#include "TreeSync.as"

const uint8 apple_count = 2;

void onInit(CBlob@ this)
{
	InitVars(this);
	this.server_setTeamNum(-1);
	TreeVars vars;
	vars.seed = XORRandom(30000);
	vars.growth_time = 250 + XORRandom(30);
	vars.height = 0;
	vars.max_height = 2 + XORRandom(2);
	vars.grown_times = 0;
	vars.max_grow_times = 50;
	vars.last_grew_time = getGameTime() - 1; //pretend we started a frame ago ;)
	InitTree(this, vars);
	this.set("TreeVars", vars);
	
	// Produce
	if (this.hasTag("instant_grow"))
	{
		GrowApples(this);
	}
}

// Grow the apples
void GrowApples(CBlob@ this)
{
    if (getNet().isServer())
    {
        for (uint8 i = 0; i < apple_count; i++)
        {
	    // Apple 1 and Apple 2
            InitApples(this, i);
        }
    }
}

// Apple 1 and Apple 2
void InitApples(CBlob@ this, uint8 apple_id)
{
    // pos
    Vec2f offset = this.getPosition();
    int v = this.isFacingLeft() ? 0 : 1;

    if (apple_id == 0) // Apple 1
    {
        offset = (offset + Vec2f(8 + v, -35));
    }
    else if (apple_id == 1) // Apple 2
    {
        offset = (offset + Vec2f(-8 + v, -33));
    }

    // create
    CBlob@ apple = server_CreateBlob('apple', -1, offset);
    if (apple !is null)
    {
        this.set_u16("apple" + apple_id, apple.getNetworkID());

        CShape@ shape = apple.getShape();

        // the apple is on the tree, so make it hang/static
        if (shape !is null)
        {
            shape.SetStatic(true);
        }
    }
}

// Sprites
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
				CSpriteLayer@ newsegment = this.addSpriteLayer("segment " + i, "Entities/Natural/Trees/FruitTrees.png" , 32, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(17);
					animGrow.AddFrame(17);

					if (i == 0)
					{
						animGrow.AddFrame(1);
						animGrow.AddFrame(9);

						if (XORRandom(2) == 0)
						{
							animGrow.AddFrame(49);
						}
						else
						{
							animGrow.AddFrame(57);
						}
					}
					else
					{
						animGrow.AddFrame(25);

						if (i == vars.max_height - 1)
						{
							animGrow.AddFrame(18);
							animGrow.AddFrame(26);
						}
						else
						{
							animGrow.AddFrame(33);
							animGrow.AddFrame(41);
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
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + spriteindex, "Entities/Natural/Trees/FruitTrees.png" , 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						float z = -550.0f - (vars.height / 100.0f);

						if ((i < 2 && XORRandom(2) == 0) || spriteindex != 2)
						{
							animGrow.AddFrame(11);
						}
						else
						{
							animGrow.AddFrame(12);
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
				CSpriteLayer@ newsegment = this.addSpriteLayer("roots", "Entities/Natural/Trees/FruitTrees.png" , 32, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(4 + (XORRandom(2) == 0 ? 8 : 0));

					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-80.0f);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					newsegment.SetOffset(segment.start_pos + Vec2f(0, 8.0f));

					newsegment.SetFacingLeft(segment.flip);
				}
			}
			else if (segment.grown_times == 4 && i == vars.max_height - 1) //top of the tree
			{
				CSpriteLayer@ newsegment = this.addSpriteLayer("extra leaves top", "Entities/Natural/Trees/FruitTrees.png" , 32, 32, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					float z = -550.0f;
					animGrow.AddFrame(12);
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
				if (XORRandom(2) == 0)
				{
					scalex = -1.0f;
				}

				for (int spriteindex = 0; spriteindex < 3; spriteindex++)
				{
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + spriteindex, "Entities/Natural/Trees/FruitTrees.png" , 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						float z = -550.0f - (vars.height * 10.0f);

						if (spriteindex == 0)
						{
							animGrow.AddFrame(11);
						}
						else
						{
							animGrow.AddFrame(12);
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
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + 3, "Entities/Natural/Trees/FruitTrees.png" , 64, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(3);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(550.1f);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						newsegment.TranslateBy(segment.end_pos);
					}
				}

				{
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + 4, "Entities/Natural/Trees/FruitTrees.png" , 64, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(7);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(-550.0f - (i * 5.0f));
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						newsegment.TranslateBy(segment.end_pos);
					}
				}
				// Time to produce!
				GrowApples(blob);
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

void onDie(CBlob@ this)
{
    // Drop apples on death if they still exist
	for (int i = 0; i < 2; i++)
	{	
		CBlob@ apple = getBlobByNetworkID(this.get_u16("apple" + i)); // Apple 1 and Apple 2
		if (apple !is null)
		{            
			CShape@ shape = apple.getShape();
			if (shape !is null)
			{
				shape.SetStatic(false);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false; // Just in case ;)
}
