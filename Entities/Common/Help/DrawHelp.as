#include "Help.as";

#define CLIENT_ONLY

// globals - we can because this is only run by one (my) player
ConfigFile done;
bool loaded = false;
const f32 HELP_DISTANCE = 2.0f;
HelpText[] renderHelps;
u32 lastSaveTime = 0;
u16 lastNetworkID = 0;

string lastDone;
u32 lastDoneTime;

bool showHelpHelp = false;

bool releasedDown;
bool releasedLeft;
bool releasedRight;
bool releasedUp;
bool releasedAction1;
bool releasedAction2;
bool releasedAction3;
bool releasedUse;
bool releasedInventory;
bool releasedPickup;

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	//this.getCurrentScript().tickFrequency = 30;
	ResetKeyCache();

	if (lastNetworkID != this.getBlob().getNetworkID())
	{
		lastNetworkID = this.getBlob().getNetworkID();
		if (loaded)
		{
			done.saveFile("HelpDone.cfg");
		}
	}
}

void ResetKeyCache()
{
	releasedDown = releasedLeft = releasedRight = releasedUp = releasedAction1 =
	                                  releasedAction2 = releasedAction3 = releasedUse = releasedInventory = releasedPickup = false;
}

void Done(const string &in name, const string &in prefix)
{
	const string name2 = prefix + " " + name;
	if (done.exists(name2))
	{
		int amount = 1 + done.read_u32(name2);
		done.add_u32(name2, amount);
	}
	else
		done.add_u32(name2, 1);

	lastDone = name;
	lastDoneTime = getGameTime();
}

