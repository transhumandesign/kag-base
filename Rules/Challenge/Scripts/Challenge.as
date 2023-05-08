
//war gamemode logic script

#define SERVER_ONLY

#include "WAR_Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"
#include "WAR_PopulateSpawnList.as"
#include "WAR_HUDCommon.as"
#include "TradingCommon.as"
#include "Descriptions.as"

const f32 MOOK_SPAWN_DISTANCE = 600.0f;
const f32 DIFFICULTY_INCREASE_DISTANCE = 500.0f;

const int MAX_DIFFICULTY = 15;

//simple config function - edit the variables in the config file
void Config(ChallengeCore@ this)
{
	CRules@ rules = getRules();
	string configstr;
	if (rules.exists("rulesconfig"))
	{
		configstr = rules.get_string("rulesconfig");
		printf("Loading rules vars from " + configstr);
	}

	if (configstr.size() == 0)
	{
		configstr = "Rules/Challenge/challenge_vars.cfg";
		printf("Vars file not found. Using default vars " + configstr);
	}

	ConfigFile cfg = ConfigFile(configstr);

	//spawn after death time
	s32 warmUpTimeSeconds = cfg.read_s32("warmup_time", 5);
	this.warmUpTime = (getTicksASecond() * warmUpTimeSeconds);
	this.spawnTime = sv_test ? 1 : cfg.read_u8("spawn_time", 5);
	this.daytime_progression = cfg.read_s32("daytime_progression", 50);
	this.start_difficulty = cfg.read_u8("start_difficulty", 0);
	this.start_class = cfg.read_string("start_class", "knight");

	this.introduction = cfg.read_string("introduction", "");
	rules.set_string("introduction", this.introduction);
	rules.Sync("introduction", true);

	this.bombsOnSpawn = cfg.read_u8("bombs", 0);
	this.woodOnSpawn = cfg.read_u8("wood", 0);
	this.repeat_map_if_lost = cfg.read_bool("repeat_map_if_lost", false);

	//how long for the game to play out?
	s32 gameDurationSecs = cfg.read_s32("game_time", -1);
	if (sv_test)
	{
		gameDurationSecs = 0;
	}

	if (gameDurationSecs <= 0)
	{
		this.gameTicksLeft = 0;
		rules.set_bool("no timer", true);
	}
	else
	{
		this.gameTicksLeft = (getTicksASecond() * gameDurationSecs);
	}
	rules.set_u32("game ticks left", this.gameTicksLeft);
	rules.set_u32("game ticks duration", this.gameTicksLeft);
	rules.Sync("game ticks left", true);
	rules.Sync("game ticks duration", true);

	rules.set_bool("repeat if dead", false);
}


// without "shared" we cannot hot-swap this class :(
// with "shared" we needt o use other function that are "shared" too

