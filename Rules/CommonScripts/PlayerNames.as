#define CLIENT_ONLY

float spacing = 1.0f; // spacing between hearts
Vec2f icon_size = Vec2f(12, 12); // heart icon frame size

float max_radius = 64.0f; // screenspace distance
uint16[] blob_ids;

void onTick(CRules@ this)
{
	if (!this.canShowHoverNames() || g_videorecording)
		return;
	
	blob_ids.clear();
	CControls@ c = getControls();
	Vec2f mouse_pos = c.getMouseWorldPos();

	uint8 team = this.getSpectatorTeamNum();
	CBlob@ my_blob = getLocalPlayerBlob();
	if (my_blob !is null) // dont change team if we are dead, so that we can see everyone names
		team = my_blob.getTeamNum();

	for (int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		CBlob@ blob = player.getBlob();
		if (blob is null || blob is my_blob)
		{
			continue;
		}

		if (team == this.getSpectatorTeamNum() || // always add if we are spectator
			team == blob.getTeamNum() && u_shownames || // if teammate and always show teammate names enabled
			((mouse_pos - blob.getPosition()).Length() <= max_radius && getMap().getColorLight(blob.getPosition()).getRed() >= 30)) // if hovering over & not in darkness
		{
			blob_ids.push_back(blob.getNetworkID());
		}
	}
}

void onRender(CRules@ this)
{
	if (!this.canShowHoverNames() || g_videorecording)
		return;
	
	CControls@ c = getControls();
	Vec2f mouse_screen_pos = c.getInterpMouseScreenPos();

	for (int i = 0; i < blob_ids.size(); i++)
	{
		CBlob@ blob = getBlobByNetworkID(blob_ids[i]);
		if (blob !is null) // you never know...
		{
			CPlayer@ player = blob.getPlayer();
			if (player !is null) // you never know...
			{
				Vec2f draw_pos = blob.getInterpolatedPosition() + Vec2f(0.0f, blob.getRadius());
				draw_pos = getDriver().getScreenPosFromWorldPos(draw_pos);

				// change alpha depending on distance between mouse and player
				float dist = Maths::Min(max_radius, (mouse_screen_pos - blob.getInterpolatedScreenPos()).Length());
				float alpha = Maths::Min(1.0f, 1.4f-(dist / max_radius)); // min 0.4, max 1

				// first draw hearts (only for "player" blobs that are also alive (knight, archer and builder))
				if (blob.hasTag("player"))
				{
					SColor heart_color = SColor(255*alpha, 255, 255, 255);
                    
					// values are doubled so they are easier to work with
					float max_health = blob.getInitialHealth() * 2.0f;
					float health = blob.getHealth() * 2.0f;

					int amount = Maths::Ceil(max_health);

					Vec2f heart_start_pos = draw_pos - Vec2f((amount/2.0f * spacing) + (amount * icon_size.x) - 1.0f, 0);

					for (int h = 0; h < amount; h++)
					{
						int icon = 0;
						// behold, sh*tcode
						if (health >= 1.0f)
							icon = 1;
						else if (health >= 0.75f)
							icon = 2;
						else if (health >= 0.5f)
							icon = 3;
						else if (health >= 0.25f)
							icon = 4;

						if (icon != 0)
							GUI::DrawIcon("HeartNBubble.png", 0, icon_size, heart_start_pos, 1.0f, heart_color); // draw a frame behind heart piece
						GUI::DrawIcon("HeartNBubble.png", icon, icon_size, heart_start_pos, 1.0f, heart_color);
						heart_start_pos.x += icon_size.x * 2.0f + spacing; // icons are drawn in 2x size, so need to do * 2.0f
						health -= 1;
					}

					draw_pos.y += 32.0f; // number i pulled up from my arse
				}

				// now draw nickname
				string name = player.getCharacterName();
				string clan_tag = player.getClantag();
				bool has_clan = clan_tag.size() > 0;

				Vec2f text_dim;
				GUI::SetFont("menu");
				GUI::GetTextDimensions(has_clan ? (clan_tag + " " + name) : name, text_dim);
				Vec2f text_dim_half = Vec2f(text_dim.x/2.0f, text_dim.y/2.0f);

				Vec2f clan_dim;
				if (has_clan)
					GUI::GetTextDimensions(clan_tag + " ", clan_dim);

				SColor text_color = SColor(255, 200, 200, 200);
				CTeam@ team = this.getTeam(blob.getTeamNum());
				if (team !is null)
					text_color = team.color;
				
				SColor clan_color = SColor(255, 128, 128, 128);

				text_color.setAlpha(255 * alpha);
				clan_color.setAlpha(255 * alpha);

				SColor rect_color = SColor(80 * alpha, 0, 0, 0);

				GUI::DrawRectangle(draw_pos - text_dim_half, draw_pos + text_dim_half + Vec2f(5.0f, 3.0f), rect_color);
				if (has_clan)
					GUI::DrawText(clan_tag, draw_pos - text_dim_half, clan_color);
				GUI::DrawText(name, draw_pos - text_dim_half + (has_clan ? Vec2f(clan_dim.x, 0) : Vec2f_zero), text_color);
			}
		}
	}
}
