#include "WAR_Structs.as";
#include "WAR_HUDCommon.as";
#include "TeamColour.as";
#include "HolidaySprites.as";

string hall_file_name;

//HUD serialisation done in the logic script now

const string WarGUITexture = "Rules/WAR/WarGUI.png";
bool tutorial = false;

void onInit(CRules@ this)
{
	hall_file_name = isAnyHoliday() ? getHolidayVersionFileName("Hall"); : "Hall.png";
	
	tutorial = this.hasTag("singleplayer");
}

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) { return; }

	GUI::SetFont("menu");

	//hud from rules bitstream
	CBitStream stream;
	this.get_CBitStream("WAR_serialised_team_hud", stream);

	u16 checkbits;
	if (stream.getBitsUsed() > 0 && stream.saferead_u16(checkbits) && checkbits == 0x54f3)
	{
		WAR_HUD hud(stream);
		const u32 gametime = getGameTime();
		Vec2f upperleft(10, 10);

		// calc sizes and raids
		bool aHallIsUnderRaid = false;
		for (uint hall_num = 0; hall_num < hud.halls.length; ++hall_num)
		{
			WAR_HUD_HALL@ hud_hall = hud.halls[hall_num];
			if (hud_hall.under_raid)
			{
				aHallIsUnderRaid = true;
				break;
			}
		}
		bool attackShown = false;
		Vec2f mouse = getControls().getMouseScreenPos();

		// draw background

		Vec2f size(128 + hud.halls.length * 32 , 64);
		GUI::DrawPane(upperleft, upperleft + size);

		// draw bears and eagles

		for (uint team_num = 0; team_num < hud.teams.length; ++team_num)
		{
			WAR_HUD_TEAM@ hud_team = hud.teams[team_num];

			CTeam@ team = this.getTeam(hud_team.number);
			if (team is null) continue;

			Vec2f mycorner = upperleft;
			if (hud_team.number == 1)
			{
				mycorner.x = upperleft.x + size.x - 64.0f;
			}

			const string team_image_fname = "GUI/TeamIcons.png";

			GUI::DrawIcon(team_image_fname, 48 + hud_team.number, Vec2f(32, 32), mycorner , 1.0f, hud_team.number);
			//todo icons
		}

		// draw shields

		for (uint hall_num = 0; hall_num < hud.halls.length; ++hall_num)
		{
			WAR_HUD_HALL@ hud_hall = hud.halls[hall_num];

			// draw top/left corner shields

			Vec2f mycorner = upperleft + Vec2f((hall_num + 2) * 32, 16);

			const string hall_image_fname = "Entities/Industry/Hall/" + hall_file_name;

			GUI::DrawIcon(hall_image_fname, 48, Vec2f(16, 16), mycorner , 1.0f, hud_hall.team_num);

			if (!hud_hall.under_raid || gametime % 30 < 15)
			{
				if (hud_hall.under_raid)
				{
					GUI::DrawIconByName("$ALERT$", mycorner + Vec2f(-17.0f, -16.0f));
				}

				// draw ticket count
				if (hud_hall.team_num < 10 && hud_hall.tickets != 0xcdcd)
				{
					mycorner.x += hud_hall.tickets > 9 ? 4 : 8;
					mycorner.y += 30.0f;
					SColor color;
					if (hud_hall.tickets == 0)
					{
						color = SColor(255, 255, 55, 0);
					}
					else if (hud_hall.tickets < 6)
					{
						color = SColor(255, 255, 255, 55);
					}
					else
					{
						color = SColor(255, 255, 255, 255);
					}

					GUI::DrawText("" + hud_hall.tickets,
					              mycorner,
					              color);
				}

				// draw factories
				//if (p.getTeamNum() == hud_hall.team_num )
				//{
				//	mycorner.y += 30.0f;
				//	const uint facCount = hud_hall.factoryIcons.length;
				//	for (uint i = 0; i < facCount; i++)
				//	{
				//		//	GUI::DrawRectangle( mycorner, mycorner + Vec2f(28.0f, 20.0f) );
				//		GUI::DrawIcon("Entities/Common/Sprites/MiniIcons.png", hud_hall.factoryIcons[i], Vec2f(16,16), mycorner + Vec2f(-1.0f,-8.0f), 1.0f, hud_hall.team_num );
				//		mycorner.y += facCount >= 4 ? 14.0f : 18.0f;
				//	}
				//}

			}

			// draw tasks for classes above hall

			if (!tutorial && u_showtutorial && (!aHallIsUnderRaid || hud_hall.under_raid))  // show only under raid hall if there is one
			{
				const f32 screenDist = 400.0f;

				CBlob@ playerBlob = p.getBlob();
				if (playerBlob !is null && playerBlob.getTickSinceCreated() < 360)
				{
					GUI::SetFont("menu");

					const bool isBuilder = playerBlob.getName() == "builder";
					const bool myTeamHall = playerBlob.getTeamNum() == hud_hall.team_num;
					CBlob@ hall = hud_hall.getBlob();
					if (hall !is null)
					{
						Vec2f pos2d = hall.getScreenPos();
						pos2d.y -= 190.0f + 6.0f * Maths::Sin(gametime / 5.5f);
						const f32 distance = (hall.getPosition() - playerBlob.getPosition()).getLength();
						const bool isOnScreen = distance < screenDist;
						Vec2f upperleft = pos2d + Vec2f(-70.0f, -16.0f);
						Vec2f lowerright = pos2d + Vec2f(70.0f, 16.0f);
						const bool mouseHover = (mouse.x > upperleft.x && mouse.x < lowerright.x && mouse.y > upperleft.y && mouse.y < lowerright.y);
						const bool hallOnLeft = pos2d.x < 150.0f;
						const bool hallOnRight = pos2d.x > getDriver().getScreenWidth() - 150.0f;


						string text;
						if (myTeamHall && hud_hall.under_raid)
						{
							if (hallOnLeft || hallOnRight) text = getTranslatedString("DEFEND THE HALL!");
							else text = getTranslatedString("DEFEND THE HALL!\n           $DEFEND_THIS$");
						}
						else if (myTeamHall && !hud_hall.under_raid && isOnScreen)
						{
							// todo: build factories / deply crates
							if (!isBuilder)
								continue;
							if (hud_hall.factoryIcons.length == 0 && gametime % 150 > 75)
							{
								text = getTranslatedString("BUILD WORKSHOPS\n           $BUILD$");
							}
							else
								text = getTranslatedString("BUILD DEFENSES\n           $BUILD$");
						}
						else if (!myTeamHall && isOnScreen && hud_hall.team_num > 10)
						{
							text = getTranslatedString("CAPTURE THE HALL!\n           $DEFEND_THIS$");
						}
						else if (!myTeamHall)
						{
							if (hallOnLeft && !isBuilder) text = getTranslatedString("$ATTACK_LEFT$ATTACK!");
							else if (hallOnRight && !isBuilder) text = getTranslatedString("ATTACK!$ATTACK_RIGHT$");
							else
							{
								if (!isOnScreen && isBuilder)
									continue;
								text = getTranslatedString("ATTACK!\n           $ATTACK_THIS$");
							}
							attackShown = true;
						}
						else
							continue;

						if (upperleft.y < 100)
							continue;
						GUI::DrawText(" " + text + " ", upperleft, lowerright, SColor(255, hud_hall.under_raid ? 255 : 0, 0, 0), true, true, !mouseHover);
					}
				}
			}
		}
	}

	//respawn text if needed
	string propname = "needs respawn hud " + p.getUsername();

	if (p.getBlob() is null && this.get_bool(propname))
	{
		propname = "time to spawn " + p.getUsername();
		s32 spawn_time = this.get_s32(propname);
		const bool noSpawns = spawn_time < 0;
		f32 difference = noSpawns ? -10000.0f : (f32(spawn_time - getGameTime()) / 30.0f);

		if (difference > 0 || difference < -1000.0f)
		{
			GUI::DrawText(!noSpawns ? getTranslatedString("Respawning in: {SEC}").replace("{SEC}", "" + Maths::Ceil(difference)) : getTranslatedString("No spawns available!") ,
			              Vec2f(getScreenWidth() / 2 - 90, getScreenHeight() * (0.3f) + Maths::Sin(getGameTime() / 3.0f) * 5.0f),
			              Vec2f(getScreenWidth() / 2 + 90, getScreenHeight() * (0.3f) + Maths::Sin(getGameTime() / 3.0f) * 5.0f + 30),
			              noSpawns ? SColor(0xffff1100) : SColor(0xffffff00), true, true);
		}
	}
}
