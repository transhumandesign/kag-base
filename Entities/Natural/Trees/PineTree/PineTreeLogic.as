// Pine tree Logic

#include "TreeSync.as"

const string spritefile = "Entities/Natural/Trees/PineTree/PineTree.png";

void onInit(CBlob@ this)
{
	InitVars(this);

	u32 seed = 0;

	if (this.exists("tree_rand"))
	{
		seed = this.get_u32("tree_rand");
	}
	else
	{
		seed = this.getNetworkID() * 139 + getGameTime() * 7;
		if (getNet().isServer())
		{
			this.set_u32("tree_rand", seed);
			this.Sync("tree_rand", true);
		}
	}

	this.server_setTeamNum(-1);
	TreeVars vars;
	vars.r.Reset(seed);
	vars.growth_time = 350 + vars.r.NextRanged(30);
	vars.height = 0;
	vars.max_height = 5 + vars.r.NextRanged(3);
	vars.grown_times = 0;
	vars.max_grow_times = 30;
	vars.last_grew_time = getGameTime() - 1; //pretend we started a frame ago ;)
	this.SetFacingLeft(vars.r.NextRanged(300) > 150);
	InitTree(this, vars);
	this.set("TreeVars", vars);

	u8 icon_frame = 11;
	if (this.hasTag("startbig")) icon_frame = 13;

	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", icon_frame, Vec2f(8, 32));
	this.SetMinimapRenderAlways(true);
	
	if (isServer())
	{
		this.set_u8("particle type", 1);	// 0: bushy, 1: pine
		this.Sync("particle type", true);
	}
}

void onTick(CBlob@ this)
{
	if (this.get_u16("grow check tick frequency") != 0 
		&& this.getTickSinceCreated() % this.get_u16("grow check tick frequency") == 0)
	{
		GrowCheck(this);
	}
	
	if (this.exists("cut_down_time")				// tree is falling
		|| this.get_u8("wiggly leaves count") == 0)	// no leaves to wiggle
	{
		return;
	}
	
	if (this.get_u16("leaf proximity check tick frequency") != 0
		&& this.getTickSinceCreated() % this.get_u16("leaf proximity check tick frequency") == 0)
	{
		LeafProximityCheck(this);
	}

	ProcessLeafWiggle(this);
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
				CSpriteLayer@ newsegment = this.addSpriteLayer("segment " + i, spritefile, 16, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);

					if (i == 0)
					{
						animGrow.AddFrame(9);
						animGrow.AddFrame(9);
						animGrow.AddFrame(17);
						animGrow.AddFrame(25);
						animGrow.AddFrame(32);
						animGrow.AddFrame(40);
					}
					else
					{
						animGrow.AddFrame(8);
						animGrow.AddFrame(8);
						animGrow.AddFrame(16);
						animGrow.AddFrame(24);
						animGrow.AddFrame(32);
					}

					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-100.0f - vars.height);

					newsegment.RotateBy(segment.angle, Vec2f(0, 0));

					newsegment.SetFacingLeft(segment.flip);

					Vec2f offset = segment.start_pos;
					newsegment.SetOffset(offset);
				}
			}
			else if (segment.grown_times == 2 && segment.height > 2)
			{
				string layerName = "leaves " + i;
				CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(9);
					animGrow.AddFrame(9);
					animGrow.AddFrame(10);
					animGrow.AddFrame(11);

					if (segment.r.NextRanged(2) == 0)
					{
						SaveWigglyLeaf(blob, layerName);
						animGrow.AddFrame(6);
					}
					else
					{
						animGrow.AddFrame(7);
					}

					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(550.1f + (vars.height * 10.0f));
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					newsegment.TranslateBy(segment.start_pos);

					newsegment.SetFacingLeft(segment.flip);
				}
			}
			else if (segment.grown_times == 5)
			{
				if (i == 0) //add roots
				{
					f32 flipsign = 1.0f;
					CSpriteLayer@ newsegment = this.addSpriteLayer("roots", spritefile, 32, 16, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame((segment.r.NextRanged(2) == 0 ? 2 : 6));

						newsegment.ResetTransform();
						newsegment.SetRelativeZ(-80.0f);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));

						newsegment.SetOffset(segment.start_pos + Vec2f(0, 8.0f));
						newsegment.SetFacingLeft(segment.flip);
					}
				}
				else if (segment.height > 2 && segment.height <= vars.max_height)  //add leaves
				{
					bool flipped = (segment.r.NextRanged(2) == 0);
					string layerName = "leaves side " + i;
					CSpriteLayer@ newsegment1 = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

					if (newsegment1 !is null)
					{
						Animation@ animGrow = newsegment1.addAnimation("grow", 0, false);
						animGrow.AddFrame(5);
						newsegment1.SetAnimation(animGrow);
						newsegment1.ResetTransform();
						newsegment1.SetRelativeZ(-550.0f - (vars.height * 10.0f));
						newsegment1.SetFacingLeft(flipped);
						newsegment1.SetOffset(segment.start_pos + Vec2f(((vars.max_height - i * 2) + segment.r.NextRanged(8)) * 0.5 + 8.0f , 4.0f));
					}
					
					CSpriteLayer@ newsegment2 = this.addSpriteLayer("leaves doubleside " + i, spritefile, 32, 32, 0, 0);

					if (newsegment2 !is null)
					{
						Animation@ animGrow = newsegment2.addAnimation("grow", 0, false);
						animGrow.AddFrame(5);
						newsegment2.SetAnimation(animGrow);
						newsegment2.ResetTransform();
						newsegment2.SetRelativeZ(-550.0f - (vars.height * 10.0f));
						newsegment2.SetFacingLeft(!flipped);
						newsegment2.SetOffset(segment.start_pos + Vec2f(((vars.max_height - i * 2) + segment.r.NextRanged(8)) * 0.5 + 8.0f , 4.0f));
					}
				}
			}

			if (segment.grown_times <= 5)
			{
				CSpriteLayer@ segmentlayer = this.getSpriteLayer("segment " + i);

				if (segmentlayer !is null)
				{
					segmentlayer.animation.SetFrameIndex(segmentlayer.animation.frame + 1);
				}
			}

			if (segment.grown_times - 2 <= 5)
			{
				CSpriteLayer@ leaveslayer = this.getSpriteLayer("leaves " + i);

				if (leaveslayer !is null)
				{
					leaveslayer.animation.SetFrameIndex(leaveslayer.animation.frame + 1);
				}
			}
		}
	}
}

void UpdateMinimapIcon(CBlob@ this, TreeVars@ vars)
{
	if (vars.grown_times < 5)
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 11, Vec2f(8, 32));
	}
	else if (vars.grown_times < 10)
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 12, Vec2f(8, 32));
	}
	else
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 13, Vec2f(8, 32));
	}
}