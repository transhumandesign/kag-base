// Drill.as

#include "Hitters.as";
#include "BuilderHittable.as";
#include "ParticleSparks.as";
#include "MaterialCommon.as";
#include "ShieldCommon.as";
#include "KnockedCommon.as";

const f32 speed_thresh = 2.4f;
const f32 speed_hard_thresh = 2.6f;

const string buzz_prop = "drill timer";

const string heat_prop = "drill heat";
const u8 heat_max = 150;
const u8 heat_drop = 140;
const u8 high_damage_window = 40; // at how much heat before max drill deals increased damage

const string last_drill_prop = "drill last active";

const u8 heat_add = 7;
const u8 heat_add_constructed = 2;
const u8 heat_add_blob = 6;
const u8 heat_cool_amount = 2;

const f32 heat_reduction_water = 0.5f;

const u8 heat_cooldown_time = 8;
const u8 heat_cooldown_time_water = u8(heat_cooldown_time / 3);

const f32 max_heatbar_view_range = 65;

const bool show_heatbar_when_idle = false;

const string required_class = "builder";

void onInit(CSprite@ this)
{
	CSpriteLayer@ heat = this.addSpriteLayer("heat", this.getFilename(), 32, 16);

	if (heat !is null)
	{
		Animation@ anim = heat.addAnimation("default", 0, true);
		{
			int[] frames = {4, 5, 6, 7};
			anim.AddFrames(frames);
		}
		heat.SetAnimation(anim);
		heat.SetRelativeZ(0.1f);
		heat.SetVisible(false);
		heat.setRenderStyle(RenderStyle::light);
	}
	this.SetEmitSound("/Drill.ogg");
}

void onInit(CBlob@ this)
{
	//todo: some tag-based keys to take interference (doesn't work on net atm)
	/*AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
	}*/

	this.set_u32("hittime", 0);
	this.Tag("place norotate"); // required to prevent drill from locking in place (blame builder code :kag_angry:)

	//this.Tag("place45"); // old 45 degree angle lock
	//this.set_s8("place45 distance", 1);
	//this.Tag("place45 perp");

	this.set_u8(heat_prop, 0);
	this.set_u16("showHeatTo", 0);
	this.set_u16("harvestWoodDoorCap", 4);
	this.set_u16("harvestStoneDoorCap",4);
	this.set_u16("harvestPlatformCap", 2);

	AddIconToken("$opaque_heatbar$", "Entities/Industry/Drill/HeatBar.png", Vec2f(24, 6), 0);
	AddIconToken("$transparent_heatbar$", "Entities/Industry/Drill/HeatBar.png", Vec2f(24, 6), 1);

	this.set_u32(last_drill_prop, 0);
	this.Tag("ignore fall");
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	u8 heat = this.get_u8(heat_prop);
	if (heat > 0) this.set_u32("time_enter",getGameTime()); // set time we enter the invo

	return true;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return (this.get_u8(heat_prop) < heat_drop);
}

void onThisRemoveFromInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	u8 heat = this.get_u8(heat_prop);
	if (heat > 0) // do we need to run this?
	{
		u32 gameTimeCache = getGameTime(); // so we dont need to keep calling it
		u32 dif = this.get_u32("time_enter"); // grab the temp time, better then doing difference since we might underflow

		while (dif < gameTimeCache)
		{
			dif += heat_cooldown_time; // add so we can beat our condition
			heat--;
			if (heat == 0) break; // if we reach the limit, stop running
		}

		this.set_u8(heat_prop, heat);
	}
}


