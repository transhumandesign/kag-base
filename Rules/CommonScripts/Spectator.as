#include "CinematicCommon.as";

#define CLIENT_ONLY

const f32 CINEMATIC_PAN_X_EASE = 12.0f;					//amount of ease along the x-axis while cinematic
const f32 CINEMATIC_PAN_Y_EASE = 12.0f;					//amount of ease along the y-axis while cinematic

const f32 CINEMATIC_ZOOM_EASE = 14.0f;					//amount of ease when zooming while cinematic
const f32 CINEMATIC_CLOSEST_ZOOM = 1.5f;				//how close the camera can zoom in while cinematic (default is 2.0f)
const f32 CINEMATIC_FURTHEST_ZOOM = 0.75f;				//how far the camera can zoom out while cinematic (default is 0.5f)

const bool AUTO_CINEMATIC = false;						//whether camera automatically becomes cinematic after no input
const u32 CINEMATIC_TIME = 10.0f * getTicksASecond();	//time until camera automatically becomes cinematic in seconds

Vec2f posTarget;										//position which cinematic camera moves towards
f32 zoomTarget = 1.0f;									//zoom level which camera zooms towards
float timeToScroll = 0.0f;								//time until next able to scroll to zoom camera
float timeToCinematic = 0.0f;							//time until camera automatically becomes cinematic
CBlob@ currentTarget;									//the current target blob
u32 switchTarget;										//time when camera can move onto new target

bool justClicked = false;
string _targetPlayer;
bool waitForRelease = false;

CPlayer@ targetPlayer()
{
	return getPlayerByUsername(_targetPlayer);
}

void SetTargetPlayer(CPlayer@ p)
{
	_targetPlayer = "";
	if (p is null) return;
	_targetPlayer = p.getUsername();
}

