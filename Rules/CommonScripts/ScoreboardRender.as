#include "ScoreboardCommon.as";
#include "Accolades.as";

CPlayer@ hoveredPlayer;
Vec2f hoveredPos;

int hovered_accolade = -1;

//returns the bottom
float drawScoreboard(CPlayer@[] players, Vec2f topleft, CTeam@ team, Vec2f emblem)
{
	if (players.size() <= 0)
		return topleft.y;
	Vec2f orig = topleft; //save for later

	f32 lineheight = 16;
	f32 padheight = 2;
	f32 stepheight = lineheight + padheight;
	Vec2f bottomright(getScreenWidth() - 100, topleft.y + (players.length + 5.5) * stepheight);
	GUI::DrawPane(topleft, bottomright, team.color);

	//offset border
	topleft.x += stepheight;
	bottomright.x -= stepheight;
	topleft.y += stepheight;

	GUI::SetFont("menu");

	//draw team info
	GUI::DrawText(getTranslatedString(team.getName()), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Players: {PLAYERCOUNT}").replace("{PLAYERCOUNT}", "" + players.length), Vec2f(bottomright.x - 400, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 2;

	const int accolades_start = 650;

	//draw player table header
	GUI::DrawText(getTranslatedString("Player"), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Username"), Vec2f(bottomright.x - 400, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Ping"), Vec2f(bottomright.x - 260, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Kills"), Vec2f(bottomright.x - 190, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Deaths"), Vec2f(bottomright.x - 120, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("KDR"), Vec2f(bottomright.x - 50, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Accolades"), Vec2f(bottomright.x - accolades_start, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 0.5f;

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();

	//draw players
	for (u32 i = 0; i < players.length; i++)
	{
		CPlayer@ p = players[i];

		topleft.y += stepheight;
		bottomright.y = topleft.y + lineheight;

		bool playerHover = mousePos.y > topleft.y && mousePos.y < topleft.y + 15;

		if (playerHover && controls.mousePressed1)
		{
			setSpectatePlayer(p.getUsername());

		}

		Vec2f lineoffset = Vec2f(0, -2);

		u32 underlinecolor = 0xff404040;
		u32 playercolour = (p.getBlob() is null || p.getBlob().hasTag("dead")) ? 0xff505050 : 0xff808080;
		if (playerHover)
		{
			playercolour = 0xffcccccc;
			@hoveredPlayer = p;
			hoveredPos = topleft;
			hoveredPos.x = bottomright.x - 150;
		}

		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, SColor(underlinecolor));
		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, SColor(playercolour));

		string tex = "";
		u16 frame = 0;
		Vec2f framesize;
		if (p.isMyPlayer())
		{
			tex = "ScoreboardIcons.png";
			frame = 4;
			framesize.Set(16, 16);
		}
		else
		{
			tex = p.getScoreboardTexture();
			frame = p.getScoreboardFrame();
			framesize = p.getScoreboardFrameSize();
		}
		if (tex != "")
		{
			GUI::DrawIcon(tex, frame, framesize, topleft, 0.5f, p.getTeamNum());
		}

		string username = p.getUsername();

		string playername = p.getCharacterName();
		string clantag = p.getClantag();

		//have to calc this from ticks
		s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f);

		//how much room to leave for names and clantags
		float name_buffer = 24.0f;
		Vec2f clantag_actualsize(0, 0);

		//render the player + stats
		SColor namecolour = getNameColour(p);

		//right align clantag
		if (clantag != "")
		{
			GUI::GetTextDimensions(clantag, clantag_actualsize);
			GUI::DrawText(clantag, topleft + Vec2f(name_buffer, 0), SColor(0xff888888));
			//draw name alongside
			GUI::DrawText(playername, topleft + Vec2f(name_buffer + clantag_actualsize.x + 8, 0), namecolour);
		}
		else
		{
			//draw name alone
			GUI::DrawText(playername, topleft + Vec2f(name_buffer, 0), namecolour);
		}

		int accolades_x = accolades_start;

		Accolades@ acc = getPlayerAccolades(username);

		//(remove crazy amount of duplicate code)
		int[] badges_encode = {
			//count,                icon,  show_text, spacing

			//misc accolades
			(acc.community_contributor ?
				1 : 0),             4,     0,         24,
			(acc.github_contributor ?
				1 : 0),             5,     0,         24,
			(acc.map_contributor ?
				1 : 0),             6,     0,         24,

			//tourney badges
			acc.gold,               0,     1,         40,
			acc.silver,             1,     1,         40,
			acc.bronze,             2,     1,         40,
			acc.participation,      3,     1,         40,

			//(final dummy)
			0, 0, 0, 0,
		};

		for(int bi = 0; bi < badges_encode.length; bi += 4)
		{
			int amount    = badges_encode[bi+0];
			int icon      = badges_encode[bi+1];
			int show_text = badges_encode[bi+2];
			int spacing   = badges_encode[bi+3];

			if(amount > 0)
			{
				float x = bottomright.x - accolades_x;

				GUI::DrawIcon("AccoladeBadges", icon, Vec2f(16, 16), Vec2f(x, topleft.y), 0.5f, p.getTeamNum());
				if (show_text > 0)
				{
					string label_text = "" + amount;
					int label_center_offset = label_text.size() < 2 ? 4 : 0;
					GUI::DrawText(
						label_text,
						Vec2f(x + 15 + label_center_offset, topleft.y),
						SColor(0xffffffff)
					);
				}

				if (playerHover && mousePos.x > x && mousePos.x < x + 16)
				{
					hovered_accolade = icon;
				}
			}

			//handle repositioning
			accolades_x -= spacing;

		}

		GUI::DrawText("" + username, Vec2f(bottomright.x - 400, topleft.y), namecolour);
		GUI::DrawText("" + ping_in_ms, Vec2f(bottomright.x - 260, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getKills(), Vec2f(bottomright.x - 190, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getDeaths(), Vec2f(bottomright.x - 120, topleft.y), SColor(0xffffffff));
		GUI::DrawText(("" + getKDR(p)).substr(0, 4), Vec2f(bottomright.x - 50, topleft.y), SColor(0xffffffff));
	}

	return topleft.y;

}

void onRenderScoreboard(CRules@ this)
{
	//sort players
	CPlayer@[] blueplayers;
	CPlayer@[] redplayers;
	CPlayer@[] spectators;
	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		f32 kdr = getKDR(p);
		bool inserted = false;
		if (p.getTeamNum() == this.getSpectatorTeamNum())
		{
			spectators.push_back(p);
			continue;
		}

		int teamNum = p.getTeamNum();
		if (teamNum == 0) //blue team
		{
			for (u32 j = 0; j < blueplayers.length; j++)
			{
				if (getKDR(blueplayers[j]) < kdr)
				{
					blueplayers.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				blueplayers.push_back(p);

		}
		else
		{
			for (u32 j = 0; j < redplayers.length; j++)
			{
				if (getKDR(redplayers[j]) < kdr)
				{
					redplayers.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				redplayers.push_back(p);

		}

	}

	//draw board

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
		return;
	int localTeam = localPlayer.getTeamNum();
	if (localTeam != 0 && localTeam != 1)
		localTeam = 0;

	@hoveredPlayer = null;

	Vec2f topleft(100, 150);
	if (blueplayers.size() + redplayers.size() > 18)
	{
		topleft.y = drawServerInfo(10);

	}
	else
	{
		drawServerInfo(40);

	}

	//(reset)
	hovered_accolade = -1;

	//draw the scoreboards

	if (localTeam == 0)
		topleft.y = drawScoreboard(blueplayers, topleft, this.getTeam(0), Vec2f(0, 0));
	else
		topleft.y = drawScoreboard(redplayers, topleft, this.getTeam(1), Vec2f(32, 0));

	topleft.y += 52;

	if (localTeam == 1)
		topleft.y = drawScoreboard(blueplayers, topleft, this.getTeam(0), Vec2f(0, 0));
	else
		topleft.y = drawScoreboard(redplayers, topleft, this.getTeam(1), Vec2f(32, 0));

	topleft.y += 52;

	if (spectators.length > 0)
	{
		//draw spectators
		f32 stepheight = 16;
		Vec2f bottomright(getScreenWidth() - 100, topleft.y + stepheight * 2);
		f32 specy = topleft.y + stepheight * 0.5;
		GUI::DrawPane(topleft, bottomright, SColor(0xffc0c0c0));

		Vec2f textdim;
		string s = getTranslatedString("Spectators:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(topleft.x + 5, specy), SColor(0xffaaaaaa));

		f32 specx = topleft.x + textdim.x + 15;
		for (u32 i = 0; i < spectators.length; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < bottomright.x - 100)
			{
				string name = p.getCharacterName();
				if (i != spectators.length - 1)
					name += ",";
				GUI::GetTextDimensions(name, textdim);
				SColor namecolour = getNameColour(p);
				GUI::DrawText(name, Vec2f(specx, specy), namecolour);
				specx += textdim.x + 10;
			}
			else
			{
				GUI::DrawText(getTranslatedString("and more ..."), Vec2f(specx, specy), SColor(0xffaaaaaa));
				break;
			}
		}

		topleft.y += 52;
	}

	drawPlayerCard(hoveredPlayer, hoveredPos);

	drawAccoladeHover(hovered_accolade, Vec2f(getScreenWidth() * 0.5, topleft.y));

}

void drawAccoladeHover(int hovered_accolade, Vec2f centre_top)
{
	if( //(invalid/"unset" hover)
		hovered_accolade < 0
		|| hovered_accolade >= accolade_description.length
	) {
		return;
	}

	string desc = accolade_description[hovered_accolade];

	Vec2f size(0, 0);
	GUI::GetTextDimensions(desc, size);

	Vec2f tl = centre_top - Vec2f(size.x / 2, 0);
	Vec2f br = tl + size;

	//margin
	Vec2f expand(8, 8);
	tl -= expand;
	br += expand;

	GUI::DrawPane(tl, br, SColor(0xffffffff));
	GUI::DrawText(desc, tl + expand, SColor(0xffffffff));
}

void onTick(CRules@ this)
{
	if(getNet().isServer() && this.getCurrentState() == GAME)
	{
		this.set_u32("match_time", this.get_u32("match_time")+1);
		this.Sync("match_time", true);
	}
}

void onInit(CRules@ this)
{
	if(getNet().isServer())
	{
		this.set_u32("match_time", 0);
		this.Sync("match_time", true);
	}
}

void onRestart(CRules@ this)
{
	if(getNet().isServer())
	{
		this.set_u32("match_time", 0);
		this.Sync("match_time", true);
	}
}