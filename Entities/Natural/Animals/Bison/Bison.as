
//script for a bison

#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = TAMABLE_BIT | DONT_GO_DOWN_BIT;
const s16 MAD_TIME = 600;

//sprite

void onInit(CSprite@ this)
{
	this.ReloadSprites(0, 0); // always blue
	
	// saddle
	CSpriteLayer@ saddle = this.addSpriteLayer("saddle", "/Saddle.png", 16, 16, 0, 0);
	if (saddle !is null)
		saddle.SetVisible(false);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		f32 x = blob.getVelocity().x;
		if (Maths::Abs(x) > 0.2f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			this.SetAnimation("idle");
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
			
	CSpriteLayer@ saddle = this.getSpriteLayer("saddle");
	const s16 friendTeam = this.getBlob().get_s16(friend_team); 

	if (friendTeam >= 0 && !saddle.isVisible())
	{
		saddle.SetVisible(true);
		this.ReloadSprites(friendTeam, friendTeam);
	}
	else if (friendTeam < 0 && saddle.isVisible())
	{
		saddle.SetVisible(false);
	}
}

//blob

void onInit(CBlob@ this)
{
	//for EatOthers
	string[] tags = {"player", "flesh"};
	this.set("tags to eat", tags);

	this.set_f32("bite damage", 1.5f);

	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.set_u8("random move freq", 12);
	this.set_f32(target_searchrad_property, 320.0f);
	this.set_f32(terr_rad_property, 85.0f);
	this.set_u8(target_lose_random, 34);

	this.getBrain().server_SetActive(true);

	//befriended team
	this.set_s16(friend_team, -1); // Please note, -1 here means "no team"

	//for steaks
	this.set_u8("number of steaks", 8);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -0.0f);

	this.Tag("flesh");

	this.set_s16("mad timer", 0);

	this.getShape().SetOffset(Vec2f(0, 6));

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.offsetZ = 10.0f;
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;

	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft(x < 0);
	}
	else
	{
		if (this.isKeyPressed(key_left))
		{
			this.SetFacingLeft(true);
		}
		if (this.isKeyPressed(key_right))
		{
			this.SetFacingLeft(false);
		}
	}

	// relax the madness

	if (getGameTime() % 65 == 0)
	{
		s16 mad = this.get_s16("mad timer");
		if (mad > 0)
		{
			mad -= 65;
			if (mad < 0)
			{
				this.set_u8(personality_property, DEFAULT_PERSONALITY);
				this.getSprite().PlaySound("/BisonBoo");
			}
			this.set_s16("mad timer", mad);
		}

		if (XORRandom(mad > 0 ? 3 : 12) == 0)
			this.getSprite().PlaySound("/BisonBoo");
	}

	// footsteps

	if (this.isOnGround() && (this.isKeyPressed(key_left) || this.isKeyPressed(key_right)))
	{
		if ((this.getNetworkID() + getGameTime()) % 9 == 0)
		{
			f32 volume = Maths::Min(0.1f + Maths::Abs(this.getVelocity().x) * 0.1f, 1.0f);
			TileType tile = this.getMap().getTile(this.getPosition() + Vec2f(0.0f, this.getRadius() + 4.0f)).type;

			if (this.getMap().isTileGroundStuff(tile))
			{
				this.getSprite().PlaySound("/EarthStep", volume, 0.75f);
			}
			else
			{
				this.getSprite().PlaySound("/StoneStep", volume, 0.75f);
			}
		}
	}
}

void MadAt(CBlob@ this, CBlob@ hitterBlob)
{
	const s16 friendTeam 	= this.get_s16(friend_team);
	
	CPlayer@ damageOwner 	= hitterBlob.getDamageOwnerPlayer();
	const u16 damageOwnerId = (damageOwner !is null && damageOwner.getBlob() !is null) ? damageOwner.getBlob().getNetworkID() : 0;
	const s16 damageOwnerTeam = (damageOwner !is null && damageOwner.getBlob() !is null) ? damageOwner.getBlob().getTeamNum() : -1;

	if (friendTeam == damageOwnerTeam || friendTeam == hitterBlob.getTeamNum()) // unfriend
	{
		this.set_s16(friend_team, -1);
	}
	else // now I'm mad!
	{
		if (friendTeam == damageOwnerTeam)
			this.set_s16(friend_team, -1);
	
		if (this.get_s16("mad timer") <= MAD_TIME / 8)
			this.getSprite().PlaySound("/BisonMad");
		this.set_s16("mad timer", MAD_TIME);
		this.set_u8(personality_property, DEFAULT_PERSONALITY | AGGRO_BIT);
		this.set_u8(state_property, MODE_TARGET);
		if (hitterBlob.hasTag("player"))
			this.set_netid(target_property, hitterBlob.getNetworkID());
		else if (damageOwnerId > 0)
		{
			this.set_netid(target_property, damageOwnerId);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	MadAt(this, hitterBlob);
	return damage;
}

#include "Hitters.as";

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("dead"))
		return false;
	return true;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null)
		return;

	const s16 friendTeam 	= this.get_s16(friend_team);
	
	if (blob.getTeamNum() != friendTeam && blob.getName() != this.getName() && blob.hasTag("flesh"))
	{
		const f32 vellen = this.getShape().vellen;
		if (vellen > 0.1f)
		{
			Vec2f pos = this.getPosition();
			Vec2f vel = this.getVelocity();
			Vec2f other_pos = blob.getPosition();
			Vec2f direction = other_pos - pos;
			direction.Normalize();
			vel.Normalize();
			if (vel * direction > 0.33f)
			{
				f32 power = Maths::Max(0.25f, 1.0f * vellen);
				this.server_Hit(blob, point1, vel, power, Hitters::flying, false);
			}
		}
	}

	// eat cake	and make friends
	{
		if (blob.getName() == "food")
		{
			// eat the food even at full health
			this.getSprite().PlaySound("/Eat.ogg");
			this.server_SetHealth(Maths::Min(this.getHealth() + 4.0f, this.getInitialHealth()));
			blob.server_Die();

			//if (blob.getPosition().x < this.getPosition().x)	crash
			//	blob.setKeyPressed( key_left, true );
			//else
			//	blob.setKeyPressed( key_right, true );

			CPlayer@ owner = blob.getDamageOwnerPlayer();
			if (owner !is null && owner.getBlob() !is null)
			{
				u8 newFriendTeam = owner.getBlob().getTeamNum();
				this.set_u8(state_property, MODE_FRIENDLY);
				
				if (this.get_s16(friend_team) != newFriendTeam)
				{
					this.set_s16(friend_team, newFriendTeam);
					this.getSprite().ReloadSprites(newFriendTeam, newFriendTeam);
				}
			}
		}
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null && customData == Hitters::flying)
	{
		Vec2f force = velocity * this.getMass() * 0.35f ;
		force.y -= 100.0f;
		hitBlob.AddForce(force);
	}
}