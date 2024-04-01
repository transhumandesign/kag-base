// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "RespawnCommandCommon.as"
#include "GenericButtonCommon.as"
#include "MakeSign.as"

namespace Trampoline
{
	const string TIMER = "trampoline_timer";
	const u16 COOLDOWN = 7;
	const u8 SCALAR = 6;
	const bool SAFETY = true;
	const int COOLDOWN_LIMIT = 8;
}

class TrampolineCooldown{
	u16 netid;
	u32 timer;
	TrampolineCooldown(u16 netid, u16 timer){this.netid = netid; this.timer = timer;}
};

void onInit(CBlob@ this)
{
	this.CreateRespawnPoint("ruins", Vec2f(0.0f, 16.0f));
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	//TDM classes
	addPlayerClass(this, "Knight", "$knight_class_icon$", "knight", "Hack and Slash.");
	addPlayerClass(this, "Archer", "$archer_class_icon$", "archer", "The Ranged Advantage.");
	this.addCommandID("class menu");

	this.Tag("change class drop inventory");

	this.getSprite().SetZ(-50.0f);   // push to background
	
	this.getShape().SetOffset(Vec2f(0,26));
	Vec2f pos = this.getPosition();
	this.setPosition(Vec2f(pos.x, pos.y - getMap().tilesize * 4));
	this.getShape().PutOnGround();
	
	// bouncing stuff
	TrampolineCooldown @[] cooldowns;
	this.set(Trampoline::TIMER, cooldowns);
	
	// when using verticesXY shape, radius from .cfg is ignored so we use this
	this.set_f32("custom radius", 48.0f);
	
	// sign
	Vec2f atPos = this.getPosition() + Vec2f(this.getTeamNum() < 1 ? + 48 : -48, 0);
	CBlob@ sign = createSign(atPos, "Welcome to Build 47856945 Super Edition !!!!!!!!");
	CShape@ sign_shape = sign.getShape();
	if (sign_shape !is null)
	{
		sign_shape.PutOnGround();
	}
}

void onTick(CBlob@ this)
{
	if (enable_quickswap)
	{
		//quick switch class
		CBlob@ blob = getLocalPlayerBlob();
		if (blob !is null && blob.isMyPlayer())
		{
			if (
				isInRadius(this, blob) && //blob close enough to ruins
				blob.isKeyJustReleased(key_use) && //just released e
				isTap(blob, 7) && //tapped e
				blob.getTickSinceCreated() > 1 //prevents infinite loop of swapping class
			) {
				CycleClass(this, blob);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
		{
			BuildRespawnMenuFor(this, caller);
		}
	}
	else
	{
		onRespawnCommand(this, cmd, params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	AddIconToken("$knight_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 12, caller.getTeamNum());
	AddIconToken("$archer_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 16, caller.getTeamNum());
	
	if (!canSeeButtons(this, caller)) return;

	if (!caller.hasTag("switch class"))
	{
		if (isInRadius(this, caller))
		{
			BuildRespawnMenuFor(this, caller);
		}
		else
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			caller.CreateGenericButton("$change_class$", Vec2f(0, 6), this, this.getCommandID("class menu"), getTranslatedString("Change class"), params);
		}
	}

	// warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (this.getPosition() - caller.getPosition()).Length() < this.get_f32("custom radius");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob is null || blob.isAttached() || blob.getShape().isStatic()) return;

	TrampolineCooldown@[]@ cooldowns;
	if (!this.get(Trampoline::TIMER, @cooldowns)) return;

	//shred old cooldown if we have too many
	if (Trampoline::SAFETY && cooldowns.length > Trampoline::COOLDOWN_LIMIT) cooldowns.removeAt(0);

	u16 netid = blob.getNetworkID();
	bool block = false;
	for(int i = 0; i < cooldowns.length; i++)
	{
		if (cooldowns[i].timer < getGameTime())
		{
			cooldowns.removeAt(i);
			i--;
		}
		else if (netid == cooldowns[i].netid)
		{
			block = true;
			break;
		}
	}
	if (!block)
	{
		Vec2f velocity_old = blob.getOldVelocity();
		if (velocity_old.Length() < 1.0f) return;

		float angle = this.getAngleDegrees();

		Vec2f direction = Vec2f(0.0f, -1.0f);
		direction.RotateBy(angle);

		float velocity_angle = direction.AngleWith(velocity_old);

		if (Maths::Abs(velocity_angle) > 90)
		{
			TrampolineCooldown cooldown(netid, getGameTime() + Trampoline::COOLDOWN);
			cooldowns.push_back(cooldown);

			Vec2f velocity = Vec2f(velocity_old.x, -Trampoline::SCALAR);
			velocity.RotateBy(angle);

			blob.setVelocity(velocity);

			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.PlaySound("TrampolineJump.ogg");
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}