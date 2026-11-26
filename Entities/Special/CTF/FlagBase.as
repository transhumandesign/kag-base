// Flag base logic

#include "CTF_FlagCommon.as"
#include "GameplayEventsCommon.as";

const string flag_name = "ctf_flag";

void onInit(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	this.SetFacingLeft(pos.x < getMap().getMapDimensions().x * 0.5f); //face center of map

	if (isServer())
	{
		CBlob@ flag = server_CreateBlob(flag_name, this.getTeamNum(), pos);
		if (flag !is null)
		{
			this.server_AttachTo(flag, "FLAG");
			this.set_netid("flag id", flag.getNetworkID());
		}
	}

	//cannot fall out of map
	this.SetMapEdgeFlags(u8(CBlob::map_collide_up) |
	                     u8(CBlob::map_collide_down) |
	                     u8(CBlob::map_collide_sides));
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;
	
	if (this.getTickSinceCreated() > 30 && !this.hasTag("nobuild sector added"))
	{
		this.Tag("nobuild sector added");
		Vec2f pos = this.getPosition();

		CMap@ map = getMap();
		map.server_AddSector(pos + Vec2f(-12, -32), pos + Vec2f(12, 16), "no build", "", this.getNetworkID());

		//clear the no build zone so we dont get unbreakable blocks
		for (int x = -12; x < 12; x += 8)
		{
			for (int y = -32; y < 8; y += 8)
			{
				if (map.isTileSolid(pos + Vec2f(x, y)))
				{
					map.server_SetTile(pos + Vec2f(x, y), CMap::tile_empty);
				}
			}
		}

		map.server_SetTile(pos + Vec2f(-8, 12), CMap::tile_bedrock);
		map.server_SetTile(pos + Vec2f(0, 12), CMap::tile_bedrock);
		map.server_SetTile(pos + Vec2f(8, 12), CMap::tile_bedrock);
	}

	if (!this.hasAttached())
	{
		CBlob@ flag = getBlobByNetworkID(this.get_netid("flag id"));
		if (flag !is null)
		{
			//check return conditions
			if (!flag.isAttached() && flag.get_u16(return_prop) >= return_time)
			{
				flag.SendCommand(flag.getCommandID("return flag client"));

				this.server_AttachTo(flag, "FLAG");
			}

			if (flag.hasTag("stalemate_return"))
			{
				flag.server_DetachAll();
				flag.SendCommand(flag.getCommandID("return flag client"));
				flag.Untag("stalemate_return"); //local

				this.server_AttachTo(flag, "FLAG");
			}
		}
		else
		{
			//Vec2f pos = this.getPosition();
			//getMap().RemoveSectorsAtPosition(pos, "no build", this.getNetworkID());
			//getMap().server_AddSector(pos + Vec2f(-12, -8), pos + Vec2f(12, 16), "no build", "", this.getNetworkID());
			this.server_Die();
		}
	}
}

//sprite

void onInit(CSprite@ this)
{
	this.SetZ(-10.0f);
}

//release held flag when touched
void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || !isServer()) return;

	if (!blob.hasTag("player")) return;	//early out for non-player collision
	if (!this.hasAttached()) return; //early out if we dont have a flag attached

	if (blob.getTeamNum() != this.getTeamNum())
	{
		if (canPickupFlag(blob))
		{
			this.server_DetachAll();

			CBlob@ flag = getBlobByNetworkID(this.get_netid("flag id"));
			if (flag !is null)
			{
				blob.server_AttachTo(flag, "PICKUP"); //attach to player

				CBitStream params;
				params.write_netid(blob.getNetworkID());
				flag.SendCommand(flag.getCommandID("pickup flag client"), params);
			}
		}
	}
	else //our team
	{
		//carrying enemy flag
		CBlob@ flag = blob.getCarriedBlob();
		if (flag !is null && !flag.hasTag("was captured") && flag.getName() == flag_name && flag.getTeamNum() != this.getTeamNum())
		{
			CPlayer@ p = blob.getPlayer();
			if (p !is null)
			{
				GE_CaptureFlag(p.getNetworkID()); // gameplay event for coins
			}

			//smash the flag
			this.server_Hit(flag, flag.getPosition(), Vec2f(), 5.0f, 0xfa, true);

			if (sv_tcpr && blob.getPlayer() !is null)
			{
				tcpr("FlagCaptured {\"player\":\"" + blob.getPlayer().getUsername() + "\",\"ticks\":" + getGameTime() + "}");
			}

			CBitStream params;
			params.write_netid(blob.getNetworkID());
			flag.SendCommand(flag.getCommandID("capture flag client"), params);
			flag.Tag("was captured");
		}
	}
}
