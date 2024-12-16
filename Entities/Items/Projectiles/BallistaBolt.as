// Blame Fuzzle.

#include "Hitters.as";
#include "ShieldCommon.as";
#include "LimitedAttacks.as";
#include "Explosion.as";
#include "DoorCommon.as";

const f32 MEDIUM_SPEED = 9.0f;
const f32 FAST_SPEED = 16.0f;
// Speed required to pierce Wooden tiles.

void onInit(CBlob@ this)
{
	this.set_u8("blocks_pierced", 0);
	this.set_bool("static", false);

	this.server_SetTimeToDie(20);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

	LimitedAttack_setup(this);

	u32[] offsets;
	this.set("offsets", offsets);
	// Offsets of the tiles that have been hit.

	this.Tag("projectile");
	this.getSprite().getConsts().accurateLighting = true;
	this.getSprite().SetFacingLeft(!this.getSprite().isFacingLeft());

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
 
	// weird ass workaround
	this.getSprite().SetFrame(this.hasTag("bomb ammo") ? 1 : 0);
}

void onTick(CBlob@ this)
{
	f32 angle = 0;

	if (!this.get_bool("static"))
	{

		Vec2f velocity = this.getVelocity();
		angle = velocity.Angle();

		Pierce(this, velocity, angle);

		if (this.hasTag("bomb ammo") && !this.hasTag("bomb"))
		{

			this.set_bool("map_damage_raycast", false);
			this.set_f32("map_damage_radius", 24.0f);

			this.Tag("bomb");
			this.getSprite().SetFrame(1);
		}
	}
	else
	{

		angle = Maths::get360DegreesFrom256(this.get_u8("angle"));

		this.setVelocity(Vec2f_zero);
		this.setPosition(Vec2f(this.get_f32("lock_x"), this.get_f32("lock_y")));
		this.getShape().SetStatic(true);
		//this.doTickScripts = false;

		// checking if blob or tile we stick to has disappeared or become non-solid
		if (this.exists("hitBlob") && this.get_bool("should_check_hitBlob"))
		{
			CBlob@ gottenBlob = getBlobByNetworkID(this.get_u32("hitBlob"));

			if (gottenBlob is null) // blob is gone
			{
				SetNonStatic(this);
			}
			else 
			{
				string n = gottenBlob.getName();
				bool isOpened = (isOpen(gottenBlob) && (n.find("door") != -1 || n == "bridge" || n == "trap_block"));
				
				if (gottenBlob.hasTag("fallen") || isOpened) // structure blob is collapsing or is an opening door/bridge/trap
				{
					SetNonStatic(this);
				}
			}
		}
		else if (this.exists("tileWorldPoint") && this.get_bool("should_check_tileWorldPoint"))
		{
			CMap@ map = getMap();
			
			Vec2f hitpos = this.get_Vec2f("tileWorldPoint");
			Tile hitTile = map.getTile(hitpos);
			
			if (!map.isTileSolid(hitTile))
			{
				SetNonStatic(this);
			}
		}
	}
	
	this.setAngleDegrees(-angle + 180.0f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CBlob@ carrier = blob.getCarriedBlob();

	if (carrier !is null)
		if (carrier.hasTag("player")
		        && (this.getTeamNum() == carrier.getTeamNum() || blob.hasTag("temp blob")))
			return false;

	return (this.getTeamNum() != blob.getTeamNum() || blob.getShape().isStatic())
	       && blob.isCollidable();
}

void Pierce(CBlob@ this, Vec2f velocity, const f32 angle)
{
	CMap@ map = this.getMap();

	const f32 speed = velocity.getLength();
	const f32 damage = speed > MEDIUM_SPEED ? 4.0f : 3.5f;

	Vec2f direction = velocity;
	direction.Normalize();

	Vec2f position = this.getPosition();
	Vec2f tip_position = position + direction * 12.0f;
	Vec2f middle_position = position + direction * 6.0f;
	Vec2f tail_position = position - direction * 12.0f;

	Vec2f[] positions =
	{
		position,
		tip_position,
		middle_position,
		tail_position
	};

	// hitting map
	for (uint i = 0; i < positions.length; i ++)
	{
		Vec2f temp_position = positions[i];
		TileType type = map.getTile(temp_position).type;

		if (map.isTileSolid(type))
		{

			u32[]@ offsets;
			this.get("offsets", @offsets);
			const u32 offset = map.getTileOffset(temp_position);

			if (offsets.find(offset) != -1)
				continue;

			BallistaHitMap(this, offset, temp_position, velocity, damage, Hitters::ballista);
			this.server_HitMap(temp_position, velocity, damage, Hitters::ballista);
		}
	}

	// hitting blob, but only at 1.5f or higher velocity
	if (this.getShape().vellen < 1.5f)
		return;
	
	HitInfo@[] infos;

	if (speed > 0.1f && map.getHitInfosFromArc(tail_position, -angle, 10, (tip_position - tail_position).getLength(), this, true, @infos))
	{
		for (uint i = 0; i < infos.length; i ++)
		{
			CBlob@ blob = infos[i].blob;
			Vec2f hit_position = infos[i].hitpos;

			if (blob !is null)
			{
				if (blob.getShape().getConsts().platform && !CollidesWithPlatform(this, blob, velocity))
					continue;

				if (!doesCollideWithBlob(this, blob) || LimitedAttack_has_hit_actor(this, blob))
					continue;

				this.server_Hit(blob, hit_position, velocity, damage, Hitters::ballista, true);
				BallistaHitBlob(this, hit_position, velocity, damage, blob, Hitters::ballista);
				LimitedAttack_add_actor(this, blob);
			}
		}
	}
}

bool DoExplosion(CBlob@ this, Vec2f velocity)
{
	if (this.hasTag("bomb"))
	{
		if (this.hasTag("dead"))
			return true;

		Explode(this, 16.0f, 2.0f);
		LinearExplosion(this, velocity, 64.0f, 8.0f, 2, 4.0f, Hitters::bomb);

		this.Tag("dead");
		this.server_Die();
		this.getSprite().Gib();

		return true;
	}

	return false;
}

void BallistaHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, const f32 damage, CBlob@ blob, u8 customData)
{
	if (DoExplosion(this, velocity)
	        || this.get_bool("static"))
		return;

	if (blob.hasTag("flesh"))
		this.getSprite().PlaySound("ArrowHitFleshFast.ogg");
	else this.getSprite().PlaySound("ArrowHitGroundFast.ogg");

	if (!blob.getShape().isStatic())
		return;

	if (blob.getHealth() > 0.0f)
	{
		const f32 angle = velocity.Angle();
		bool isStatic = false;

		if (blob.hasTag("wooden"))
		{
			this.setVelocity(velocity * 0.5f);

			u8 blocks_pierced = this.get_u8("blocks_pierced");
			const f32 speed = velocity.getLength();

			if (blocks_pierced < 1 && speed > FAST_SPEED)
			{
				this.set_u8("blocks_pierced", blocks_pierced + 1);
			}
			else 
			{
				isStatic = true;
				SetStatic(this, angle);
			}
		}
		else 
		{
			isStatic = true;
			SetStatic(this, angle);
		}
		
		// saving information on what was hit to determine when the ballista bolt should collapse
		if (isServer() && isStatic)
		{
			this.set_u32("hitBlob", blob.getNetworkID());
			this.set_bool("should_check_hitBlob", true);
		}
	}
	else 
	{
		this.setVelocity(velocity * 0.7f);
	}
}

