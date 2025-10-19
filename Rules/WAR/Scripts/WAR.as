
//war gamemode logic script

#define SERVER_ONLY

#include "WAR_Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"
#include "WAR_PopulateSpawnList.as"
#include "MakeCrate.as"
#include "ScrollCommon.as"
#include "WAR_HUDCommon.as"
#include "TradingCommon.as"
#include "Descriptions.as"
#include "MigrantCommon.as"
#include "WAR_Population.as"
#include "Costs.as"

//simple config function - edit the variables in the config file
void Config(WarCore@ this)
{
	string configstr = sv_test ? "Rules/WAR/war_vars_test.cfg" : "Rules/WAR/war_vars.cfg";
	if (this.rules.exists("warconfig"))
	{
		configstr = this.rules.get_string("warconfig");
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
		this.rules.set_bool("no timer", true);
	}
	else
	{
		this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes);
	}
	//how many players have to be in for the game to start
	this.minimum_players_in_team = cfg.read_s32("minimum_players_in_team", 2);
	//whether to scramble each game or not
	this.scramble_teams = cfg.read_bool("scramble_teams", true);

	this.shipmentFirstTime = getTicksASecond() * 60 * cfg.read_s32("shipment_first_time", 15);
	this.shipmentFrequency = getTicksASecond() * 60 * cfg.read_s32("shipment_frequency", 3);

	//how far away counts as raiding?
	f32 raid_percent = cfg.read_f32("raid_percent", 30) / 100.0f;

	CMap@ map = getMap();
	if (map is null)
		this.raid_distance = raid_percent * 2048.0f; //presume 256 tile map
	else
		this.raid_distance = raid_percent * map.tilemapwidth * map.tilesize;

	//spawn after death time
	this.defaultSpawnTime = this.spawnTime = (getTicksASecond() * cfg.read_s32("spawn_time", 15));
}


// without "shared" we cannot hot-swap this class :(
// with "shared" we needt o use other function that are "shared" too

