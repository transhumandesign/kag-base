//ReportRender.as

#define CLIENT_ONLY

const int r = 35;

void onInit(CRules@ this)
{
	int cb_id = Render::addScript(Render::layer_prehud, "ReportRender.as", "ReportRenderFunction", 0.0f);
}

void ReportRenderFunction(int id)
{
    if (isClient())
	{
		CPlayer@ player = getLocalPlayer();

		if(player !is null && player.hasTag("moderator"))
		{
			CPlayer@[] reported;
			for (u8 i = 0; i < getPlayerCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				CBlob@ b = p.getBlob();
				if(p !is null && p.hasTag("reported"))
				{
					if(p.isMod() && b is null)
					{
						continue;
					}
					else
					{
						reported.push_back(p);
					}
				}
			}

			//draw side pane with reported players
			if(reported.length() > 0)
			{
				Vec2f screenPos = Vec2f(getScreenWidth() * 0.9f, getScreenHeight() * 0.70f);
				GUI::SetFont("menu");
				//draw right pane
				GUI::DrawPane(Vec2f(screenPos.x - 90, screenPos.y - 10), Vec2f(screenPos.x + 90, screenPos.y + (reported.length() * 18) - 5), SColor(128, 0, 0, 0));

				for (u8 i = 0; i < reported.length; i++)
				{
					CPlayer@ p = reported[i];
					if (p !is null)
					{
						int report_count = p.get_u8("reportCount");
						//TODO: translation friendly!
						string report_text = p.getUsername() + " has " + report_count + " report" + (report_count > 1 ? "s" : "") + ".";
						CBlob@ b = p.getBlob();
						if (b !is null)
						{
							Vec2f pos = b.getPosition();
							Vec2f worldPos = getDriver().getScreenPosFromWorldPos(pos);

							//draw hexagon around reported players.
							for(u8 j = 0; j < 6; j++)
							{
											//color
								RenderLine(	SColor(255, 255, 0, 0),
											//start line
											Vec2f(pos.x + (r * Maths::Cos(j * 60 * (Maths::Pi / 180.f))), pos.y + (r * Maths::Sin(j * 60 * (Maths::Pi / 180.f)))),
											//end line
											Vec2f(pos.x + (r * Maths::Cos((j + 1) * 60 * (Maths::Pi / 180.f))), pos.y + (r * Maths::Sin((j + 1) * 60 * Maths::Pi / 180.f))),
											//weight
											0.8f,
											//z level
											b.getSprite().getZ() + 0.1f
											);
							}

							//draw grey pane on the players, with the name of said player
							GUI::DrawPane(Vec2f(worldPos.x - 80, worldPos.y - 50), Vec2f(worldPos.x + 80, worldPos.y - 30), SColor(128, 0, 0, 0));
							GUI::DrawShadowedTextCentered(report_text, Vec2f(worldPos.x, worldPos.y - 40), SColor(255, 255, 0, 0));
						}
						
						//draw names on right pane
						GUI::DrawShadowedTextCentered(report_text, Vec2f(screenPos.x, screenPos.y + (i * 18)), SColor(255, 255, 0, 0));
					}
				}
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