shared class ChallengeSpawns : RespawnSystem
{
	ChallengeCore@ mycore;

	WarPlayerInfo@[] spawns;

	s32 nextSpawn;
	bool first;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@mycore = cast < ChallengeCore@ > (core);
		nextSpawn = 10;
		first = true;
	}

	void Update()
	{
		s32 time = getGameTime();
		if (time % 28 == 0)
		{
			for (uint i = 0; i < spawns.length; i++)
			{
				updatePlayerSpawnTime(spawns[i]);
			}

			// calculate team sizes

			getRules().set_u8("team 0 count", getTeamSize(mycore.teams, 0));
			getRules().set_u8("team 1 count", getTeamSize(mycore.teams, 1));
		}

		if (time > nextSpawn) //each second
		{
			for (uint i = 0; i < spawns.length; i++)
			{
				WarPlayerInfo@ info = spawns[i];
				if (info.wave_delay > 0)
				{
					info.wave_delay--;
				}
			}
			int delta = -1;
			//we do erases in here, and unfortunately don't
			//have any other way to detect them than just looping until nothing more comes out.
			while (delta != 0)
			{
				uint len = spawns.length;
				for (uint i = 0; i < spawns.length; i++)
				{
					WarPlayerInfo@ info = spawns[i];
					DoSpawnPlayer(info);   //check if we should spawn them
				}
				delta = spawns.length - len;
			}

			nextSpawn += 30;
		}
	}

	void updatePlayerSpawnTime(WarPlayerInfo@ w_info)
	{
		WarTeamInfo@ team = cast < WarTeamInfo@ > (core.getTeam(w_info.team));
		//sync player time to them directly
		string propname = "time to spawn " + w_info.username;
		s32 time = getSpawnTime(team, w_info);
		mycore.rules.set_s32(propname, time);
		mycore.rules.SyncToPlayer(propname, getPlayerByUsername(w_info.username));
		propname = "needs respawn hud " + w_info.username;
		mycore.rules.set_bool(propname, (time > s32(getGameTime())));
		mycore.rules.SyncToPlayer(propname, getPlayerByUsername(w_info.username));
	}

	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (p_info);

		if (getRules().isMatchRunning() && (canSpawnPlayer(p_info) || first))
		{
			p_info.team = 0;

			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?
			if (player is null)
			{
				return;
			}
			RemovePlayerFromSpawn(player);
			first = false;

			Vec2f spawnPos;

			// force
			p_info.team = 0;
			p_info.blob_name = mycore.getStartClass(p_info.blob_name);

			if (p_info.blob_name == "builder")
				mycore.buildersCount++;
			if (p_info.blob_name == "knight")
				mycore.knightsCount++;
			if (p_info.blob_name == "archer")
				mycore.archersCount++;

			CBlob@ spawnBlob = getSpawnBlobs(p_info);
			if (spawnBlob !is null)
			{
				spawnPos = spawnBlob.getPosition();
			}
			else
			{
				spawnPos = getSpawnLocation(p_info.team);
			}

			string propname = "needs respawn hud " + p_info.username;
			mycore.rules.set_bool(propname, false);
			mycore.rules.SyncToPlayer(propname, getPlayerByUsername(p_info.username));
			p_info.spawnsCount++;

			SpawnPlayerIntoWorld(spawnPos, p_info);
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (p_info);

		return w_info.wave_delay == 0;
	}

	s32 getSpawnTime(WarTeamInfo@ team, WarPlayerInfo@ w_info)
	{
		return nextSpawn + w_info.wave_delay * 30;
	}

	Vec2f getSpawnLocation(int team)
	{
		CMap@ map = getMap();

		// get markers

		Vec2f respawnPos;
		if (map.getMarker(team == 0 ? "blue main spawn" : "red main spawn", respawnPos))
		{
			return respawnPos;
		}

		f32 side = map.tilesize * 5.0f;
		f32 x = team == 0 ? side : (map.tilesize * map.tilemapwidth - side);
		f32 y = map.tilesize * map.tilemapheight;
		for (uint i = 0; i < map.tilemapheight; i++)
		{
			y -= map.tilesize;
			if (!map.isTileSolid(map.getTile(Vec2f(x, y)))
			        && !map.isTileSolid(map.getTile(Vec2f(x - map.tilesize, y)))
			        && !map.isTileSolid(map.getTile(Vec2f(x + map.tilesize, y)))
			        && !map.isTileSolid(map.getTile(Vec2f(x, y - map.tilesize)))
			        && !map.isTileSolid(map.getTile(Vec2f(x, y - 2 * map.tilesize)))
			        && !map.isTileSolid(map.getTile(Vec2f(x, y - 3 * map.tilesize)))
			   )
				break;
		}
		y -= 32.0f;
		return Vec2f(x, y);
	}

	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		WarPlayerInfo@ info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(player));
		if (info is null) { warn("CHALLENGE LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(CPlayer@ player) )"); return; }

		int pos = spawns.find(info);
		if (pos != -1)
		{
			spawns.erase(pos);
		}
	}

	void AddPlayerToSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		WarPlayerInfo@ info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(player));

		if (info is null) { warn("CHALLENGE LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

		//wave delay used as seconds
		info.wave_delay = 1 + mycore.spawnTime;
		info.spawnpoint = player.getSpawnPoint();

		spawns.push_back(info);
	}

	bool isSpawning(CPlayer@ player)
	{
		WarPlayerInfo@ info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(player));
		int pos = spawns.find(info);
		return (pos != -1);
	}

	CBlob@ getSpawnBlobs(PlayerInfo@ p_info, bool takeUnderRaid = false)
	{
		CBlob@[] available;
		WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (p_info);
		if (w_info.deathDistanceToBase <= 0.0f) // first time
		{
			return null;
		}

		Vec2f deathPosition = w_info.deathPosition;

		// get "respawn" bases
		// only if close to them

		PopulateSpawnList(@available, w_info.team, takeUnderRaid);

		if (available.length > 0)
		{
			// pick closest to death position
			while (available.size() > 0)
			{
				f32 closestDist = 999999.9f;
				uint closestIndex = 999;
				for (uint i = 0; i < available.length; i++)
				{
					CBlob @b = available[i];
					Vec2f bpos = b.getPosition();
					const f32 dist = (bpos - w_info.deathPosition).getLength();
					if (dist < closestDist)
					{
						closestDist = dist;
						closestIndex = i;
					}
				}
				if (closestIndex >= 999)
				{
					break;
				}
				return available[closestIndex];
			}
		}

		return null;
	}

};

