// Mine.as

#include "Hitters.as";
#include "Explosion.as";

const u8 MINE_PRIMING_TIME = 45;

const string MINE_STATE = "mine_state";
const string MINE_TIMER = "mine_timer";
const string MINE_PRIMING = "mine_priming";

enum State
{
	NONE = 0,
	PRIMED
};

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	
	if (shape !is null)
	{
		shape.getVars().waterDragScale = 16.0f;
		shape.getConsts().collideWhenAttached = true;
	}

	this.set_f32("explosive_radius", 32.0f);
	this.set_f32("explosive_damage", 8.0f);
	this.set_f32("map_damage_radius", 32.0f);
	this.set_f32("map_damage_ratio", 0.5f);
	this.set_bool("map_damage_raycast", true);
	this.set_string("custom_explosion_sound", "KegExplosion.ogg");
	this.set_u8("custom_hitter", Hitters::mine);

	this.Tag("ignore fall");
	this.Tag("ignore_saw");
	this.Tag(MINE_PRIMING);

	if (this.exists(MINE_STATE))
	{
		if (isClient())
		{
			CSprite@ sprite = this.getSprite();

			if (this.get_u8(MINE_STATE) == PRIMED)
			{
				sprite.SetFrameIndex(1);
			}
			else
			{
				sprite.SetFrameIndex(0);
			}
		}
	}
	else
	{
		this.set_u8(MINE_STATE, NONE);
	}

	this.set_u8(MINE_TIMER, 0);
	this.addCommandID("mine_primed_client");

	this.getCurrentScript().tickIfTag = MINE_PRIMING;
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached | Script::tick_not_ininventory;

}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		//tick down
		if (this.getVelocity().LengthSquared() < 1.0f && 
		   (this.isAttachedToPoint("MAG") || !this.isAttached()))
		{		
			u8 timer = this.get_u8(MINE_TIMER);
			timer++;
			this.set_u8(MINE_TIMER, timer);

			if (timer >= MINE_PRIMING_TIME)
			{
				this.Untag(MINE_PRIMING);

				if (this.isInInventory()) return;

				if (this.get_u8(MINE_STATE) == PRIMED) return;

				this.set_u8(MINE_STATE, PRIMED);

				this.getShape().checkCollisionsAgain = true;

				this.SendCommand(this.getCommandID("mine_primed_client"));
			}
		}
		//reset if bumped/moved
		else if (this.hasTag(MINE_PRIMING))
		{
			this.set_u8(MINE_TIMER, 0);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("mine_primed_client") && isClient())
	{
		this.set_u8(MINE_STATE, PRIMED);
		
		this.getShape().checkCollisionsAgain = true;

		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetFrameIndex(1);
			sprite.PlaySound("MineArmed.ogg");
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (this.get_u8(MINE_STATE) == PRIMED)
	{
		this.set_u8(MINE_STATE, NONE);
		this.getSprite().SetFrameIndex(0);
	}

	if (this.getDamageOwnerPlayer() is null || this.getTeamNum() != attached.getTeamNum())
	{
		CPlayer@ player = attached.getPlayer();
		if (player !is null)
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.Untag(MINE_PRIMING);

	if (this.get_u8(MINE_STATE) == PRIMED)
	{
		this.set_u8(MINE_STATE, NONE);
		this.getSprite().SetFrameIndex(0);
	}

	if (this.getDamageOwnerPlayer() is null || this.getTeamNum() != inventoryBlob.getTeamNum())
	{
		CPlayer@ player = inventoryBlob.getPlayer();
		if (player !is null)
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (isServer())
	{
		this.Tag(MINE_PRIMING);
		this.set_u8(MINE_TIMER, 0);
	}
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (isServer() && !this.isAttached())
	{
		this.Tag(MINE_PRIMING);
		this.set_u8(MINE_TIMER, 0);
	}
}

bool explodeOnCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() != blob.getTeamNum() &&
	(blob.hasTag("flesh") || blob.hasTag("projectile") || blob.hasTag("vehicle"));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (getNet().isServer() && blob !is null)
	{
		if (this.get_u8(MINE_STATE) == PRIMED && explodeOnCollideWithBlob(this, blob))
		{
			this.Tag("exploding");
			this.Sync("exploding", true);

			this.server_SetHealth(-1.0f);
			this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	if (getNet().isServer() && this.hasTag("exploding"))
	{
		const Vec2f POSITION = this.getPosition();

		CBlob@[] blobs;
		getMap().getBlobsInRadius(POSITION, this.getRadius() + 4, @blobs);
		for(u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ target = blobs[i];
			if (target.hasTag("flesh") &&
			(target.getTeamNum() != this.getTeamNum() || target.getPlayer() is this.getDamageOwnerPlayer()))
			{
				this.server_Hit(target, POSITION, Vec2f_zero, 8.0f, Hitters::mine_special, true);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return this.get_u8(MINE_STATE) != PRIMED || this.getTeamNum() == blob.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return customData == Hitters::builder? this.getInitialHealth() / 2 : damage;
}

void onRender(CSprite@ this)
{
	if (g_videorecording) return;

	//hover over primed mine to check if its my mine
	CBlob@ blob = this.getBlob();
	if (blob.getDamageOwnerPlayer() is getLocalPlayer())
	{
		Vec2f mouseWorldPos = getControls().getMouseWorldPos();
		Vec2f minePos = blob.getPosition();

		float radius = 10.0f;
		float distanceSq = (mouseWorldPos - minePos).LengthSquared();

		if (distanceSq < radius * radius)
		{
			blob.RenderForHUD(Vec2f_zero, RenderStyle::outline_front);
		}
	}
}
