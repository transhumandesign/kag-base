// Ladder.as

#include "Hitters.as";
#include "HolidaySprites.as";

string gibs_file_name;

void onInit(CBlob@ this)
{
	this.Tag("ignore blocking actors");

	CShape@ shape = this.getShape();
	if (shape is null) return;

	shape.SetRotationsAllowed(false);
	shape.getVars().waterDragScale = 10.0f;

	ShapeConsts@ consts = shape.getConsts();
	if (consts is null) return;

	consts.collideWhenAttached = false;
	consts.waterPasses = true;
	consts.tileLightSource = true;
	consts.mapCollisions = false;
	
	gibs_file_name = isAnyHoliday() ? getHolidayVersionFileName("GenericGibs") : "GenericGibs.png";

	this.SetFacingLeft((this.getNetworkID() * 31) % 2 == 1);  //for ladders on map
	
	if (this.getName() == "ladder")
	{
		if (isServer())
		{
			dictionary harvest;
			harvest.set('mat_wood', 6);
			this.set('harvest', harvest);
		}
	}

	if (this.hasTag("cheated")) // spawned in using chat commands
	{
		shape.SetStatic(true); // stop from falling
		shape.SetGravityScale(0.0f);
		this.set_u16("timePlaced",0);
		this.Tag("fallen");
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("/build_ladder.ogg");
	this.getSprite().SetZ(-40);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 _damage = damage;
	
	if (customData == Hitters::builder)
	{
		_damage = 1.5f;
	}
	
	if (this.getHealth() - _damage < 0)
	{
		for (uint i = 0; i < 4; i++)
		{
			makeGibParticle(gibs_file_name, this.getPosition(), getRandomVelocity(-90.0f, 2.5f, 360.0f),
		              1, XORRandom(8), Vec2f(8, 8), 2.5f, 255, "", 0);
		}
	}
	
	return _damage;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}