shared class ChallengeCore : RulesCore
{
	s32 warmUpTime;
	s32 spawnTime;
	s32 daytime_progression;
	s32 difficulty;
	s32 start_difficulty;
	f32 lastDifficultyIncPos;
	int intervalSpawnerCount;
	f32 playerFarthestDistance;
	int necromancerWinCounter;
	s32 gameTicksLeft;
	string introduction;
	u8 bombsOnSpawn;
	u8 woodOnSpawn;
	bool repeat_map_if_lost;

	int showIntroductionTime;
	int showIntroductionCounter;

	string start_class;
	int archersCount, buildersCount, knightsCount;

	ChallengeSpawns@ war_spawns;

	ChallengeCore() {}

	ChallengeCore(bool skip)
	{
		super(skip);
	}

	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		@war_spawns = cast < ChallengeSpawns@ > (_respawns);
		rules.SetCurrentState(WARMUP);
		server_CreateBlob("Entities/Meta/ChallengeMusic.cfg");

		difficulty = start_difficulty;
		lastDifficultyIncPos = 0.0f;
		intervalSpawnerCount = -1;
		playerFarthestDistance = 150.0f;
		showIntroductionTime = 20 * 30;
		showIntroductionCounter = 0;

		archersCount = buildersCount = knightsCount = 0;

		CMap@ map = getMap();
		if (getNet().isServer())
		{
			if (daytime_progression == -1)
			{
				map.SetDayTime(playerFarthestDistance / float(map.tilemapwidth * map.tilesize));
			}
			else
			{
				map.SetDayTime(float(daytime_progression) / 100.0f);
			}
		}
	}

	void Update()
	{
		const u32 time = getGameTime();
		//HUD
		if (time % 31 == 0)
		{
			updateHUD();

			// update day time - dawn - dusk based on players x position
			if (daytime_progression == -1)
			{
				CBlob@ playerBlob = getLocalPlayerBlob();
				if (playerBlob !is null)
				{
					if (playerBlob.getPosition().x > playerFarthestDistance)
					{
						playerFarthestDistance = playerBlob.getPosition().x;
					}
				}
				CMap@ map = getMap();
				map.SetDayTime((playerFarthestDistance + 300.0f) / float(map.tilemapwidth * map.tilesize));
			}
		}
		if (rules.isGameOver()) { return; }

		if (rules.isIntermission() || rules.isWarmup() || !hasPlayers())
		{
			warmUpTime--;
			if (warmUpTime <= 0)
			{
				rules.SetCurrentState(GAME);
				rules.SetGlobalMessage(rules.get_string("introduction"));

			}
			else
			{
				rules.SetGlobalMessage("{INTRODUCTION}\n\n{STARTING_IN}");
				rules.AddGlobalMessageReplacement("INTRODUCTION", rules.get_string("introduction"));
				rules.AddGlobalMessageReplacement("STARTING_IN", "Starting in... {SEC}s");
				rules.AddGlobalMessageReplacement("SEC", "" + ((warmUpTime / 30) + 1));
			}
		}
		else if (rules.isMatchRunning())
		{
			if (time % 30 == 0)
			{
				UpdatePlayerCounts();
				UpdateMooks();

				// update timer

				if (gameTicksLeft > 0)
				{
					gameTicksLeft -= 30;
					if (gameTicksLeft <= 0)
					{
						// end game - time limit
						rules.SetTeamWon(1);
						rules.SetCurrentState(GAME_OVER);
						rules.SetGlobalMessage("Time passed!");
						sv_mapautocycle = true;
						gameTicksLeft = 0;
					}
					rules.set_u32("game ticks left", gameTicksLeft);
					rules.Sync("game ticks left", true);
					if (gameTicksLeft == 0)
					{ return; }

				}

				if (showIntroductionCounter < showIntroductionTime)
				{
					rules.SetGlobalMessage(rules.get_string("introduction"));
					showIntroductionCounter++;
				}
				else
				{
					rules.SetGlobalMessage("");
				}
			}
		}

		if (necromancerWinCounter > 0)
		{
			necromancerWinCounter--;
			if (necromancerWinCounter == 0)
			{
				Sound::Play("/FanfareWin.ogg");
			}
		}

		RulesCore::Update(); //update respawns
	}

	void updateHUD()
	{

	}

	//team stuff

	void AddTeam(CTeam@ team)
	{
		WarTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
	{
		buildersCount = archersCount = knightsCount = 0;
		WarPlayerInfo p(player.getUsername(), 0, getStartClass("knight"));	// always team 0
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
	}

	bool hasPlayers()
	{
		for (uint i = 0; i < 1; i++)
		{
			if (teams[i].players_count == 0)
			{
				return false;
			}
		}
		return true;
	}

	string getStartClass(const string lastClassName)
	{
		bool noBuilder = getTeamSize(teams, 0) <= 1;

		CBlob@[] players;
		getBlobsByTag("player", @players);
		int playersCount = 0;
		for (uint i = 0; i < players.length; i++)
		{
			CBlob@ player = players[i];
			if (player.getTeamNum() == 0)
			{
				if (player.getName() == "builder")
					buildersCount++;
				else if (player.getName() == "archer")
					archersCount++;
				else if (player.getName() == "knight")
					knightsCount++;
			}
		}

		// set it

		if (start_class == "last")
		{
			return lastClassName;
		}
		else if (start_class == "random")
		{
			int c = XORRandom(3);
			if (c == 0)
				return "knight";
			if (c == 1)
				return "archer";
			if (!noBuilder)
				return "builder";
			else
				return "knight";
		}
		else if (start_class == "no builder")
		{
			int c = XORRandom(2);
			while (true)
			{
				if (c == 0)
					return "knight";

				if (c == 1)
					return "archer";
			}
		}
		else if (start_class == "mostly archer")
		{
			int c = XORRandom(3);
			while (true)
			{
				if (c == 0
				        && (archersCount <= knightsCount || archersCount <= buildersCount))
					return "archer";

				if (c == 1
				        && (knightsCount <= 1))
					return "knight";

				if (c == 2 && !noBuilder
				        && (buildersCount <= 0))
					return "builder";

				c = (c + 1) % 3;
				if (c == 0)
					return "archer";
			}
		}
		else if (start_class == "mostly knight")
		{
			int c = XORRandom(3);
			//	printf("RANDOM CLASS " + c + "    "+ " knightsCount " + knightsCount + " buildersCount " + buildersCount);
			while (true)
			{
				if (c == 0
				        && (knightsCount <= archersCount || knightsCount <= buildersCount))
					return "knight";

				if (c == 1
				        && (archersCount <= 1))
					return "archer";

				if (c == 2 && !noBuilder
				        && (buildersCount <= 0))
					return "builder";

				c = (c + 1) % 3;
				if (c == 0)
					return "knight";
			}
		}
		else if (start_class == "mostly builder")
		{
			int c = XORRandom(3);
			while (true)
			{
				if (c == 0
				        && (buildersCount <= archersCount || buildersCount <= knightsCount))
					return "builder";

				if (c == 1
				        && (archersCount <= 1))
					return "archer";

				if (c == 2
				        && (knightsCount <= 0))
					return "knight";

				c = (c + 1) % 3;
				if (c == 0)
					return "builder";
			}
		}
		return start_class;
	}

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
	{
		if (victim !is null)
		{
			CBlob@ blob = victim.getBlob();
			if (blob !is null)
			{
				f32 deathDistanceToBase = Maths::Abs(war_spawns.getSpawnLocation(blob.getTeamNum()).x - blob.getPosition().x);
				NotifyDeathPosition(victim, blob.getPosition(), deathDistanceToBase);

				int coins = victim.getCoins();
				server_DropCoins(blob.getPosition(), coins * 0.5f);
				victim.server_setCoins(coins * 0.5f); // lose half coins

				// check if necromancer nearby - evil laigh

				CBlob@[] blobs;
				if (getBlobsByName("necromancer", @blobs))
				{
					for (uint step = 0; step < blobs.length; ++step)
					{
						Vec2f npos = blobs[step].getPosition();
						if ((npos - blob.getPosition()).getLength() < 400.0f)
						{
							blobs[step].getSprite().PlayRandomSound("EvilLaughShort");
							break;
						}
					}
				}
			}
		}
	}

	void UpdatePlayerCounts()
	{
		for (uint i = 0; i < teams.length; i++)
		{
			WarTeamInfo@ team = cast < WarTeamInfo@ > (teams[i]);
			//"reset" with migrant count
			team.alive_count = team.migrantCount;
			team.under_raid = false;
		}

		for (uint step = 0; step < players.length; ++step)
		{
			CPlayer@ p = getPlayerByUsername(players[step].username);
			if (p is null) continue;
			CBlob@ player = p.getBlob();
			if (player is null) continue;
			//whew, actually got a blob now..
			if (!player.hasTag("dead"))
			{
				uint teamNum = uint(player.getTeamNum());
				if (teamNum >= 0 && teamNum < teams.length)
				{
					teams[teamNum].alive_count++;
				}
			}
		}

		CBlob@[] rooms;
		getBlobsByName("hall", @rooms);
		for (uint i = 0; i < teams.length; i++)
		{
			WarTeamInfo@ team = cast < WarTeamInfo@ > (teams[i]);

			for (uint roomStep = 0; roomStep < rooms.length; roomStep++)
			{
				CBlob@ room = rooms[roomStep];
				const u8 teamNum = room.getTeamNum();
				if (teamNum == i)
				{
					if (room.hasTag("under raid"))
					{
						team.under_raid = true;
					}
				}
			}
		}

	}

	void NotifyDeathPosition(CPlayer@ player, Vec2f deathPosition, const f32 distance)
	{
		WarPlayerInfo@ info = cast < WarPlayerInfo@ > (getInfoFromPlayer(player));
		if (info is null) { return; }
		info.deathDistanceToBase = distance;
		info.deathPosition = deathPosition;
	}

	bool getPlayerBlobs(CBlob@[]@ playerBlobs)
	{
		for (uint step = 0; step < players.length; ++step)
		{
			CPlayer@ p = getPlayerByUsername(players[step].username);
			if (p is null) continue;

			CBlob@ blob = p.getBlob();
			if (blob !is null)
			{
				playerBlobs.push_back(blob);
			}
		}
		return playerBlobs.size() > 0;
	}


	void UpdateMooks()	// run every second
	{
		CBlob@[] playerBlobs;
		if (getPlayerBlobs(playerBlobs))
		{
			CMap@ map = getMap();
			SpawnMooksOnSight("knight", map, playerBlobs, true);
			SpawnMooksOnSight("archer", map, playerBlobs, true);

			intervalSpawnerCount++;
			if (intervalSpawnerCount % 5 == 0)
			{
				IntervalSpawnMooksOnSight(map, playerBlobs);
			}
		}
	}

	void SpawnMooksOnSight(const string &in classname, CMap@ map, CBlob@[]@ playerBlobs, bool removeSpawn)
	{
		Vec2f[] knightsPos;
		if (map.getMarkers("mook " + classname, knightsPos))
		{
			for (uint i = 0; i < knightsPos.length; i++)
			{
				bool seeHim = false;
				Vec2f spos = knightsPos[i];
				for (uint pbi = 0; pbi < playerBlobs.length; pbi++)
				{
					if ((playerBlobs[pbi].getPosition() - spos).getLength() < MOOK_SPAWN_DISTANCE)
					{
						seeHim = true;
						break;
					}
				}

				if (seeHim)
				{
					if (removeSpawn)
					{
						map.RemoveMarker("mook " + classname, i);
					}
					SpawnMook(spos, classname);
					return;
				}
			}
		}
	}

	void IntervalSpawnMooksOnSight(CMap@ map, CBlob@[]@ playerBlobs)
	{
		Vec2f[] knightsPos;
		if (map.getMarkers("mook spawner", knightsPos))
		{
			for (uint i = 0; i < knightsPos.length; i++)
			{
				Vec2f spos = knightsPos[i];
				for (uint pbi = 0; pbi < playerBlobs.length; pbi++)
				{
					const f32 dist = (playerBlobs[pbi].getPosition() - spos).getLength();
					if (dist < MOOK_SPAWN_DISTANCE
					        && (dist < MOOK_SPAWN_DISTANCE / 2.0f || !map.rayCastSolid(playerBlobs[pbi].getPosition(), spos)))
					{
						map.RemoveMarker("mook spawner", i);
						SpawnMook(spos, "knight");
						return;
					}
				}
			}
		}
	}

	CBlob@ SpawnMook(Vec2f pos, const string &in classname)
	{
		CBlob@ blob = server_CreateBlobNoInit(classname);
		if (blob !is null)
		{
			//setup ready for init
			blob.setSexNum(XORRandom(2));
			blob.server_setTeamNum(1);
			blob.setPosition(pos + Vec2f(4.0f, 0.0f));
			const bool lowPlayerCount = getTeamSize(teams, 0) <= 4;
			if (difficulty >= 15)
			{
				blob.set_s32("difficulty", lowPlayerCount ? 9 + XORRandom(6) : difficulty);
			}
			else
				blob.set_s32("difficulty", difficulty);
			SetMookHead(blob, classname);
			blob.Init();
			blob.SetFacingLeft(XORRandom(2) == 0);
			blob.getBrain().server_SetActive(true);
			blob.server_SetTimeToDie(60 * 6);	 // delete after 6 minutes
			if (lowPlayerCount)
			{
				blob.server_SetHealth(blob.getInitialHealth() * 0.5f);
			}
			GiveAmmo(blob);
		}
		return blob;
	}

	void GiveAmmo(CBlob@ blob)
	{
		if (blob.getName() == "archer")
		{
			CBlob@ mat = server_CreateBlob("mat_arrows");
			if (mat !is null)
			{
				blob.server_PutInInventory(mat);
			}
		}
	}

	void SetMookHead(CBlob@ blob, const string &in classname)
	{
		const bool isKnight = classname == "knight";

		int head = 15;
		int selection = difficulty + XORRandom(3);
		if (selection > 15)
		{
			selection = 15;
			head = 17 + XORRandom(36);
		}
		else
		{
			if (isKnight)
			{
				switch (selection)
				{
					case 0:  head = 37; break;
					case 1:  head = 18; break;
					case 2:  head = 19; break;
					case 3:  head = 42; break;
					case 4:  head = 22; break;
					case 5:  head = 23; break;
					case 6:  head = 16; break;
					case 7:  head = 48; break;
					case 8:  head = 46; break;
					case 9:  head = 45; break;
					case 10: head = 47; break;
					case 11: head = 20; break;
					case 12: head = 21; break;
					case 13: head = 44; break;
					case 14: head = 43; break;
					case 15: head = 36; break;
				}
			}
			else
			{
				switch (selection)
				{
					case 0:  head = 35; break;
					case 1:  head = 51; break;
					case 2:  head = 52; break;
					case 3:  head = 26; break;
					case 4:  head = 22; break;
					case 5:  head = 27; break;
					case 6:  head = 24; break;
					case 7:  head = 49; break;
					case 8:  head = 17; break;
					case 9:  head = 17; break;
					case 10: head = 17; break;
					case 11: head = 33; break;
					case 12: head = 32; break;
					case 13: head = 34; break;
					case 14: head = 25; break;
					case 15: head = 36; break;
				}
			}
		}

		head += 16; //reserved heads changed

		blob.setHeadNum(head);
	}
};

