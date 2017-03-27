// script for rooms that hold migrants in them

#include "MigrantCommon.as"

void onInit(CBlob@ this)
{
	if (!this.exists("migrants count"))	 // how many are currently there
		this.set_u8("migrants count", 0);
	if (!this.exists("migrants max"))
		this.set_u8("migrants max", 1);
	if (!this.exists("migrants auto"))
		this.set_bool("migrants auto", false); // do migrants pop in automatically on collide

	this.addCommandID("put migrant");
	this.addCommandID("out migrant");

	this.Tag("migrant room");

	AddIconToken("$put_migrant$", "Entities/Characters/Migrant/MigrantMale.png", Vec2f(32, 32), 3);
	AddIconToken("$out_migrant$", "Entities/Characters/Migrant/MigrantMale.png", Vec2f(32, 32), 17);

	this.getCurrentScript().tickFrequency = 149;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && carried.hasTag("migrant") && !isRoomFullOfMigrants(this))
	{
		CBitStream params;
		params.write_u16(carried.getNetworkID());
		const string name = carried.getName();
		caller.CreateGenericButton("$put_migrant$", Vec2f(0.0f, 7.0f), this, this.getCommandID("put migrant"), "Tuck into bed", params);
	}
	//else
//   if ((carried is null || !carried.hasTag("migrant")) && this.get_u8("migrants count") > 0)
//   {
	//   CBitStream params;
	//   params.write_u16( caller.getNetworkID() );
	//   caller.CreateGenericButton( "$out_migrant$", Vec2f(0.0f, 0.0f), this, this.getCommandID("out migrant"), "Wake up", params );
	//}
}

void onTick(CBlob@ this)
{
	if (getNet().isServer())
	{
		// put migrants standing around in dorm

		CBlob@[] blobsInRadius;
		if (this.getTeamNum() != 255 && !isRoomFullOfMigrants(this) && this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.25f, @blobsInRadius))
		{
			// first check if enemies nearby
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (b !is this && b.getTeamNum() != this.getTeamNum() && b.hasTag("player"))
				{
					return;
				}
			}
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (b !is this && !b.isAttached()
				        && b.getTickSinceCreated() > 150 // so they dont get in immediately
				        && b.getShape().vellen < 0.1f
				        && b.getTeamNum() == this.getTeamNum()
				        && b.hasTag("migrant")
				        && b.get_u8("strategy") != Strategy::runaway)
				{
					CBitStream params;
					params.write_u16(b.getNetworkID());
					this.SendCommand(this.getCommandID("put migrant"), params);
					b.server_Die();
					break;
				}
			}
		}

		// sync
		this.Sync("migrants count", true);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("put migrant"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_u16());
		if (!isRoomFullOfMigrants(this))
		{
			if (getNet().isServer() && blob !is null && blob.hasTag("migrant"))
			{
				blob.server_Die();
				this.set_u8("migrants count", this.get_u8("migrants count") + 1);
			}
			this.getSprite().PlaySound("PopIn.ogg");
			if (this.hasTag("bed"))
			{
				this.getSprite().PlaySound("/MigrantSleep");
			}
		}
	}
	else if (cmd == this.getCommandID("out migrant"))
	{
		u8 migrants = this.get_u8("migrants count");
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (migrants > 0)
		{
			this.set_u8("migrants count", migrants - 1);
			if (getNet().isServer())
			{
				CBlob@ migrant = CreateMigant(this.getPosition(), this.getTeamNum());
				if (migrant !is null)
				{
					migrant.IgnoreCollisionWhileOverlapped(this);
					if (caller !is null)
					{
						caller.server_Pickup(migrant);
					}
				}
			}
		}
	}
}

//void onCollision( CBlob@ this, CBlob@ blob, bool solid )
//{
//	if (getNet().isServer() && blob !is null && !blob.isAttached() && this.get_bool("migrants auto") && blob.hasTag("migrant") && !isRoomFullOfMigrants(this) && blob.get_u8("strategy") != Strategy::runaway)
//	{
//		CBitStream params;
//		params.write_u16( blob.getNetworkID() );
//		this.SendCommand( this.getCommandID( "put migrant" ), params );
//	}
//}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f)
	{
		if (getNet().isServer())
		{
			CBitStream params;
			params.write_u16(0);
			this.SendCommand(this.getCommandID("out migrant"), params);
		}
		this.getSprite().PlaySound("/MigrantHmm");
	}
	return damage;
}

void onDie(CBlob@ this)
{
	for (uint i = 0; i < this.get_u8("migrants count"); i++)
	{
		CBlob@ migrant = CreateMigant(this.getPosition(), this.getTeamNum());
	}
}

/// SPRITE

void onRender(CSprite@ this)
{
	CPlayer@ p = getLocalPlayer();
	if (p is null) { return; }
	CBlob@ blob = this.getBlob();


	const u8 count = blob.get_u8("migrants count");
	const u8 max = blob.get_u8("migrants max");
	const u32 nextRespawnTime = blob.get_u32("next respawn time");
	const int dif = nextRespawnTime - getGameTime();
	Vec2f pos = blob.getScreenPos();
	//if (dif >= 0 && max > 0 && count < max)
	//{
	//	GUI::DrawText( "" + (dif / getTicksASecond() + 1),
	//		pos + Vec2f(0,4),
	//		count < max ? color_white : SColor(255, 55, 255, 0) );
	//}
	GUI::SetFont("menu");
	GUI::DrawText("" + count,
	              pos + Vec2f(0, 4),
	              count == max ? SColor(255, 255, 55, 0) : SColor(255, 55, 255, 0));

}
