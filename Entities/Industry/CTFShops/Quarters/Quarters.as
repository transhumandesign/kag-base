// Quarters.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "StandardControlsCommon.as"
#include "GenericButtonCommon.as"

const f32 beer_amount = 1.0f;
const f32 heal_amount = 0.25f;
const u8 heal_rate = 30;

void onInit(CSprite@ this)
{
	CSpriteLayer@ bed = this.addSpriteLayer("bed", "Quarters.png", 32, 16);
	if (bed !is null)
	{
		{
			bed.addAnimation("default", 0, false);
			int[] frames = {14, 15};
			bed.animation.AddFrames(frames);
		}
		bed.SetOffset(Vec2f(1, 4));
		bed.SetVisible(true);
	}

	CSpriteLayer@ zzz = this.addSpriteLayer("zzz", "Quarters.png", 8, 8);
	if (zzz !is null)
	{
		{
			zzz.addAnimation("default", 15, true);
			int[] frames = {96, 97, 98, 98, 99};
			zzz.animation.AddFrames(frames);
		}
		zzz.SetOffset(Vec2f(-3, -6));
		zzz.SetLighting(false);
		zzz.SetVisible(false);
	}

	CSpriteLayer@ backpack = this.addSpriteLayer("backpack", "Quarters.png", 16, 16);
	if (backpack !is null)
	{
		{
			backpack.addAnimation("default", 0, false);
			int[] frames = {26};
			backpack.animation.AddFrames(frames);
		}
		backpack.SetOffset(Vec2f(-14, 7));
		backpack.SetVisible(false);
	}

	this.SetEmitSound("MigrantSleep.ogg");
	this.SetEmitSoundPaused(true);
	this.SetEmitSoundVolume(0.5f);
}

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		bed.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_pickup | key_inventory);
		bed.SetMouseTaken(true);
	}

	ShopMadeItem@ onMadeItem = @onShopMadeItem;
	this.set("onShopMadeItem handle", @onMadeItem);

	this.addCommandID("rest");
	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	this.Tag("has window");

	//INIT COSTS
	InitCosts();

	// ICONS
	AddIconToken("$quarters_beer$", "Quarters.png", Vec2f(24, 24), 7);
	AddIconToken("$quarters_meal$", "Quarters.png", Vec2f(48, 24), 2);
	AddIconToken("$quarters_egg$", "Quarters.png", Vec2f(24, 24), 8);
	AddIconToken("$quarters_burger$", "Quarters.png", Vec2f(24, 24), 9);
	AddIconToken("$rest$", "InteractionIcons.png", Vec2f(32, 32), 29);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(5, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Beer - 1 Heart", "$quarters_beer$", "beer", Descriptions::beer, false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::beer);
		AddHurtRequirement(s.requirements);
	}
	{
		ShopItem@ s = addShopItem(this, "Meal - Full Health", "$quarters_meal$", "meal", Descriptions::meal, false);
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::meal);
		AddHurtRequirement(s.requirements);
	}
	{
		ShopItem@ s = addShopItem(this, "Egg - Full Health", "$quarters_egg$", "egg", Descriptions::egg, false);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::egg);
	}
	{
		ShopItem@ s = addShopItem(this, "Burger - Full Health", "$quarters_burger$", "food", Descriptions::burger, true);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::burger);
	}
}