void onTick(CSprite@ this)
{
	if (g_videorecording)
	{
		doSave();
		return;
	}
	/*if (!u_showtutorial)
	{
		doSave();
		return;
	}*/

	CBlob@ blob = this.getBlob();
	const u32 gametime = getGameTime();

	CBlob@[] blobsInRadius;
	CMap@ map = blob.getMap();
	CInventory@ inv = blob.getInventory();
	CBlob@ carried = blob.getCarriedBlob();

	if (!loaded)
	{
		if (!done.loadFile("../Cache/HelpDone.cfg"))
		{
			done.saveFile("HelpDone.cfg");
		}

		if (done.exists("showHelpHelp"))
		{
			showHelpHelp = done.read_u32("showHelpHelp") != 0;
		}
		else
		{
			showHelpHelp = true;
		}

		loaded = true;
	}

	// cahce key presses

	if (blob.isKeyJustReleased(key_down))
	{
		releasedDown = true;
	}
	if (blob.isKeyJustReleased(key_left))
	{
		releasedLeft = true;
	}
	if (blob.isKeyJustReleased(key_right))
	{
		releasedRight = true;
	}
	if (blob.isKeyJustReleased(key_up))
	{
		releasedUp = true;
	}
	if (blob.isKeyJustReleased(key_action1))
	{
		releasedAction1 = true;
	}
	if (blob.isKeyJustReleased(key_action2))
	{
		releasedAction2 = true;
	}
	if (blob.isKeyJustReleased(key_action3))
	{
		releasedAction3 = true;
	}
	if (blob.isKeyJustReleased(key_use))
	{
		releasedUse = true;
	}
	if (blob.isKeyJustReleased(key_inventory))
	{
		releasedInventory = true;
	}
	if (blob.isKeyJustReleased(key_pickup))
	{
		releasedPickup = true;
	}

	if (gametime % 43 == 0)
	{
		// seated

		if (blob.isAttached())
		{
			if (releasedAction1)
			{
				AttachmentPoint@ ap = blob.getAttachments().getAttachmentPointByName("GUNNER");
				if (ap !is null && ap.getOccupied() !is null && isRecipientOfHelp(blob, ap.getOccupied(), "help GUNNER action"))
				{
					Done("done help GUNNER action", blob.getName());
				}
			}

			if (releasedDown || releasedLeft || releasedRight)
			{
				AttachmentPoint@ ap = blob.getAttachments().getAttachmentPointByName("DRIVER");
				if (ap !is null && ap.getOccupied() !is null && isRecipientOfHelp(blob, ap.getOccupied(), "help DRIVER movement"))
				{
					Done("done help DRIVER movement", blob.getName());
				}
			}

			if (releasedUp)
			{
				AttachmentPoint@ ap = blob.getAttachments().getAttachmentPointByName("GUNNER");
				if (ap !is null && ap.getOccupied() !is null && isRecipientOfHelp(blob, ap.getOccupied(), "help hop out"))
				{
					Done("done help hop out", blob.getName());
				}
			}
		}
		else
		{
			// near

			if (map !is null && map.getBlobsInRadius(blob.getPosition(), blob.getRadius() + HELP_DISTANCE, @blobsInRadius))
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (b !is blob)
					{
						if (releasedUse && isRecipientOfHelp(blob, b, "help use"))
						{
							Done("done help use", b.getName());
						}

						if (releasedAction1 && isRecipientOfHelp(blob, b, "help action"))
						{
							Done("done help action", b.getName());
						}

						if (releasedAction2)
						{
							if (isRecipientOfHelp(blob, b, "help action2"))
								Done("done help action2", b.getName());
						}

						if (releasedUp && isRecipientOfHelp(blob, b, "help jump"))
						{
							Done("done help jump", b.getName());
						}

						if (releasedDown && isRecipientOfHelp(blob, b, "help hop"))
						{
							Done("done help hop", b.getName());
						}

						if (gametime % 30 == 0 && isRecipientOfHelp(blob, b, "help show"))
						{
							Done("done help show", b.getName());
						}
					}
				}
			}

			// carried

			if (carried !is null)
			{
				if (isRecipientOfHelp(blob, carried, "help pickup"))
				{
					Done("done help pickup", carried.getName());
				}

				if (releasedAction3 && isRecipientOfHelp(blob, carried, "help activate"))
				{
					Done("done help activate", carried.getName());
				}

				if (releasedAction3 && isRecipientOfHelp(blob, carried, "help rotate"))
				{
					Done("done help rotate", carried.getName());
				}

				if (releasedAction3 && isRecipientOfHelp(blob, carried, "help throw") && carried.hasTag("activated"))
				{
					Done("done help throw", carried.getName());

					// hack:
					if (carried.getName() == "bomb")
					{
						Done("done help activate", "mat_bombs");
					}
				}

				if (releasedUse && isRecipientOfHelp(blob, carried, "help use carried"))
				{
					Done("done help use carried", carried.getName());
				}

			}

			// inventory

			string lastitem;
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @b = inv.getItem(i);

				if (releasedInventory && isRecipientOfHelp(blob, b, "help switch"))
				{
					Done("done help switch", b.getName());
				}
			}

			// general - self

			if (releasedAction2 && isRecipientOfHelp(blob, blob, "help self action2"))
			{
				Done("done help self action2", blob.getName());
			}

			if (releasedAction1 && isRecipientOfHelp(blob, blob, "help self action"))
			{
				Done("done help self action", blob.getName());
			}

			if (carried !is null && releasedPickup && isRecipientOfHelp(blob, blob, "help throw"))
			{
				Done("done help throw", blob.getName());
			}

			if (carried !is null && releasedInventory && isRecipientOfHelp(blob, blob, "help putback"))
			{
				Done("done help putback", blob.getName());
			}

			if (releasedInventory && isRecipientOfHelp(blob, blob, "help inventory"))
			{
				Done("done help inventory", blob.getName());
			}

			if ((releasedUp || releasedLeft || releasedRight) && isRecipientOfHelp(blob, blob, "help movement"))
			{
				Done("done help movement", blob.getName());
			}

			if (releasedDown && isRecipientOfHelp(blob, blob, "help self hide"))
			{
				Done("done help self hide", blob.getName());
			}

			if (gametime % 30 == 0 && isRecipientOfHelp(blob, blob, "help show"))
			{
				Done("done help show", blob.getName());
			}
		}

		ResetKeyCache();
	}

	// GATHER

	if (gametime % 36 == 0)
	{
		renderHelps.clear();

		// seated

		if (blob.isAttached())
		{
			AttachmentPoint@ gunner = blob.getAttachments().getAttachmentPointByName("GUNNER");
			if (gunner !is null && gunner.getOccupied() !is null)
			{
				if (shouldDraw(blob, gunner.getOccupied(), "help GUNNER action"))
				{
					renderHelps.push_back(getHelpText(gunner.getOccupied(), "help GUNNER action"));
				}
				if (shouldDraw(blob, gunner.getOccupied(), "help hop out"))
				{
					renderHelps.push_back(getHelpText(gunner.getOccupied(), "help hop out"));
				}
			}

			AttachmentPoint@ vehicle = blob.getAttachments().getAttachmentPointByName("DRIVER");
			if (vehicle !is null && vehicle.getOccupied() !is null)
			{
				if (shouldDraw(blob, vehicle.getOccupied(), "help DRIVER movement"))
				{
					renderHelps.push_back(getHelpText(vehicle.getOccupied(), "help DRIVER movement"));
				}
				if (shouldDraw(blob, vehicle.getOccupied(), "help hop out"))
				{
					renderHelps.push_back(getHelpText(vehicle.getOccupied(), "help hop out"));
				}
			}

		}
		else
		{
			// near

			if (map !is null && map.getBlobsInRadius(blob.getPosition(), blob.getRadius() + HELP_DISTANCE, @blobsInRadius))
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (b !is blob && !wasAlreadyInList(blobsInRadius, i, b))
					{
						if (!b.isAttached()
						        && (!b.hasTag("flesh") || b.hasTag("trader")))  // HACK
						{
							HelpText[]@ helps = getHelps(b);
							if (helps !is null)
							{
								for (uint i = 0; i < helps.length; i++)
								{
									HelpText@ ht = helps[i];
									if (ht.name != "help movement" && ht.name != "help putback" && ht.name != "help activate" && ht.name != "help throw" && ht.name != "help rotate" && ht.name != "help GUNNER action"  && ht.name != "help DRIVER movement" && ht.name != "help hop out" 	  //HACK:
									        && shouldDraw(blob, b, ht))
									{
										renderHelps.push_back(ht);
									}
								}
							}
						}
					}
				}
			}

			// inventory

			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @b = inv.getItem(i);
				if (shouldDraw(blob, b, "help activate"))
				{
					renderHelps.push_back(getHelpText(b, "help activate"));
				}

				if (shouldDraw(blob, b, "help switch"))
				{
					renderHelps.push_back(getHelpText(b, "help switch"));
				}
			}

			//carry

			if (carried !is null)
			{
				if (shouldDraw(blob, carried, "help activate") && !carried.hasTag("activated"))
				{
					renderHelps.push_back(getHelpText(carried, "help activate"));
				}

				if (shouldDraw(blob, carried, "help throw") && carried.hasTag("activated"))
				{
					renderHelps.push_back(getHelpText(carried, "help throw"));
				}

				if (shouldDraw(blob, carried, "help rotate"))
				{
					renderHelps.push_back(getHelpText(carried, "help rotate"));
				}

				if (shouldDraw(blob, carried, "help use carried"))
				{
					renderHelps.push_back(getHelpText(carried, "help use carried"));
				}
			}


			// general - self


			HelpText[]@ helps = getHelps(blob);
			if (helps !is null)
			{
				for (uint i = 0; i < helps.length; i++)
				{
					HelpText@ ht = helps[i];
					if (((ht.name != "help throw") || (carried !is null && !carried.hasTag("temp blob") && !carried.hasTag("activated")))
					        && shouldDraw(blob, blob, ht))
					{
						renderHelps.push_back(ht);
					}
				}
			}
		}
	}

	// SAVE

	doSave();
}

