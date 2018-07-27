// red barrier before match starts

const f32 BARRIER_PERCENT = 0.175f;
//if the barrier has been set
bool barrier_set = false;
//
int barrier_wait = 30;
int barrier_timer = 0;

bool shouldBarrier(CRules@ this)
{
	return this.isIntermission() || this.isWarmup() || this.isBarrier();
}

void onTick(CRules@ this)
{
	if(!HandleSync(this)) return;

	if (shouldBarrier(this))
	{
		if (!barrier_set)
		{
			if (barrier_timer < barrier_wait)
			{
				barrier_timer++;
			}
			else
			{
				barrier_set = true;
				addBarrier();
			}
		}

		f32 x1, x2, y1, y2;
		getBarrierPositions(x1, x2, y1, y2);
		const f32 middle = x1 + (x2 - x1) * 0.5f;

		CBlob@[] blobsInBox;
		if (getMap().getBlobsInBox(Vec2f(x1, y1), Vec2f(x2, y2), @blobsInBox))
		{
			for (uint i = 0; i < blobsInBox.length; i++)
			{
				CBlob @b = blobsInBox[i];
				if (b.getTeamNum() < 100 || b.hasTag("no barrier pass"))
				{
					Vec2f pos = b.getPosition();

					//players clamped to edge
					if (b.getPlayer() !is null)
					{
						Vec2f pos = b.getPosition();
						if (pos.x >= x1 && pos.x <= x2)
						{
							Vec2f vel = b.getVelocity();
							float margin = 0.01f;
							float vel_base = 0.01f;
							if (pos.x < middle)
							{
								pos.x = Maths::Min(x1 - margin, pos.x) - margin;
								vel.x = Maths::Min(-vel_base, -Maths::Abs(vel.x));
							}
							else
							{
								pos.x = Maths::Max(x2 + margin, pos.x) + margin;
								vel.x = Maths::Max(vel_base, Maths::Abs(vel.x));
							}
							b.setPosition(pos);
							b.setVelocity(vel);
						}
					}
					//other objects pushed softly (annoying for players apparently)
					else
					{
						f32 f = b.getMass() * 2.0f;

						if (pos.x < middle)
						{
							b.AddForce(Vec2f(-f, -f * 0.1f));
						}
						else
						{
							b.AddForce(Vec2f(f, -f * 0.1f));
						}
					}
				}
			}
		}
	}
	else
	{
		if (barrier_set)
		{
			removeBarrier();
			barrier_set = false;
			barrier_timer = 0;
		}
	}
}

//if the barrier has been cached
bool done_sync = false;
bool HandleSync(CRules@ this)
{
	if(!done_sync)
	{
		if (isServer())
		{
			f32 x1, x2, y1, y2;
			getBarrierPositions(x1, x2, y1, y2);
			this.set_f32("barrier_x1", x1);
			this.Sync("barrier_x1", true);
			this.set_f32("barrier_x2", x2);
			this.Sync("barrier_x2", true);
			this.set_f32("barrier_y1", y1);
			this.Sync("barrier_y1", true);
			this.set_f32("barrier_y2", y2);
			this.Sync("barrier_y2", true);
			done_sync = true;
		}
		if(isClient())
		{
			if (this.get_f32("barrier_x1") != -1.0f)
			{
				done_sync = true;
			}
		}
	}
	return done_sync;
}

void onRestart(CRules@ this)
{
	barrier_set = false;
	barrier_timer = 0;

	//dummy these out
	this.set_f32("barrier_x1", -1.0f);
	this.set_f32("barrier_x2", -1.0f);
	this.set_f32("barrier_y1", -1.0f);
	this.set_f32("barrier_y2", -1.0f);
	done_sync = false;
}

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRender(CRules@ this)
{
	if (!done_sync) return;

	if (shouldBarrier(this))
	{
		f32 x1, x2, y1, y2;
		getBarrierPositions(x1, x2, y1, y2);
		float alpha = Maths::Clamp01(float(barrier_timer) / float(barrier_wait));
		GUI::DrawRectangle(
			getDriver().getScreenPosFromWorldPos(Vec2f(x1, y1)),
			getDriver().getScreenPosFromWorldPos(Vec2f(x2, y2)),
			SColor(int(100 * alpha), 235, 0, 0)
		);
	}
}

//extra area of no build around the barrier
const float noBuildExtra = 8.0f * 3.0f;

void getBarrierPositions(f32 &out x1, f32 &out x2, f32 &out y1, f32 &out y2)
{
	if (done_sync)
	{
		CRules@ rules = getRules();
		x1 = rules.get_f32("barrier_x1");
		x2 = rules.get_f32("barrier_x2");
		y1 = rules.get_f32("barrier_y1");
		y2 = rules.get_f32("barrier_y2");
		return;
	}

	CMap@ map = getMap();

	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapMiddle = mapWidth * 0.5f;
	const f32 barrierWidth = Maths::Floor(BARRIER_PERCENT * map.tilemapwidth) * map.tilesize;
	const f32 extraWidth = ((map.tilemapwidth % 2 == 1) ? 0.5f : 0.0f) * map.tilesize;

	// set horizontal positions based on BARRIER_PERCENT
	x1 = mapMiddle - (barrierWidth + extraWidth);
	x2 = mapMiddle + (barrierWidth + extraWidth);

	// overwrite x1 and x2 if 2 red barrier markers are found
	Vec2f[] barrierPositions;
	if (map.getMarkers("red barrier", barrierPositions))
	{
		if (barrierPositions.length() == 2)
		{
			int left = barrierPositions[0].x < barrierPositions[1].x ? 0 : 1;
			x1 = barrierPositions[left].x;
			x2 = barrierPositions[1 - left].x + map.tilesize;
		}
	}
	//different behaviour based on "default" barriers or not
	//default area we can build shouldn't change based on this
	//change so the barrier area has to move instead
	else
	{
		x1 += noBuildExtra;
		x2 -= noBuildExtra;
	}

	// set vertical positions (hugely outside map area)
	y2 = map.tilemapheight * map.tilesize;
	y1 = -y2;
	y2 *= 2.0f;
}

/**
 * Adding the barrier sector to the map
 */

void addBarrier()
{
	CMap@ map = getMap();

	f32 x1, x2, y1, y2;
	getBarrierPositions(x1, x2, y1, y2);

	Vec2f ul(x1, y1);
	Vec2f lr(x2, y2);

	if (map.getSectorAtPosition((ul + lr) * 0.5, "barrier") is null)
	{
		//actual barrier sector
		map.server_AddSector(Vec2f(x1, y1), Vec2f(x2, y2), "barrier");

		//no build sector
		map.server_AddSector(Vec2f(x1 - noBuildExtra, y1), Vec2f(x2 + noBuildExtra, y2), "no build");
	}
}

/**
 * Removing the barrier sector from the map
 */

void removeBarrier()
{
	CMap@ map = getMap();

	f32 x1, x2, y1, y2;
	getBarrierPositions(x1, x2, y1, y2);

	//remove at the bottom of the map rather than the middle
	//to avoid potentially removing a no build zone from a hall or something
	Vec2f mid((x1 + x2) * 0.5, (map.tilemapheight - 2) * map.tilesize);

	map.RemoveSectorsAtPosition(mid, "barrier");
	map.RemoveSectorsAtPosition(mid, "no build");
}
