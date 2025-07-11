// Modified chest for Christmas

#include "LootCommon.as";
#include "GenericButtonCommon.as";

// blob

void onInit(CBlob@ this)
{
	this.Tag("activatable");
	this.addCommandID("activate");
	this.addCommandID("activate client");

	this.Tag("ignore_saw");
	this.Tag("ignore fall");
	this.Tag("dont blend immediately");
	this.Tag("medium weight");

	AddIconToken("$chest_open$", "InteractionIcons.png", Vec2f(32, 32), 20);
	AddIconToken("$chest_close$", "InteractionIcons.png", Vec2f(32, 32), 13);
}

void onTick(CBlob@ this)
{
	// parachute

	if (this.hasTag("parachute"))
	{
		if (this.getSprite().getSpriteLayer("parachute") is null)
		{
			ShowParachute(this);
		}

		// para force + swing in wind
		this.AddForce(Vec2f(Maths::Sin(getGameTime() * 0.03f) * 1.0f, -30.0f * this.getVelocity().y));

		if (this.isOnGround() || this.isInWater() || this.isAttached())
		{
			this.Untag("parachute");
			HideParachute(this);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || this.exists(DROP)) return;

	const f32 DISTANCE_MAX = this.getRadius() + caller.getRadius() + 8.0f;
	if (this.getDistanceTo(caller) > DISTANCE_MAX || this.isAttached()) return;

	CButton@ button = caller.CreateGenericButton(
		"$chest_open$",										// icon token
		Vec2f_zero,											// button offset
		this,												// button attachment
		this.getCommandID("activate"),						// command id
		getTranslatedString("Open your Christmas present"));// description

	button.radius = 12.0f;
	button.enableRadius = 24.0f;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;
					
		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check
		const f32 DISTANCE_MAX = this.getRadius() + caller.getRadius() + 8.0f;
		if (this.getDistanceTo(caller) > DISTANCE_MAX || this.isAttached()) return;

		this.AddForce(Vec2f(0, -800));

		// add guaranteed piece of loot from your class index
		const string NAME = caller.getName();
		if (NAME == "archer")
		{
			addLoot(this, INDEX_ARCHER, 2, 0);
		}
		else if (NAME == "builder")
		{
			addLoot(this, INDEX_BUILDER, 2, 0);
		}
		else if (NAME == "knight")
		{
			addLoot(this, INDEX_KNIGHT, 2, 0);
		}

		server_CreateLoot(this, this.getPosition(), caller.getTeamNum());

		this.SendCommand(this.getCommandID("activate client"));

		this.server_Die();
	}
	else if (cmd == this.getCommandID("activate client") && isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetAnimation("open");
			sprite.PlaySound("ChestOpen.ogg", 3.0f);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void ShowParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.addSpriteLayer("parachute",   32, 32);

	if (parachute !is null)
	{
		Animation@ anim = parachute.addAnimation("default", 0, true);
		anim.AddFrame(1);
		parachute.SetOffset(Vec2f(0.0f, - 17.0f));
	}
}

void HideParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.getSpriteLayer("parachute");

	if (parachute !is null && parachute.isVisible())
	{
		parachute.SetVisible(false);
		ParticlesFromSprite(parachute);
	}
}

void onDie(CBlob@ this)
{
	CSprite@ s = this.getSprite();
	if (s !is null)
		s.Gib();
}

// sprite

void onInit(CSprite@ this)
{
	this.ReloadSprites(XORRandom(8), 0);
}
