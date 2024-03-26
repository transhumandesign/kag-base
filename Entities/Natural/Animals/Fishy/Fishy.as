
//script for a cute fishy

#include "AnimalConsts.as";
#include "MakeFood.as";
#include "ArcherCommon.as";

const u8 cookAfterInFireTicks = 10;

//sprite

const array<array<string>> anims =
{
	{"speck_default", "speck_idle", "speck_dead"},
	{"baby_default", "baby_idle", "baby_dead"},
	{"young_default", "young_idle", "young_dead"},
	{"default", "idle", "dead"}
};

void onInit(CSprite@ this)
{
	uint col = uint(XORRandom(8));
	if (this.getBlob().exists("colour"))
		col = this.getBlob().get_u8("colour");
	else
		this.getBlob().set_u8("colour", col);

	this.ReloadSprites(col, 0); //random colour
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	u8 age = Maths::Min(blob.get_u8("age"), 3);
	u8 age_frame_index = (3-age)*4; // 4 ages, 4 sprite-variants per age (age 0 = old, age 3 = young)

	if (!blob.hasTag("dead"))
	{
		if (blob.isKeyPressed(key_left) ||
		        blob.isKeyPressed(key_right) ||
		        blob.isKeyPressed(key_up) ||
		        blob.isKeyPressed(key_down))
		{
			this.SetAnimation(anims[age][0]);
			blob.SetInventoryIcon("Fishy.png", age_frame_index+1, Vec2f(16, 16)); // default anim frames are age_frame_index+0, age_frame_index+1, age_frame_index+2.
		}
		else
		{
			this.SetAnimation(anims[age][1]);
			blob.SetInventoryIcon("Fishy.png", age_frame_index+0, Vec2f(16, 16)); // idle anim frames are age_frame_index+0.
		}
	}
	else
	{
		this.SetAnimation(anims[age][2]);
		blob.SetInventoryIcon("Fishy.png", age_frame_index+3, Vec2f(16, 16)); // dead anim frames are age_frame_index+3.
	}
}

//blob

void onInit(CBlob@ this)
{
	this.set_u8(personality_property, SCARED_BIT | STILL_IDLE_BIT);
	this.set_f32(target_searchrad_property, 56.0f);

	this.getBrain().server_SetActive(true);

	this.set_f32("swimspeed", 0.5f);
	this.set_f32("swimforce", 0.1f);

	this.Tag("flesh");
	this.Tag("builder always hit");

	this.getCurrentScript().tickFrequency = 40;

	if (!this.exists("age"))
		this.set_u8("age", 0);

	this.Tag("pushedByDoor");
	
	this.set_u16("fire duration", 0);

	this.Tag("cookable in fireplace");
	this.set_string("cooked name", "Cooked Fish");
	this.set_u8("cooked sprite index", 1);
}

void onTick(CBlob@ this)
{
	// cook it after it's been in fire
	if (getGameTime() % 5 == 0)
	{
		if (isServer())
		{
			CMap@ map 		= getMap();
			Vec2f position 	= this.getPosition();
		
			u16 fire_duration = this.exists("fire duration") ? this.get_u16("fire duration") : 0;
			
			if (map.isInFire(position))
			{
				fire_duration++;
							
				if (fire_duration >= cookAfterInFireTicks)
				{
					Cook(this); // MakeFood.as
				}
				
				this.set_u16("fire duration", fire_duration);
			}
			else if (fire_duration > 0)
			{
				fire_duration--;
			
				this.set_u16("fire duration", fire_duration);
			}
		}
	}
	
	if (getGameTime() % 40 == 0)
	{
		f32 x = this.getVelocity().x;
		if (Maths::Abs(x) > 1.0f)
		{
			this.SetFacingLeft(x < 0);
		}
		else
		{
			if (this.isKeyPressed(key_left))
				this.SetFacingLeft(true);
			if (this.isKeyPressed(key_right))
				this.SetFacingLeft(false);
		}

		if (isServer())
		{				
			// aging
			u8 age = this.get_u8("age");
			if (age < 3)
			{
				if (XORRandom(512) < 16)
				{
					age++;
				}

				this.set_u8("age", age);
				this.Sync("age", true);
			}
			else if (XORRandom(512) < 4)
			{
				this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 1.0f, 0, true); //death from old age
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "arrow" 
		&& hitterBlob.get_u8("arrow type") == ArrowType::fire
		&& !this.hasTag("cooked"))
	{
		Cook(this); // MakeFood.as
	}

	if (damage == 0)
		return damage;

	u8 age = this.get_u8("age");

	this.Tag("dead");
	this.AddScript("Eatable.as");
	this.getShape().getConsts().buoyancy = 0.8f;
	this.getShape().getConsts().collidable = true;
	this.server_SetTimeToDie(40);

	CSprite@ sprite = this.getSprite();

	sprite.SetAnimation(anims[age][2]);

	sprite.SetFacingLeft(!sprite.isFacingLeft());

	return damage;
}