//pass stuff to the core from each of the hooks

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	printf("Restarting rules script: " + getCurrentScriptName());
	ChallengeSpawns spawns();
	ChallengeCore core(true); //delayed setup
	Config(core);
	core.Setup(this, spawns);
	this.set("core", @core);

	this.set_bool("singleplayer", true);
	this.SetGlobalMessage("");
}

void onBlobChangeTeam(CRules@ this, CBlob@ blob, const int oldTeam)
{
	if (blob.getName() == "hall" && oldTeam <= 2)
	{
		// check if any halls remain
		int teamHalls = 0;
		CBlob@[] rooms;
		getBlobsByName("hall", @rooms);
		for (uint roomStep = 0; roomStep < rooms.length; roomStep++)
		{
			CBlob@ room = rooms[roomStep];
			const u8 teamNum = room.getTeamNum();
			if (teamNum == oldTeam)
			{
				teamHalls++;
			}
		}

		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			ChallengeCore@ mycore = cast < ChallengeCore@ > (core);
			mycore.teams[oldTeam].lost = teamHalls == 0;

			// delete any spawners nearb
			Vec2f hallPos = blob.getPosition();
			DeleteSpawnersAtPos("mook spawner", hallPos, blob.getRadius() * 2.0f);
		}
	}
}