void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	bool buzz = blob.get_bool(buzz_prop);
	if (buzz)
	{
		this.SetAnimation("buzz");
	}
	else if (this.isAnimationEnded())
	{
		this.SetAnimation("default");
	}

	CSpriteLayer@ heatlayer = this.getSpriteLayer("heat");
	if (heatlayer !is null)
	{
		u8 heat = Maths::Min(blob.get_u8(heat_prop), heat_max);
		f32 heatPercent = heat / float(heat_max);
		if (heatPercent > 0.1f)
		{
			heatlayer.setRenderStyle(RenderStyle::light);
			blob.SetLight(true);
			blob.SetLightRadius(heatPercent * 24.0f);
			SColor lightColor = SColor(255, 255, Maths::Min(255, 128 + int(heatPercent * 128)), 64);
			blob.SetLightColor(lightColor);
			heatlayer.SetVisible(true);
			heatlayer.animation.frame = heatPercent * 3;
			if (heatPercent > 0.7f && getGameTime() % 3 == 0)
			{
				makeSteamParticle(blob, Vec2f());
			}
		}
		else
		{
			blob.SetLight(false);
			heatlayer.SetVisible(false);
		}
	}
}


void onTick(CBlob@ this)
{
	u8 heat = this.get_u8(heat_prop);
	const u32 gametime = getGameTime();
	bool inwater = this.isInWater();

	CSprite@ sprite = this.getSprite();

	if (heat > 0)
	{
		if (gametime % heat_cooldown_time == 0)
		{
			heat--;
		}

		if (inwater && heat >= heat_add && gametime % (Maths::Max(heat_cooldown_time_water, 1)) == 0)
		{
			u8 lim = u8(heat_max * 0.7f);
			if (heat > lim)
			{
				makeSteamPuff(this);
			}
			else
			{
				makeSteamPuff(this, 0.5f, 5, false);
			}
			heat -= heat_cool_amount;
		}
		this.set_u8(heat_prop, heat);
		this.Sync(heat_prop, true);
	}
	sprite.SetEmitSoundPaused(true);
	if (this.isAttachedToPoint("PICKUP"))
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		if (holder is null || holder.isAttached()) return;

		AimAtMouse(this, holder); // aim at our mouse pos

		if (int(heat) >= heat_drop)
		{
			makeSteamPuff(this, 1.5f, 3, false);
			this.server_Hit(holder, holder.getPosition(), Vec2f(), 0.25f, Hitters::burn, true);
			this.server_DetachFrom(holder);
			sprite.PlaySound("DrillOverheat.ogg");
		}

		if (holder.getName() == required_class || sv_gamemode == "TDM")
		{
			if (!holder.isKeyPressed(key_action1) || isKnocked(holder))
			{
				this.set_bool(buzz_prop, false);
				return;
			}

			//set funny sound under water
			if (inwater)
			{
				sprite.SetEmitSoundSpeed(0.8f + (getGameTime() % 13) * 0.01f);
			}
			else
			{
				sprite.SetEmitSoundSpeed(1.0f);
			}

			sprite.SetEmitSoundPaused(false);
			this.set_bool(buzz_prop, true);

			if (heat < heat_max)
			{
				heat++;
			}

			u8 delay_amount = 8;
			if (this.get_bool("just hit dirt")) delay_amount = 10;
			if (inwater) delay_amount = 20;
			
			bool skip = (gametime < this.get_u32(last_drill_prop) + delay_amount);

			if (skip)
			{
				return;
			}
			else
			{
				this.set_u32(last_drill_prop, gametime); // update last drill time
				this.set_bool("just hit dirt", false);	
				this.Sync("just hit dirt", true);
			}

			// delay drill
			{
				const bool facingleft = this.isFacingLeft();
				Vec2f direction = Vec2f(1, 0).RotateBy(this.getAngleDegrees() + (facingleft ? 180.0f : 0.0f));
				const f32 sign = (facingleft ? -1.0f : 1.0f);

				const f32 attack_distance = 6.0f;
				Vec2f attackVel = direction * attack_distance;

				const f32 distance = 20.0f;

				bool hitsomething = false;
				bool hitblob = false;

				CMap@ map = getMap();
				if (map !is null)
				{
					HitInfo@[] hitInfos;
					if (map.getHitInfosFromArc((this.getPosition() - attackVel), -attackVel.Angle(), 30, distance, this, true, @hitInfos))
					{
						bool hit_ground = false;
						for (uint i = 0; i < hitInfos.length; i++)
						{
							f32 attack_dam = 1.0f;
							HitInfo@ hi = hitInfos[i];
							bool hit_constructed = false;
							CBlob@ b = hi.blob;
							if (b !is null) // blob
							{
								// blob ignore list, this stops the drill from overheating f a s t
								// or blobs to increase damage to (for the future)
								string name = b.getName();

								if (b.hasTag("invincible") || b.getName() == "bush")
								{
									continue; // carry on onto the next loop, dont waste time & heat on this
								}

								//detect
								const bool is_ground = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();
								if (is_ground)
								{
									hit_ground = true;
								}

								if (b.getTeamNum() == holder.getTeamNum() ||
								        hit_ground && !is_ground)
								{
									continue;
								}


								if (isServer())
								{
									if (int(heat) >= heat_max - high_damage_window) // are we at high heat? more damage!
									{
										attack_dam += 0.5f;
									}

									if (b.hasTag("shielded") && blockAttack(b, attackVel, 0.0f)) // are they shielding? reduce damage!
									{
										attack_dam /= 2;
									}

									this.server_Hit(b, hi.hitpos, attackVel, attack_dam, Hitters::drill);

									Material::fromBlob(holder, hi.blob, attack_dam, this);
								}

								hitsomething = true;
								hitblob = true;
							}
							else // map
							{
								if (map.getSectorAtPosition(hi.hitpos, "no build") !is null)
									continue;

								TileType tile = hi.tile;

								if (isServer())
								{
									for (uint i = 0; i < 2; i++)
									{
										//tile destroyed last hit

										if (!map.isTileSolid(map.getTile(hi.tileOffset))){ break; }

										map.server_DestroyTile(hi.hitpos, 1.0f, this);

										if (map.isTileCastle(tile) || map.isTileWood(tile) || map.isTileGold(tile))
										{
											Material::fromTile(holder, tile, 1.0f);
										}
										else
										{
											Material::fromTile(holder, tile, 0.75f);
										}
										
										if (map.isTileGround(tile) || map.isTileStone(tile) || map.isTileThickStone(tile)) 
										{
											this.set_bool("just hit dirt", true);
											this.Sync("just hit dirt", true);
										}

									}

								}

								if (isClient())
								{
									if (map.isTileBedrock(tile))
									{
										sprite.PlaySound("metal_stone.ogg");
										sparks(hi.hitpos, attackVel.Angle(), 1.0f);
									}
								}

								//only counts as hitting something if its not mats, so you can drill out veins quickly
								if (!map.isTileStone(tile) || !map.isTileGold(tile))
								{
									hitsomething = true;
									if (map.isTileCastle(tile) || map.isTileWood(tile))
									{
										hit_constructed = true;
									}
									else
									{
										hit_ground = true;
									}
								}

							}
							if (hitsomething)
							{
								if (heat < heat_max)
								{
									if (hit_constructed)
									{
										heat += heat_add_constructed;
									}
									else if (hitblob)
									{
										heat += heat_add_blob;
									}
									else
									{
										heat += heat_add;
									}
								}
								hitsomething = false;
								hitblob = false;
							}
						}
					}
				}
			}
		}
		else
		{
			if (isClient() &&
			        holder.isMyPlayer())
			{
				if (holder.isKeyJustPressed(key_action1))
				{
					holder.getSprite().PlaySound("NoAmmo.ogg", 0.5);
				}
			}
		}
		this.set_u8(heat_prop, heat);
		this.Sync(heat_prop, true);
	}
	else
	{
		this.set_bool(buzz_prop, false);
		if (heat <= 0)
		{
			this.getCurrentScript().runFlags |= Script::tick_not_sleeping;
		}
		else
		{
			this.getCurrentScript().runFlags &= ~Script::tick_not_sleeping;
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::fire)
	{
		this.set_u8(heat_prop, heat_max);
		makeSteamPuff(this);
	}

	if (customData == Hitters::water)
	{
		u8 current_heat = this.get_u8(heat_prop);
		
		if (current_heat > 0)
			makeSteamPuff(this);
			
		current_heat = Maths::Max(current_heat - heat_max * heat_reduction_water, 0);
			
		this.set_u8(heat_prop, current_heat);
	}

	return damage;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getCurrentScript().runFlags &= ~Script::tick_not_sleeping;
	CPlayer@ player = attached.getPlayer();
	if (player !is null)
		this.set_u16("showHeatTo", player.getNetworkID());

	CShape@ shape = this.getShape();
	if (shape !is null)
	{
		this.setPosition(attached.getPosition()); // required to stop the first tick to be out of position

		shape.SetGravityScale(0); // this stops the shape from 'falling' when its attached to something, (helps the heat bar from looking bad above 30 fps)
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	this.set_u16("showHeatTo", 0);

	CShape@ shape = this.getShape();
	if (shape !is null)
	{
		shape.SetGravityScale(1);
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().SetEmitSoundPaused(true);
}

void onRender(CSprite@ this)
{
	CPlayer@ local = getLocalPlayer();
	CBlob@ localBlob = local.getBlob();

	if (local is null || localBlob is null)
		return;

	CBlob@ blob = this.getBlob();
	u16 holderID = blob.get_u16("showHeatTo");

	CPlayer@ holder = holderID == 0 ? null : getPlayerByNetworkId(holderID);
	if (holder is null){return;}

	CBlob@ holderBlob = holder.getBlob();
	if (holderBlob is null){return;}

	if (holderBlob.getName() != required_class && sv_gamemode != "TDM"){return;}

	Vec2f mousePos = getControls().getMouseWorldPos();
	Vec2f blobPos = blob.getPosition();
	Vec2f localPos = localBlob.getPosition();

	bool inRange = (blobPos - localPos).getLength() < max_heatbar_view_range;
	bool hover = (mousePos - blobPos).getLength() < blob.getRadius() * 1.50f;

	if ((hover && inRange) || (holder !is null && holder.isLocal()))
	{
		int transparency = 255;
		u8 heat = blob.get_u8(heat_prop);
		f32 percentage = Maths::Min(1.0, f32(heat) / f32(heat_max));

		//Vec2f pos = blob.getScreenPos() + Vec2f(-22, 16);

		Vec2f pos = holderBlob.getInterpolatedScreenPos() + (blob.getScreenPos() - holderBlob.getScreenPos()) + Vec2f(-22, 16);
		Vec2f dimension = Vec2f(42, 4);
		Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

		if ((heat > 0 && show_heatbar_when_idle) || (blob.get_bool(buzz_prop)))
		{
			GUI::DrawIconByName("$opaque_heatbar$", pos);
		}
		else
		{
			transparency = 168;
			GUI::DrawIconByName("$transparent_heatbar$", pos);
		}

		GUI::DrawRectangle(pos + Vec2f(4, 4), bar + Vec2f(4, 4), SColor(transparency, 59, 20, 6));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 4), SColor(transparency, 148, 27, 27));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 2), SColor(transparency, 183, 51, 51));
	}
}


void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.015625f * rad;
	ParticleAnimated(filename, this.getPosition() + random, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void makeSteamPuff(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 10, const bool sound = true)
{
	if (sound)
	{
		this.getSprite().PlaySound("Steam.ogg");
	}

	makeSteamParticle(this, Vec2f(), "MediumSteam");
	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32) * 0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity(-90, velocity * randomness, 360.0f);
		makeSteamParticle(this, vel);
	}
}

void AimAtMouse(CBlob@ this, CBlob@ holder)
{
	// code used from BlobPlacement.as, just edited to use mouse pos instead of 45 degree angle
	Vec2f aimpos = holder.getAimPos();
	Vec2f pos = this.getPosition();
	Vec2f aim_vec = (pos - aimpos);
	aim_vec.Normalize();

	f32 mouseAngle = aim_vec.getAngleDegrees();

	if (!this.isFacingLeft()) mouseAngle += 180;

	this.setAngleDegrees(-mouseAngle); // set aim pos
}
