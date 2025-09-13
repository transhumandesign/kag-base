
// set camera on local player
// this just sets the target, specific camera vars are usually set in StandardControls.as

#define CLIENT_ONLY

#include "Spectator.as"

int deathTime = 0;
Vec2f deathLock;
int helptime = 0;
bool spectatorTeam;

void Reset(CRules@ this)
{
	SetTargetPlayer(null);
	CCamera@ camera = getCamera();
	if (camera !is null)
	{
		camera.setTarget(null);
		// start fairly unzoomed, so we have a nice zoom-in effect
		camera.targetDistance = 0.25f;
	}

	currentTarget = 0;
	switchTarget = 0;

	//initially position camera to view entire map
	ViewEntireMap();
	// force lock camera position immediately, even if not cinematic
	posActual = posTarget;

	panEaseModifier = 1.0f;
	zoomEaseModifier = 1.0f;

	timeToCinematic = 0;
	deathTime = 0;
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	helptime = 0;
	setCinematicEnabled(true);
	setCinematicForceDisabled(false);
	Reset(this);
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	CCamera@ camera = getCamera();
	if (camera !is null && player !is null && player is getLocalPlayer())
	{
		posActual = blob.getPosition();
		camera.setPosition(posActual);
		camera.setTarget(blob);
		camera.mousecamstyle = 1; //follow
	}
}

//change to spectator cam on team change
void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	CCamera@ camera = getCamera();
	CBlob@ playerBlob = player is null ? player.getBlob() : null;

	if (camera !is null && newteam == this.getSpectatorTeamNum() && getLocalPlayer() is player)
	{
		resetHelpText();
		spectatorTeam = true;
		camera.setTarget(null);
		setCinematicEnabled(true);
		if (playerBlob !is null)
		{
			playerBlob.ClearButtons();
			playerBlob.ClearMenus();

			posActual = playerBlob.getPosition();
			camera.setPosition(posActual);
			deathTime = getGameTime();
		}
	}
	else if (getLocalPlayer() is player)
	{
		spectatorTeam = false;
	}
}

void resetHelpText()
{
	helptime = getGameTime();
}

//Change to spectator cam on death
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	CCamera@ camera = getCamera();
	CBlob@ victimBlob = victim !is null ? victim.getBlob() : null;
	CBlob@ attackerBlob = attacker !is null ? attacker.getBlob() : null;

	//Player died to someone
	if (camera !is null && victim is getLocalPlayer())
	{
		// let's only bother with the info pane on switching to spec
		// resetHelpText();

		//Player killed themselves
		if (victim is attacker || attacker is null)
		{
			camera.setTarget(null);
			if (victimBlob !is null)
			{
				victimBlob.ClearButtons();
				victimBlob.ClearMenus();
				deathLock = victimBlob.getPosition();
			}
		}
		else
		{
			if (victimBlob !is null)
			{
				victimBlob.ClearButtons();
				victimBlob.ClearMenus();
			}

			if (attackerBlob !is null)
			{
				SetTargetPlayer(attackerBlob.getPlayer());
				deathLock = victimBlob.getPosition();
			}
			else
			{
				camera.setTarget(null);
			}
		}

		deathTime = getGameTime() + 1 * getTicksASecond();
		setCinematicEnabled(true);
	}
}

void SpecCamera(CRules@ this)
{
	//death effect
	CCamera@ camera = getCamera();
	if (camera !is null && getLocalPlayerBlob() is null && getLocalPlayer() !is null)
	{
		const int diffTime = deathTime - getGameTime();
		// death effect
		if (!spectatorTeam && diffTime > 0)
		{
			//lock camera
			posActual = deathLock;
			camera.setPosition(deathLock);
			//zoom in for a bit
			const float zoom_target = 2.0f;
			const float zoom_speed = 5.0f;
			camera.targetDistance = Maths::Min(zoom_target, camera.targetDistance + zoom_speed * getRenderDeltaTime());
		}
		else
		{
			Spectator(this);
		}
	}
}

