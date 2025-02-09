
#include "ChickenCommon.as";

const int GROW_TIME = 20 * getTicksASecond();
const string CAN_GROW_TIME = "can grow time";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 120;
	this.addCommandID("hatch client");
	ResetGrowTime(this);
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

void onTick(CBlob@ this)
{
	if (isServer() && getGameTime() > this.get_u32(CAN_GROW_TIME))
	{
		int count = 0;
		CBlob@[] blobs;
		this.getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ other = blobs[step];
			if (other.getName() == "chicken" && !other.isAttached() && !other.isInInventory())
			{
				count++;
			}
		}

		this.server_SetHealth(-1);
		this.server_Die();
		this.SendCommand(this.getCommandID("hatch client"));

		// Prevent chickens from spawning in blocks
		CMap@ map = getMap();
		if (map !is null && count < MAX_CHICKENS)
		{
			f32 chicken_radius = 5.0f;
			Vec2f chicken_height_offset = Vec2f(0, -chicken_radius);
			Vec2f spawn_pos = this.getPosition() + chicken_height_offset;
			Vec2f tile_pos = map.getTileSpacePosition(spawn_pos);
			
			// Solids in or above our block, abort
			if (hasSolid(map, tile_pos))
			{
				return;
			}

			bool tiles_left = hasSolid(map, tile_pos + Vec2f(-1, 0));
			bool tiles_right = hasSolid(map, tile_pos + Vec2f(1, 0));

			// 1 wide gap, abort
			if (tiles_left && tiles_right)
			{
				return;
			}

			// Check if we need to shift
			if (tiles_left ^^ tiles_right)
			{
				spawn_pos.x = map.getAlignedWorldPos(spawn_pos).x + (tiles_left ? chicken_radius : 2);  // Not sure why these offsets had to be so weird
			}

			server_CreateBlob("chicken", this.getTeamNum(), spawn_pos + chicken_height_offset);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("hatch client") && isClient())
	{
		CSprite@ s = this.getSprite();
		if (s !is null)
		{
			s.Gib();
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	ResetGrowTime(this);
}

void ResetGrowTime(CBlob@ this)
{
	this.set_u32(CAN_GROW_TIME, getGameTime() + GROW_TIME);
}

bool hasSolid(CMap@ map, Vec2f tile_pos)
{
	Tile this_tile = map.getTileFromTileSpace(tile_pos);
	Tile above_tile = map.getTileFromTileSpace(tile_pos + Vec2f(0, -1));
	return map.isTileSolid(this_tile) || map.hasTileSolidBlobs(this_tile) || map.isTileSolid(above_tile) || map.hasTileSolidBlobs(above_tile);
}