
//CTF gamemode logic script

#define SERVER_ONLY

#include "CTF_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";

#include "CTF_PopulateSpawnList.as"

//edit the variables in the config file below to change the basics
// no scripting required!
void Config(CTFCore@ this)
{
	string configstr = "Rules/CTF/ctf_vars.cfg";
	if (getRules().exists("ctfconfig"))
	{
		configstr = getRules().get_string("ctfconfig");
	}

	ConfigFile cfg = ConfigFile(configstr);

	//how long to wait for everyone to spawn in?
	s32 warmUpTimeSeconds = cfg.read_s32("warmup_time", 30);
	this.warmUpTime = (getTicksASecond() * warmUpTimeSeconds);

	//how long for the game to play out?
	s32 gameDurationMinutes = cfg.read_s32("game_time", -1);
	if (gameDurationMinutes <= 0)
	{
		this.gameDuration = 0;
		getRules().set_bool("no timer", true);
	}
	else
	{
		this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes);
	}
	//how many players have to be in for the game to start
	this.minimum_players_in_team = cfg.read_s32("minimum_players_in_team", 2);
	//whether to scramble each game or not
	this.scramble_teams = cfg.read_bool("scramble_teams", true);

	//spawn after death time
	this.spawnTime = (getTicksASecond() * cfg.read_s32("spawn_time", 15));

}

shared string base_name() { return "tent"; }
shared string flag_name() { return "ctf_flag"; }
shared string flag_spawn_name() { return "flag_base"; }

//CTF spawn system

const s32 spawnspam_limit_time = 10;