void Spectator(CRules@ this)
{
	CCamera@ camera = getCamera();
	CControls@ controls = getControls();
	CMap@ map = getMap();

	if (camera is null || controls is null || map is null)
	{
		return;
	}

	//variables
	Vec2f mapDim = map.getMapDimensions();
	f32 camSpeed = getRenderApproximateCorrectionFactor() * 15.0f / zoomTarget;

    if (this.get_bool("set new target"))
    {
        string newTarget = this.get_string("new target");
        _targetPlayer = newTarget;
        if (targetPlayer() !is null)
        {
            waitForRelease = true;
            this.set_bool("set new target", false);
        }
    }

	//scroll to zoom
	if (timeToScroll <= 0)
	{
		if (controls.mouseScrollUp)
		{
			timeToScroll = 7;
			setCinematicEnabled(false);

			if (zoomTarget < 1.0f)
			{
				zoomTarget = 1.0f;
			}
			else
			{
				zoomTarget = 2.0f;
			}
		}
		else if (controls.mouseScrollDown)
		{
			timeToScroll = 7;
			setCinematicEnabled(false);

			if (zoomTarget > 1.0f)
			{
				zoomTarget = 1.0f;
			}
			else
			{
				zoomTarget = 0.5f;
			}
		}
	}
	else
	{
		timeToScroll -= getRenderApproximateCorrectionFactor();
	}

	//move camera using action movement keys
	if (controls.ActionKeyPressed(AK_MOVE_LEFT))
	{
		pos.x -= camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}
	if (controls.ActionKeyPressed(AK_MOVE_RIGHT))
	{
		pos.x += camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}
	if (controls.ActionKeyPressed(AK_MOVE_UP))
	{
		pos.y -= camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}
	if (controls.ActionKeyPressed(AK_MOVE_DOWN))
	{
		pos.y += camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}

    if (controls.isKeyJustReleased(KEY_LBUTTON))
    {
        waitForRelease = false;
    }

	if (!isCinematicEnabled()) //player-controlled zoom
	{
		if (Maths::Abs(camera.targetDistance - zoomTarget) > 0.001f)
		{
			camera.targetDistance = (camera.targetDistance * (3.0f - getRenderApproximateCorrectionFactor() + 1.0f) + (zoomTarget * getRenderApproximateCorrectionFactor())) / 4.0f;
		}
		else
		{
			camera.targetDistance = zoomTarget;
		}

		if (AUTO_CINEMATIC)
		{
			timeToCinematic -= getRenderApproximateCorrectionFactor();
			if (timeToCinematic <= 0)
			{
				setCinematicEnabled(true);
			}
		}
	}
	else //cinematic camera
	{
		//by default, view entire map from center
		posTarget = Vec2f(mapDim.x, mapDim.y) / 2.0f;
		f32 zoomW = calculateZoomLevelW(mapDim.x);
		f32 zoomH = calculateZoomLevelH(mapDim.y);
		zoomTarget = Maths::Min(zoomW, zoomH);
		zoomTarget = Maths::Clamp(zoomTarget, 0.5f, 2.0f); //its fine to clamp between default min/max zoom here

		CBlob@[] blobs;
		getBlobs(@blobs);
		calculateImportance(blobs);
		blobs = sortBlobsByImportance(blobs);

		CBlob@[] players;
		getBlobsByTag("player", @players);

		if (
			this.isMatchRunning() && !this.isWarmup() && !this.isGameOver() && //game running
			!focusOnBlob(blobs) && //not focusing on a blob
			players.length > 0 //players exist
		) {
			u32 maxDistX = 0.0f;
			u32 maxDistY = 0.0f;

			//calculate mean position of all players
			posTarget = Vec2f(0, 0);
			for (uint i = 0; i < players.length; i++)
			{
				CBlob@ blob = players[i];

				posTarget += blob.getInterpolatedPosition();

				//look for largest distance between two players
				for (uint j = i + 1; j < players.length; j++)
				{
					CBlob@ blob2 = players[j];
					u32 distX = Maths::Abs(blob.getPosition().x - blob2.getPosition().x);
					u32 distY = Maths::Abs(blob.getPosition().y - blob2.getPosition().y);
					maxDistX = Maths::Max(distX, maxDistX);
					maxDistY = Maths::Max(distY, maxDistY);
				}
			}
			posTarget /= players.length;

			if (players.length == 1)
			{
				//follow blob with normal zoom
				zoomTarget = 1.0f;
			}
			else
			{
				//dynamic zoom to fit all players
				f32 zoomW = calculateZoomLevelW(maxDistX * 1.8f);
				f32 zoomH = calculateZoomLevelH(maxDistY * 1.8f);
				zoomTarget = Maths::Min(zoomW, zoomH);
			}

			zoomTarget = Maths::Clamp(zoomTarget, CINEMATIC_FURTHEST_ZOOM, CINEMATIC_CLOSEST_ZOOM);
		}

		//adjust camera pos and zoom
		camera.targetDistance += (zoomTarget - camera.targetDistance) / CINEMATIC_ZOOM_EASE * getRenderApproximateCorrectionFactor();
		pos.x += (posTarget.x - pos.x) / CINEMATIC_PAN_X_EASE * getRenderApproximateCorrectionFactor();
		pos.y += (posTarget.y - pos.y) / CINEMATIC_PAN_Y_EASE * getRenderApproximateCorrectionFactor();
	}

	//click on players to track them or set camera to mousePos
	Vec2f mousePos = controls.getMouseWorldPos();
	if (controls.isKeyJustPressed(KEY_LBUTTON) && !waitForRelease)
	{
		CBlob@[] players;
		SetTargetPlayer(null);
		getBlobsByTag("player", @players);
		for (uint i = 0; i < players.length; i++)
		{
			CBlob@ blob = players[i];
			Vec2f bpos = blob.getInterpolatedPosition();
			if (blob.getName() == "migrant") //screw migrants
			{
				continue;
			}

			if (Maths::Pow(mousePos.x - bpos.x, 2) + Maths::Pow(mousePos.y - bpos.y, 2) <= Maths::Pow(blob.getRadius() * 2, 2) && camera.getTarget() !is blob)
			{
				SetTargetPlayer(blob.getPlayer());
				camera.setTarget(blob);
				waitForRelease = true;
				setCinematicEnabled(false);
			}
		}
	}
	else if (!waitForRelease && controls.isKeyPressed(KEY_LBUTTON) && camera.getTarget() is null) //classic-like held mouse moving
	{
		pos += (mousePos - pos) / 8.0f * getRenderApproximateCorrectionFactor();
		setCinematicEnabled(false);
	}

	if (targetPlayer() !is null)
	{
		if (camera.getTarget() !is targetPlayer().getBlob())
		{
			camera.setTarget(targetPlayer().getBlob());
		}
		pos = camera.getPosition();
		setCinematicEnabled(false);
	}
	else
	{
		camera.setTarget(null);
	}

	//set specific zoom if we have a target
	if (camera.getTarget() !is null)
	{
		camera.mousecamstyle = 1;
		camera.mouseFactor = 0.5f;
		return;
	}

	//keep camera within map boundaries
	f32 borderMarginX = map.tilesize * 2.0f / zoomTarget;
	f32 borderMarginY = map.tilesize * 2.0f / zoomTarget;
	pos.x = Maths::Clamp(pos.x, borderMarginX, mapDim.x - borderMarginX);
	pos.y = Maths::Clamp(pos.y, borderMarginY, mapDim.y - borderMarginY);

	//set camera position
	camera.setPosition(pos);
}
