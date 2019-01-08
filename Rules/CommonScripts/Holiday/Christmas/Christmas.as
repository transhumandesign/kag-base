// Christmas.as
//
//TODO: re-apply new holiday sprites when holiday is active
//		(check git history around xmas 2018 for holiday versions)

const int present_interval = 30 * 60 * 5; // 5 minutes

// Snow stuff
bool _snow_ready = false;
Vertex[] Verts;
SColor snow_col(0xffffffff);

void onInit(CRules@ this)
{
	this.addCommandID("xmas sound");

	if(isClient() && !v_fastrender)
	{
		Render::addScript(Render::layer_background, "Christmas.as", "DrawSnow", 0);
	}

	onRestart(this);
}

void onRestart(CRules@ this)
{
	_snow_ready = false;
	this.set_s32("present timer", present_interval);
}

void onTick(CRules@ this)
{
	if (!getNet().isServer() || this.isWarmup() || !(this.gamemode_name == "CTF" || this.gamemode_name == "TTH"))
		return;

	if (!this.exists("present timer"))
	{
		return;
	}
	else if (this.get_s32("present timer") <= 0)
	{
		// reset present timer
		this.set_s32("present timer", present_interval);

		CMap@ map = getMap();
		const f32 mapCenter = map.tilemapwidth * map.tilesize * 0.5;

		CBlob@[] trees;

		if (getBlobsByName("tree_pine", @trees))
		{
			CBlob@[] trees_blue;
			CBlob@[] trees_red;

			for (uint i = 0; i < trees.length; i++)
			{
				if (trees[i].get_u8("height") >= 5)
				{
					// sort trees based on position..
					if (trees[i].getPosition().x < mapCenter)
					{
						trees_blue.push_back(trees[i]);
					}
					else
					{
						trees_red.push_back(trees[i]);
					}
				}
			}

			bool is_spawned = false;

			if (trees_blue.length > 0)
			{
				spawnPresent(trees_blue[XORRandom(trees_blue.length)].getPosition(), 0);
				is_spawned = true;
			}
			if (trees_red.length > 0)
			{
				spawnPresent(trees_red[XORRandom(trees_red.length)].getPosition(), 1);
				is_spawned = true;
			}

			if (is_spawned)
			{
				CBitStream bt;
				this.SendCommand(this.getCommandID("xmas sound"), bt);
			}
		}
	}
	else
	{
		this.sub_s32("present timer", 1);
	}
}

void spawnPresent(Vec2f spawnpos, u8 team)
{
	server_CreateBlob("present", team, spawnpos);
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if(cmd == this.getCommandID("xmas sound"))
	{
		Sound::Play("Christmas.ogg");
	}
}

// Snow

void InitSnow()
{
	if(_snow_ready) return;

	_snow_ready = true;

	Verts.clear();
	CMap@ map  = getMap();
	int chunksX = map.tilemapwidth  / 32 + 3;
	int chunksY = map.tilemapheight / 32 + 3;
	for(int cX = 0; cX < chunksX; cX++)
	{
		for(int cY = 0; cY < chunksY; cY++)
		{
			float patch = 256;
			Verts.push_back(Vertex((cX-1)*patch, (cY)*patch,   -500, 0, 0, snow_col));
			Verts.push_back(Vertex((cX)*patch,   (cY)*patch,   -500, 1, 0, snow_col));
			Verts.push_back(Vertex((cX)*patch,   (cY-1)*patch, -500, 1, 1, snow_col));
			Verts.push_back(Vertex((cX-1)*patch, (cY-1)*patch, -500, 0, 1, snow_col));
		}
	}
}

void DrawSnow(int id)
{
	InitSnow();

	//disable if holiday has ended
	if (getRules().get_string("holiday") != "Christmas")
	{
		Render::RemoveScript(id);
		return;
	}

	float[] trnsfm;
	for(int i = 0; i < 3; i++)
	{
		float gt = getGameTime() * (1.0f + (0.031f * i)) + (997 * i);
		float X = Maths::Cos(gt/49.0f)*20 +
			Maths::Cos(gt/31.0f) * 5 +
			Maths::Cos(gt/197.0f) * 10;
		float Y = gt % 255;
		Matrix::MakeIdentity(trnsfm);
		Matrix::SetTranslation(trnsfm, X, Y, 0);
		Render::SetModelTransform(trnsfm);
		Render::SetAlphaBlend(true);
		Render::RawQuads("Snow.png", Verts);
	}
}