void DeleteSpawnersAtPos(const string &in name, Vec2f pos, const f32 radius)
{
	Vec2f[] knightsPos;
	CMap@ map = getMap();
	if (map.getMarkers(name, knightsPos))
	{
		for (uint i = 0; i < knightsPos.length; i++)
		{
			Vec2f spos = knightsPos[i];
			if ((pos - spos).getLength() < radius)
			{
				map.RemoveMarker(name, i);
				DeleteSpawnersAtPos(name, pos, radius);
				return;
			}
		}
	}
}

// TRADING

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	const string name = blob.getName();
	if (name == "tradingpost")
	{
		MakeTradeMenu(blob);
	}
	else if (name == "hall")
	{
		blob.RemoveScript("TunnelTravel.as");
		blob.RemoveScript("PickupIntoStorage.as");
		blob.RemoveScript("Researching.as");
		blob.Untag("change class store inventory");
		blob.Tag("change class drop inventory");
		blob.Tag("script added"); // so it wont add Researching.as on change team
	}
	else if (name == "catapult")
	{
		blob.RemoveScript("DecayInWater.as");
		blob.RemoveScript("DecayIfLowHealth.as");
		blob.RemoveScript("DecayIfFlipped.as");
		blob.RemoveScript("DecayIfLeftAlone.as");
	}

	if (blob.hasTag("material"))
	{
		blob.RemoveScript("DecayQuantity.as");
	}
}