void onTick(CBlob@ this)
{
	// TODO: Add stage based sleeping, rest(2 * 30) | sleep(heal_amount * (patient.getHealth() - patient.getInitialHealth())) | awaken(1 * 30)
	// TODO: Add SetScreenFlash(rest_time, 19, 13, 29) to represent the player gradually falling asleep
	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		CBlob@ patient = bed.getOccupied();
		if (patient !is null)
		{
			if (bed.isKeyJustPressed(key_up) || patient.getHealth() == 0)
			{
				if (isServer())
				{
					patient.server_DetachFrom(this);
				}
			}
			else if (getGameTime() % heal_rate == 0)
			{
				if (requiresTreatment(this, patient))
				{
					if (patient.isMyPlayer())
					{
						Sound::Play("Heart.ogg", patient.getPosition(), 0.5);
					}
					if (isServer())
					{
						f32 oldHealth = patient.getHealth();
						patient.server_Heal(heal_amount);
						patient.add_f32("heal amount", patient.getHealth() - oldHealth);
					}
				}
				else
				{
					if (isServer())
					{
						patient.server_DetachFrom(this);
					}
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	// TODO: fix GetButtonsFor Overlapping, when detached this.isOverlapping(caller) returns false until you leave collision box and re-enter
	Vec2f tl, br, c_tl, c_br;
	this.getShape().getBoundingRect(tl, br);
	caller.getShape().getBoundingRect(c_tl, c_br);
	bool isOverlapping = br.x - c_tl.x > 0.0f && br.y - c_tl.y > 0.0f && tl.x - c_br.x < 0.0f && tl.y - c_br.y < 0.0f;

	if (!isOverlapping || !bedAvailable(this) || !requiresTreatment(this, caller))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
		caller.CreateGenericButton("$rest$", Vec2f(-6, 0), this, this.getCommandID("rest"), getTranslatedString("Rest"));
	}
	this.set_bool("shop available", isOverlapping);
}

void onShopMadeItem(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id, caller_id, item_id;
	string name;

	if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
	{
		return;
	}

	CBlob@ caller = getBlobByNetworkID(caller_id);
	if (caller is null) return;

	if (name == "beer")
	{
		caller.server_Heal(beer_amount);
	}
	else if (name == "meal")
	{
		caller.server_SetHealth(caller.getInitialHealth());
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		this.getSprite().PlaySound("/ChaChing.ogg");

		u16 this_id, caller_id, item_id;
		string name;

		if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
		{
			return;
		}

		if (name == "beer")
		{
			this.getSprite().PlaySound("/Gulp.ogg");
		}
		else if (name == "meal")
		{
			this.getSprite().PlaySound("/Eat.ogg");
		}
	}
	else if (cmd == this.getCommandID("rest") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();

		if (player is null) 
		{
			return;
		}

		CBlob@ caller = player.getBlob();

		if (caller !is null && !caller.isAttached())
		{
			f32 distance = this.getDistanceTo(caller);

			// range check: do not rest if more than 5 blocks away from quarter's center
			if (distance > 40) return;

			AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
			if (bed !is null && bedAvailable(this))
			{
				CBlob@ carried = caller.getCarriedBlob();

				if (carried !is null)
				{
					if (!caller.server_PutInInventory(carried))
					{
						carried.server_DetachFrom(caller);
					}
				}
				this.server_AttachTo(caller, "BED");
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	attached.getShape().getConsts().collidable = false;
	attached.SetFacingLeft(true);
	attached.AddScript("WakeOnHit.as");

	if (not getNet().isClient()) return;

	CSprite@ sprite = this.getSprite();

	if (sprite is null) return;

	updateLayer(sprite, "bed", 1, true, false);
	updateLayer(sprite, "zzz", 0, true, false);
	updateLayer(sprite, "backpack", 0, true, false);

	sprite.SetEmitSoundPaused(false);
	sprite.RewindEmitSound();

	CSprite@ attached_sprite = attached.getSprite();

	if (attached_sprite is null) return;

	attached_sprite.SetVisible(false);
	attached_sprite.PlaySound("GetInVehicle.ogg");

	CSpriteLayer@ head = attached_sprite.getSpriteLayer("head");

	if (head is null) return;

	Animation@ head_animation = head.getAnimation("default");

	if (head_animation is null) return;

	CSpriteLayer@ bed_head = sprite.addSpriteLayer("bed head", head.getFilename(),
		16, 16, attached.getTeamNum(), attached.getSkinNum());

	if (bed_head is null) return;

	Animation@ bed_head_animation = bed_head.addAnimation("default", 0, false);

	if (bed_head_animation is null) return;

	bed_head_animation.AddFrame(head_animation.getFrame(2));

	uint rotation = !this.isFacingLeft() ? 80 : 280;

	bed_head.SetAnimation(bed_head_animation);
	bed_head.RotateBy(rotation, Vec2f_zero);
	bed_head.SetOffset(Vec2f(1, 2));
	bed_head.SetFacingLeft(!this.isFacingLeft());
	bed_head.SetVisible(true);
	bed_head.SetRelativeZ(2);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.getShape().getConsts().collidable = true;
	detached.AddForce(Vec2f(0, -20));
	detached.RemoveScript("WakeOnHit.as");

	CSprite@ detached_sprite = detached.getSprite();
	if (detached_sprite !is null)
	{
		detached_sprite.SetVisible(true);
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		updateLayer(sprite, "bed", 0, true, false);
		updateLayer(sprite, "zzz", 0, false, false);
		updateLayer(sprite, "bed head", 0, false, true);
		updateLayer(sprite, "backpack", 0, false, false);

		sprite.SetEmitSoundPaused(true);
	}
}

void updateLayer(CSprite@ sprite, string name, int index, bool visible, bool remove)
{
	if (sprite !is null)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(name);
		if (layer !is null)
		{
			if (remove == true)
			{
				sprite.RemoveSpriteLayer(name);
				return;
			}
			else
			{
				layer.SetFrameIndex(index);
				layer.SetVisible(visible);
			}
		}
	}
}

bool bedAvailable(CBlob@ this)
{
	if (this.getHealth() <= 0.0f) return false;

	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		return bed.getOccupied() is null;
	}
	return false;
}

bool requiresTreatment(CBlob@ this, CBlob@ caller)
{
	return caller.getHealth() < caller.getInitialHealth() && (!caller.isAttached() || caller.isAttachedTo(this));
}
