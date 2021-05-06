// Standard menu player controls
// add to blob and sprite

#include "ThrowCommon.as"
#include "WheelMenuCommon.as"
#include "KnockedCommon.as"
#include "PickupCommon.as"

void onInit(CBlob@ this)
{
	CBlob@[] blobs;
	this.set("pickup blobs", blobs);
	CBlob@[] closestblobs;
	this.set("closest blobs", closestblobs);

	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	this.addCommandID("pickup item");

	AddIconToken("$filled_bucket$", "Bucket.png", Vec2f(16, 16), 1);

	// setup pickup menu wheel
	WheelMenu@ menu = get_wheel_menu("pickup");
	if (menu.entries.length == 0)
	{
		menu.option_notice = "Pickup";

		// knight stuff
		menu.add_entry(PickupWheelMenuEntry("Keg", "$keg$", "keg"));

		const PickupWheelOption[] bomb_options = {PickupWheelOption("bomb", 1), PickupWheelOption("mat_bombs", 0)};
		menu.add_entry(PickupWheelMenuEntry("Bomb", "$mat_bombs$", bomb_options, Vec2f(0, -8.0f)));

		const PickupWheelOption[] waterbomb_options = {PickupWheelOption("waterbomb", 1), PickupWheelOption("mat_waterbombs", 0)};
		menu.add_entry(PickupWheelMenuEntry("Water Bomb", "$mat_waterbombs$", waterbomb_options, Vec2f(0, -6.0f)));

		menu.add_entry(PickupWheelMenuEntry("Mine", "$mine$", "mine"));

		// archer stuff
		menu.add_entry(PickupWheelMenuEntry("Arrows", "$mat_arrows$", "mat_arrows", Vec2f(0, -8.0f)));
		menu.add_entry(PickupWheelMenuEntry("Water Arrows", "$mat_waterarrows$", "mat_waterarrows", Vec2f(0, 2.0f)));
		menu.add_entry(PickupWheelMenuEntry("Fire Arrows", "$mat_firearrows$", "mat_firearrows", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Bomb Arrows", "$mat_bombarrows$", "mat_bombarrows"));

		// builder stuff
		menu.add_entry(PickupWheelMenuEntry("Gold", "$mat_gold$", "mat_gold", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Stone", "$mat_stone$", "mat_stone", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Wood", "$mat_wood$", "mat_wood", Vec2f(0, -6.0f)));
		menu.add_entry(PickupWheelMenuEntry("Drill", "$drill$", "drill", Vec2f(-16.0f, 0.0f)));
		menu.add_entry(PickupWheelMenuEntry("Saw", "$saw$", "saw", Vec2f(-16.0f, -16.0f)));
		menu.add_entry(PickupWheelMenuEntry("Trampoline", "$trampoline$", "trampoline", Vec2f(-16.0f, -8.0f)));
		menu.add_entry(PickupWheelMenuEntry("Boulder", "$boulder$", "boulder"));
		menu.add_entry(PickupWheelMenuEntry("Sponge", "$sponge$", "sponge", Vec2f(0, 8.0f)));
		menu.add_entry(PickupWheelMenuEntry("Seed", "$seed$", "seed", Vec2f(8.0f, 8.0f)));

		// misc
		menu.add_entry(PickupWheelMenuEntry("Log", "$log$", "log"));
		const PickupWheelOption[] food_options = {
			PickupWheelOption("food"),
			PickupWheelOption("heart"),
			PickupWheelOption("fishy"),
			PickupWheelOption("grain"),
			PickupWheelOption("steak"),
			PickupWheelOption("egg"),
			PickupWheelOption("flowers")
		};
		menu.add_entry(PickupWheelMenuEntry("Food", "$food$", food_options));
		menu.add_entry(PickupWheelMenuEntry("Ballista Ammo", "$mat_bolts$", "mat_bolts"));
		menu.add_entry(PickupWheelMenuEntry("Crate", "$crate$", "crate", Vec2f(-16.0f, 0)));
		menu.add_entry(PickupWheelMenuEntry("Bucket", "$filled_bucket$", "bucket"));
	}

}

void onTick(CBlob@ this)
{
	if (this.isInInventory() || isKnocked(this))
	{
		this.clear("pickup blobs");
		this.clear("closest blobs");
		return;
	}

	CControls@ controls = getControls();

	// drop / pickup / throw
	if (controls.ActionKeyPressed(AK_PICKUP_MODIFIER))
	{
		WheelMenu@ menu = get_wheel_menu("pickup");
		if (this.isKeyPressed(key_pickup) && menu !is get_active_wheel_menu())
		{
			set_active_wheel_menu(@menu);
		}

		if (this.isKeyPressed(key_pickup))
		{
			GatherPickupBlobs(this);

			CBlob@[]@ pickupBlobs;
			this.get("pickup blobs", @pickupBlobs);

			CBlob@[] available;
			FillAvailable(this, available, pickupBlobs);

			for (uint i = 0; i < menu.entries.length; i++)
			{
				PickupWheelMenuEntry@ entry = cast<PickupWheelMenuEntry>(menu.entries[i]);
				entry.disabled = true;

				for (uint j = 0; j < available.length; j++)
				{
					string bname = available[j].getName();
					for (uint k = 0; k < entry.options.length; k++)
					{
						if (entry.options[k].name == bname)
						{
							entry.disabled = false;
							break;
						}
					}

					if (!entry.disabled)
					{
						break;
					}
				}

			}

		}

	}
	else if (this.isKeyJustPressed(key_pickup))
	{
		TapPickup(this);

		if (this.isAttached()) // default drop from attachment
		{
			int count = this.getAttachmentPointCount();

			for (int i = 0; i < count; i++)
			{
				AttachmentPoint @ap = this.getAttachmentPoint(i);

				if (ap.getOccupied() !is null && ap.name != "PICKUP")
				{
					CBitStream params;
					params.write_netid(ap.getOccupied().getNetworkID());
					this.SendCommand(this.getCommandID("detach"), params);
					this.set_bool("release click", false);
					break;
				}
			}
		}
		else
		{
			this.set_bool("release click", true);
		}
	}
	else
	{
		WheelMenu@ menu = get_wheel_menu("pickup");
		if ((this.isKeyJustReleased(key_pickup) || controls.isKeyJustReleased(controls.getActionKeyKey(AK_PICKUP_MODIFIER)))
			&&  get_active_wheel_menu() is menu)
		{
			PickupWheelMenuEntry@ selected = cast<PickupWheelMenuEntry>(menu.get_selected());
			set_active_wheel_menu(null);

			if (selected !is null && !selected.disabled)
			{
				CBlob@[] blobsInRadius;
				if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + 50.0f, @blobsInRadius))
				{
					uint highestPriority = 0;
					float closestScore = 600.0f;
					CBlob@ closest;

					for (uint i = 0; i < blobsInRadius.length; i++)
					{
						CBlob@ b = blobsInRadius[i];

						string bname = b.getName();
						for (uint j = 0; j < selected.options.length; j++)
						{
							PickupWheelOption@ selectedOption = @selected.options[j];
							if (bname == selectedOption.name)
							{
								if (!canBlobBePickedUp(this, b))
								{
									break;
								}

								float maxDist = Maths::Max(this.getRadius() + b.getRadius() + 20.0f, 36.0f);
								float dist = (this.getPosition() - b.getPosition()).Length();
								float factor = dist / maxDist;

								float score = getPriorityPickupScale(this, b, factor);

								if (score < closestScore || selectedOption.priority > highestPriority)
								{
									highestPriority = selectedOption.priority;
									closestScore = score;
									@closest = @b;
								}
							}
						}
					}

					if (closest !is null)
					{
						// NOTE: optimisation: use selected-option-blobs-in-radius
						@closest = @GetBetterAlternativePickupBlobs(blobsInRadius, closest);
						server_Pickup(this, this, closest);
					}

				}

			}

			return;

		}

		if (this.isKeyPressed(key_pickup))
		{
			GatherPickupBlobs(this);

			CBlob@[]@ closestBlobs;
			this.get("closest blobs", @closestBlobs);
			closestBlobs.clear();

			CBlob@ closest = getClosestBlob(this);
			if (closest !is null)
			{
				closestBlobs.push_back(closest);
			}
		}

		if (this.isKeyJustReleased(key_pickup))
		{
			if (this.get_bool("release click"))
			{
				CBlob@[]@ closestBlobs;
				this.get("closest blobs", @closestBlobs);

				CBlob@ pickBlob;

				if (!closestBlobs.empty())
				{
					@pickBlob = closestBlobs[0];
				}

				CBitStream params;
				params.write_netid(this.getNetworkID());
				params.write_bool(pickBlob !is null);

				if (pickBlob !is null)
				{
					params.write_netid(pickBlob.getNetworkID());
				}

				params.write_Vec2f(this.getPosition());
				params.write_Vec2f(this.getAimPos() - this.getPosition());
				params.write_Vec2f(this.getVelocity());

				this.SendCommand(this.getCommandID("pickup item"), params);
			}

			ClearPickupBlobs(this);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (!isServer()) return;

	if (cmd == this.getCommandID("pickup item"))
	{
		CBlob@ carried = this.getCarriedBlob();

		CBlob@ owner = getBlobByNetworkID(params.read_netid());
		if (owner is null) return;

		CBlob@ pickBlob;
		if (params.read_bool())
		{
			@pickBlob = getBlobByNetworkID(params.read_netid());
		}

		if (carried !is null)
		{
			Vec2f pos = params.read_Vec2f();
			Vec2f vector = params.read_Vec2f();
			Vec2f vel = params.read_Vec2f();

			if (!carried.hasTag("custom throw"))
			{
				DoThrow(owner, carried, pos, vector, vel);
			}
		}
		else if (pickBlob !is null)
		{
			this.server_Pickup(pickBlob);
		}
	}
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	// render item held when in inventory

	if (blob.isKeyPressed(key_inventory))
	{
		CBlob @pickBlob = blob.getCarriedBlob();

		if (pickBlob !is null)
		{
			pickBlob.RenderForHUD((blob.getAimPos() + Vec2f(0.0f, 8.0f)) - blob.getPosition() , RenderStyle::normal);
		}
	}

	if (blob.isKeyPressed(key_pickup))
	{
		// pickup render
		bool tickPlayed = false;
		bool hover = false;
		CBlob@[]@ pickupBlobs;
		CBlob@[]@ closestBlobs;
		blob.get("closest blobs", @closestBlobs);
		CBlob@ closestBlob = null;
		if (closestBlobs.length > 0)
		{
			@closestBlob = closestBlobs[0];
		}

		if (blob.get("pickup blobs", @pickupBlobs))
		{
			// render outline only if hovering
			for (uint i = 0; i < pickupBlobs.length; i++)
			{
				CBlob @b = pickupBlobs[i];

				bool canBePicked = canBlobBePickedUp(blob, b);

				if (canBePicked)
				{
					b.RenderForHUD(RenderStyle::outline_front);
				}

				if (b is closestBlob)
				{
					hover = true;
					Vec2f dimensions;
					GUI::SetFont("menu");

					/*
					GUI::DrawCircle(
						getDriver().getScreenPosFromWorldPos(b.getPosition()),
						32.0f,
						SColor(255, 255, 255, 255)
					);
					*/

					GUI::GetTextDimensions(b.getInventoryName(), dimensions);
					GUI::DrawText(getTranslatedString(b.getInventoryName()), getDriver().getScreenPosFromWorldPos(b.getPosition() - Vec2f(0, -b.getHeight() / 2)) - Vec2f(dimensions.x / 2, -8.0f), color_white);

					// draw mouse hover effect
					//if (canBePicked)
					{
						b.RenderForHUD(RenderStyle::additive);

						if (!tickPlayed)
						{
							if (blob.get_u16("hover netid") != b.getNetworkID())
							{
								Sound::Play(CFileMatcher("/select.ogg").getFirst());
							}

							blob.set_u16("hover netid", b.getNetworkID());
							tickPlayed = true;
						}

						//break;
					}
				}

			}

			// no hover
			if (!hover)
			{
				blob.set_u16("hover netid", 0);
			}

			// render outlines

			//for (uint i = 0; i < pickupBlobs.length; i++)
			//{
			//    pickupBlobs[i].RenderForHUD( RenderStyle::outline_front );
			//}
		}
	}
}
