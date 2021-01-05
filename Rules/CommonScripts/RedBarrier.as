////  VARS  ////

// Server owners should edit the value inside RedBarrierVars.cfg
f32 BARRIER_PERCENT = 0.175;
f32 VEL_PUSHBACK = 1.35;

// Var to know if the barrier is currently up 
// (used for clearing the barrier once when its game time)
bool SERVER_BARRIER_SET = false; 

// Gets toggled to true when we know the 
// config has different values
bool SYNC_CUSTOM_VARS = false;

////  HOOKS  ////

void onInit(CRules@ this)
{
	this.addCommandID("set_barrier_pos");
	this.addCommandID("set_barrier_vars");

	onRestart(this);
}

void onRestart(CRules@ this)
{
	if (!isServer())
		return;

	LoadConfigVars();

	SetBarrierPosition(this);

	int playerCount = getPlayerCount();
	for (int a = 0; a < playerCount; a++)
	{
		CPlayer@ player = getPlayer(a);

		if (player is null)
			continue;

		SyncToPlayer(this, player);

		if (SYNC_CUSTOM_VARS)
			SyncVarsToPlayer(this, player);
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!isServer() && !shouldBarrier(this))
		return;

	SyncToPlayer(this, player);

	if (SYNC_CUSTOM_VARS)
		SyncVarsToPlayer(this, player);
}

void onTick(CRules@ this)
{
	if (!shouldBarrier(this))
	{
		if (SERVER_BARRIER_SET)
			RemoveBarrier(this);

		return;
	}

	CMap@ map = getMap();
	
	CMap::Sector@ sector = map.getSector("barrier");
	if (sector is null)
		return;

	u16 x1 = this.get_u16("barrier_x1");
	u16 x2 = this.get_u16("barrier_x2");
	u16 middle =  (x1 + x2) * 0.5f;

	CBlob@[] blobsInBox;
	if (map.getBlobsInSector(sector, @blobsInBox))
	{
		for (uint i = 0; i < blobsInBox.length; i++)
		{
			CBlob @b = blobsInBox[i];

			if (!b.getShape().isStatic() && 
				(b.getTeamNum() < 100 || b.hasTag("no barrier pass") || 
				 b.hasTag("material") || b.getName() == "spikes"))
			{
				PushBlob(b, middle);
			}
		}
	}
}

void onRender(CRules@ this)
{
	if (!shouldBarrier(this))
		return;

	u16 x1 = this.get_u16("barrier_x1");
	u16 x2 = this.get_u16("barrier_x2");

	Driver@ driver = getDriver();
	Vec2f left  = driver.getScreenPosFromWorldPos(Vec2f(x1, 0));
	Vec2f right = driver.getScreenPosFromWorldPos(Vec2f(x2, 0));

	left.y = 0;
	right.y = driver.getScreenHeight();

	GUI::DrawRectangle(
		left,
		right,
		SColor(100, 235, 0, 0)
	);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (!isClient())
		return;

	if (cmd == this.getCommandID("set_barrier_pos"))
	{
		u16 x1 = params.read_u16();
		u16 x2 = params.read_u16();

		this.set_u16("barrier_x1", x1);
		this.set_u16("barrier_x2", x2);
	}
	else if (cmd == this.getCommandID("set_barrier_vars"))
	{
		VEL_PUSHBACK = params.read_f32();
	}
}

////  FUNCTIONS  ////

void PushBlob(CBlob@ blob, u16 middle)
{
	Vec2f vel = blob.getVelocity();

	if (blob.getPosition().x < middle)
		vel.x -= VEL_PUSHBACK;
	else
		vel.x += VEL_PUSHBACK;

	blob.setVelocity(vel);
}

void LoadConfigVars()
{
	ConfigFile cfg = ConfigFile("Rules/CommonScripts/RedBarrierVars.cfg");

	if (cfg is null)
		return; // We tried :(

	BARRIER_PERCENT = cfg.read_f32("barrier_percent", 0.175f);
	
	// Check that we have edited the var
	// and that the client needs said value
	f32 pushback = cfg.read_f32("blob_pushback", 1.35f);

	if (pushback != VEL_PUSHBACK)
	{
		SYNC_CUSTOM_VARS = true;
		VEL_PUSHBACK = pushback;
	}
}

// Only used server side, client doesnt normally have info required
void SetBarrierPosition(CRules@ this)
{
	SERVER_BARRIER_SET = true;

	Vec2f[] barrierPositions;
	CMap@ map = getMap();
	u16 x1, x2;

	// Are there barrier markers?
	if (map.getMarkers("red barrier", barrierPositions) 
		&& barrierPositions.length() == 2)
	{
		int left = barrierPositions[0].x < barrierPositions[1].x ? 0 : 1;
		x1 = barrierPositions[left].x;
		x2 = barrierPositions[1 - left].x + map.tilesize;
	}
	else // No? Okay lets make our own!
	{
		const f32 mapWidth = map.tilemapwidth * map.tilesize;
		const f32 mapMiddle = mapWidth * 0.5f;
		const f32 barrierWidth = Maths::Floor(BARRIER_PERCENT * map.tilemapwidth) * map.tilesize;
		const f32 extraWidth = ((map.tilemapwidth % 2 == 1) ? 0.5f : 0.0f) * map.tilesize;

		x1 = mapMiddle - (barrierWidth + extraWidth);
		x2 = mapMiddle + (barrierWidth + extraWidth);
	}

	this.set_u16("barrier_x1", x1);
	this.set_u16("barrier_x2", x2);

	map.server_AddSector(Vec2f(x1, 0), Vec2f(x2,  map.tilemapheight * map.tilesize), "barrier");
}

void RemoveBarrier(CRules@ this)
{
	SERVER_BARRIER_SET = false;

	CMap@ map = getMap();
	u16 x1 = this.get_u16("barrier_x1");
	u16 x2 = this.get_u16("barrier_x2");

	Vec2f mid(
		// Exact middle of the zone horizontally
		(x1 + x2) * 0.5f,
		// Remove at the bottom of the map rather than the middle
		// to avoid potentially removing a no build zone from a hall or something
		(map.tilemapheight - 2) * map.tilesize
	);

	map.RemoveSectorsAtPosition(mid, "barrier");
}

// Sync barrier to said player
// Only send x as we dont have horizontal barriers (mods will add that in manually anyhow)
void SyncToPlayer(CRules@ this, CPlayer@ player)
{
	CBitStream stream = CBitStream();
	stream.write_u16(this.get_u16("barrier_x1"));
	stream.write_u16(this.get_u16("barrier_x2"));

	this.SendCommand(
		this.getCommandID("set_barrier_pos"),
		stream,
		player
	);
}

// Server will send its vars to the current player
// We only send this if we know that the cfg has been edited
void SyncVarsToPlayer(CRules@ this, CPlayer@ player)
{
	// Only send pushback as its the only one client needs
	CBitStream stream = CBitStream();
	stream.write_f32(VEL_PUSHBACK);

	this.SendCommand(
		this.getCommandID("set_barrier_vars"),
		stream,
		player
	);
}

const bool shouldBarrier(CRules@ this)
{
	return this.isIntermission() || this.isWarmup() || this.isBarrier();
}