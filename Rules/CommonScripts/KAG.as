#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"

void onInit(CRules@ this)
{
	LoadDefaultMapLoaders();
	LoadDefaultGUI();

	sv_gravity = 9.81f;
	particles_gravity.y = 0.25f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	PrecacheTextures();

	//smooth shader
	Driver@ driver = getDriver();

	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", true);

	//also restart stuff
	onRestart(this);
}

bool need_sky_check = true;
void onRestart(CRules@ this)
{
	//map borders
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetBorderFadeWidth(24.0f);
		map.SetBorderColourTop(SColor(0xff000000));
		map.SetBorderColourLeft(SColor(0xff000000));
		map.SetBorderColourRight(SColor(0xff000000));
		map.SetBorderColourBottom(SColor(0xff000000));

		//do it first tick so the map is definitely there
		//(it is on server, but not on client unfortunately)
		need_sky_check = true;

		//map name
		if (isClient())
		{
			string[] mapPath = map.getMapName().split('/');				//split file path
			string mapFile = mapPath[mapPath.length() - 1];				//get file name
			string mapName = mapFile.substr(0, mapFile.length() - 4);	//remove .png

			string text = getTranslatedString("Map: {MAP}").replace("{MAP}", mapName);
			client_AddToChat(text);
		}
	}
}

void onTick(CRules@ this)
{
	//TODO: figure out a way to optimise so we don't need to keep running this hook
	if (need_sky_check)
	{
		need_sky_check = false;
		CMap@ map = getMap();
		//find out if there's any solid tiles in top row
		// if not - semitransparent sky
		// if yes - totally solid, looks buggy with "floating" tiles
		bool has_solid_tiles = false;
		for(int i = 0; i < map.tilemapwidth; i++) {
			if(map.isTileSolid(map.getTile(i))) {
				has_solid_tiles = true;
				break;
			}
		}
		map.SetBorderColourTop(SColor(has_solid_tiles ? 0xff000000 : 0x80000000));
	}

	if (isClient())
	{
		for (uint i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			string username = p.getUsername();
			string nickname = p.getCharacterName();
			int team = p.getTeamNum();
			bool sameName = (nickname == username);

			//name changed
			const string NAME_PROP = username + " old nickname";
			if (this.exists(NAME_PROP) && this.get_string(NAME_PROP) != nickname)
			{
				string text = getTranslatedString("{USERNAME} is now known as {PLAYER}")
					.replace("{USERNAME}", username)
					.replace("{PLAYER}", nickname);
				client_AddToChat(text);
			}

			//update old nickname
			this.set_string(NAME_PROP, nickname);

			//suppress team scramble chat spam
			if (getGameTime() > 5)
			{
				//get team name
				string teamName = "";
				if (team < this.getTeamsCount())
				{
					teamName = getTranslatedString(this.getTeam(team).getName());
				}

				//team changed
				const string TEAM_PROP = username + " old team";
				if (this.exists(TEAM_PROP) && this.get_s32(TEAM_PROP) != team)
				{
					string text;
					if (team == this.getSpectatorTeamNum())
					{
						text = getTranslatedString(sameName ? "{PLAYER} is now spectating" : "{PLAYER} ({USERNAME}) is now spectating");
					}
					else if (teamName != "")
					{
						text = getTranslatedString(sameName ? "{PLAYER} has joined {TEAM}" : "{PLAYER} ({USERNAME}) has joined {TEAM}")
							.replace("{TEAM}", teamName);
					}
					else
					{
						text = getTranslatedString(sameName ? "{PLAYER} has switched teams" : "{PLAYER} ({USERNAME}) has switched teams");
					}
					text = text.replace("{PLAYER}", nickname).replace("{USERNAME}", username);

					client_AddToChat(text, ConsoleColour::GAME);
				}

				//update old team
				this.set_s32(TEAM_PROP, team);
			}
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (isClient())
	{
		//join message
		string username = player.getUsername();
		string nickname = player.getCharacterName();

		string text = "{USERNAME} connected";
		if (username != nickname)
		{
			text += " as {PLAYER}";
		}
		text = getTranslatedString(text)
			.replace("{USERNAME}", username)
			.replace("{PLAYER}", nickname);

		client_AddToChat(text);
	}
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, Emotes::dots, 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, Emotes::off);
}