shared class CTFSpawns : RespawnSystem
{
	CTFCore@ CTF_core;

	bool force;
	s32 limit;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@CTF_core = cast < CTFCore@ > (core);

		limit = spawnspam_limit_time;
	}

	void Update()
	{
		for (uint team_num = 0; team_num < CTF_core.teams.length; ++team_num)
		{
			CTFTeamInfo@ team = cast < CTFTeamInfo@ > (CTF_core.teams[team_num]);

			for (uint i = 0; i < team.spawns.length; i++)
			{
				CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (team.spawns[i]);

				UpdateSpawnTime(info, i);

				DoSpawnPlayer(info);
			}
		}
	}

	void UpdateSpawnTime(CTFPlayerInfo@ info, int i)
	{
		if (info !is null)
		{
			u8 spawn_property = 255;

			if (info.can_spawn_time > 0)
			{
				info.can_spawn_time--;
				spawn_property = u8(Maths::Min(250, (info.can_spawn_time / 30)));
			}

			string propname = "ctf spawn time " + info.username;

			CTF_core.rules.set_u8(propname, spawn_property);
			CTF_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));
		}

	}

	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		if (canSpawnPlayer(p_info))
		{
			//limit how many spawn per second
			if (limit > 0)
			{
				limit--;
				return;
			}
			else
			{
				limit = spawnspam_limit_time;
			}

			// tutorials hack
			if (getRules().exists("singleplayer"))
			{
				p_info.team = 0;
			}

			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

			if (player is null)
			{
				RemovePlayerFromSpawn(p_info);
				return;
			}
			if (player.getTeamNum() != int(p_info.team))
			{
				player.server_setTeamNum(p_info.team);
			}

			// remove previous players blob
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer(null);
				blob.server_Die();
			}

			CBlob@ playerBlob = SpawnPlayerIntoWorld(getSpawnLocation(p_info), p_info);

			if (playerBlob !is null)
			{
				// spawn resources
				p_info.spawnsCount++;
				RemovePlayerFromSpawn(player);
			}
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (p_info);

		if (info is null) { warn("CTF LOGIC: Couldn't get player info ( in bool canSpawnPlayer(PlayerInfo@ p_info) ) "); return false; }

		if (force) { return true; }

		return info.can_spawn_time <= 0;
	}

	Vec2f getSpawnLocation(PlayerInfo@ p_info)
	{
		CTFPlayerInfo@ c_info = cast < CTFPlayerInfo@ > (p_info);
		if (c_info !is null)
		{
			CBlob@ pickSpawn = getBlobByNetworkID(c_info.spawn_point);
			if (pickSpawn !is null &&
			        pickSpawn.hasTag("respawn") && !isUnderRaid(pickSpawn) &&
			        pickSpawn.getTeamNum() == p_info.team)
			{
				return pickSpawn.getPosition();
			}
			else
			{
				CBlob@[] spawns;
				PopulateSpawnList(spawns, p_info.team);

				for (uint step = 0; step < spawns.length; ++step)
				{
					if (spawns[step].getTeamNum() == s32(p_info.team))
					{
						return spawns[step].getPosition();
					}
				}
			}
		}

		return Vec2f(0, 0);
	}

	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
	}

	void RemovePlayerFromSpawn(PlayerInfo@ p_info)
	{
		CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (p_info);

		if (info is null) { warn("CTF LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(PlayerInfo@ p_info) )"); return; }

		string propname = "ctf spawn time " + info.username;

		for (uint i = 0; i < CTF_core.teams.length; i++)
		{
			CTFTeamInfo@ team = cast < CTFTeamInfo@ > (CTF_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				team.spawns.erase(pos);
				break;
			}
		}

		CTF_core.rules.set_u8(propname, 255);   //not respawning
		CTF_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));

		//DONT set this zero - we can re-use it if we didn't actually spawn
		//info.can_spawn_time = 0;
	}

	void AddPlayerToSpawn(CPlayer@ player)
	{
		s32 tickspawndelay = s32(CTF_core.spawnTime);

		CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (core.getInfoFromPlayer(player));

		if (info is null) { warn("CTF LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

		//clamp it so old bad values don't get propagated
		s32 old_spawn_time = Maths::Max(0, Maths::Min(info.can_spawn_time, tickspawndelay));

		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		if (info.team < CTF_core.teams.length)
		{
			CTFTeamInfo@ team = cast < CTFTeamInfo@ > (CTF_core.teams[info.team]);

			info.can_spawn_time = ((old_spawn_time > 30) ? old_spawn_time : tickspawndelay);

			info.spawn_point = player.getSpawnPoint();
			team.spawns.push_back(info);
		}
		else
		{
			error("PLAYER TEAM NOT SET CORRECTLY! " + info.team + " / " + CTF_core.teams.length);
		}
	}

	bool isSpawning(CPlayer@ player)
	{
		CTFPlayerInfo@ info = cast < CTFPlayerInfo@ > (core.getInfoFromPlayer(player));
		for (uint i = 0; i < CTF_core.teams.length; i++)
		{
			CTFTeamInfo@ team = cast < CTFTeamInfo@ > (CTF_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				return true;
			}
		}
		return false;
	}

};

shared class CTFCore : RulesCore
{
	s32 warmUpTime;
	s32 gameDuration;
	s32 spawnTime;

	s32 minimum_players_in_team;

	s32 players_in_small_team;
	bool scramble_teams;

	CTFSpawns@ ctf_spawns;

	CTFCore() {}

	CTFCore(CRules@ _rules, RespawnSystem@ _respawns)
	{
		super(_rules, _respawns);
	}


	int gamestart;
	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		gamestart = getGameTime();
		@ctf_spawns = cast < CTFSpawns@ > (_respawns);
		_rules.set_string("music - base name", base_name());
		server_CreateBlob("Entities/Meta/WARMusic.cfg");
		players_in_small_team = -1;
	}

	void Update()
	{
		if (rules.isGameOver()) { return; }

		s32 ticksToStart = gamestart + warmUpTime - getGameTime();
		ctf_spawns.force = false;

		if (ticksToStart <= 0 && (rules.isWarmup()))
		{
			rules.SetCurrentState(GAME);
		}
		else if (ticksToStart > 0 && rules.isWarmup()) //is the start of the game, spawn everyone + give mats
		{
			rules.SetGlobalMessage("Match starts in " + ((ticksToStart / 30) + 1));
			ctf_spawns.force = true;
		}

		if ((rules.isIntermission() || rules.isWarmup()) && (!allTeamsHavePlayers()))  //CHECK IF TEAMS HAVE ENOUGH PLAYERS
		{
			gamestart = getGameTime();
			rules.set_u32("game_end_time", gamestart + gameDuration);
			rules.SetGlobalMessage("Not enough players in each team for the game to start.\nPlease wait for someone to join...");
			ctf_spawns.force = true;
		}
		else if (rules.isMatchRunning())
		{
			rules.SetGlobalMessage("");
		}

		/*
		 * If you want to do something tricky with respawning flags and stuff here, go for it
		 */

		RulesCore::Update(); //update respawns
		CheckTeamWon();

	}

	//HELPERS
	bool allTeamsHavePlayers()
	{
		for (uint i = 0; i < teams.length; i++)
		{
			if (teams[i].players_count < minimum_players_in_team)
			{
				return false;
			}
		}

		return true;
	}

	//team stuff

	void AddTeam(CTeam@ team)
	{
		CTFTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
	{
		if (getRules().exists("singleplayer"))
		{
			team = 0;
		}
		else
		{
			team = player.getTeamNum();
		}
		CTFPlayerInfo p(player.getUsername(), team, (XORRandom(512) >= 256 ? "knight" : "archer"));
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
	}

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
	{
		if (!rules.isMatchRunning()) { return; }

		if (victim !is null)
		{
			if (killer !is null && killer.getTeamNum() != victim.getTeamNum())
			{
				addKill(killer.getTeamNum());
			}
		}
	}

	void onSetPlayer(CBlob@ blob, CPlayer@ player)
	{
		if (blob !is null && player !is null)
		{
			//GiveSpawnResources( blob, player );
		}
	}

	//setup the CTF bases

	void SetupBase(CBlob@ base)
	{
		if (base is null)
		{
			return;
		}

		//nothing to do
	}

	void SetupBases()
	{
		// destroy all previous spawns if present
		CBlob@[] oldBases;
		getBlobsByName(base_name(), @oldBases);

		for (uint i = 0; i < oldBases.length; i++)
		{
			oldBases[i].server_Die();
		}

		CMap@ map = getMap();

		if (map !is null)
		{
			//spawn the spawns :D
			Vec2f respawnPos;

			f32 auto_distance_from_edge_tents = Maths::Min(map.tilemapwidth * 0.15f * 8.0f, 100.0f);

			if (!getMap().getMarker("blue main spawn", respawnPos))
			{
				warn("CTF: Blue spawn added");
				respawnPos = Vec2f(auto_distance_from_edge_tents, map.getLandYAtX(auto_distance_from_edge_tents / map.tilesize) * map.tilesize - 16.0f);
			}

			respawnPos.y -= 8.0f;
			SetupBase(server_CreateBlob(base_name(), 0, respawnPos));

			if (!getMap().getMarker("red main spawn", respawnPos))
			{
				warn("CTF: Red spawn added");
				respawnPos = Vec2f(map.tilemapwidth * map.tilesize - auto_distance_from_edge_tents, map.getLandYAtX(map.tilemapwidth - (auto_distance_from_edge_tents / map.tilesize)) * map.tilesize - 16.0f);
			}

			respawnPos.y -= 8.0f;
			SetupBase(server_CreateBlob(base_name(), 1, respawnPos));

			//setup the flags

			//temp to hold them all
			Vec2f[] flagPlaces;

			f32 auto_distance_from_edge = Maths::Min(map.tilemapwidth * 0.25f * 8.0f, 400.0f);

			//blue flags
			if (getMap().getMarkers("blue spawn", flagPlaces))
			{
				for (uint i = 0; i < flagPlaces.length; i++)
				{
					server_CreateBlob(flag_spawn_name(), 0, flagPlaces[i] + Vec2f(0, map.tilesize));
				}

				flagPlaces.clear();
			}
			else
			{
				warn("CTF: Blue flag added");
				f32 x = auto_distance_from_edge;
				respawnPos = Vec2f(x, (map.getLandYAtX(x / map.tilesize) - 2) * map.tilesize);
				server_CreateBlob(flag_spawn_name(), 0, respawnPos);
			}

			//red flags
			if (getMap().getMarkers("red spawn", flagPlaces))
			{
				for (uint i = 0; i < flagPlaces.length; i++)
				{
					server_CreateBlob(flag_spawn_name(), 1, flagPlaces[i] + Vec2f(0, map.tilesize));
				}

				flagPlaces.clear();
			}
			else
			{
				warn("CTF: Red flag added");
				f32 x = map.tilemapwidth * map.tilesize - auto_distance_from_edge;
				respawnPos = Vec2f(x, (map.getLandYAtX(x / map.tilesize) - 2) * map.tilesize);
				server_CreateBlob(flag_spawn_name(), 1, respawnPos);
			}
		}

		rules.SetCurrentState(WARMUP);
	}

	//checks
	void CheckTeamWon()
	{
		if (!rules.isMatchRunning()) { return; }

		// get all the flags
		CBlob@[] flags;
		getBlobsByName(flag_name(), @flags);

		int winteamIndex = -1;
		CTFTeamInfo@ winteam = null;
		s8 team_wins_on_end = -1;

		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			CTFTeamInfo@ team = cast < CTFTeamInfo@ > (teams[team_num]);

			bool win = true;
			for (uint i = 0; i < flags.length; i++)
			{
				//if there exists an enemy flag, we didn't win yet
				if (flags[i].getTeamNum() != team_num)
				{
					win = false;
					break;
				}
			}

			if (win)
			{
				winteamIndex = team_num;
				@winteam = team;
			}

		}

		rules.set_s8("team_wins_on_end", team_wins_on_end);

		if (winteamIndex >= 0)
		{
			// add winning team coins
			if (rules.isMatchRunning())
			{
				CBlob@[] players;
				getBlobsByTag("player", @players);
				for (uint i = 0; i < players.length; i++)
				{
					CPlayer@ player = players[i].getPlayer();
					if (player !is null && players[i].getTeamNum() == winteamIndex)
					{
						player.server_setCoins(player.getCoins() + 10);
					}
				}
			}

			rules.SetTeamWon(winteamIndex);   //game over!
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage(winteam.name + " wins the game!");
		}
	}

	void addKill(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			CTFTeamInfo@ team_info = cast < CTFTeamInfo@ > (teams[team]);
		}
	}

};

//pass stuff to the core from each of the hooks

void Reset(CRules@ this)
{
	CBitStream stream;
	stream.write_u16(0xDEAD); //check bits rewritten when theres something useful
	this.set_CBitStream("ctf_serialised_team_hud", stream);
    this.Sync("ctf_serialized_team_hud", true);

	printf("Restarting rules script: " + getCurrentScriptName());
	CTFSpawns spawns();
	CTFCore core(this, spawns);
	Config(core);
	core.SetupBases();
	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
	this.set_s32("restart_rules_after_game_time", 25 * 30);
}

// had to add it here for tutorial cause something didnt work in the tutorial script
void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (this.exists("tutorial"))
	{
		const string name = blob.getName();
		if ((name == "archer" || name == "knight" || name == "chicken") && !blob.hasTag("dropped coins"))
		{
			server_DropCoins(blob.getPosition(), XORRandom(15) + 5);
			blob.Tag("dropped coins");
		}
	}
}
