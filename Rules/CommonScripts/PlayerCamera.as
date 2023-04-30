
// set camera on local player
// this just sets the target, specific camera vars are usually set in StandardControls.as

#define CLIENT_ONLY

#include "Spectator.as"

int deathTime = 0;
Vec2f deathLock;
int helptime = 0;
bool spectatorTeam;

Vec2f pos;

void Reset(CRules@ this)
{
	SetTargetPlayer(null);
	CCamera@ camera = getCamera();
	if (camera !is null)
	{
		camera.setTarget(null);
	}

	helptime = 0;
	setCinematicEnabled(true);
	currentTarget = 0;
	switchTarget = 0;

	//initially position camera to view entire map
	ViewEntireMap();
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	CCamera@ camera = getCamera();
	if (camera !is null && player !is null && player is getLocalPlayer())
	{
		pos = blob.getPosition();
		camera.setPosition(pos);
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

			pos = playerBlob.getPosition();
			camera.setPosition(pos);
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
	if (u_showtutorial)
	{
		helptime = getGameTime();
	}
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
		resetHelpText();
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

void onRender(CRules@ this)
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
			pos = deathLock;
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

	int time = getGameTime();

	GUI::SetFont("menu");

	const int endTime1 = helptime + (getTicksASecond() * 12);
	const int endTime2 = helptime + (getTicksASecond() * 24);
	const int endTime3 = helptime + (getTicksASecond() * 36);

	string text = "";

	if (time < endTime1)
	{
		text = "You can use the movement keys and clicking to move the camera.";
	}
	else if (time < endTime2)
	{
		text = "If you click on a player the camera will follow them.\nSimply press the movement keys or click again to stop following a player.";
	}
	else if (time < endTime3)
	{
		text = "Pressing right click enables cinematic camera.\nThe camera will automatically follow the action.";
	}

	if (text != "" && u_showtutorial)
	{
		//translate
		text = getTranslatedString(text);
		//position post translation so centering works properly
		Vec2f ul, lr;
		ul = Vec2f(getScreenWidth() / 2.0, 3.0 * getScreenHeight() / 4);
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		ul -= size * 0.5;
		lr = ul + size;
		//wiggle up and down
		float wave = Maths::Sin(getGameTime() / 10.0f) * 5.0f;
		ul.y += wave;
		lr.y += wave;
		//draw
		GUI::DrawButtonPressed(ul - Vec2f(10, 10), lr + Vec2f(10, 10));
		GUI::DrawText(text, ul, SColor(0xffffffff));
	}
}

void onTick(CRules@ this)
{
	if (isCinematic())
	{
		Vec2f mapDim = getMap().getMapDimensions();

		if (this.isMatchRunning())
		{
			if (getGameTime() % CINEMATIC_UPDATE_INTERVAL == 0)
			{
				CBlob@[]@ blobs = buildImportanceList();
				SortBlobsByImportance(blobs);
				importantBlobs = blobs;
			}

			if (!FOCUS_ON_IMPORTANT_BLOBS || !focusOnBlob(importantBlobs))
			{
				CBlob@[] playerBlobs;
				if (getBlobsByTag("player", @playerBlobs))
				{
					posTarget = Vec2f_zero;
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
						posTarget += pos;
					}

					//mean position of all players
					posTarget /= playerBlobs.length;

					//zoom target
					Vec2f maxDist = maxPos - minPos;
					calculateZoomTarget(maxDist.x, maxDist.y);
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

	//right click to enable cinematic camera
	CControls@ controls = getControls();
	if (
		controls !is null &&								//controls exist
		controls.isKeyJustPressed(KEY_RBUTTON) &&			//right clicked
		(spectatorTeam || getLocalPlayerBlob() is null))	//is in spectator or dead
	{
		SetTargetPlayer(null);
		setCinematicEnabled(true);
	}
}
