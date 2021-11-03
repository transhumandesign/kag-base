// Pine tree Logic

#include "TreeSync.as"

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

	u8 icon_frame = 9;
	if (this.hasTag("startbig")) icon_frame = 13;

	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", icon_frame, Vec2f(8, 32));
	this.SetMinimapRenderAlways(true);
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
				CSpriteLayer@ newsegment = this.addSpriteLayer("segment " + i, "Entities/Natural/Trees/Trees.png" , 16, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);

					if (i == 0)
					{
						animGrow.AddFrame(49);
						animGrow.AddFrame(49);
						animGrow.AddFrame(65);
						animGrow.AddFrame(81);
						animGrow.AddFrame(96);
						animGrow.AddFrame(112);
					}
					else
					{
						animGrow.AddFrame(48);
						animGrow.AddFrame(48);
						animGrow.AddFrame(64);
						animGrow.AddFrame(80);
						animGrow.AddFrame(96);
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
				CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i, "Entities/Natural/Trees/Trees.png" , 32, 32, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(26);
					animGrow.AddFrame(26);
					animGrow.AddFrame(27);
					animGrow.AddFrame(28);

					if (segment.r.NextRanged(2) == 0)
					{
						animGrow.AddFrame(19);
					}
					else
					{
						animGrow.AddFrame(20);
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
					CSpriteLayer@ newsegment = this.addSpriteLayer("roots", "Entities/Natural/Trees/Trees.png" , 32, 16, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(4 + (segment.r.NextRanged(2) == 0 ? 8 : 0));

						newsegment.ResetTransform();
						newsegment.SetRelativeZ(-80.0f);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));

						newsegment.SetOffset(segment.start_pos + Vec2f(0, 8.0f));
						newsegment.SetFacingLeft(segment.flip);
					}
				}
				else if (segment.height > 2 && segment.height <= vars.max_height)  //add leaves
				{
					bool flip = false;
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves side " + i, "Entities/Natural/Trees/Trees.png" , 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(18);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(-550.0f - (vars.height * 10.0f));

						bool flip = (segment.r.NextRanged(2) == 0);
						newsegment.SetFacingLeft(flip);

						newsegment.SetOffset(segment.start_pos + Vec2f(((vars.max_height - i * 2) + segment.r.NextRanged(8)) * 0.5 + 8.0f , 4.0f));
					}

					if (segment.r.NextRanged(2) == 0)
					{
						CSpriteLayer@ secondnewsegment = this.addSpriteLayer("leaves doubleside " + i, "Entities/Natural/Trees/Trees.png" , 32, 32, 0, 0);

						if (secondnewsegment !is null)
						{
							Animation@ animGrow = secondnewsegment.addAnimation("grow", 0, false);
							animGrow.AddFrame(18);
							secondnewsegment.SetAnimation(animGrow);
							secondnewsegment.ResetTransform();
							secondnewsegment.SetRelativeZ(-550.0f - (vars.height * 10.0f));

							flip = !flip;

							secondnewsegment.SetFacingLeft(flip);

							secondnewsegment.SetOffset(segment.start_pos + Vec2f(((vars.max_height - i * 2) + segment.r.NextRanged(8)) * 0.5 + 8.0f , 4.0f));
						}
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
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 9, Vec2f(8, 32));
	}
	else if (vars.grown_times < 10)
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 11, Vec2f(8, 32));
	}
	else
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 13, Vec2f(8, 32));
	}
}