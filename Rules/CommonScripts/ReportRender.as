//ReportRender.as

#define CLIENT_ONLY

const int r = 35;

// void Setup()
// {
// 	//ensure texture for our use exists
// 	if(!Texture::exists(test_name))
// 	{
// 		if(!Texture::createBySize(test_name, 8, 8))
// 		{
// 			warn("texture creation failed");
// 		}
// 		else
// 		{
// 			ImageData@ edit = Texture::data(test_name);

// 			for(int i = 0; i < edit.size(); i++)
// 			{
// 				edit[i] = SColor((((i + i / 8) % 2) == 0) ? 0xff707070 : 0xff909090);
// 			}

// 			if(!Texture::update(test_name, edit))
// 			{
// 				warn("texture update failed");
// 			}
// 		}
// 	}
// }

void onInit(CRules@ this)
{
	// Setup();
	int cb_id = Render::addScript(Render::layer_prehud, "ReportRender.as", "ReportRenderFunction", 0.0f);
}

void onRestart(CRules@ this)
{
	// Setup();
}


void ReportRenderFunction(int id)
{
    CPlayer@ player = getLocalPlayer();
	CBlob@[] players;
	getBlobsByTag("player", @players);
	if(player !is null && player.hasTag("moderator"))
    {
        // print("You're moderating");
        for (u8 i = 0; i < players.length; i++)
        {
            if(players[i].getPlayer().hasTag("reported"))
            {
                Vec2f pos = players[i].getPosition();
                Vec2f worldPos = getDriver().getScreenPosFromWorldPos(pos);
                Vec2f screenPos = Vec2f(getScreenWidth() * 0.8f, getScreenHeight() * 0.8f);

                // print("he's moderating");

                for(u8 j = 0; j < 6; j++)
                {
                    RenderLine(SColor(255, 255, 0, 0), Vec2f(pos.x + (r * Maths::Cos(j * 60 * (Maths::Pi / 180.f))), pos.y + (r * Maths::Sin(j * 60 * (Maths::Pi / 180.f)))), Vec2f(pos.x + (r * Maths::Cos((j + 1) * 60 * (Maths::Pi / 180.f))), pos.y + (r * Maths::Sin((j + 1) * 60 * Maths::Pi / 180.f))), 0.8f, players[i].getSprite().getZ() + 0.1f);
                    
                }

                GUI::DrawShadowedTextCentered(players[i].getPlayer().getUsername() + " has " + players[i].get_u8("reportCount") + " reports.", Vec2f(worldPos.x, worldPos.y - 40), SColor(255, 255, 0, 0));
                GUI::DrawShadowedTextCentered(players[i].getPlayer().getUsername() + " has " + formatInt(players[i].get_u8("reportCount"), "", 0) + " reports.", screenPos, SColor(255, 255, 0, 0));
            }
        }
    }
}

const string lineTextureName = "report texture";
Vec2f[] tex_coords;

bool setup = false; // has DoSetup been called?

void RenderLine(SColor col, Vec2f pos1, Vec2f pos2, f32 weight, f32 z)
{
    if (!setup)
    {
        DoLineSetup(); // make sure texture exists before using it
    }

    Vec2f temp = (pos1 - pos2).RotateBy(90.0f);
    temp.Normalize();
    Vec2f offset = temp * weight / 2.0f;

    Vertex[] v_raw;

    v_raw.push_back(Vertex(pos1 - offset, z, tex_coords[0], col));
    v_raw.push_back(Vertex(pos1 + offset, z, tex_coords[1], col));
    v_raw.push_back(Vertex(pos2 + offset, z, tex_coords[2], col));
    v_raw.push_back(Vertex(pos2 - offset, z, tex_coords[3], col));

    Render::RawQuads(lineTextureName, v_raw);
}

void DoLineSetup()
{
	if(!Texture::exists(lineTextureName))
	{
		if(!Texture::createBySize(lineTextureName, 1, 1))
		{
			warn("texture creation failed");
		}
		else
		{
			ImageData@ edit = Texture::data(lineTextureName);

			for(int i = 0; i < edit.size(); i++)
			{
				edit[i] = SColor(0xffffffff);
			}

			if(!Texture::update(lineTextureName, edit))
			{
				warn("texture update failed");
			}
		}
	}
    tex_coords.push_back(Vec2f(0, 0));
    tex_coords.push_back(Vec2f(0, 1));
    tex_coords.push_back(Vec2f(1, 1));
    tex_coords.push_back(Vec2f(1, 0));
    setup = true;
}
