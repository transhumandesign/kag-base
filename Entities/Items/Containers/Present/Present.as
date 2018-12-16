// Modified chest for Christmas

#include "LootCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("medium weight");

	AddIconToken("$chest_open$", "InteractionIcons.png", Vec2f(32, 32), 20);
	AddIconToken("$chest_close$", "InteractionIcons.png", Vec2f(32, 32), 13);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if(this.exists(DROP)) return;

	const f32 DISTANCE_MAX = this.getRadius() + caller.getRadius() + 8.0f;
	if(this.getDistanceTo(caller) > DISTANCE_MAX || this.isAttached()) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton(
	"$chest_open$",										// icon token
	Vec2f_zero,											// button offset
	this,												// button attachment
	this.getCommandID("activate"),						// command id
	getTranslatedString("Open your Christmas present"),	// description
	params);											// cbitstream parameters

	button.radius = 12.0f;
	button.enableRadius = 24.0f;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("activate"))
	{
		this.AddForce(Vec2f(0, -800));

		if(getNet().isServer())
		{
			u16 id;
			if(!params.saferead_u16(id)) return;

			CBlob@ caller = getBlobByNetworkID(id);
			if(caller is null) return;

			const string NAME = caller.getName();
			if(NAME == "archer")
			{
				addLoot(this, INDEX_ARCHER, 2, 0);
			}
			else if(NAME == "builder")
			{
				addLoot(this, INDEX_BUILDER, 2, 0);
			}
			else if(NAME == "knight")
			{
				addLoot(this, INDEX_KNIGHT, 2, 0);
			}

			server_CreateLoot(this, this.getPosition(), caller.getTeamNum());
			this.server_Die();
		}

		this.Tag("_chest_open");
		this.Sync("_chest_open", true);
		CSprite@ sprite = this.getSprite();
		if(sprite !is null)
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