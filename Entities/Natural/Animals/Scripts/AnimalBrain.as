//brain

#define SERVER_ONLY

#include "PressOldKeys.as";
#include "AnimalConsts.as";

void onInit(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	blob.set_u8(delay_property , 5 + XORRandom(5));
	blob.set_u8(state_property, MODE_IDLE);

	if (!blob.exists(terr_rad_property))
	{
		blob.set_f32(terr_rad_property, 32.0f);
	}

	if (!blob.exists(target_searchrad_property))
	{
		blob.set_f32(target_searchrad_property, 32.0f);
	}

	if (!blob.exists(personality_property))
	{
		blob.set_u8(personality_property, 0);
	}

	if (!blob.exists(target_lose_random))
	{
		blob.set_u8(target_lose_random, 14);
	}

	if (!blob.exists("random move freq"))
	{
		blob.set_u8("random move freq", 2);
	}

	this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 200.0f;
	//this.getCurrentScript().tickFrequency = 5; // cant limit this, needs to press keys each frame

	Vec2f terpos = blob.getPosition();
	terpos += blob.getRadius();
	blob.set_Vec2f(terr_pos_property, terpos);
}


void onTick(CBrain@ this)
{
	CBlob @blob = this.getBlob();

	u8 delay = blob.get_u8(delay_property);
	if (delay > 0) delay--;

	// set territory
	if (blob.getTickSinceCreated() == 10)
	{
		Vec2f terpos = blob.getPosition();
		terpos += blob.getRadius();
		blob.set_Vec2f(terr_pos_property, terpos);
		//	printf("set territory " + blob.getPosition().x + " " + blob.getPosition().y );
	}

	if (delay == 0)
	{
		delay = 4 + XORRandom(8);

		Vec2f pos = blob.getPosition();
		bool facing_left = blob.isFacingLeft();

		{
			u8 mode = blob.get_u8(state_property);
			u8 personality = blob.get_u8(personality_property);

			//printf("mode " + mode);

			//"blind" attacking
			if (mode == MODE_TARGET)
			{
				CBlob@ target = getBlobByNetworkID(blob.get_netid(target_property));

				if (target is null || XORRandom(blob.get_u8(target_lose_random)) == 0 || target.isInInventory())
				{
					mode = MODE_IDLE;
				}
				else
				{
					Vec2f tpos = target.getPosition();

					f32 search_radius = blob.get_f32(target_searchrad_property);

					if ((tpos - pos).getLength() >= (search_radius))
					{
						mode = MODE_IDLE;
					}

					blob.setKeyPressed((tpos.x < pos.x) ? key_left : key_right, true);

					if (personality & DONT_GO_DOWN_BIT == 0 || (blob.isOnGround() && tpos.y <= pos.y + 3 * blob.getRadius()))
					{
						blob.setKeyPressed((tpos.y < pos.y) ? key_up : key_down, true);
					}
				}
			}
			//"blind" fleeing
			else if (mode == MODE_FLEE)
			{
				CBlob@ target = getBlobByNetworkID(blob.get_netid(target_property));

				if (target is null || target.isInInventory())
				{
					mode = MODE_IDLE;
				}
				else
				{
					Vec2f tpos = target.getPosition();
					const f32 search_radius = blob.get_f32(target_searchrad_property);
					if ((tpos - pos).getLength() >= search_radius * 3.0f)
					{
						mode = MODE_IDLE;
					}
					else
					{
						blob.setKeyPressed((tpos.x > pos.x) ? key_left : key_right, true);
						blob.setKeyPressed((tpos.y > pos.y) ? key_up : key_down, true);
					}
				}
			}
			// has a friend
			else if (mode == MODE_FRIENDLY)
			{
				CBlob@ our_friend = getBlobByNetworkID(blob.get_netid(friend_property));
				if (our_friend is null)
				{
					mode = MODE_IDLE;
				}
				else
				{
					Vec2f tpos = our_friend.getPosition();
					const f32 search_radius = blob.get_f32(target_searchrad_property);
					const f32 dist = (tpos - pos).getLength();
					if (dist >= search_radius * 3)
					{
						mode = MODE_IDLE;
					}
					if (blob.getRadius() * 2.0f < dist)
					{
						blob.setKeyPressed((tpos.x < pos.x) ? key_left : key_right, true);
						//blob.setKeyPressed( (tpos.y < pos.y) ? key_up : key_down, true); hack for land animal
					}
				}
			}
			else //mode == idle
			{
				if (personality != 0) //we have a special personality
				{
					f32 search_radius = blob.get_f32(target_searchrad_property);
					string name = blob.getName();

					CBlob@[] blobs;
					blob.getMap().getBlobsInRadius(pos, search_radius, @blobs);

					for (uint step = 0; step < blobs.length; ++step)
					{
						//TODO: sort on proximity? done by engine?
						CBlob@ other = blobs[step];

						if (other is blob) continue; //lets not run away from / try to eat ourselves...

						if (personality & SCARED_BIT != 0)   //scared
						{
							if (other.getRadius() > blob.getRadius() && other.hasTag("flesh")) // not scared of same or smaller creatures
							{
								mode = MODE_FLEE;
								blob.set_netid(target_property, other.getNetworkID());
								break;
							}
						}

						if (personality & AGGRO_BIT != 0)  //aggressive
						{
							//TODO: flags for these...
							if (other.getName() != name && //dont eat same type of blob
							        other.hasTag("flesh")) //attack flesh blobs
							{
								mode = MODE_TARGET;
								blob.set_netid(target_property, other.getNetworkID());
								break;
							}
						}
					}
				}

				if (blob.getTickSinceCreated() > 30) // delay so we dont get false terriroty pos
				{
					Vec2f territory_pos = blob.get_Vec2f(terr_pos_property);
					f32 territory_range = blob.get_f32(terr_rad_property);

					Vec2f territory_dir = (territory_pos - pos);
					////("territory " + territory_pos.x + " " + territory_pos.y );
					//	printf("territory_dir " + territory_dir.Length() + " " + territory_range  );
					if (territory_dir.Length() > territory_range && !blob.hasAttached())
					{
						//head towards territory

						blob.setKeyPressed((territory_dir.x < 0.0f) ? key_left : key_right, true);
						blob.setKeyPressed((territory_dir.y > 0.0f) ? key_down : key_up, true);
					}
					else
					{
						if (personality & TAMABLE_BIT != 0 && blob.hasAttached()) // shake off anyone riding
						{
							blob.setKeyPressed(blob.wasKeyPressed(key_right) ? key_left : key_right, true);
						}
						else if (personality & STILL_IDLE_BIT == 0)
						{
							u8 randomMoveFrequency = blob.get_u8("random move freq");
							//change direction at random or when on wall

							if (XORRandom(randomMoveFrequency) == 0 || blob.isOnWall())
							{
								blob.setKeyPressed(blob.wasKeyPressed(key_right) ? key_left : key_right, true);
							}

							if (XORRandom(randomMoveFrequency) == 0 || blob.isOnCeiling() || blob.isOnGround())
							{
								blob.setKeyPressed(blob.wasKeyPressed(key_down) ? key_down : key_down, true);
							}
						}
					}
				}

			}

			blob.set_u8(state_property, mode);
		}
	}
	else
	{
		PressOldKeys(blob);
	}

	blob.set_u8(delay_property, delay);
}