TradeItem@ addItemForCoin(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description)
{
	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	if (item !is null && cost > 0)
	{
		AddRequirement(item.reqs, "coin", "", "Coins", cost);
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeTradeMenu(CBlob@ trader)
{
	// build menu
	CreateTradeMenu(trader, Vec2f(3, 6), "Buy weapons");

	//
	addTradeSeparatorItem(trader, "$MENU_GENERIC$", Vec2f(3, 1));
	addItemForCoin(trader, "Bomb", 10, true, "$mat_bombs$", "mat_bombs", Descriptions::bomb);
	addItemForCoin(trader, "Water Bomb", 10, true, "$mat_waterbombs$", "mat_waterbombs", Descriptions::waterbomb);
	addItemForCoin(trader, "Keg", 50, true, "$keg$", "keg", Descriptions::keg);
	addItemForCoin(trader, "Arrows", 5, true, "$mat_arrows$", "mat_arrows", Descriptions::arrows);
	addItemForCoin(trader, "Water Arrows", 10, true, "$mat_waterarrows$", "mat_waterarrows", Descriptions::waterarrows);
	addItemForCoin(trader, "Fire Arrows", 15, true, "$mat_firearrows$", "mat_firearrows", Descriptions::firearrows);
	addItemForCoin(trader, "Bomb Arrow", 10, true, "$mat_bombarrows$", "mat_bombarrows", Descriptions::bombarrows);
	addItemForCoin(trader, "Mine", 25, true, "$mine$", "mine", Descriptions::mine);
	addItemForCoin(trader, "Mounted Bow", 80, true, "$mounted_bow$", "mounted_bow", Descriptions::mounted_bow);
	addItemForCoin(trader, "Drill", 30, true, "$drill$", "drill", Descriptions::drill);
	addItemForCoin(trader, "Boulder", 5, true, "$boulder$", "boulder", Descriptions::boulder);
	addItemForCoin(trader, "Burger", 10, true, "$food$", "food", Descriptions::food);
	//addItemForCoin( trader, "Balloon Bomber", 100, true, "$bomber$", "bomber", "An airship." );
	//addItemForCoin( trader, "Catapult", 80, true, "$catapult$", "catapult", Descriptions::catapult );
	//addItemForCoin( trader, "Ballista", 80, true, "$ballista$", "ballista", Descriptions::ballista );
}

// add coins for red dead

// f32 onPlayerTakeDamage( CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale )

void onBlobDie(CRules@ this, CBlob@ blob)
{
	const string name = blob.getName();
	if (blob.getTeamNum() == 1 && (name == "archer" || name == "knight") && !blob.hasTag("dropped coins"))
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			ChallengeCore@ ccore = cast < ChallengeCore@ > (core);
			Vec2f pos = blob.getPosition();

			// drop coins

			if (this.exists("drop coins"))
			{
				server_DropCoins(pos, XORRandom(5) * ((ccore.difficulty + 1) / 2.0f));
				// random bomb
				if (XORRandom(4) == 0)
				{
					server_CreateBlob("mat_bombs", -1, pos);
				}
			}
			blob.Tag("dropped coins");

			// increase difficulty at each death

			if (pos.x - ccore.lastDifficultyIncPos > DIFFICULTY_INCREASE_DISTANCE)
			{
				ccore.difficulty++;
				if (ccore.difficulty > MAX_DIFFICULTY)
				{
					ccore.difficulty = MAX_DIFFICULTY;
				}

				ccore.lastDifficultyIncPos = pos.x;
			}

			// make sure interval spawner spawns next second
			ccore.intervalSpawnerCount = -1;

			// add kills/scores

			CPlayer@ killer = blob.getPlayerOfRecentDamage();
			if (killer !is null)
			{
				killer.setKills(killer.getKills() + 1);
				// temporary until we have a proper score system
				killer.setScore(100 * (f32(killer.getKills()) / f32(killer.getDeaths() + 1)));
			}
		}
	}

	// open all doors
	if (name == "necromancer")
	{
		CBlob@[] doors;
		if (getBlobsByTag("door", @doors))
		{
			for (uint i = 0; i < doors.length; i++)
			{
				CBlob@ door = doors[i];
				if (door.getTeamNum() != 0)
				{
					door.getSprite().Gib();
					door.server_Die();
				}
			}
		}

		CBlob@ playerBlob = getLocalPlayerBlob();
		if (playerBlob !is null)
		{
			Sound::Play("/EvilLaugh.ogg", (playerBlob.getPosition() + blob.getPosition()) / 2.0f);
		}
		else
		{
			Sound::Play("/EvilLaugh.ogg");
		}

		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			ChallengeCore@ ccore = cast < ChallengeCore@ > (core);
			ccore.necromancerWinCounter = 90;
		}
	}

	if (this.get_bool("repeat if dead") && !this.isGameOver() && blob.getPlayer() !is null)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			ChallengeCore@ ccore = cast < ChallengeCore@ > (core);

			ccore.UpdatePlayerCounts();

			WarTeamInfo@ team = cast < WarTeamInfo@ > (ccore.teams[0]);
			if (team.alive_count == 0)
			{
				this.SetTeamWon(1);
				this.SetCurrentState(GAME_OVER);
				this.SetGlobalMessage("Round lost!");
				sv_mapautocycle = !ccore.repeat_map_if_lost;
				//	print("sv_mapautocycle " + sv_mapautocycle );
			}
		}
	}
}


//
void MakeMaterial(CBlob@ blob,  const string &in name, const int quantity)
{
	CBlob@ mat = server_CreateBlobNoInit(name);

	if (mat !is null)
	{
		mat.Tag('custom quantity');
		mat.Init();

		mat.server_SetQuantity(quantity);

		if (not blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob !is null && player !is null)
	{
		const string name = blob.getName();

		RulesCore@ core;
		this.get("core", @core);
		if (core !is null)
		{
			ChallengeCore@ ccore = cast < ChallengeCore@ > (core);
			if (name == "archer")
			{
				MakeMaterial(blob, "mat_arrows", 30);
			}
			else if (name == "knight")
			{
				MakeMaterial(blob, "mat_bombs", ccore.bombsOnSpawn);
			}
			else if (name == "builder")
			{
				MakeMaterial(blob, "mat_wood", ccore.woodOnSpawn);
			}
		}
	}
}
