// generic character head script

const s32 NUM_HEADFRAMES = 4;
const s32 NUM_UNIQUEHEADS = 30;
const int FRAMES_WIDTH = 8 * NUM_HEADFRAMES;

int getHeadFrame(CBlob@ blob, int headIndex)
{
	if(headIndex < NUM_UNIQUEHEADS)
	{
		return headIndex * NUM_HEADFRAMES;
	}

	if(headIndex == 255 || headIndex == NUM_UNIQUEHEADS)
	{
		CRules@ rules = getRules();
		bool holidayhead = false;
		if(rules !is null && rules.exists("holiday"))
		{
			const string HOLIDAY = rules.get_string("holiday");
			if(HOLIDAY == "Halloween")
			{
				headIndex = NUM_UNIQUEHEADS + 43;
				holidayhead = true;
			}
			else if(HOLIDAY == "Christmas")
			{
				headIndex = NUM_UNIQUEHEADS + 61;
				holidayhead = true;
			}
		}

		//if nothing special set
		if(!holidayhead)
		{
			string config = blob.getConfig();
			if(config == "builder")
			{
				headIndex = NUM_UNIQUEHEADS;
			}
			else if(config == "knight")
			{
				headIndex = NUM_UNIQUEHEADS + 1;
			}
			else if(config == "archer")
			{
				headIndex = NUM_UNIQUEHEADS + 2;
			}
			else if(config == "migrant")
			{
				Random _r(blob.getNetworkID());
				headIndex = 69 + _r.NextRanged(2); //head scarf or old
			}
			else
			{
				// default
				headIndex = NUM_UNIQUEHEADS;
			}
		}
	}

	return (((headIndex - NUM_UNIQUEHEADS / 2) * 2) +
	        (blob.getSexNum() == 0 ? 0 : 1)) * NUM_HEADFRAMES;
}

CSpriteLayer@ LoadHead(CSprite@ this, u8 headIndex)
{
	this.RemoveSpriteLayer("head");
	// add head
	string texname = "Entities/Characters/Sprites/Heads.png";
	CSpriteLayer@ head = this.addSpriteLayer("head", texname, 16, 16,
	                     this.getBlob().getTeamNum(),
	                     this.getBlob().getSkinNum());
	CBlob@ blob = this.getBlob();

	// set defaults
	s32 headFrame = getHeadFrame(blob, headIndex);


	blob.set_s32("head index", headFrame);
	if (head !is null)
	{
		Animation@ anim = head.addAnimation("default", 0, false);
		anim.AddFrame(headFrame);
		anim.AddFrame(headFrame + 1);
		anim.AddFrame(headFrame + 2);
		head.SetAnimation(anim);

		head.SetFacingLeft(blob.isFacingLeft());
	}
	return head;
}

void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	if (blob !is null && blob.getName() != "bed")
	{
		int frame = blob.get_s32("head index");
		int framex = frame % FRAMES_WIDTH;
		int framey = frame / FRAMES_WIDTH;

		Vec2f pos = blob.getPosition();
		Vec2f vel = blob.getVelocity();
		f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.5;
		makeGibParticle("Entities/Characters/Sprites/Heads.png",
		                pos, vel + getRandomVelocity(90, hp , 30),
		                framex, framey, Vec2f(16, 16),
		                2.0f, 20, "/BodyGibFall", blob.getTeamNum());
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	ScriptData@ script = this.getCurrentScript();
	if (script is null)
		return;

	if (blob.getShape().isStatic())
	{
		script.tickFrequency = 60;
	}
	else
	{
		script.tickFrequency = 1;
	}


	// head animations
	CSpriteLayer@ head = this.getSpriteLayer("head");

	// load head when player is set or it is AI
	if (head is null && (blob.getPlayer() !is null || (blob.getBrain() !is null && blob.getBrain().isActive()) || blob.getTickSinceCreated() > 3))
	{
		@head = LoadHead(this, blob.getHeadNum());
	}

	if (head !is null)
	{
		// set the head offset and Z value according to the pink/yellow pixels
		PixelOffset @po = getDriver().getPixelOffset(this.getFilename(), this.getFrame());

		if (po !is null)
		{
			// behind, in front or not drawn
			if (po.level == 0)
			{
				head.SetVisible(false);
			}
			else
			{
				head.SetVisible(this.isVisible());
				head.SetRelativeZ(po.level * 0.25f);
			}

			// set the proper offset
			Vec2f headoffset(this.getFrameWidth() / 2, -this.getFrameHeight() / 2);
			headoffset += this.getOffset();
			headoffset += Vec2f(-po.x, po.y);
			headoffset += Vec2f(0, -2);
			head.SetOffset(headoffset);

			if (blob.hasTag("dead") || blob.hasTag("dead head"))
			{
				head.animation.frame = 2;

				// sparkle blood if cut throat
				if (getNet().isClient() && getGameTime() % 2 == 0 && blob.hasTag("cutthroat"))
				{
					Vec2f vel = getRandomVelocity(90.0f, 1.3f * 0.1f * XORRandom(40), 2.0f);
					ParticleBlood(blob.getPosition() + Vec2f(this.isFacingLeft() ? headoffset.x : -headoffset.x, headoffset.y), vel, SColor(255, 126, 0, 0));
					if (XORRandom(100) == 0)
						blob.Untag("cutthroat");
				}
			}
			else if (blob.hasTag("attack head"))
			{
				head.animation.frame = 1;
			}
			else
			{
				head.animation.frame = 0;
			}
		}
		else
		{
			head.SetVisible(false);
		}
	}
}