void onRender(CRules@ this)
{
	if (!v_capped)
	{
		SpecCamera(this);
	}

	if (targetPlayer() !is null && getLocalPlayerBlob() is null)
	{
		GUI::SetFont("menu");
		GUI::DrawText(
			getTranslatedString("Following {CHARACTERNAME} ({USERNAME})")
			.replace("{CHARACTERNAME}", targetPlayer().getCharacterName())
			.replace("{USERNAME}", targetPlayer().getUsername()),
			Vec2f(getScreenWidth() / 2 - 90, getScreenHeight() * (0.2f)),
			Vec2f(getScreenWidth() / 2 + 90, getScreenHeight() * (0.2f) + 30),
			SColor(0xffffffff), true, true
		);
	}

	if (getLocalPlayerBlob() !is null)
	{
		return;
	}

	if (!v_camera_cinematic)
	{
		return;
	}

	int time = getGameTime() + getInterpolationFactor();
	const int endTime1 = helptime + (getTicksASecond() * 1);

	GUI::SetFont("menu");

	Vec2f screenSize = getDriver().getScreenDimensions();
	Vec2f mousePos = getControls().getMouseScreenPos();

	string text = "Cinematic camera";
	Vec2f textMaxSize;
	GUI::GetTextDimensions(text, textMaxSize);

	Vec2f noticeOrigin(128, screenSize.y - 23);
	Vec2f rmbIconOrigin = noticeOrigin + Vec2f(0, -2);
	Vec2f indIconOrigin = noticeOrigin + Vec2f(34, 4);
	Vec2f textOrigin = noticeOrigin + Vec2f(52, 3);
	Vec2f noticeSize(
		textOrigin.x - noticeOrigin.x + textMaxSize.x + 12,
		28
	);
	Vec2f indicatorOrigin(
		noticeOrigin.x + 24,
		screenSize.y
	);
	Vec2f indicatorSize(
		noticeOrigin.x + noticeSize.x - indicatorOrigin.x,
		2.0f
	);

	Vec2f proximityCheckOrigin(
		noticeOrigin.x + noticeSize.x * 0.5,
		screenSize.y
	);
	// stretch Y to reduce false positives
	Vec2f cursorDiff = mousePos - proximityCheckOrigin;
	cursorDiff *= Vec2f(1.0f, 3.5f); // cause no dot opMul lmao.
	float cursorProximity = cursorDiff.Length();
	cursorProximity = Maths::Clamp01((cursorProximity - 96) / 64.0f);

	float timeToCinematicFactor = (
		!cinematicForceDisabled && !cinematicEnabled
		? timeToCinematic / AUTO_CINEMATIC_TIME
		: 0.0f
	);

	// hide the tip if the cursor is far AND if the help tip was shown for a
	// while
	float hidingFactor = Maths::Min(
		Maths::Min(
			cursorProximity,
			Maths::Clamp01(1.0f - timeToCinematicFactor * 16.0)
		),
		Maths::Clamp01((time - endTime1) / 2.0)
	);

	if (hidingFactor > 0.99f)
	{
		return;
	}

	Vec2f addedOffset = Vec2f(0.0, 18.0) * hidingFactor;
	noticeOrigin += addedOffset;
	rmbIconOrigin += addedOffset;
	indIconOrigin += addedOffset;
	textOrigin += addedOffset;

	string indicatorToken = (
		cinematicForceDisabled
		? "$SmallIndicatorInactive$"
		: "$SmallIndicatorOn$"
	);

	GUI::DrawPane(noticeOrigin + Vec2f(8.0, 0.0), noticeOrigin + noticeSize);
	GUI::DrawIconByName(indicatorToken, indIconOrigin);
	GUI::DrawText(text, textOrigin, SColor());

	if (timeToCinematicFactor > 0.01)
	{
		for (int yoff = 1; yoff <= indicatorSize.y; ++yoff)
		{
			GUI::DrawLine2D(
				Vec2f(indicatorOrigin.x, indicatorOrigin.y - yoff),
				Vec2f(indicatorOrigin.x + (indicatorSize.x * timeToCinematicFactor), indicatorOrigin.y - yoff),
				SColor(255, 255, 200, 0)
			);
		}
	}

	GUI::DrawIconByName("$RMB$", rmbIconOrigin);
}

void onTick(CRules@ this)
{
	if (v_capped)
	{
		SpecCamera(this);
	}

	if (isCinematic())
	{
		Vec2f mapDim = getMap().getMapDimensions();

		if (this.isMatchRunning())
		{
			CBlob@[]@ importantBlobs = buildImportanceList();
			SortBlobsByImportance(importantBlobs);

			panEaseModifier = 1.0f;

			if (!FOCUS_ON_IMPORTANT_BLOBS || !focusOnBlob(importantBlobs))
			{
				Vec2f newTarget = Vec2f_zero;
				CBlob@[] playerBlobs;
				if (getBlobsByTag("player", @playerBlobs))
				{
					Vec2f minPos = mapDim;
					Vec2f maxPos = Vec2f_zero;

					for (uint i = 0; i < playerBlobs.length; i++)
					{
						CBlob@ blob = playerBlobs[i];
						Vec2f pos = blob.getPosition();

						CBlob@[] blobOverlaps;
						blob.getOverlapping(@blobOverlaps);

						//max distance along each axis
						maxPos.x = Maths::Max(maxPos.x, pos.x);
						maxPos.y = Maths::Max(maxPos.y, pos.y);
						minPos.x = Maths::Min(minPos.x, pos.x);
						minPos.y = Maths::Min(minPos.y, pos.y);

						//sum player positions
						newTarget += pos;
					}

					//mean position of all players
					newTarget /= playerBlobs.length;

					panEaseModifier = 1.0 / Maths::Min(8.0f, playerBlobs.length + 1.0f);

					// try to curb shakiness when players move a lot
					if ((newTarget - posTarget).Length() > 6.0f * Maths::Min(16, playerBlobs.length + 1))
					{
						// move now
						posTarget = newTarget;

						//zoom target
						Vec2f maxDist = maxPos - minPos;
						calculateZoomTarget(maxDist.x, maxDist.y);
					}
				}
				else //no player blobs
				{
					ViewEntireMap();
				}
			}
		}
		else //game not in progress
		{
			ViewEntireMap();
		}
	}

	//right click to toggle cinematic camera
	CControls@ controls = getControls();
	if (
		v_camera_cinematic &&                               //user didn't perma disable
		controls !is null &&								//controls exist
		controls.isKeyJustPressed(KEY_RBUTTON) &&			//right clicked
		(spectatorTeam || getLocalPlayerBlob() is null) && //is in spectator or dead
		getGameTime() > deathTime)
	{
		if (cinematicForceDisabled)
		{
			SetTargetPlayer(null);
			setCinematicEnabled(true);
			setCinematicForceDisabled(false);
			resetHelpText();
			Sound::Play("Sounds/GUI/menuclick.ogg");
		}
		else
		{
			setCinematicForceDisabled(true);
			resetHelpText();
			Sound::Play("Sounds/GUI/back.ogg");
		}
	}
}
