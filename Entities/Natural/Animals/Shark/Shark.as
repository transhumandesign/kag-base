
//script for a scary shark

#include "AnimalConsts.as";

//sprite

void onInit(CSprite@ this)
{
	this.ReloadSprites(0, 0); //always blue
}

const string angle_prop = "shark angle";
const string chomp_tag = "chomping";

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		//scary chomping
		if (blob.hasTag(chomp_tag))
		{
			if (this.animation.name != "chomp")
			{
				this.PlaySound(blob.get_string("bite sound"));
			}
			this.SetAnimation("chomp");
			return;
		}

		if (blob.getVelocity().LengthSquared() > 0.5f && (!this.isAnimation("chomp") || this.isAnimationEnded()))
		{
			this.SetAnimation("default");
		}
		else if (this.isAnimationEnded())
		{
			this.SetAnimation("idle");
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

//blob

void onInit(CBlob@ this)
{
	//for EatOthers
	string[] tags = {"player", "flesh"};
	this.set("tags to eat", tags);

	this.set_f32("bite damage", 1.5f);

	//for aquatic animal
	this.set_f32(terr_rad_property, 64.0f);
	this.set_f32(target_searchrad_property, 96.0f);

	this.set_u8(personality_property, AGGRO_BIT);

	this.getBrain().server_SetActive(true);

	this.set_u8(target_lose_random, 8);

	//for steaks
	this.set_u8("number of steaks", 5);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -0.0f);

	this.Tag("flesh");

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
	return false; //maybe make a knocked out state? for loading to cata?
}

void onTick(CBlob@ this)
{
	Vec2f vel = this.getVelocity();

	if (getNet().isServer() && getGameTime() % 10 == 0)
	{
		//player compatible
		CPlayer@ myplayer = this.getPlayer();
		this.getBrain().server_SetActive(myplayer is null || myplayer.isBot());

		if (this.get_u8(state_property) == MODE_TARGET)
		{
			CBlob@ b = getBlobByNetworkID(this.get_netid(target_property));
			if (b !is null && this.getDistanceTo(b) < 56.0f)
			{
				this.Tag(chomp_tag);
			}
			else
			{
				this.Untag(chomp_tag);
			}
		}
		else
		{
			this.Untag(chomp_tag);
		}
		this.Sync(chomp_tag, true);
	}

	bool significantvel = (vel.LengthSquared() > 1.0f && Maths::Abs(vel.x) > 0.2f);

	if (significantvel)
	{
		this.SetFacingLeft(vel.x < 0);
	}

	//TODO: make this work nicely :P
	//rotate based on velocity

	/*bool left = this.isFacingLeft();

	f32 oldangle = -this.getAngleDegrees();
	vel.y *= -0.5f;

	f32 angle = 0.0f;
	if(significantvel)
	{
		angle = -vel.Angle();
	}

	if(Maths::Abs(oldangle - angle) > 180.0f)
	{
		if(angle > oldangle)
			angle -= 360.0f;
		else
			oldangle -= 360.0f;
	}
	f32 change = oldangle - angle;

	f32 dif = (left?1:-1)*(Maths::Min(Maths::Abs(change) * 0.1f,10.0f));
	if(change > 0)
		oldangle += dif;
	else
		oldangle -= dif;

	this.setAngleDegrees(-oldangle);*/

}
