//Auto-mining quarry
//converts wood into ores

const string fuel = "mat_wood";
const string ore = "mat_stone";
const string rare_ore = "mat_gold";

//balance
const int input = 25;       //input cost in fuel
const int output = 20;       //output amount in ore
const int rare_chance = 20; //one-in
const int time_taken = 72;  //ticks

//fuel levels for animation
const int max_fuel = 1000;
const int mid_fuel = 550;
const int low_fuel = 300;

void onInit(CSprite@ this)
{
	CSpriteLayer@ belt = this.addSpriteLayer("belt", "QuarryBelt.png", 20, 20);
	if (belt !is null)
	{
		//default anim
		{
			Animation@ anim = belt.addAnimation("default", 0, true);
			int[] frames = {
				0, 1, 2, 3,
				4, 5, 6, 7,
				8, 9, 10, 11,
				12, 13
			};
			anim.AddFrames(frames);
		}
		//belt setup
		belt.SetOffset(Vec2f(-8.0f, 1.0f));
		belt.SetRelativeZ(1);
		belt.SetVisible(true);
	}

	CSpriteLayer@ wood = this.addSpriteLayer("wood", "Quarry.png", 16, 16);
	if (wood !is null)
	{
		wood.SetOffset(Vec2f(9.0f, 1.0f));
		wood.SetVisible(false);
	}
}

void onInit(CBlob@ this)
{
	//building properties
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getSprite().SetZ(-50);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = time_taken;

	//quarry properties
	this.set_s16("wood", 0);
	this.set_bool("working", false);

	//commands
	this.addCommandID("add fuel");
}

void onTick(CBlob@ this)
{
	//only do "real" update logic on server
	if(getNet().isServer())
	{
		int blobCount = this.get_s16("wood");
		if (blobCount >= input)
		{
			this.set_bool("working", true);

			if (spawnOre(this.getPosition()))
			{
				this.set_s16("wood", blobCount - input); //burn some wood
			}
		}
		else
		{
			this.set_bool("working", false);
		}

		//keep properties in sync (only done each update and delta-compressed anyway)
		this.Sync("working", true);
		this.Sync("wood", true);
	}

	//update sprite based on modified or synced properties
	updateWoodLayer(this.getSprite());
	animateBelt(this, this.get_bool("working"));
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (this.get_s16("wood") < max_fuel)
	{
		CButton@ button = caller.CreateGenericButton("$mat_wood$", Vec2f(-4.0f, 0.0f), this, this.getCommandID("add fuel"), "Add fuel", params);
		if (button !is null)
		{
			button.deleteAfterClick = false;
			button.SetEnabled(caller.hasBlob(fuel, 1));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("add fuel"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if(caller is null) return;

		//amount we'd like to insert
		int requestedAmount = Maths::Min(250, max_fuel - this.get_s16("wood"));
		//amount we _can_ insert
		int ammountToStore = Maths::Min(requestedAmount, caller.getInventory().getCount(fuel));
		//can we even insert anything?
		if(ammountToStore > 0)
		{
			caller.TakeBlob(fuel, ammountToStore);
			this.set_s16("wood", this.get_s16("wood") + ammountToStore);

			updateWoodLayer(this.getSprite());
		}
	}
}

bool spawnOre(Vec2f position)
{
	int r = XORRandom(rare_chance);
	bool rare = (r == 0);

	CBlob@ _ore = server_CreateBlobNoInit(!rare ? ore : rare_ore);

	if (_ore is null) return false;

	_ore.Tag('custom quantity');
	_ore.Init();
	_ore.setPosition(position + Vec2f(-8.0f, 0.0f));
	_ore.server_SetQuantity(output);

	return true;
}

void updateWoodLayer(CSprite@ this)
{
	int wood = this.getBlob().get_s16("wood");
	CSpriteLayer@ layer = this.getSpriteLayer("wood");

	if (layer is null) return;

	if (wood < input)
	{
		layer.SetVisible(false);
	}
	else
	{
		layer.SetVisible(true);
		int frame = 5;
		if (wood > low_fuel) frame = 6;
		if (wood > mid_fuel) frame = 7;
		layer.SetFrameIndex(frame);
	}
}

void animateBelt(CBlob@ this, bool isActive)
{
	//safely fetch the animation to modify
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ belt = sprite.getSpriteLayer("belt");
	if (belt is null) return;
	Animation@ anim = belt.getAnimation("default");
	if (anim is null) return;

	//modify it based on activity
	if (isActive)
	{
		// slowly start animation
		if (anim.time == 0) anim.time = 5;
		if (anim.time > 3) anim.time--;
	}
	else
	{
		// slowly stop animation
		if (anim.time % 5 > 0) anim.time++;
		anim.time = anim.time % 5;
	}
}