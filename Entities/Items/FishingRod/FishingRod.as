// Fishing Rod script

const uint LINE_SEGMENTS 	= 1;	// number of nodes used in the fishing line (1 is minimum)
const uint LINE_THRESHOLD 	= 160;	// max distance between two nodes, used for determining if corrections should be made
const uint LINE_GIVE_STEP	= 6;	// line distance to give at a time
const uint LINE_TAKE_STEP	= 18;	// line distance to pull at a time
const uint LINE_COOLDOWN	= 4;	// ticks to wait until giving/pulling again
const bool DEBUG 			= false;

const string[] names_to_catch_priority	= {"bison", "shark"};	// these will not attach to the hook, but the hook attaches to them :)

const string[] names_to_catch = {"ctf_flag", "fishy", "mine", "bucket", "log", "keg", "sponge", "lantern", "drill", "food", 
"egg", "grain", "steak", "scroll", "crate", "boulder", "mat_bombs", "mat_waterbombs", "mat_arrows", "mat_firearrows", 
"mat_waterarrows", "mat_bombarrows", "mat_wood", "mat_stone", "mat_gold", "bomb"};

void onInit(CBlob@ this)
{
	this.Tag("no falldamage");
	this.Tag("medium weight");
	this.Tag("ignore_arrow");
	this.Tag("place norotate");
	this.Tag("dont deactivate");
	this.set_f32("gib health", -1.5f);
	this.set_netid("hooked id", 0);
	
	this.addCommandID("activate"); 	// Action3
	this.addCommandID("retract");	// Use
	
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	point.SetKeysToTake(key_action1 | key_action2);
	
	this.Tag("line gone");	// requirement for creating a line
	CreateLine(this);
}

