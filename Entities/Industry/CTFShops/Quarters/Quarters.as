// Quarters.as

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "StandardControlsCommon.as";
#include "CTFShopCommon.as";
#include "RunnerHead.as";

s32 cost_beer = 5;
s32 cost_meal = 10;
s32 cost_egg = 30;
s32 cost_burger = 20;

const f32 beer_ammount = 1.0f;
const f32 heal_ammount = 0.25f;
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

	this.addCommandID("rest");
	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	// ICONS
	AddIconToken("$quarters_beer$", "Quarters.png", Vec2f(24, 24), 7);
	AddIconToken("$quarters_meal$", "Quarters.png", Vec2f(48, 24), 2);
	AddIconToken("$quarters_egg$", "Quarters.png", Vec2f(24, 24), 8);
	AddIconToken("$quarters_burger$", "Quarters.png", Vec2f(24, 24), 9);
	AddIconToken("$rest$", "InteractionIcons.png", Vec2f(32, 32), 29);

	//load config
	if (getRules().exists("ctf_costs_config"))
	{
		cost_config_file = getRules().get_string("ctf_costs_config");
	}

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	cost_beer = cfg.read_s32("cost_beer", cost_beer);
	cost_meal = cfg.read_s32("cost_meal", cost_meal);
	cost_egg = cfg.read_s32("cost_egg", cost_egg);
	cost_burger = cfg.read_s32("cost_burger", cost_burger);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(5, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Beer - 1 Heart", "$quarters_beer$", "beer", "A refreshing mug of beer.", false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "coin", "", "Coins", cost_beer);
	}
	{
		ShopItem@ s = addShopItem(this, "Meal - Full Health", "$quarters_meal$", "meal", "A hearty meal to get you back on your feet.", false);
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "coin", "", "Coins", cost_meal);
	}
	{
		ShopItem@ s = addShopItem(this, "Egg - Full Health", "$quarters_egg$", "egg", "A suspiciously undercooked egg, maybe it will hatch.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", cost_egg);
	}
	{
		ShopItem@ s = addShopItem(this, "Burger - Full Health", "$quarters_burger$", "food", "A burger to go.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", cost_burger);
	}
}

void onTick(CBlob@ this)
{
	// TODO: Add stage based sleeping, rest(2 * 30) | sleep(heal_ammount * (patient.getHealth() - patient.getInitialHealth())) | awaken(1 * 30)
	// TODO: Add SetScreenFlash(rest_time, 19, 13, 29) to represent the player gradually falling asleep
	bool isServer = getNet().isServer();
	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		CBlob@ patient = bed.getOccupied();
		if (patient !is null)
		{
			if (bed.isKeyJustPressed(key_up))
			{
				if (isServer)
				{
					patient.server_DetachFrom(this);
				}
			}
			else if (getGameTime() % heal_rate == 0)
			{
				if (requiresTreatment(patient))
				{
					if (patient.isMyPlayer())
					{
						Sound::Play("Heart.ogg", patient.getPosition());
					}
					if (isServer)
					{
						patient.server_Heal(heal_ammount);
					}
				}
				else
				{
					if (isServer)
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
	// TODO: fix GetButtonsFor Overlapping, when detached this.isOverlapping(caller) returns false until you leave collision box and re-enter
	Vec2f tl, br, c_tl, c_br;
	this.getShape().getBoundingRect(tl, br);
	caller.getShape().getBoundingRect(c_tl, c_br);
	bool isOverlapping = br.x - c_tl.x > 0.0f && br.y - c_tl.y > 0.0f && tl.x - c_br.x < 0.0f && tl.y - c_br.y < 0.0f;

	if(!isOverlapping || !bedAvailable(this) || !requiresTreatment(caller))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton("$rest$", Vec2f(-6, 0), this, this.getCommandID("rest"), "Rest", params);
	}
	this.set_bool("shop available", isOverlapping);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = (getNet().isServer());

	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
		{
			return;
		}
		string name = params.read_string();
		{
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob is null)
			{
				return;
			}
			if (name == "beer")
			{
				// TODO: gulp gulp sound
				if (isServer)
				{
					callerBlob.server_Heal(beer_ammount);
				}
			}
			else if (name == "meal")
			{
				this.getSprite().PlaySound("/Eat.ogg");
				if (isServer)
				{
					callerBlob.server_SetHealth(callerBlob.getInitialHealth());
				}
			}
		}
	}
	else if (cmd == this.getCommandID("rest"))
	{
		u16 caller_id;
		if (!params.saferead_netid(caller_id))
			return;

		CBlob@ caller = getBlobByNetworkID(caller_id);
		if (caller !is null)
		{
			AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
			if (bed !is null && bedAvailable(this))
			{
				CBlob@ carried = caller.getCarriedBlob();
				if (isServer)
				{
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
}

const string default_head_path = "Entities/Characters/Sprites/Heads.png";

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	attached.getShape().getConsts().collidable = false;
	attached.SetFacingLeft(true);
	attached.AddScript("WakeOnHit.as");

	string texName = default_head_path;
	CSprite@ attached_sprite = attached.getSprite();
	if (attached_sprite !is null && getNet().isClient())
	{
		attached_sprite.SetVisible(false);
		attached_sprite.PlaySound("GetInVehicle.ogg");
		CSpriteLayer@ head = attached_sprite.getSpriteLayer("head");
		if (head !is null)
		{
			texName = head.getFilename();
		}
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		updateLayer(sprite, "bed", 1, true, false);
		updateLayer(sprite, "zzz", 0, true, false);
		updateLayer(sprite, "backpack", 0, true, false);

		sprite.SetEmitSoundPaused(false);
		sprite.RewindEmitSound();

		if (getNet().isClient())
		{
			CSpriteLayer@ bed_head = sprite.addSpriteLayer("bed head", texName, 16, 16, attached.getTeamNum(), attached.getSkinNum());
			if (bed_head !is null)
			{
				Animation@ anim = bed_head.addAnimation("default", 0, false);

				if (texName == default_head_path)
				{
					anim.AddFrame(getHeadFrame(attached, attached.getHeadNum()) + 2);
				}
				else
				{
					anim.AddFrame(2);
				}

				bed_head.SetAnimation(anim);
				bed_head.SetFacingLeft(true);
				bed_head.RotateBy(80, Vec2f_zero);
				bed_head.SetRelativeZ(2);
				bed_head.SetOffset(Vec2f(1, 2));
				bed_head.SetVisible(true);
			}
		}
	}
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
	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		CBlob@ patient = bed.getOccupied();
		if (patient !is null)
		{
			return false;
		}
	}
	return true;
}

bool requiresTreatment(CBlob@ caller)
{
	return caller.getHealth() < caller.getInitialHealth();
}