void doSave()
{
	const u32 gametime = getGameTime();
	if (gametime - lastSaveTime > (!u_showtutorial ? 1800 : 600))
	{
		done.add_u32("showHelpHelp", showHelpHelp ? 1 : 0);
		done.saveFile("HelpDone.cfg");
		lastSaveTime = gametime;
	}
}

bool wasAlreadyInList(CBlob@[] blobs, uint index, CBlob@ blob)
{
	const string name = blob.getName();
	for (uint i = 0; i < index; i++)
	{
		CBlob @b = blobs[i];
		if (name == b.getName())
			return true;
	}
	return false;
}

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	Vec2f offset(52.0f, getDriver().getScreenHeight() - 68.0f);

	CBlob@ blob = this.getBlob();

	int count = 0;

	// render helps

	const int size = renderHelps.size();
	for (int i = size - 1; i >= 0; i--)
	{
		if (renderHelps[i].showAlways == true || u_showtutorial)
		{
			offset = DrawHelp(blob, renderHelps[i], offset);
		}
	}

	// draw item captions

	if (u_showtutorial)
	{
		if (getHUD().menuState == 0 && !getHUD().hasButtons() && !getHUD().hasMenus() &&
		        !blob.isKeyPressed(key_left) && !blob.isKeyPressed(key_right) &&
		        !blob.isKeyPressed(key_up) && !blob.isKeyPressed(key_action1) &&
		        !blob.isKeyPressed(key_down) && !blob.isKeyPressed(key_action2) &&
		        !blob.isKeyPressed(key_pickup) && !blob.isKeyPressed(key_inventory)
		   )
		{
			CBlob@ mouseBlob = getMap().getBlobAtPosition(getControls().getMouseWorldPos());
			if (mouseBlob !is null && (!mouseBlob.hasTag("player") || mouseBlob.hasTag("migrant")))
			{
				string invName = getTranslatedString(mouseBlob.getInventoryName());
				Vec2f dimensions;
				GUI::SetFont("menu");
				GUI::GetTextDimensions(invName, dimensions);
				GUI::DrawText(invName, getDriver().getScreenPosFromWorldPos(mouseBlob.getInterpolatedPosition() - Vec2f(0, -mouseBlob.getHeight() / 2)) - Vec2f(dimensions.x / 2, -8.0f), color_white);					//	mouseBlob.RenderForHUD( RenderStyle::outline_front );
			}
		}
	}

	// draw arrow for noobs

	if (showHelpHelp && u_showtutorial)
	{
		int bounce = 4 * Maths::Sin((getGameTime() + blob.getNetworkID()) / 4.5f);
		Vec2f upperleft = offset + Vec2f(-30.0f, -199.0f + bounce);
		Vec2f lowerright = offset + Vec2f(170.0f, 0.0f + bounce);
		GUI::SetFont("menu");
		GUI::DrawText(getTranslatedString("$!!!$$GREEN$WATCH THESE FOR          .          GAMEPLAY HELP$GREEN$\n\n\n$KEY_ESC$ CHECK CONTROLS\n\n$KEY_F1$ HELP ON/OFF\n\n(click to remove this)\n\n      $DEFEND_THIS$"), upperleft, lowerright, color_black, true, true, true);

		if (getControls().mousePressed1)
		{
			Vec2f mousepos2d = getControls().getMouseScreenPos();
			if (mousepos2d.x > upperleft.x && mousepos2d.x < lowerright.x && mousepos2d.y > upperleft.y && mousepos2d.y < lowerright.y)
			{
				showHelpHelp = false;
			}

			if (getGameTime() > 1000)
			{
				showHelpHelp = false;
			}
		}
	}
}