void onTick(CBlob@ this)
{
	DisableWhenInWall(this);

	CBlob@ hook;
	float distance_to_next;
	float distance_limit;
	
	//int cooldown_temp = LINE_COOLDOWN - getGameTime() + this.get_u32("line_last_used");
	//uint cooldown = Maths::Max(cooldown_temp, 0);
	
	// check and adjust lines
	for (uint j = 0; j < LINE_SEGMENTS; j++)
	{	
		if (!this.exists("line_id" + j))	break;
	
		u16 line_to_give 	= this.get_u16("line_to_give" + j);
		u16 line_id 		= this.get_u16("line_id" + j);
		u16 line_id_next	= this.get_u16("line_id" + (j + 1));
		CBlob@ line 		= getBlobByNetworkID(line_id);
		CBlob@ nextline 	= getBlobByNetworkID(line_id_next);
		
		if (line is null || nextline is null)	
		{
			//in case the line somehow despawned, recreate the line
			if (!this.isOnWall())
			{
				DeleteLine(this);
				CreateLine(this);
			}
			
			break;
		}
				
		distance_to_next 		= nextline.getDistanceTo(line);
		distance_limit 		= LINE_THRESHOLD - line_to_give + ((nextline.hasTag("hook")) ? 8 : 0);
		
		if (!nextline.isAttached())
		{
			// before the correction calculation, make nextline a bit lower already, if no wall below. Hacky but yeah.
			Vec2f newpos = Vec2f(nextline.getPosition().x, nextline.getPosition().y + getMap().tilesize/2);
			if (!getMap().isTileSolid(newpos))
				nextline.setPosition(newpos);
			
			if (distance_to_next > distance_limit)
			{			
				// if nextline is too far from current line, make it closer
				float factor 		= (distance_to_next - distance_limit) / distance_to_next;
				Vec2f nextline_pos 	= nextline.getPosition();
				Vec2f line_pos		= line.getPosition();
				
				float correctionx = (nextline_pos.x - line_pos.x) * factor;
				float correctiony = (nextline_pos.y - line_pos.y) * factor;
				
				Vec2f nextline_newpos = Vec2f(nextline_pos.x - correctionx, nextline_pos.y - correctiony);
				uint putontile 	= getMap().isTileSolid(nextline_newpos) ? getMap().tilesize : 0;		// so lines don't end up in walls. Hacky but yeah.
				//uint putsideway	= getMap().isTileSolid(Vec2f(nextline_newpos.x, nextline_newpos.y + putontile)

				nextline.setPosition(Vec2f(nextline_newpos.x, nextline_newpos.y - putontile));
				nextline.setVelocity(Vec2f_zero);
			}
		}

		// save the position
		this.set_Vec2f("line_pos" + j, line.getPosition());
		
		// set angle of hook
		if (nextline.hasTag("hook"))	
		{
			@hook = @nextline;
		
			Vec2f hookpos = nextline.getPosition();
			Vec2f pos = line.getPosition();
			Vec2f vec = (pos - hookpos);
			vec.Normalize();
			f32 angle = vec.getAngleDegrees() - 90;
			nextline.setAngleDegrees(-angle); // set angle
			nextline.SetFacingLeft(this.isFacingLeft());
			nextline.setVelocity(Vec2f_zero);
			
			// save the hook position, too
			this.set_Vec2f("line_pos" + (j + 1), nextline.getPosition());
		}
	}
	
	if (this.isAttachedToPoint("PICKUP"))
	{
		AttachmentPoint@ pickup = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = pickup.getOccupied();
		
		if (holder !is null)
		{								
			bool not_in_cooldown = (this.get_u32("line_last_used") + LINE_COOLDOWN) < getGameTime(); 
			
			//send commands - check cooldown so as to not spam commands, even though the functions also check the cooldown
			if (holder.isKeyPressed(key_use) && not_in_cooldown)
			{
				this.SendCommand(this.getCommandID("retract"));
			}
			else if (holder.isKeyPressed(key_action3) && not_in_cooldown)
			{
				this.SendCommand(this.getCommandID("activate"));
			}
			
			//catch things
			if (hook !is null && isServer())
			{
				// add force and set facing if something is pulling at the hook
				if 	(hook.isAttached() 
					&& this.hasTag("catching heavy")) 	
				{
					bool holder_is_left = holder.getPosition().x < hook.getPosition().x;
	
					holder.SetFacingLeft(holder_is_left ? false : true);
					this.SetFacingLeft(holder_is_left ? false : true);
					hook.SetFacingLeft(holder_is_left ? false : true);
					CBlob@ hooked = getBlobByNetworkID(this.get_netid("hooked id"));
					
					if 	( hooked !is null
						&& this.getTickSinceCreated() % 10 == 0 
						&& distance_to_next > distance_limit)
					{
							//addforce
					}
					
				}
			
				if (!hook.isAttached() && !hook.hasAttached())
					this.Untag("catching heavy");
			
				CBlob@[] overlapping;
				hook.getOverlapping(overlapping);
				
				for (uint p = 0; p < overlapping.length; p++)
				{
					CBlob@ b = overlapping[p];
				
					if (b is this)	continue;	// hook overlapping with your own rod

					if (names_to_catch_priority.find(b.getName()) != -1)
					{
						// attach hook to this animal
						
						CAttachment@ a = b.getAttachments();
						if (a !is null)
						{
							AttachmentPoint@ ap = a.getAttachmentPointByName("MOUTH");
							if (ap is null)
							{
								@ap = a.AddAttachmentPoint("MOUTH", true);
								ap.offset = Vec2f(ap.offset.x + 12, ap.offset.y+4); //this will do for now
							}
							
							if (ap !is null && ap.getOccupied() is null)
							{
								b.server_AttachTo(hook, "MOUTH");
								this.set_netid("hooked id", b.getNetworkID());
							}
						}
						
						this.Tag("catching heavy");
					}
					
					if (names_to_catch.find(b.getName()) != -1)
					{
						// attach this thing to the hook
						CAttachment@ a = hook.getAttachments();
						if (a !is null)
						{
							AttachmentPoint@ ap = a.getAttachmentPointByName("HOOK");
							if (ap !is null && ap.getOccupied() is null
								&& !(b.getName() == "ctf_flag" && holder.getTeamNum() == b.getTeamNum()))
							{
								uint bteam = b.getTeamNum();
								hook.server_AttachTo(b, "HOOK");
								b.server_setTeamNum(bteam);		// workaround; this shouldn't be necessary...
								
								//maybe pulling animation if item is heavy?
								//this.getSprite().SetAnimation("pulling");
							}
						}
					}
				}
				
				if (this.hasTag("catching heavy") && this.getSprite().isAnimation("default"))
					this.getSprite().SetAnimation("pulling");
				else if (!this.hasTag("catching heavy") && this.getSprite().isAnimation("pulling"))
					this.getSprite().SetAnimation("default");
			}
			
			// rotated in hand
				Vec2f ray = holder.getAimPos() - this.getPosition();
				ray.Normalize();

				f32 angle = ray.Angle();
				angle = holder.isFacingLeft()? 135 : 45;
				angle -= 90;
				this.setAngleDegrees(-angle);
				
			// make sprite not flip based on mouse
			if (holder.isFacingLeft())
			{	
				this.getSprite().SetFacingLeft(true);
			}
			else
			{
				this.getSprite().SetFacingLeft(false);
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.name == "MAG")
		DeleteLine(this);
	else if (attachedPoint.name == "PICKUP")
		CreateLine(this);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.name == "PICKUP")
		this.setPosition(detached.getPosition());	// prevent throwing through walls

	//consider deleteLine here if nothing on hook
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		GiveLine(this);
	}
	else if (cmd == this.getCommandID("retract"))
	{
		RetractLine(this);
	}
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return true;
	// only if nothing on hook
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	DeleteLine(this);
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	CreateLine(this);
}

