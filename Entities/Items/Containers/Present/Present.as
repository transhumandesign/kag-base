// Modified chest for Christmas

#include "LootCommon.as";
#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
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

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton(
		"$chest_open$",										// icon token
		Vec2f_zero,											// button offset
		this,												// button attachment
		this.getCommandID("activate"),						// command id
		getTranslatedString("Open your Christmas present"),	// description
		params												// cbitstream parameters
	);

	button.radius = 12.0f;
	button.enableRadius = 24.0f;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		this.AddForce(Vec2f(0, -800));

		if (getNet().isServer())
		{
			u16 id;
			if (!params.saferead_u16(id)) return;

			CBlob@ caller = getBlobByNetworkID(id);
			if (caller is null) return;

			const string name = caller.getName();
			if (name == "archer")
			{
				addLoot(this, INDEX_ARCHER, 2, 0);
			}
			else if (name == "builder")
			{
				addLoot(this, INDEX_BUILDER, 2, 0);
			}
			else if (name == "knight")
			{
				addLoot(this, INDEX_KNIGHT, 2, 0);
			}

			server_CreateLoot(this, this.getPosition(), caller.getTeamNum());
			this.server_Die();
		}

		CSprite@ sprite = this.getSprite();
		if (sprite !is null) {
			sprite.PlaySound("ChestOpen.ogg", 1.0f);
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