Vec2f DrawHelpText(const string &in text, Vec2f offset, f32 donePercent, const bool drawBackground, const bool drawGlow)
{
	if (text.size() == 0)
		return Vec2f_zero;
	//Vec2f pos = this.getScreenPos();
	Vec2f pos = offset;
	//f32 y = Maths::Max( 200, int(pos.y) );
	f32 y = pos.y;
	Vec2f dim;
	GUI::SetFont("menu");
	GUI::GetTextDimensions(text, dim);
	Vec2f ul = Vec2f(pos.x - 50, y - 18.0f);
	Vec2f lr = Vec2f(pos.x + 240.0f, y + 18.0f);
	if (drawBackground)
	{
		if (!drawGlow)
		{
			GUI::DrawProgressBar(ul, lr, donePercent);
		}
		else
		{
			GUI::DrawButtonHover(ul, lr);
		}
	}
	GUI::DrawText(text, ul + Vec2f(5.0f, 6.0f), lr, color_white, false, false);
	return dim;
}

Vec2f DrawHelp(CBlob@ this, HelpText @ht, Vec2f offset)
{
	if (offset.y < 570.f)
		return offset; // no drawing

	if (ht !is null)
	{
		const bool recipient = isRecipientOfHelp(this, ht);
		ht.drawSize = DrawHelpText(recipient ? ht.text : ht.altText, Vec2f(offset.x * ht.fadeOut, offset.y), 0.0f, true, false);	// 1.0f - (ht.reduceAfterTimes == 0 ? 0.0f : float(ht.usedCount)/float(ht.reduceAfterTimes))
		if (recipient || ht.altText.size() > 0)
		{
			offset.y -= 50.0f;
		}
		return offset;
	}
	return offset;
}

