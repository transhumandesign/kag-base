// Flowers logic

#include "canGrow.as";
#include "MakeSeed.as";

//sprites to load by index
const string[] seed_sprites =
{
	"Entities/Natural/Seed/Seed.png",       //normal seed
	"Entities/Natural/Seed/Seed.png",       //grain seed
	"Entities/Natural/Trees/Trees.png",     //pine
	"Entities/Natural/Trees/Trees.png",     //bushy
	"Entities/Natural/Farming/Grain.png",   //grains
	"Entities/Natural/Seed/Seed.png",  //bush
	"Entities/Natural/Seed/Seed.png",  //flowers
};

// names of seeds
const string[] seed_names =
{
	"Seed",           //normal seed
	"Grain Seed",     //grain seed
	"Pine Seed",        //pine
	"Oak Seed",     //bushy
	"Grain",       //grains
	"Bush seed",    //bush
	"Flower seed"   //flowers
};

const u32 OPT_TICK = 31;

void onInit(CBlob@ this)
{
	if (this.exists("sprite index"))
	{
		u8 spriteIndex = this.get_u8("sprite index");

		if (spriteIndex < seed_sprites.length)
		{
			LoadSprite(this, seed_sprites[spriteIndex], spriteIndex);
		}

		if (spriteIndex < seed_names.length)
		{
			this.setInventoryName(seed_names[spriteIndex]);
		}
	}
	else
	{
		LoadSprite(this, seed_sprites[0], 0);
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
	int frameWidth = 8, frameHeight = 8;

	if (spriteIndex == 2 || spriteIndex == 3)
	{
		frameWidth = 16;
		frameHeight = 16;
	}

	sprite.ReloadSprite(filename, frameWidth, frameHeight);
	Animation@ anim = sprite.addAnimation("loadedSeed", 0, false);

	if (anim !is null)
	{
		switch (spriteIndex)
		{
			case 2: anim.AddFrame(20); anim.AddFrame(21); sprite.SetOffset(Vec2f(0, -2)); break;

			case 3: anim.AddFrame(4); anim.AddFrame(5); sprite.SetOffset(Vec2f(0, -2)); break;

			//case 4: anim.AddFrame(0); anim.AddFrame(1); sprite.SetOffset( Vec2f(0,2) ); break;

			default: anim.AddFrame(0); anim.AddFrame(1); break;
		}

		sprite.SetAnimation(anim);
		this.SetInventoryIcon(filename, anim.getFrame(0), Vec2f(frameWidth, frameHeight));
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

void onDie (CBlob@ blob) {
    if (isServer()) {
        if (!blob.hasTag("done_growing")) {
            
            // NOTE(hobey): blob fell in the void; resummon the blob at the top of the map
            
            CMap@ map = getMap();
            
            Vec2f pos = blob.getPosition();
            
            float min_x = 16;
            float max_x = (map.tilemapwidth * map.tilesize - 16);
            if (pos.x < min_x) pos.x = min_x;
            if (pos.x > max_x) pos.x = max_x;
            
            pos.y = 0;
            bool do_summon = true;
            while (true) {
                if (!map.isTileSolid(pos)) break;
                pos.y += 8;
                if (pos.y > (map.tilemapheight * map.tilesize)) {
                    do_summon = false; // NOTE(hobey): if the blob fell into the void, and there's a colomn of blocks from top to bottom of the map, delete the blob for good
                    break;
                }
            }
            
            if (do_summon) {
                // CBlob@ new_blob = server_MakeSeed(pos, blob.get_string("seed_grow_blobname"), blob.get_u16("growtime"), blob.get_u8("spriteIndex"), blob.get_u8("created_blob_radius"));
                CBlob@ new_blob = server_MakeSeed(pos, blob.get_string("seed_grow_blobname"));
            }
        }
    }
}