shared class WarSpawns : RespawnSystem
{
	WarCore@ war_core;

	WarPlayerInfo@[] spawns;

	bool force;
	s32 nextSpawn;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@war_core = cast < WarCore@ > (core);

		nextSpawn = getGameTime();

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

			getRules().set_u8("team 0 count", getTeamSize(war_core.teams, 0));
			getRules().set_u8("team 1 count", getTeamSize(war_core.teams, 1));
		}

		if (time > nextSpawn)
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
					//	print("spawn for "+info.username+" , waves to go: "+info.wave_delay);
					DoSpawnPlayer(info);   //check if we should spawn them
				}
				delta = spawns.length - len;
			}

			nextSpawn = getGameTime() + getTimeMultipliedByPlayerCount(war_core.spawnTime);
		}
	}

	void updatePlayerSpawnTime(WarPlayerInfo@ w_info)
	{
		WarTeamInfo@ team = cast < WarTeamInfo@ > (core.getTeam(w_info.team));
		//sync player time to them directly
		string propname = "time to spawn " + w_info.username;
		const s32 time = w_info.wave_delay <= 2 ? getSpawnTime(team, w_info) : -10000;     // no spawns?
		war_core.rules.set_s32(propname, time);
		war_core.rules.SyncToPlayer(propname, getPlayerByUsername(w_info.username));
		propname = "needs respawn hud " + w_info.username;
		war_core.rules.set_bool(propname, (time < -1000 || time > s32(getGameTime())));
		war_core.rules.SyncToPlayer(propname, getPlayerByUsername(w_info.username));
	}

	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (p_info);

		if (canSpawnPlayer(p_info))
		{
			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?
			if (player is null)
			{
				return;
			}
			RemovePlayerFromSpawn(player);

			// force blue on tutorials
			if (getRules().hasTag("singleplayer"))
			{
				p_info.team = 0;
			}

			CBlob@ spawnBlob;
			CBlob@ playerBlob;
			{
				@spawnBlob = getSpawnBlobs(p_info);
				if (spawnBlob !is null)
				{
					if (spawnBlob.hasTag("migrant"))   // kill the migrant
					{
						spawnBlob.server_Die();
					}
					@playerBlob = SpawnPlayerIntoWorld(spawnBlob.getPosition(), p_info);

					if (playerBlob !is null && spawnBlob.hasTag("bed"))  // send "respawn" cmd
					{
						CBitStream params;
						params.write_netid(playerBlob.getNetworkID());
						spawnBlob.SendCommand(spawnBlob.getCommandID("respawn"), params);
					}
				}
				else if (!war_core.rules.isMatchRunning())
				{
					// create new builder at edge
					if (p_info.team < war_core.teams.length)
					{
						p_info.blob_name = sv_test ? "archer" : "knight"; // force knight
						WarTeamInfo@ team = cast < WarTeamInfo@ > (core.getTeam(p_info.team));
						if (team.bedsCount > 0 || !team.under_raid)
						{
							@playerBlob = SpawnPlayerIntoWorld(getSpawnLocation(p_info.team), p_info);
						}
					}
				}
			}

			if (playerBlob !is null)
			{
				//hud
				string propname = "needs respawn hud " + p_info.username;
				war_core.rules.set_bool(propname, false);
				war_core.rules.SyncToPlayer(propname, getPlayerByUsername(p_info.username));

				p_info.spawnsCount++;
			}
			else // search for spawn again
			{
				AddPlayerToSpawn(player);
			}

		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		if (force) { return true; }
		WarPlayerInfo@ w_info = cast < WarPlayerInfo@ > (p_info);
		return (w_info.wave_delay == 0);
	}

	s32 getSpawnTime(WarTeamInfo@ team, WarPlayerInfo@ w_info)
	{
		return nextSpawn + ((w_info.wave_delay - 1) * getTimeMultipliedByPlayerCount(war_core.spawnTime));
	}

	Vec2f getSpawnLocation(int team)
	{
		CMap@ map = getMap();
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

	s32 getTimeMultipliedByPlayerCount(s32 time)
	{
		// change spawn time according to player count
		if (war_core.players.length < 6)
		{
			time *= 0.33f;
		}
		else if (war_core.players.length < 9)
		{
			time *= 0.5f;
		}
		else if (war_core.players.length < 13)
		{
			time *= 0.75f;
		}
		else if (war_core.players.length > 16)
		{
			time *= 1.2f;
		}
		else if (war_core.players.length > 22)
		{
			time *= 1.5f;
		}
		else if (war_core.players.length > 27)
		{
			time *= 1.75f;
		}
		return time;
	}

	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		WarPlayerInfo@ info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(player));
		if (info is null) { warn("WAR LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(CPlayer@ player) )"); return; }

		int pos = spawns.find(info);
		if (pos != -1)
		{
			spawns.erase(pos);
		}
	}

	void AddPlayerToSpawn(CPlayer@ player)
	{
		WarPlayerInfo@ info = cast < WarPlayerInfo@ > (core.getInfoFromPlayer(player));

		if (info is null) { warn("WAR LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

		u32 current_delay = info.wave_delay;

		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		if (current_delay == 0 || current_delay > 3)
		{
			//default to next wave spawn (not this wave spawn)
			info.wave_delay = 1;

			if (nextSpawn - getGameTime() <= war_core.spawnTime / 2)
				info.wave_delay += 1;
		}
		else
		{
			info.wave_delay = current_delay;
		}

		CBlob@ spawnBlob = getSpawnBlobs(info, true);
		if (spawnBlob !is null)
		{
			if (spawnBlob.hasTag("under raid"))
			{
				info.wave_delay += 1;
			}
			if (isHallDepleted(spawnBlob))
			{
				info.wave_delay += 1;
			}
		}

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

		u16 spawnpoint = w_info.spawnpoint;

		// pick closest to death position
		if (spawnpoint > 0)
		{
			CBlob@ pickSpawn = getBlobByNetworkID(spawnpoint);
			if (pickSpawn !is null
					&& (takeUnderRaid || !pickSpawn.hasTag("under raid"))
					&& pickSpawn.getTeamNum() == w_info.team
			   )
			{
				return pickSpawn;
			}
			else
			{
				spawnpoint = 0; // can't pick this -> auto-pick
			}
		}

		// auto-pick closest
		if (spawnpoint == 0)
		{
			// get "respawn" bases
			PopulateSpawnList(@available, w_info.team, takeUnderRaid);

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

shared class WarCore : RulesCore
{
	string base_name = "war_base";

	s32 warmUpTime;
	s32 gameDuration;
	s32 spawnTime;
	s32 defaultSpawnTime;
	s32 minimum_players_in_team;
	bool scramble_teams;
	s32 shipmentFirstTime;
	s32 shipmentFrequency;
	f32 alivePercent;
	s32 startingMigrants;
	bool missingHalls;
	int lastHall;

	f32 raid_distance;

	WarSpawns@ war_spawns;

	WarCore() {}

	WarCore(CRules@ _rules, RespawnSystem@ _respawns)
	{
		super(_rules, _respawns);
	}

	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		gametime = getGameTime();
		startTime = 0;
		for (uint i = 0; i < teams.length; i++)
		{
			nextShipmentTime.push_back(0);
		}
		@war_spawns = cast < WarSpawns@ > (_respawns);
		rules.SetCurrentState(WARMUP);
		server_CreateBlob("Entities/Meta/WARMusic.cfg");
		missingHalls = true;

		if(_rules.get_bool("tutorial"))
		{
			lastHall = 0;
			CBlob@[] halls;
			getBlobsByName("hall", @halls);
			for(int i=0;i<halls.length;i++)
			{
				if(halls[i].getPosition().x>=halls[lastHall].getPosition().x)
				{
					lastHall=i;
				}
			}
			halls[lastHall].server_setTeamNum(1);

		}
	}

	int gametime;
	int startTime;
	int[] nextShipmentTime; // for every team

	void Update()
	{
		//HUD
		if (getGameTime() % 31 == 0)
		{
			updateHUD();
		}

		//don't update any more if the game has finished
		if (rules.isGameOver()) { return; }

		const u32 time = getGameTime();
		const bool havePlayers = allTeamsHavePlayers();

		const int tick_freq = 35;
		const bool should_tick = ((time % 35) == 0);

		const bool is_build_time = (rules.isIntermission() || rules.isWarmup());

		if (should_tick)
		{
			updateMigrants(time % (10 * tick_freq) == 0);
			UpdatePlayerCounts();
			UpdatePopulationCounter();
			UpdateTeamsLost();
			missingHalls = (GetTeamWon() == -2);
		}

		//manage build time
		if (is_build_time)
		{
			//hold the start of the countdown if needed
			bool can_start = !missingHalls && havePlayers;
			if (!can_start)
			{
				//figure out the most helpful message
				string start_message = "";
				if(!havePlayers)
				{
					start_message = "Not enough players in each team for the game to start.\nPlease wait for someone to join...";
				}
				else if(missingHalls)
				{
					start_message = "Waiting for a hall capture before starting the game...";
				}
				//update the start time
				gametime = time + warmUpTime;
				rules.set_u32("game_end_time", time + gameDuration);
				rules.SetGlobalMessage(start_message);
				war_spawns.force = true;
			}
			//otherwise, update match start time
			else
			{
				s32 ticksToStart = gametime - time;
				war_spawns.force = false;
				//ready to go!
				if (ticksToStart <= 0)
				{
					rules.SetGlobalMessage("");
					rules.SetCurrentState(GAME);
				}
				//otherwise, is the start of the game, spawn everyone + give mats
				else
				{
					rules.SetGlobalMessage("Match starts in {SEC}");
					rules.AddGlobalMessageReplacement("SEC", "" + ((ticksToStart / 30) + 1));
					war_spawns.force = true;
				}
			}
		}
		else
		{
			if (should_tick)
			{
				//needs to be updated before the teamwon
				//check if the team won
				CheckTeamWon();
			}
		}

		//handle shipments
		if (havePlayers && should_tick)
		{
			if (startTime == 0)
			{
				startTime = time;
			}
			updateShipments();
		}


		RulesCore::Update(); //update respawns
	}

	void updateHUD()
	{
		CBitStream serialised_team_hud;
		serialised_team_hud.write_u16(0x54f3);

		WAR_HUD hud;

		WarTeamInfo@[] temp_teams;
		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			WarTeamInfo@ team = cast < WarTeamInfo@ > (teams[team_num]);

			if (team !is null)
			{
				temp_teams.push_back(team);
			}
		}

		CBlob@[] halls;
		getBlobsByName("hall", @halls);

		hud.Generate(temp_teams, halls);

		hud.Serialise(serialised_team_hud);

		rules.set_CBitStream("WAR_serialised_team_hud", serialised_team_hud);
		rules.Sync("WAR_serialised_team_hud", true);
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
		WarTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
	{
		WarPlayerInfo p(player.getUsername(), player.getTeamNum(), "knight");
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
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

	//figure out if any teams lost
	void UpdateTeamsLost()
	{
		//(don't update if game is over; prevents halls changing after the game is decided from mattering)
		if(rules.isGameOver()) return;

		bool[] has_hall(teams.length, false);

		//mask out teams that have halls
		CBlob@[] halls;
		getBlobsByName("hall", @halls);
		for (uint i = 0; i < halls.length; ++i)
		{
			CBlob@ hall = halls[i];
			const u8 team = hall.getTeamNum();

			if (team < has_hall.length)
			{
				has_hall[team] = true;
			}
		}

		//set lost flag on all teams without halls
		for (uint i = 0; i < has_hall.length; ++i)
		{
			teams[i].lost = !(has_hall[i]);
		}
	}

	//checks

	//check the "win" state
	// >= 0 this team won
	// -1   game still in progress
	// -2   noone captured anything
	int GetTeamWon()
	{
		//count how many teams lost + note team(s) that aren't losing
		int not_lost = -1;
		int lostCount = 0;
		for (uint i = 0; i < teams.length; i++)
		{
			if (teams[i].lost)
			{
				lostCount++;
			}
			else
			{
				not_lost = i;
			}
		}

		//only one team left? return it
		if (lostCount == (teams.length - 1) && not_lost != -1)
		{
			return not_lost;
		}

		// tie condition
		return (lostCount == teams.length) ?
			// no halls taken on any side
			-2:
			// or still have halls
			-1;
	}

	// check if anybody won, and set the global state/message if they did
	void CheckTeamWon()
	{
		// can't lose/modify state if the match is not running
		if (!rules.isMatchRunning()) { return; }
		if(rules.get_bool("tutorial"))
		{
			CBlob@[] halls;
			getBlobsByName("hall", @halls);
			if(halls[lastHall] !is null && halls[lastHall].getTeamNum()==1)
			{
				return;
			}
		}

		int team_won = GetTeamWon();
		if(team_won >= 0 && team_won < teams.length)
		{
			BaseTeamInfo@ team = teams[team_won];
			rules.SetTeamWon(team_won);
			rules.SetCurrentState(GAME_OVER);
		}
	}

	//update the crate resource shipments
	void updateShipments()
	{
		if (startTime > 0)
		{
			const s32 time = getGameTime();
			const bool warmup = rules.isWarmup();

			// gather storages
			CBlob@[] bases;
			CBlob@[] available;
			getBlobsByName("hall", @bases);

			for (uint i = 0; i < teams.length; i++)
			{
				// ship?
				if ((nextShipmentTime[i] == 0 && time >= startTime + shipmentFirstTime) ||
					(nextShipmentTime[i] > 0  && time >= nextShipmentTime[i]))
				{
					available.clear();

					for (uint step = 0; step < bases.length; ++step)
					{
						CBlob@ base = bases[step];
						if (uint(base.getTeamNum()) == i)
						{
							available.push_back(base);
						}
					}

					for (uint step = 0; step < available.length; ++step)
					{
						CBlob@ base = available[ step ];


						// check if doesnt have lots of mats or shipment crates
						bool needsMats = true;
						int baseWood = base.getBlobCount("mat_wood");
						if (!warmup)
						{
							CBlob@[] blobsInRadius;
							if (getMap().getBlobsInRadius(base.getPosition(), base.getRadius() * 3.0f, @blobsInRadius))
							{
								for (uint i = 0; i < blobsInRadius.length; i++)
								{
									CBlob @b = blobsInRadius[i];
									//crate nearby
									if (b.hasTag("unpackall"))
									{
										needsMats = false;
										break;
									}
									//count wood
									else if (b.getName() == "mat_wood")
									{
										baseWood += b.getQuantity();
									}
								}
							}

							if (baseWood > 1000)
							{
								needsMats = false;
							}
						}

						if (needsMats)
						{
							CBitStream params;
							base.SendCommand(base.getCommandID("shipment"), params);

							// spawn crate
							Vec2f droppos = base.getPosition();
							droppos.x += (base.getTeamNum() == 0) ? -45.0f : 45.0f;
							CBlob@ crate = server_MakeCrateOnParachute("", "", 5, base.getTeamNum(), getDropPosition(droppos));
							if (crate !is null)
							{
								// make unpack button
								crate.Tag("unpackall");
								//crate.Tag("destroy on touch");
								for (uint i = 0; i < 2; i++)
								{
									CBlob@ mat = server_CreateBlob("mat_wood");
									if (mat !is null)
									{
										crate.server_PutInInventory(mat);
									}
								}
								if (warmup)
								{
									for (uint i = 0; i < 1; i++)
									{
										CBlob@ mat = server_CreateBlob("mat_stone");
										if (mat !is null)
										{
											crate.server_PutInInventory(mat);
										}
									}
								}
							}
						}

						int freq = war_spawns.getTimeMultipliedByPlayerCount(shipmentFrequency);
						if (warmup) {
							freq = shipmentFrequency * 0.1f;
						}
						nextShipmentTime[i] = time + freq;
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

	void updateMigrants(bool spawn)
	{
		for (uint i = 0; i < teams.length; i++)
		{
			WarTeamInfo@ team = cast < WarTeamInfo@ > (teams[i]);
			team.migrantsInDormCount = getMigrantsInDormCount(i);
			team.migrantCount = getMigrantsCount(i);
			team.bedsCount = getBedsCount(i);
		}
	}

	CBlob@ SpawnMigrant(const int teamNum)
	{
		Vec2f pos = war_spawns.getSpawnLocation(teamNum);
		return CreateMigant(pos, teamNum);
	}

	int getBedsCount(const int teamNum)
	{
		int count = 0;
		CBlob@[] rooms;
		getBlobsByTag("migrant room", @rooms);
		for (uint i = 0; i < rooms.length; i++)
		{
			CBlob@ room = rooms[i];
			if (room.getTeamNum() == teamNum)
			{
				count += room.get_u8("migrants max");
			}
		}
		return count;
	}

	int getMigrantsCount(const int teamNum)
	{
		int count = 0;
		CBlob@[] migrants;
		getBlobsByTag("migrant", @migrants);
		for (uint i = 0; i < migrants.length; i++)
		{
			CBlob@ migrant = migrants[i];
			if (migrant.getTeamNum() == teamNum && !migrant.hasTag("dead"))
			{
				count++;
			}
		}

		return count;
	}

	int getMigrantsInDormCount(const int teamNum)
	{
		int count = 0;

		// rooms with migrants

		CBlob@[] rooms;
		getBlobsByTag("migrant room", @rooms);
		for (uint i = 0; i < rooms.length; i++)
		{
			CBlob@ room = rooms[i];
			if (room.getTeamNum() == teamNum)
			{
				count += room.get_u8("migrants count");
			}
		}

		return count;
	}

	//////////////////////////////////////////////////////////////////////////

	void UpdatePopulationCounter()
	{
		for (uint teamNum = 0; teamNum < teams.length; teamNum++)
		{
			WarTeamInfo@ team = cast < WarTeamInfo@ > (teams[ teamNum ]);
			setPopulation(teamNum, team.migrantCount + team.migrantsInDormCount);
		}
	}
};

//pass stuff to the core from each of the hooks

void Reset(CRules@ this)
{
	InitCosts();

	printf("Restarting rules script: " + getCurrentScriptName());
	WarSpawns spawns();
	WarCore core(this, spawns);
	Config(core);
	this.set("core", @core);

	core.gametime = getGameTime() + core.warmUpTime;

	this.set("start_gametime", core.gametime);//is this legacy?

	this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as

	// place no build zones at sides
	CMap@ map = getMap();
	f32 space = map.tilesize * 5.0f;
	map.server_AddSector(Vec2f(0.0f, 0.0f), Vec2f(space, map.tilemapheight * map.tilesize), "no build");
	map.server_AddSector(Vec2f(map.tilemapwidth * map.tilesize - space, 0.0f), Vec2f(map.tilemapwidth * map.tilesize, map.tilemapheight * map.tilesize), "no build");

	//

	for (uint i = 0; i < core.teams.length; i++)
	{
		setPopulation(i, 0);
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
	const int restart_after = (!this.hasTag("tutorial") ? 30 : 5) * 30;
	this.set_s32("restart_rules_after_game_time", restart_after);

	getNet().legacy_cmd = true;
}

void DoUpdateTeamsLost()
{
	CRules@ this = getRules();

	WarCore@ core;
	this.get("core", @core);
	if (core is null) return;

	core.UpdateTeamsLost();
}

void onStateChange(CRules@ this, const u8 oldState)
{
	if (this.getCurrentState() == GAME)
	{
		DoUpdateTeamsLost();
	}
}

void onBlobChangeTeam(CRules@ this, CBlob@ blob, const int oldTeam)
{
	if (blob.getName() == "hall" && oldTeam < 2)
	{
		DoUpdateTeamsLost();
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "hall")
	{
		DoUpdateTeamsLost();
	}
}

// TRADING

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "tradingpost")
	{
		MakeWarTradeMenu(blob);
	}
	else if (blob.getName() == "mat_gold")
	{
		blob.RemoveScript("DecayQuantity.as");
	}
}

TradeItem@ addGoldForItem(CBlob@ this, const string &in name,
						  int cost, const string &in cost_mat, const string &in cost_mat_description,
						  const bool instantShipping,
						  const string &in iconName,
						  const string &in configFilename,
						  const string &in description)
{
	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	if (item !is null && cost > 0)
	{
		AddRequirement(item.reqs, "blob", cost_mat, cost_mat_description, cost);
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeWarTradeMenu(CBlob@ trader)
{
	InitCosts();

	// build menu
	CreateTradeMenu(trader, Vec2f(3, 11), "Trade");

	//econ techs
//	addTradeSeparatorItem( trader, "$MENU_INDUSTRY$", Vec2f(3,1) );
//	addTradeScrollFromScrollDef(trader, "saw", cost_crappiest, Descriptions::saw);
	//addTradeEmptyItem(trader);

	//siege techs
	addTradeSeparatorItem(trader, "$MENU_SIEGE$", Vec2f(3, 1));
	addTradeScrollFromScrollDef(trader, "mounted bow", WARCosts::medium_scroll, Descriptions::mounted_bow);
	addTradeScrollFromScrollDef(trader, "ballista", WARCosts::medium_scroll, Descriptions::ballista);
	addTradeScrollFromScrollDef(trader, "catapult", WARCosts::big_scroll, Descriptions::catapult);

	//boats
	addTradeSeparatorItem(trader, "$MENU_NAVAL$", Vec2f(3, 1));
	addTradeScrollFromScrollDef(trader, "longboat", WARCosts::medium_scroll, Descriptions::longboat);
	addTradeScrollFromScrollDef(trader, "warboat", WARCosts::big_scroll, Descriptions::warboat);
	addTradeEmptyItem(trader);

	//item kits
	addTradeSeparatorItem(trader, "$MENU_KITS$", Vec2f(3, 1));
	//addTradeScrollFromScrollDef(trader, "military basics", cost_crappy, Descriptions::militarybasics);
	addTradeScrollFromScrollDef(trader, "water ammo", WARCosts::crappy_scroll, Descriptions::waterarrows);
	addTradeScrollFromScrollDef(trader, "bomb ammo", WARCosts::big_scroll, Descriptions::bombarrows);
	addTradeScrollFromScrollDef(trader, "pyro", WARCosts::big_scroll, Descriptions::pyro);
	addTradeScrollFromScrollDef(trader, "drill", WARCosts::crappiest_scroll, Descriptions::drill);
	addTradeScrollFromScrollDef(trader, "saw", WARCosts::crappiest_scroll, Descriptions::saw);
	addTradeScrollFromScrollDef(trader, "explosives", WARCosts::big_scroll, Descriptions::explosives);

	//magic scrolls
	addTradeSeparatorItem(trader, "$MENU_MAGIC$", Vec2f(3, 1));
	addTradeScrollFromScrollDef(trader, "carnage", 400, Descriptions::scroll_carnage);
	addTradeScrollFromScrollDef(trader, "drought", 120, Descriptions::scroll_drought);
	addTradeEmptyItem(trader);

	//material exchange
	addTradeSeparatorItem(trader, "$MENU_MATERIAL$", Vec2f(3, 1));

	f32 wood_sell_price = 5.0f;
	f32 wood_buy_price = 4.0f;

	f32 stone_sell_price = 2.5f;
	f32 stone_buy_price = 2.0f;

	s32 wood_stack_price = s32(500 / wood_sell_price);
	s32 gold_wood_price = s32(500 * wood_buy_price);

	s32 stone_stack_price = s32(500.0f / stone_sell_price);
	s32 gold_stone_price = s32(500.0f * stone_buy_price);

	addTradeItem(trader, "Wood", wood_stack_price, true,						"$mat_wood$", "mat_wood", "Exchange " + wood_stack_price + " Gold for 500 Wood");
	addTradeItem(trader, "Stone", stone_stack_price, true,						"$mat_stone$", "mat_stone", "Exchange " + stone_stack_price + " Gold for 500 Stone");
	//addTradeEmptyItem( trader );
	//addGoldForItem( trader, "Gold", gold_wood_price, "mat_wood", "Wood", true, 	"$mat_gold$", "mat_gold", "Exchange "+gold_wood_price+" Wood for 250 Gold" );
	//addGoldForItem( trader, "Gold", gold_stone_price, "mat_stone", "Stone", true, "$mat_gold$", "mat_gold", "Exchange "+gold_stone_price+" Stone for 250 Gold" );

	//individual items
	//addTradeSeparatorItem( trader, "$MENU_OTHER$", Vec2f(3,1) );
	//addTradeScrollFromScrollDef(trader, "boulder", cost_crappy, Descriptions::boulder);
	//addTradeEmptyItem(trader);
	//addTradeEmptyItem(trader);

	//individual items
	//addTradeSeparatorItem( trader, "$MENU_TECHS$", Vec2f(3,1) );
	//addTradeScrollFromScrollDef(trader, "stone", cost_crappy, Descriptions::stonetech);
}