bool isRecipientOfHelp(CBlob@ this, HelpText@ ht)
{
	if (ht is null)
		return false;
	const string name = this.getName();
	//printf("name " + name + " ht.recipient " + ht.recipient );
	return (ht.recipient.size() == 0 || ht.recipient == name);
}

bool isRecipientOfHelp(CBlob@ this, CBlob@ b, const string &in name)
{
	HelpText @ht = getHelpTextWithRecipient(b, name, this.getName());
	if (ht !is null)
	{
		return isRecipientOfHelp(this, ht);
	}
	return false;
}

bool isInReach(CBlob@ this, CBlob@ blob)
{
	Vec2f col;
	return (!getMap().rayCastSolid(blob.getPosition(), this.getPosition(), col));
}

bool shouldDraw(CBlob@ this, CBlob@ blob, HelpText@ help)
{
	if (help.fadeOut < -5.0f)
		return false;
	if (isInReach(this, blob))
	{
		string doneName = blob.getName() + " done " + help.name;
		if (!done.exists(doneName))
			return true;
		help.usedCount = done.read_u32(doneName);
		if (help.usedCount < help.reduceAfterTimes + 1)
			return true;
		else
		{
			//if (blob.getTickSinceCreated() < 90) {
			//	help.fadeOut = -10.0f;
			//}
			//else if (help.fadeOut > 0.74f)
			//{
			//	help.fadeOut -= 0.0025f;
			//	return true;
			//}
			//else
			//if (help.fadeOut > 0.33f)
			//{
			//	help.fadeOut *= 1.35f * help.fadeOut;
			//	return true;
			//}
			//else
			//	if (help.fadeOut > -5.0f)
			//	{
			//		help.fadeOut -= 0.1f;
			//		return true;
			//	}
		}
	}

	return false;
}


bool shouldDraw(CBlob@ this, CBlob@ blob, const string &in helpName)
{
	// drawn already?
	for (uint i = 0; i < renderHelps.length; i++)
	{
		HelpText@ ht = renderHelps[i];
		if (helpName == ht.name)
		{
			return false;
		}
	}

	HelpText@ help = getHelpTextWithRecipient(blob, helpName, this.getName());
	if (help is null)
	{
		return false;
	}

	return shouldDraw(this, blob, help);
}
