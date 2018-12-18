// Christmas.as

const int present_interval = 25 * 60 * 5; // 5 minutes

// Snow stuff
Vertex[] Verts;
SColor col(0xffffffff);

void onInit(CRules@ this)
{
    this.addCommandID("play sound");

    InitSnow();
    Render::addScript(Render::layer_background, "Christmas.as", "MoveSnow", 0);

	if(isServer())
	{
		LoadNextMap();
	}

	onRestart(this);
}

void onRestart(CRules@ this)
{
	CMap@ map = getMap();

	this.set_s32("present timer", present_interval);

	CBlob@[] bushes;

	getBlobsByName("bush", @bushes);

	if (bushes.length > 0)
	{
		for (uint i = 0; i < bushes.length; i++)
		{
			bushes[i].getSprite().ReloadSprite("Rules/CommonScripts/Holiday/Christmas/Sprites/Bushes_Christmas.png");
		}
	}

	map.CreateTileMap(0, 0, 8.0f, "Rules/CommonScripts/Holiday/Christmas/Sprites/world_Christmas.png");
	map.CreateSkyGradient("Rules/CommonScripts/Holiday/Christmas/Sprites/skygradient_Christmas.png");
	map.AddBackground("Rules/CommonScripts/Holiday/Christmas/Sprites/BackgroundPlains_Christmas.png", Vec2f(0.0f, -18.0f), Vec2f(0.3f, 0.3f), color_white);
	map.AddBackground("Rules/CommonScripts/Holiday/Christmas/Sprites/BackgroundTrees_Christmas.png", Vec2f(0.0f,  -5.0f), Vec2f(0.4f, 0.4f), color_white);
	map.AddBackground("Rules/CommonScripts/Holiday/Christmas/Sprites/BackgroundIsland_Christmas.png", Vec2f(0.0f, 0.0f), Vec2f(0.6f, 0.6f), color_white);
    
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
	            this.SendCommand(this.getCommandID("play sound"), bt);
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
    if(cmd == this.getCommandID("play sound"))
    {
        Sound::Play("Christmas.ogg");
    }
}

// Snow

void InitSnow()
{
    Verts.clear();
    CMap@ map  = getMap();
    int chunksX = map.tilemapwidth/32+2;
    int chunksY = map.tilemapheight/32+2;
    for(int cX = 0; cX < chunksX; cX++)
        for(int cY = 0; cY < chunksY; cY++)
        {
            Verts.push_back(Vertex((cX-1)*256, (cY)*256, -500, 0, 0, col));
            Verts.push_back(Vertex((cX)*256, (cY)*256, -500, 1, 0, col));
            Verts.push_back(Vertex((cX)*256, (cY-1)*256, -500, 1, 1, col));
            Verts.push_back(Vertex((cX-1)*256, (cY-1)*256, -500, 0, 1, col));
        }
}

void MoveSnow(int id)
{
    float[] trnsfm;
    for(int i = 0; i < 3; i++)
    {
        float gt = getGameTime()+30*i;
        float X = Maths::Cos(gt/40)*20;
        float Y = gt % 255;
        Matrix::MakeIdentity(trnsfm);
        Matrix::SetTranslation(trnsfm, X, Y, 0);
        Render::SetModelTransform(trnsfm);
        Render::SetAlphaBlend(true);
        Render::RawQuads("Snow.png", Verts);
    }
}