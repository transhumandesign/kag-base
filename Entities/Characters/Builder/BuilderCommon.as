// BuilderCommon.as

#include "BuildBlock.as";
#include "PlacementCommon.as";
#include "CheckSpam.as";
#include "GameplayEvents.as";

const f32 allow_overlap = 2.0f;

shared class HitData
{
	u16 blobID;
	Vec2f tilepos;
};

Vec2f getBuildingOffsetPos(CBlob@ blob, CMap@ map, Vec2f required_tile_space)
{
	Vec2f halfSize = required_tile_space * 0.5f;

	Vec2f pos = blob.getPosition();
	pos.x = int(pos.x / map.tilesize);
	pos.x *= map.tilesize;
	pos.x += map.tilesize * 0.5f;

	pos.y -= required_tile_space.y * map.tilesize * 0.5f - map.tilesize;
	pos.y = int(pos.y / map.tilesize);
	pos.y *= map.tilesize;
	pos.y += map.tilesize * 0.5f;

	Vec2f offsetPos = pos - Vec2f(halfSize.x , halfSize.y) * map.tilesize;
	Vec2f alignedWorldPos = map.getAlignedWorldPos(offsetPos);
	return alignedWorldPos;
}

CBlob@ server_BuildBlob(CBlob@ this, BuildBlock[]@ blocks, uint index)
{
	if (index >= blocks.length)
	{
		return null;
	}

	this.set_u32("cant build time", 0);

	CInventory@ inv = this.getInventory();
	BuildBlock@ b = @blocks[index];

	this.set_TileType("buildtile", 0);

	CBlob@ anotherBlob = inv.getItem(b.name);
	if (getNet().isServer() && anotherBlob !is null)
	{
		this.server_Pickup(anotherBlob);
		this.set_u8("buildblob", 255);
		return null;
	}

	Vec2f pos = this.getPosition();

	if (b.buildOnGround)
	{
		const bool onground = this.isOnGround();

		bool fail = !onground;

		CMap@ map = getMap();

		Vec2f space = Vec2f(b.size.x / 8, b.size.y / 8);
		Vec2f offsetPos = getBuildingOffsetPos(this, map, space);

		Vec2f tl = offsetPos;
		Vec2f br = offsetPos;

		if (!fail)
		{
			// check every tile space of the built blob for "no build sector" or "solid tile"
			for(f32 step_x = 0.0f; step_x < space.x ; ++step_x)
			{
				for(f32 step_y = 0.0f; step_y < space.y ; ++step_y)
				{
					Vec2f temp = (Vec2f(step_x + 0.5, step_y + 0.5) * map.tilesize);
					Vec2f v = offsetPos + temp;
					if (map.getSectorAtPosition(v , "no build") !is null || map.isTileSolid(v))
					{
						fail = true;
						break;
					}
				}
			}
			// if we still havent failed
			// check if we're making a building
			// -> need to do some additional checking
			if (!fail && b.name == "building")
			{
				tl = Vec2f(offsetPos.x, offsetPos.y);
				br = Vec2f(offsetPos.x + b.size.x, offsetPos.y + b.size.y);

				Vec2f b_pos = Vec2f(tl.x + (b.size.x * 0.5f), tl.y + (b.size.y * 0.5f));
				Vec2f b_half = Vec2f(b.size.x, b.size.y) * 0.5f;

				CBlob@[] overlapping;
				map.getBlobsInBox(tl, br, @overlapping);
				for (uint i = 0; i < overlapping.length; i++)
				{
					CBlob@ o_blob = overlapping[i];
					CShape@ o_shape = o_blob.getShape();
					if (o_blob !is null &&
					        o_shape !is null &&
					        !o_blob.isAttached() &&
					        o_shape.isStatic() &&
					        !o_shape.getVars().isladder)
					{
						//check if any of those blobs are overlapping
						Vec2f o_pos = o_blob.getPosition();
						Vec2f o_half = Vec2f(o_shape.getWidth(), o_shape.getHeight()) * 0.5f;
						Vec2f dif = Vec2f(Maths::Abs(o_pos.x - b_pos.x), Maths::Abs(o_pos.y - b_pos.y));
						Vec2f total = o_half + b_half;
						Vec2f sep = total - dif;
						if (sep.x > allow_overlap && sep.y > allow_overlap)
						{
							//check if they aren't on the ignore list
							//done here to avoid a bunch of string comp earlier
							if (isBlocking(o_blob))
							{
								fail = true;
								break;
							}
						}
					}
				}
			}
		}

		if (fail)
		{
			if (this.isMyPlayer())
			{
				this.getSprite().PlaySound("/NoAmmo", 0.5);
			}
			this.set_Vec2f("building space", space);
			this.set_u32("cant build time", getGameTime());
			return null;
		}

		pos = offsetPos + space * map.tilesize * 0.5f;

		this.getSprite().PlaySound("/Construct");
		// take inv here instead of in onDetach
		server_TakeRequirements(inv, b.reqs);
		DestroyScenary(tl, br);
		SendGameplayEvent(createBuiltBlobEvent(this.getPlayer(), b.name));
	}

	this.set_u8("buildblob", index);

	if (getNet().isServer())
	{
		CBlob@ blockBlob = server_CreateBlob(b.name, this.getTeamNum(), Vec2f(0,0));
		if (blockBlob !is null)
		{
			CShape@ shape = blockBlob.getShape();
			shape.SetStatic(false);
			shape.server_SetActive(false);
			blockBlob.setPosition(pos);
			//blockBlob.

			if (!b.buildOnGround)
			{
				this.server_Pickup(blockBlob);
			}
			else
			{
				shape.server_SetActive(true); // have it enable if its a shop
			}

			if (b.temporaryBlob)
			{
				blockBlob.Tag("temp blob");
			}
			return blockBlob;
		}
	}

	return null;
}

bool canBuild(CBlob@ this, BuildBlock[]@ blocks, uint index)
{
	if (index >= blocks.length)
	{
		return false;
	}

	BuildBlock@ block = @blocks[index];

	BlockCursor @bc;
	this.get("blockCursor", @bc);
	if (bc is null)
	{
		return false;
	}

	bc.missing.Clear();
	bc.hasReqs = hasRequirements(this.getInventory(), block.reqs, bc.missing, not block.buildOnGround);

	return bc.hasReqs;
}

void ClearCarriedBlock(CBlob@ this)
{
	// clear variables
	this.set_u8("buildblob", 255);
	this.set_TileType("buildtile", 0);

	// remove carried block, if any
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null && carried.hasTag("temp blob"))
	{
		carried.Untag("temp blob");
		carried.server_Die();
	}
}