void BallistaHitMap(CBlob@ this, const u32 offset, Vec2f hit_position, Vec2f velocity, const f32 damage, u8 customData)
{
	if (DoExplosion(this, velocity)
	        || this.get_bool("static"))
		return;

	this.getSprite().PlaySound("ArrowHitGroundFast.ogg");

	CMap@ map = getMap();
	TileType type = map.getTile(offset).type;
	const f32 angle = velocity.Angle();
	bool isStatic = false;

	if (type == CMap::tile_bedrock)
	{

		this.Tag("dead");
		this.server_Die();
		this.getSprite().Gib();

	}
	else if (!map.isTileGroundStuff(type))
	{

		if (map.getSectorAtPosition(hit_position, "no build") is null)
			map.server_DestroyTile(hit_position, 1.0f, this);

		u8 blocks_pierced = this.get_u8("blocks_pierced");
		const f32 speed = velocity.getLength();

		this.setVelocity(velocity * 0.5f);
		this.push("offsets", offset);

		if (blocks_pierced < 1 && speed > FAST_SPEED
		        && map.isTileWood(type))
		{
			this.set_u8("blocks_pierced", blocks_pierced + 1);
		}
		else 
		{
			isStatic = true;
			SetStatic(this, angle);
		}
	}
	else if (map.isTileSolid(type))
	{
		isStatic = true;
		SetStatic(this, angle);
	}
	
	// saving information on what was hit to determine when the ballista bolt should collapse
	if (isStatic && isServer())
	{
		this.set_Vec2f("tileWorldPoint", hit_position);
		this.set_bool("should_check_tileWorldPoint", true);
	}
}

void SetStatic(CBlob@ this, const f32 angle)
{
	Vec2f position = this.getPosition();

	this.set_u8("angle", Maths::get256DegreesFrom360(angle));
	this.set_bool("static", true);
	this.set_f32("lock_x", position.x);
	this.set_f32("lock_y", position.y);

	this.Sync("static", true);
	this.Sync("lock_x", true);
	this.Sync("lock_y", true);

	this.setVelocity(Vec2f_zero);
	this.setPosition(position);
	this.getShape().SetStatic(true);
	
	this.getShape().getVars().isladder = true;

	//this.getCurrentScript().runFlags |= Script::remove_after_this;
}

void SetNonStatic(CBlob@ this)
{
	//this.set_u8("angle", Maths::get256DegreesFrom360(angle));
	//this.set_u8("angle", 180);
	
	this.set_bool("static", false);
	this.set_bool("should_check_tileWorldPoint", false);
	this.set_bool("should_check_hitBlob", false);
	
	this.Sync("static", true);
	this.Sync("should_check_tileWorldPoint", true);
	this.Sync("should_check_hitBlob", true);
	
	this.setVelocity(Vec2f_zero);
	this.getShape().SetStatic(false);
	
	this.getShape().getVars().isladder = false;

	//this.getCurrentScript().runFlags |= Script::remove_after_this;
}

bool CollidesWithPlatform(CBlob@ this, CBlob@ blob, Vec2f velocity)
{
	f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}