void onRender(CSprite@ this)
{
	// debug start
	
	if (DEBUG && this.getBlob().isAttachedToPoint("PICKUP"))
	{
		GUI::SetFont("menu");
		GUI::DrawText("(DEBUG)", Vec2f(10,0), SColor(255, 255, 255, 255));
		
		for (uint i = 0; i <= LINE_SEGMENTS; i++)
		{
			if (this.getBlob().exists("line_to_give" + i))
			{
				u16 linetogive = this.getBlob().get_u16("line_to_give" + i);
				GUI::DrawText("line to give (" + i + "): " + linetogive, Vec2f(10,10+i*10), SColor(255, 255, 255, 255));
			}
			
			if (this.getBlob().exists("line_pos" + i))
			{
				Vec2f lineposition = this.getBlob().get_Vec2f("line_pos" + i );
				GUI::DrawLine(Vec2f(lineposition.x - 3, lineposition.y - 3), Vec2f(lineposition.x + 3, lineposition.y + 3), SColor(255, 255, 255, 255));
				GUI::DrawLine(Vec2f(lineposition.x - 3, lineposition.y + 3), Vec2f(lineposition.x + 3, lineposition.y - 3), SColor(255, 255, 255, 255));
			}
			
		}
		
		CBlob@[] lineblobs;
		getBlobsByName("fishingrodline", lineblobs);
		
		u32 last_used = this.getBlob().get_u32("line_last_used");
		int val = LINE_COOLDOWN - getGameTime() + this.getBlob().get_u32("line_last_used");
		int cooldown = Maths::Max(val, 0);
		GUI::DrawText("rod cooldown : " + cooldown, Vec2f(10,60+LINE_SEGMENTS*10), SColor(255, 255, 255, 255));
		GUI::DrawText("rod last used : " + last_used, Vec2f(10,70+LINE_SEGMENTS*10), SColor(255, 255, 255, 255));
		GUI::DrawText("fishing lines spawned : " + lineblobs.length, Vec2f(10,80+LINE_SEGMENTS*10), SColor(255, 255, 255, 255));
	}

	// debug end

	if (!isServer() || this.getBlob().hasTag("line gone"))	return;

	// draw fishing line, from the line piece that's attached to the rod, to the hook
	
	Vec2f linepos = this.getBlob().get_Vec2f("line_pos0");
	Vec2f nextpos = this.getBlob().get_Vec2f("line_pos" + LINE_SEGMENTS);
	Vec2f nextpos2 = Vec2f(nextpos.x, nextpos.y-2);
	Vec2f h1 = Vec2f(linepos.x, linepos.y + 10);
	Vec2f h2 = Vec2f(nextpos.x, nextpos.y);

	GUI::DrawSpline(linepos, nextpos2, h1, h2, 8, SColor(55, 160, 160, 160));
}

