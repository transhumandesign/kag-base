// Drill.as

#include "Hitters.as";
#include "BuilderHittable.as";
#include "ParticleSparks.as";
#include "MaterialCommon.as";

const f32 speed_thresh = 2.4f;
const f32 speed_hard_thresh = 2.6f;

const string buzz_prop = "drill timer";

const string heat_prop = "drill heat";
const u8 heat_max = 150;

const string last_drill_prop = "drill last active";

const u8 heat_add = 4;
const u8 heat_add_constructed = 2;
const u8 heat_add_blob = heat_add * 2;
const u8 heat_cool_amount = 2;

const u8 heat_cooldown_time = 5;
const u8 heat_cooldown_time_water = u8(heat_cooldown_time / 3);

const f32 max_heatbar_view_range = 65;

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
		f32 heat = Maths::Min(blob.get_u8(heat_prop), heat_max);
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

void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!getNet().isClient()) return;

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.015625f * rad;
	ParticleAnimated(CFileMatcher(filename).getFirst(), this.getPosition() + random, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
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

void onInit(CBlob@ this)
{
	//todo: some tag-based keys to take interference (doesn't work on net atm)
	/*AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
	}*/

	this.set_u32("hittime", 0);
	this.Tag("place45");
	this.set_s8("place45 distance", 1);
	this.Tag("place45 perp");
	this.set_u8(heat_prop, 0);
	this.set_s32("showHeatTo", -1);

	this.set_u32(last_drill_prop, 0);
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
	}
	sprite.SetEmitSoundPaused(true);
	if (this.isAttached())
	{
		this.getCurrentScript().runFlags &= ~(Script::tick_not_sleeping);
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		if (holder is null) return;

		// cool faster if holder is moving
		if (heat > 0 && holder.getShape().vellen > 0.01f && getGameTime() % heat_cooldown_time == 0)
		{
			heat--;
		}

		this.getShape().SetRotationsAllowed(false);

		if (int(heat) >= heat_max - (heat_add * 1.5))
		{
			makeSteamPuff(this, 1.5f, 3, false);
			this.server_Hit(holder, holder.getPosition(), Vec2f(), 0.25f, Hitters::burn, true);
			this.server_DetachFrom(holder);
			sprite.PlaySound("DrillOverheat.ogg");
		}

		if (holder.getName() == required_class || sv_gamemode == "TDM")
		{
			if (!holder.isKeyPressed(key_action1) || holder.get_u8("knocked") > 0)
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

			const u8 delay_amount = inwater ? 20 : 8;
			bool skip = (gametime < this.get_u32(last_drill_prop) + delay_amount);

			if (skip)
			{
				return;
			}
			else
			{
				this.set_u32(last_drill_prop, gametime); // update last drill time
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
					if (map.getHitInfosFromArc((this.getPosition() - attackVel), -attackVel.Angle(), 30, distance, this, false, @hitInfos))
					{
						bool hit_ground = false;
						for (uint i = 0; i < hitInfos.length; i++)
						{
							f32 attack_dam = 1.0f;
							HitInfo@ hi = hitInfos[i];
							bool hit_constructed = false;
							if (hi.blob !is null) // blob
							{
								//detect
								const bool is_ground = hi.blob.hasTag("blocks sword") && !hi.blob.isAttached() && hi.blob.isCollidable();
								if (is_ground)
								{
									hit_ground = true;
								}

								if (hi.blob.getTeamNum() == holder.getTeamNum() ||
								        hit_ground && !is_ground)
								{
									continue;
								}

								//

								if (getNet().isServer())
								{
									// Deal extra damage if hot
									if (int(heat) > heat_max * 0.5f)
									{
										attack_dam += 1.0f;
									}

									this.server_Hit(hi.blob, hi.hitpos, attackVel, attack_dam, Hitters::drill);

									// Yield half
									Material::fromBlob(holder, hi.blob, attack_dam * 0.5f);
								}

								hitsomething = true;
								hitblob = true;
							}
							else // map
							{
								if (map.getSectorAtPosition(hi.hitpos, "no build") !is null)
									continue;

								TileType tile = hi.tile;

								if (getNet().isServer())
								{
									map.server_DestroyTile(hi.hitpos, 1.0f, this);
									map.server_DestroyTile(hi.hitpos, 1.0f, this);

									Material::fromTile(holder, tile, 1.0f);
								}

								if (getNet().isClient())
								{
									if (map.isTileBedrock(tile))
									{
										sprite.PlaySound("/metal_stone.ogg");
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
			if (getNet().isClient() &&
			        holder.isMyPlayer())
			{
				if (holder.isKeyJustPressed(key_action1))
				{
					Sound::Play("Entities/Characters/Sounds/NoAmmo.ogg");
				}
			}
		}
		this.set_u8(heat_prop, heat);
	}
	else
	{
		this.getShape().SetRotationsAllowed(true);
		this.set_bool(buzz_prop, false);
		if (heat <= 0)
		{
			this.getCurrentScript().runFlags |= Script::tick_not_sleeping;
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
		this.set_u8(heat_prop, 0);
		makeSteamPuff(this);
	}

	return damage;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getCurrentScript().runFlags &= ~Script::tick_not_sleeping;
	this.set_s32("showHeatTo", getPlayerIndex(attached.getPlayer()));
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	this.set_s32("showHeatTo", -1);
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().SetEmitSoundPaused(true);
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CPlayer@ holder = getPlayer(blob.get_s32("showHeatTo"));
	
	Vec2f mousePos = getControls().getMouseWorldPos();
	Vec2f blobPos = blob.getPosition();

	bool inRange = (blobPos - getLocalPlayer().getBlob().getPosition()).getLength() < max_heatbar_view_range;
	bool hover = (mousePos - blobPos).getLength() < blob.getRadius() * 1.50f;
	
	if ((hover && inRange) || (holder !is null && holder.isLocal()))
	{
		u8 heat = blob.get_u8(heat_prop);

    	Vec2f pos = blob.getScreenPos() + Vec2f(-21, 10);
    	Vec2f dimension = Vec2f(24, 8);

		f32 percentage = f32(heat) / heat_max;

    	GUI::DrawRectangle(Vec2f(pos.x, pos.y), 
							Vec2f(pos.x + dimension.x, pos.y + dimension.y));

		GUI::DrawRectangle(Vec2f(pos.x + 2, pos.y + 2),
							Vec2f(pos.x + dimension.x - 2, pos.y + dimension.y - 2),
							SColor(0xff0ddb1e));

    	GUI::DrawRectangle(Vec2f(pos.x + 2 + (dimension.x-4) * (1 - percentage), pos.y + 2),
                    		Vec2f(pos.x + dimension.x - 2, pos.y + dimension.y - 2),
                    		SColor(0xffdb0d17));
	}
}