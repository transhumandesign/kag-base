// Flamer.as

#include "MechanismsCommon.as";
#include "Hitters.as";
#include "ArcherCommon.as";
#include "ArrowCommon.as";
#include "FireplaceCommon.as";
#include "MakeFood.as";
#include "ProductionCommon.as";

const u16 waterHitWaitTime = 30;

class Flamer : Component
{
	u16 id;
	Vec2f offset;

	Flamer(Vec2f position, u16 netID, Vec2f _offset)
	{
		x = position.x;
		y = position.y;

		id = netID;
		offset = _offset;
	}

	void Activate(CBlob@ this)
	{
		UpdateState(this, 1);
		this.Tag("activated");
		this.set_u8("delayed start", 10);
	 }

	void Deactivate(CBlob@ this)
	{
		UpdateState(this, 0);
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by KnightLogic.as
	this.Tag("blocks sword");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_castle_back);
	
	//this.getCurrentScript().tickFrequency = 3; // arrow igniting requires frequency of 1
	this.getCurrentScript().tickIfTag = "activated";
	this.SetLightRadius(55.0f);
	this.SetLight(false);
	this.getSprite().SetEmitSound("Flamer.ogg");
	this.getSprite().SetEmitSoundPaused(true);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;
	const u16 angle = this.getAngleDegrees();
	const Vec2f offset = Vec2f(0, -1).RotateBy(angle);

	Flamer component(position, this.getNetworkID(), offset);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_NONE,                          // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetZ(500);
	sprite.SetFacingLeft(false);
	
	this.set_Vec2f("offset", offset);
}

void onTick(CBlob@ this)
{
	u8 state = this.get_u8("state");

	if (state == 1)
	{
		CreateFlame(this);
		
		bool active = !this.hasTag("underwater") && !this.get_bool("blocked");
		
		this.SetLight(active ? true : false);
		this.getSprite().SetEmitSoundPaused(active ? false : true);
	}
	else
	{
		this.SetLight(false);
		this.getSprite().SetEmitSoundPaused(true);
		this.Untag("activated");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isWaterHitter(customData))
	{
		if (this.exists("blocked") && !this.get_bool("blocked"))
		{
			this.getSprite().PlaySound("/ExtinguishFire.ogg");
			this.set_u32("last water hit", getGameTime());
		}
	}

	return damage;
}

void CreateFlame(CBlob@ this)
{
	bool blocked 	= false;
	CMap@ map		= getMap();
	Vec2f offset 	= this.get_Vec2f("offset"); 
	Vec2f pos 		= this.getPosition() + offset * map.tilesize * 0.6f; 	// fire emit position
	Vec2f pos2 		= this.getPosition() + offset * map.tilesize; 			// offset center position

	// exit is blocked, don't show particles
    if (map.rayCastSolid(pos + offset, pos + offset)) // moves one pixel in offset's direction
	{	
		Tile tile			= map.getTile(pos);
		TileType tileType 	= tile.type;
		
		if (map.isTileWood(tileType) || ((tile.flags & Tile::FLAMMABLE) != 0))
			map.server_setFireWorldspace(pos, true);
			
		blocked = true;
	}
	else if (map.isInWater(pos))
	{
		if (!this.hasTag("underwater"))
			this.getSprite().PlaySound("/ExtinguishFire.ogg");
	
		this.Tag("underwater");
		blocked = true;
	}
	else 
	{
		this.Untag("underwater");
		
		TileType t = map.getTile(pos).type;
		
		if (map.isTileGrass(t))
			map.server_setFireWorldspace(pos, true);
			
		// also burn the block that is one tile beyond the exit
		Vec2f worldspace;
		
		Vec2f pos_one_tile_further = pos + offset * map.tilesize;
		TileType t2 = map.getTile(pos_one_tile_further).type;
				
		if (map.isTileWood(t2) || map.isTileGrass(t2))
			map.server_setFireWorldspace(pos_one_tile_further, true);
	}
		
	// fire particles
	u32 ticksSinceWaterHit 	= getGameTime() - this.get_u32("last water hit");
	bool shouldBurn = ticksSinceWaterHit > waterHitWaitTime && !blocked;
	
	if (shouldBurn && this.getTickSinceCreated() % 3 == 0)
	{	
		// calculate deviation and velocity
		f32 deviation = (XORRandom(100) - 50) / 20.0f;
		Vec2f velocity = offset;
		velocity.RotateBy(deviation);
		velocity *= 1.0f;
	
		// flame particle
		CParticle@ p = ParticleAnimated(
		"FlamerParticle.png", 	// file name
		pos, 					// position
		velocity, 			// velocity
		XORRandom(360), 	// rotation
		1.0f, 				// scale
		3,					// ticks per frame
		-0.025f,			// gravity
		true);				// self lit
		
		if (p !is null)
		{
			p.diesoncollide	= true;
			p.fastcollision	= true;
			p.lighting 		= true;
		}
	}
	
	// save blocked status for usage in onHit()
	this.set_bool("blocked", blocked);
	
	// checks to see if we should apply burning to blobs
	if (!shouldBurn)
	{ 
		this.set_u8("delayed start", 10);
		return; 
	}
	else 
	{
		u8 delayTimer = this.get_u8("delayed start");
		
		if (delayTimer > 0)	
		{
			delayTimer--;
			this.set_u8("delayed start", delayTimer);
			return; 
		}
	}
	
	// checks are passed, applying burning to blobs now
	CBlob@[] blobs;
	map.getBlobsInRadius(pos2, 7.5f, @blobs);
	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		
		if (blob is null 
			|| blob is this
			|| blob.isInWater())	
		{
			continue;
		}

		//ignite arrows in a radius of 7.5
		if (blob.getName() == "arrow"
			&& this.get_u8("arrow type") == ArrowType::normal
			&& !blob.getSprite().isAnimation("fire")
			&& blob.getTickSinceCreated() > 1)
			{
				turnOnFire(blob); // ArrowCommon.as
				break;
			}
		
		//do something else with the other blobs if they are within radius 3.7
		// ignite fireplace, cook food and apply damage
		else 
		{
			Vec2f distance = pos2 - blob.getPosition();
			f32 p = distance.Length() - blob.getRadius() - 3.7f;
		
			if (p < 0)
			{
				if (blob.getName() == "fireplace" 
					&& !blob.getSprite().isAnimation("fire")) // ignite fireplace
				{
					Ignite(blob); // FireplaceCommon.as
				}
				else if (isServer())
				{
					cookFood(blob);
					
					if (!blob.hasTag("invincible"))
					{
						blob.server_Hit(blob, blob.getPosition(), blob.getVelocity(), 0.0f, Hitters::fire);
						blob.set_s16("burn timer", Maths::Ceil(blob.get_s16("burn timer") * 0.75f)); // slightly decrease fire duration
					}
				}
			}
		}
	}
}

void UpdateState(CBlob@ this, u8 state)
{
	this.set_u8("state", state);
		
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetFrameIndex(state);
}
