// Flowers logic

#include "canGrow.as";

//sprites to load by index
const string seed_file = "Entities/Natural/Seed/Seed.png";

// names of seeds
const string[] seed_names =
{
	"Seed",			//normal seed
	"Grain Seed",	//grain seed
	"Bush seed",	//bush
	"Flower seed",	//flowers
	"Pine Seed",	//pine tree
	"Oak Seed",		//bushy tree
	"Apple Seed"	//apple tree
};

const u32 OPT_TICK = 31;

void onInit(CBlob@ this)
{
	if (this.exists("sprite index"))
	{
		u8 spriteIndex = this.get_u8("sprite index");

		LoadSprite(this, seed_file, spriteIndex);

		if (spriteIndex < seed_names.length)
		{
			this.setInventoryName(seed_names[spriteIndex]);
		}
	}
	else
	{
		LoadSprite(this, seed_file, 0);
	}

	if (!this.exists("created_blob_radius"))
	{
		this.set_u8("created_blob_radius", 4);
	}

	if (!this.exists("seed_grow_time"))
	{
		this.set_u16("seed_grow_time", 0);
	}

	if (!this.exists("seed_grow_blobname"))
	{
		this.set_string("seed_grow_blobname", "WARNING: SEED BLOBNAME NOT SET");
	}

	this.Tag("place norotate");
	this.Tag("pushedByDoor");

	this.getCurrentScript().tickFrequency = OPT_TICK;
}


void LoadSprite(CBlob@ this, string filename, u8 spriteIndex)
{
	CSprite@ sprite = this.getSprite();
	sprite.ReloadSprite(filename, 16, 16);
	
	Animation@ anim = sprite.addAnimation("loadedSeed", 0, false);

	if (anim !is null)
	{
		anim.AddFrame(0 + 2 * spriteIndex); 
		anim.AddFrame(1 + 2 * spriteIndex);

		sprite.SetAnimation(anim);
		this.SetInventoryIcon(filename, anim.getFrame(0), Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
	u16 seed_grow_time = this.get_u16("seed_grow_time");

	if (canGrowAt(this, this.getPosition()) && !this.isAttached())
	{
		this.getSprite().SetFrameIndex(1);

		if (seed_grow_time > OPT_TICK)
		{
			seed_grow_time -= OPT_TICK;
		}
	}
	else
	{
		this.getSprite().SetFrameIndex(0);
	}

	this.set_u16("seed_grow_time", seed_grow_time);

	if (seed_grow_time <= OPT_TICK)
	{
		this.server_Die();

		if (getNet().isServer())
		{
			float rad = f32(this.get_u8("created_blob_radius")) - this.getRadius();
			CBlob@ b = server_CreateBlob(this.get_string("seed_grow_blobname"), -1, this.getPosition() + Vec2f(0, rad));
			/*if (b !is null) //not needed, pushes out of the ground unecessarily
			{
			    b.getShape().PutOnGround();
			}*/
		}
	}

	if (isServer())
	{
		CMap@ map = getMap();
		const f32 tilesize = map.tilesize;

		Vec2f tpos = this.getPosition() + Vec2f(0, tilesize);
		if (!map.isTileGround(map.getTile(tpos).type))
		{
			// drop down when not supported
			CShape@ shape = this.getShape();
			shape.server_SetActive(true);

			shape.SetStatic(false);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getSprite().SetFrameIndex(0);
}