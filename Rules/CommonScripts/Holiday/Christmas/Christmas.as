// Christmas.as
//
//TODO: re-apply new holiday sprites when holiday is active
//		(check git history around xmas 2018 for holiday versions)

#include "TreeCommon.as";

const int present_interval = 30 * 60 * 10; // 10 minutes
const int gifts_per_hoho = 3;

// Snow stuff
bool _snow_ready = false;
Vertex[] Verts;
SColor snow_col(0xffffffff);
f64 frameTime = 0;

void onInit(CRules@ this)
{
	if (isClient())
	{
		this.set_s16("snow_render_id", 0);
	}

	this.addCommandID("xmas sound");

	onRestart(this);
}

void onRestart(CRules@ this)
{
	_snow_ready = false;
	this.set_s32("present timer", present_interval);
	frameTime = 0;
}

void onTick(CRules@ this)
{
	if (isClient())
	{
		s16 renderId = this.get_s16("snow_render_id");
		// Have we just disabled fast render
		if (renderId == 0 && !v_fastrender)
		{
			this.set_s16("snow_render_id", Render::addScript(Render::layer_background, "Christmas.as", "DrawSnow", 0));
		} 
		else if (renderId != 0 && v_fastrender || this.get_string("holiday") != "Christmas") // Have we just enabled fast render OR is holiday over
		{
			Render::RemoveScript(renderId);
			this.set_s16("snow_render_id", 0);
		}
	}
	
	if (!isClient() || this.isWarmup() || !(this.gamemode_name == "CTF" || this.gamemode_name == "TTH" || this.gamemode_name == "SmallCTF"))
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

			for (uint i = 0; i < trees.size(); i++)
			{
				TreeVars@ vars;
				trees[i].get("TreeVars", @vars);

				if (vars.height >= 5)
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

			for (uint i = 0; i < gifts_per_hoho; i++)
			{
				if (trees_blue.length > 0)
				{
					int random = XORRandom(trees_blue.length);
					spawnPresent(trees_blue[random].getPosition(), XORRandom(8));
					trees_blue.removeAt(random);
					is_spawned = true;
				}
				else
				{
					spawnPresent(Vec2f(XORRandom(map.tilemapwidth * map.tilesize / 2), 0), XORRandom(8)).Tag("parachute");
					is_spawned = true;
				}

				if (trees_red.length > 0)
				{
					int random = XORRandom(trees_red.length);
					spawnPresent(trees_red[random].getPosition(), XORRandom(8));
					trees_red.removeAt(random);
					is_spawned = true;
				}
				else
				{
					is_spawned = true;
					spawnPresent(Vec2f(map.tilemapwidth * map.tilesize - XORRandom(map.tilemapwidth * map.tilesize / 2), 0), XORRandom(8)).Tag("parachute");
				}
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

CBlob@ spawnPresent(Vec2f spawnpos, u8 team)
{
	return server_CreateBlob("present", team, spawnpos);
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
	frameTime += getRenderApproximateCorrectionFactor();
	
	float[] trnsfm;
	for(int i = 0; i < 3; i++)
	{
		float gt = frameTime * (1.0f + (0.031f * i)) + (997 * i);
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
