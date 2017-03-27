// function for setting a builder blob to migrant

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		find_teammate,
		find_dorm,
		runaway
	};
};

const f32 SEEK_RANGE = 400.0f;
const f32 ENEMY_RANGE = 100.0f;

shared void SetMigrant(CBlob@ blob, bool isMigrant)
{
	if (blob is null)
		return;

	if (isMigrant) // on
	{
		blob.Tag("migrant");
		blob.getBrain().server_SetActive(true);
	}
	else // off
	{
		blob.Untag("migrant");
		blob.getBrain().server_SetActive(false);
	}
}

shared CBlob@ CreateMigant(Vec2f pos, int team)
{
	CBlob@ blob = server_CreateBlobNoInit("migrant");
	if (blob !is null)
	{
		//setup ready for init
		blob.setSexNum(XORRandom(2));
		blob.server_setTeamNum(team);
		blob.setPosition(pos);

		blob.Init();

		blob.SetFacingLeft(XORRandom(2) == 0);

		SetMigrant(blob, true);   //requires brain -> after init
	}
	return blob;
}

bool isRoomFullOfMigrants(CBlob@ this)
{
	return this.get_u8("migrants count") >= this.get_u8("migrants max");
}

bool needsReplenishMigrant(CBlob@ this)
{
	return this.get_u8("migrants count") < this.get_u8("migrants max");
}

void AddMigrantCount(CBlob@ this, int add = 1)
{
	this.set_u8("migrants count", this.get_u8("migrants count") + add);
}

void DecMigrantCount(CBlob@ this, int dec = 1)
{
	this.set_u8("migrants count", this.get_u8("migrants count") - dec);
}
