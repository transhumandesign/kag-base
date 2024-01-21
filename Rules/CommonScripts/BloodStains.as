
#define CLIENT_ONLY

#include "Hitters.as";

const u16 blood_stain_lifetime = 900; // 30 sec

class BloodStain
{
	u32 tileOffset;
	u8 frame;
	u16 endTime;
}

void onInit(CRules@ this)
{
	// reset?
	
	CMap@ map = getMap();
	
	if (map !is null)
	{
		if (!map.hasScript("BloodStains.as")) 
			map.AddScript("BloodStains.as");
	}
}

void AddBloodStain(CRules@ this, uint tile_offset, u8 frame)
{
	if (!this.exists("blood stains"))
	{
		//print("creating blood stains array in rules");
	
		BloodStain[] blood_stains;
		this.set("blood stains", blood_stains);
	}
	
	// print("adding a stain");
	
	BloodStain b;
	b.tileOffset = tile_offset;
	b.frame = frame;
	b.endTime = getGameTime() + blood_stain_lifetime;
	this.push("blood stains", b);
}

void onTick(CRules@ this)
{
	//check if blood stains expired	
	if (getGameTime() % 60 == 0)
	{
		BloodStain[] blood_stains;
		this.get("blood stains", blood_stains);
		
		if (blood_stains.size() == 0)	return;
		
		//print("blood stains count: " + blood_stains.size());
		
		for (s16 i = blood_stains.size() - 1; i >= 0; i--)
		{
			BloodStain bs = blood_stains[i];
			
			if (bs is null) continue;
			
			if (getGameTime() > bs.endTime)
			{
				this.removeAt("blood stains", i);
				
				//print("removing a stain");
			}
		}
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	CBlob@ victimBlob = victim.getBlob();

	if (victimBlob is null)
		return;
		
	if (!(customData == Hitters::suicide || customData == Hitters::sword || customData == Hitters::bomb || customData == Hitters::explosion 
		|| customData == Hitters::keg || customData == Hitters::mine || customData == Hitters::mine_special || customData == Hitters::saw))
	{
		return;
	}
		
	CMap@ map = getMap();
	Vec2f victimPos = victimBlob.getPosition();
	Vec2f victimPosBottom = victimBlob.getPosition() + Vec2f(0, victimBlob.getHeight() / 2);
	Vec2f victimPosLeft = victimBlob.getPosition() - Vec2f(victimBlob.getWidth() / 2, 0);
	Vec2f victimPosRight = victimBlob.getPosition() + Vec2f(victimBlob.getWidth() / 2, 0);
	Vec2f victimPosTop = victimBlob.getPosition() - Vec2f(0, victimBlob.getHeight() / 2);
		
	checkGround(this, victimPosBottom, map);
	checkLeftWall(this, victimPosLeft, map);
	checkRightWall(this, victimPosRight, map);
	checkCeiling(this, victimPosTop, map);
}

void checkGround(CRules@ rules, Vec2f victimPos, CMap@ map)
{
	Vec2f left 			= victimPos + Vec2f(-map.tilesize, map.tilesize);
	Vec2f above_left 	= victimPos + Vec2f(-map.tilesize, 0);
	Vec2f center 		= victimPos + Vec2f(0, map.tilesize);
	Vec2f above_center 	= victimPos;
	Vec2f right 		= victimPos + Vec2f(map.tilesize, map.tilesize);;
	Vec2f above_right 	= victimPos + Vec2f(map.tilesize, 0);;
	
	bool left_available = map.isTileSolid(left) && !map.isTileSolid(above_left);
	bool center_available = map.isTileSolid(center) && !map.isTileSolid(above_center);
	bool right_available = map.isTileSolid(right) && !map.isTileSolid(above_right);
	
	Vec2f tilePos;
	u32 tile_offset;
	u8 frame;
	u8 rndm = XORRandom(5);
		
	if (left_available)
	{
		tilePos 	= left;
		tile_offset = getMap().getTileOffset(tilePos);
		frame 		= 0 + rndm * 11;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (center_available)
	{
		tilePos 	= center;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 1 + rndm * 11;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (right_available)
	{
		tilePos 	= right;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 2 + rndm * 11;
		AddBloodStain(rules, tile_offset, frame);
	}
}

void checkCeiling(CRules@ rules, Vec2f victimPos, CMap@ map)
{
	Vec2f left 			= victimPos + Vec2f(-map.tilesize, -map.tilesize);
	Vec2f below_left 	= victimPos + Vec2f(-map.tilesize, 0);
	Vec2f center 		= victimPos + Vec2f(0, -map.tilesize);
	Vec2f below_center 	= victimPos;
	Vec2f right 		= victimPos + Vec2f(map.tilesize, -map.tilesize);;
	Vec2f below_right 	= victimPos + Vec2f(map.tilesize, 0);;

	bool left_available = map.isTileSolid(left) && !map.isTileSolid(below_left);
	bool center_available = map.isTileSolid(center) && !map.isTileSolid(below_center);
	bool right_available = map.isTileSolid(right) && !map.isTileSolid(below_right);
	
	Vec2f tilePos;
	u32 tile_offset;
	u8 frame;
	u8 rndm = XORRandom(5);

	if (left_available)
	{
		tilePos 	= left;
		tile_offset = getMap().getTileOffset(tilePos);
		frame 		= 3 + rndm * 11;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (center_available)
	{
		tilePos 	= center;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 4 + rndm * 11;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (right_available)
	{
		tilePos 	= right;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 5 + rndm * 11;
		AddBloodStain(rules, tile_offset, frame);
	}
}

void checkLeftWall(CRules@ rules, Vec2f victimPos, CMap@ map)
{
	Vec2f top 				= victimPos + Vec2f(-map.tilesize, -map.tilesize);
	Vec2f right_of_top 		= victimPos + Vec2f(0, -map.tilesize);
	Vec2f center 			= victimPos + Vec2f(-map.tilesize, 0);
	Vec2f right_of_center 	= victimPos;
	Vec2f bottom 			= victimPos + Vec2f(-map.tilesize, map.tilesize);
	Vec2f right_of_bottom 	= victimPos + Vec2f(0, map.tilesize);

	bool top_available = map.isTileSolid(top) && !map.isTileSolid(right_of_top);
	bool center_available = map.isTileSolid(center) && !map.isTileSolid(right_of_center);
	bool bottom_available = map.isTileSolid(bottom) && !map.isTileSolid(right_of_bottom);

	Vec2f tilePos;
	u32 tile_offset;
	u8 frame;
	u8 rndm = XORRandom(5);
		
	if (top_available)
	{
		tilePos 	= top;
		tile_offset = getMap().getTileOffset(tilePos);
		frame 		= 7 + rndm;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (center_available)
	{
		tilePos 	= center;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 18 + rndm;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (bottom_available)
	{
		tilePos 	= bottom;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 29 + rndm;
		AddBloodStain(rules, tile_offset, frame);
	}
}

void checkRightWall(CRules@ rules, Vec2f victimPos, CMap@ map)
{
	Vec2f top 				= victimPos + Vec2f(map.tilesize, -map.tilesize);
	Vec2f left_of_top 		= victimPos + Vec2f(0, -map.tilesize);
	Vec2f center 			= victimPos + Vec2f(map.tilesize, 0);
	Vec2f left_of_center 	= victimPos;
	Vec2f bottom 			= victimPos + Vec2f(map.tilesize, map.tilesize);
	Vec2f left_of_bottom 	= victimPos + Vec2f(0, map.tilesize);

	bool top_available = map.isTileSolid(top) && !map.isTileSolid(left_of_top);
	bool center_available = map.isTileSolid(center) && !map.isTileSolid(left_of_center);
	bool bottom_available = map.isTileSolid(bottom) && !map.isTileSolid(left_of_bottom);

	Vec2f tilePos;
	u32 tile_offset;
	u8 frame;
	u8 rndm = XORRandom(5);
		
	if (top_available)
	{
		tilePos 	= top;
		tile_offset = getMap().getTileOffset(tilePos);
		frame 		= 39 + rndm;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (center_available)
	{
		tilePos 	= center;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 50 + rndm;
		AddBloodStain(rules, tile_offset, frame);
	}
	
	if (bottom_available)
	{
		tilePos 	= bottom;
		tile_offset = getMap().getTileOffset(tilePos);
		frame		= 61 + rndm;
		AddBloodStain(rules, tile_offset, frame);
	}
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	// remove stain when tile is destroyed
	if (!this.isTileSolid(newtile) && this.isTileSolid(oldtile))
	{	
		BloodStain[] blood_stains;
		CRules@ rules = getRules();
		rules.get("blood stains", blood_stains);
		
		if (blood_stains.size() == 0)	return;
		
		for (s16 i = blood_stains.size() - 1; i >= 0; i--)
		{
			BloodStain bs = blood_stains[i];
			
			if (bs is null) continue;
			
			if (index == bs.tileOffset)
			{
				rules.removeAt("blood stains", i);
			}
		}
	}
}

bool onMapTileCollapse(CMap@ this, u32 offset)
{
	BloodStain[] blood_stains;
	CRules@ rules = getRules();
	rules.get("blood stains", blood_stains);
	
	if (blood_stains.size() == 0)	return true;
	
	for (s16 i = blood_stains.size() - 1; i >= 0; i--)
	{
		BloodStain bs = blood_stains[i];
		
		if (bs is null) continue;
		
		if (offset == bs.tileOffset)
		{
			rules.removeAt("blood stains", i);
		}
	}
	return true;
}

void onRender(CRules@ this)
{
	if (g_kidssafe) return;

	BloodStain[] blood_stains;
	this.get("blood stains", blood_stains);
	
	for (u16 i = 0; i < blood_stains.size(); i++)
	{
		BloodStain bs = blood_stains[i];
		
		if (bs is null) continue;
		
		Vec2f tile_pos = getMap().getTileWorldPosition(bs.tileOffset);
		Driver@ driver = getDriver();
		
		float scale 	= getCamera().targetDistance * driver.getResolutionScaleFactor();
		Vec2f pos 		= driver.getScreenPosFromWorldPos(tile_pos);
		u8 frame		= bs.frame;

		GUI::DrawIcon("BloodStains.png", frame, Vec2f(8, 8), pos, scale);
	}
}

	