void onDie(CBlob@ this)
{
	DeleteLine(this);
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 2.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	CParticle@ Body		= makeGibParticle("FishingRod.png", pos, vel + getRandomVelocity(90, hp , 80), 1, 2, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Arm		= makeGibParticle("FishingRod.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 2, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Shield	= makeGibParticle("FishingRod.png", pos, vel + getRandomVelocity(90, hp , 80), 3, 2, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}

void GiveLine(CBlob@ this)
{
	if 	(this.hasTag("line gone") 
		|| (this.get_u32("line_last_used") + LINE_COOLDOWN) > getGameTime())	
	{
		return;
	}

	uint line_give_step = LINE_GIVE_STEP;

	for (int i = LINE_SEGMENTS - 1; i >= 0; i--)
	{
		u16 line_to_give 	= this.get_u16("line_to_give" + i);
		
		while (line_to_give > 0 && line_give_step > 0)
		{
			line_to_give--;
			line_give_step--;			
		}

		uint new_value = Maths::Max(line_to_give - line_give_step, 0);
		this.set_u16("line_to_give" + i, new_value);
		this.set_u32("line_last_used", getGameTime());
			
		// play sound of giving line
			
		if (line_give_step == 0)	break;
	}
	if (line_give_step > 0)
		this.getSprite().PlaySound("/SpinningReelStuck.ogg");
	else
		this.getSprite().PlaySound("/SpinningReel.ogg");
}

void RetractLine(CBlob@ this)
{
	if 	(this.hasTag("line gone") 
		|| (this.get_u32("line_last_used") + LINE_COOLDOWN) > getGameTime())	
	{
		return;
	}

	uint line_take_step = LINE_TAKE_STEP;

	for (int i = 0; i < LINE_SEGMENTS; i++)
	{
		u16 line_to_give 	= this.get_u16("line_to_give" + i);
		
		while (line_to_give < LINE_THRESHOLD && line_take_step > 0)
		{
			line_to_give++;
			line_take_step--;			
		}

		uint new_value = Maths::Min(line_to_give + line_take_step, LINE_THRESHOLD);
		this.set_u16("line_to_give" + i, new_value);
		this.set_u32("line_last_used", getGameTime());
			
		if (line_take_step == 0)	break;
	}
	
	//if (line_take_step > 0)
	//	this.getSprite().PlaySound("/SpinningReelStuck.ogg");
	//else
	if (line_take_step == 0 )
		this.getSprite().PlaySound("/SpinningReelPull.ogg");
}

void DeleteLine(CBlob@ this)
{
	if (this.hasTag("line gone") || !isServer())	return;
	
	// delete all line segments and hook	
	for (uint i = 0; i <= LINE_SEGMENTS; i++)
	{	
		u16 line_id 		= this.get_u16("line_id" + i);
		CBlob@ line 		= getBlobByNetworkID(line_id);
				
		if (line !is null)
			line.server_Die();	
	}

	this.Tag("line gone");
}

void CreateLine(CBlob@ this)
{
	if (!this.hasTag("line gone") || !isServer())	return;

	Vec2f rodpos = this.getPosition();
	uint team = this.getTeamNum();
	
	for (uint i = 0; i <= LINE_SEGMENTS; i++)
	{	
		CBlob@ line = server_CreateBlob("fishingrodline");

		if (line !is null)
		{
			line.Tag("rod exists");
			line.Tag("ignore_arrow");
			line.Tag("ignore fall");
			line.Tag("ignore_saw");
			line.getShape().getConsts().collidable = false;
			line.getShape().getConsts().collideWhenAttached = false;
			line.setPosition(Vec2f(rodpos.x, rodpos.y-16));
			line.getSprite().SetVisible(false);
			this.set_u16("line_id" + i, line.getNetworkID());
			this.set_u16("line_to_give" + i, LINE_THRESHOLD);
			
			if (i == 0) 	// first segment - attach to tip of rod
			{	
				line.server_setTeamNum(team);	// workaround; this shouldn't be necessary. server_AttachTo changes team of "this" for reasons I don't know.
				this.server_AttachTo(line, "TIP");
			}
			else if (i == LINE_SEGMENTS) 	// last segment - make it a hook
			{
				line.Tag("hook");
				Animation@ animation = line.getSprite().getAnimation("default");
				if (animation !is null)
				{
					animation.SetFrameIndex(2);
				}
				line.getSprite().SetVisible(true);
				
				CAttachment@ a = line.getAttachments();

				if (a !is null)
				{
					a.AddAttachmentPoint("HOOK", true);
				}
				
				this.set_u16("hook_id" + i, line.getNetworkID());
			}
		}
	}
	
	this.set_u32("line_last_used", getGameTime());
	this.Untag("line gone");
}

void DisableWhenInWall(CBlob@ this)
{
	if (this.isOnWall())
	{
		DeleteLine(this);
	}
	else
	{
		CreateLine(this);
	}
}

// TODO:
/*
	- Pulled animals should addforce rod
	- Pulled animals should ESCAPE
	- animals not on hook should go to hook
	- Animals reacting to the hook and biting on it; Maybe with bait only?
	- check if line is drawn in online dedicated server, if enemy is holding it or you are holding.
	- item on hook should detach from hook if picked up

issues:
	- if rod is offscreen, line isn't drawn - fix this by running onrender for the hook, too.
	- make hook to not get stuck in wall if moving it sideways into a wall
	- ability to throw the hook or make rod swing out
	- server_AttachTo() changes rod's team num for no reason; workaround is in place.
	- make rod not to fall through platform
	- if enemy ctf flag is on hook, timer isn't running. Should change that in the ctf_flag logic, maybe.
*/