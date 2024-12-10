#include "CinematicCommon.as"
#include "MapVotesCommon.as"

#define CLIENT_ONLY

const bool FOCUS_ON_IMPORTANT_BLOBS = true;						//whether camera should focus on important blobs

const float CINEMATIC_PAN_X_EASE = 6.0f;						//amount of ease along the x-axis while cinematic
const float CINEMATIC_PAN_Y_EASE = 6.0f;						//amount of ease along the y-axis while cinematic

const float CINEMATIC_ZOOM_EASE = 16.0f;						//amount of ease when zooming while cinematic
const float CINEMATIC_CLOSEST_ZOOM = 1.0f;						//how close the camera can zoom in while cinematic (default is 2.0f)
const float CINEMATIC_FURTHEST_ZOOM = 0.5f;						//how far the camera can zoom out while cinematic (default is 0.5f)

const float AUTO_CINEMATIC_TIME = 3.0f;							//time until camera automatically becomes cinematic. set to zero to disable

Vec2f posActual;
Vec2f posTarget;												//position which cinematic camera moves towards
float zoomTarget = 1.0f;										//zoom level which camera zooms towards
float timeToScroll = 0.0f;										//time until next able to scroll to zoom camera
float timeToCinematic = 0.0f;									//time until camera automatically becomes cinematic
float panEaseModifier = 1.0f;                                   //by how much the x/y ease values are multiplied
float zoomEaseModifier = 1.0f;                                  //by how much the zoom ease values are multiplied
uint currentTarget;											    //the current target blob
uint switchTarget;												//time when camera can move onto new target

bool justClicked = false;
string _targetPlayer;
bool waitForRelease = false;

CPlayer@ targetPlayer()
{
	return getPlayerByUsername(_targetPlayer);
}

const Vec2f[] easePosLerpTable = {
	Vec2f(0.0,   1.0),
	Vec2f(8.0,   1.0),
	Vec2f(16.0,  0.8),
	Vec2f(64.0,  0.6),
	Vec2f(96.0,  0.8),
	Vec2f(128.0, 1.0),
};

float ease(float current, float target, float factor)
{
	const float diff = target - current;
	const float linearCorrection = diff * factor * panEaseModifier;

	const float x = Maths::Abs(diff);

	float cubicCorrectionMod = 1.0;
	for (int i = 1; i < easePosLerpTable.size(); ++i)
	{
		Vec2f a = easePosLerpTable[i-1];
		Vec2f b = easePosLerpTable[i];
		if (x >= a.x && x < b.x)
		{
			const float f = (x - a.x) / (b.x - a.x);
			cubicCorrectionMod = Maths::Lerp(a.y, b.y, f);
			break;
		}
	}

	const float finalCorrection = linearCorrection * cubicCorrectionMod;

	return current + linearCorrection * cubicCorrectionMod;
}

void ViewEntireMap()
{
	CMap@ map = getMap();

	if (map !is null)
	{
		Vec2f mapDim = map.getMapDimensions();
		posTarget = mapDim / 2.0f;
		Vec2f zoomLevel = calculateZoomLevel(mapDim.x, mapDim.y);
		zoomTarget = Maths::Min(zoomLevel.x, zoomLevel.y);
		zoomTarget = Maths::Clamp(zoomTarget, 0.5f, 2.0f);
	}
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
	float camSpeed = getRenderApproximateCorrectionFactor() * 15.0f / zoomTarget;

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
		if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN)))
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
		else if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT)))
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
		posActual.x -= camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}
	if (controls.ActionKeyPressed(AK_MOVE_RIGHT))
	{
		posActual.x += camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}
	if (controls.ActionKeyPressed(AK_MOVE_UP))
	{
		posActual.y -= camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}
	if (controls.ActionKeyPressed(AK_MOVE_DOWN))
	{
		posActual.y += camSpeed;
		SetTargetPlayer(null);
		setCinematicEnabled(false);
	}

    if (controls.isKeyJustReleased(KEY_LBUTTON))
    {
        waitForRelease = false;
    }

	if (!isCinematicEnabled() || targetPlayer() !is null) //player-controlled zoom
	{
		if (Maths::Abs(camera.targetDistance - zoomTarget) > 0.001f)
		{
			camera.targetDistance = (camera.targetDistance * (3.0f - getRenderApproximateCorrectionFactor() + 1.0f) + (zoomTarget * getRenderApproximateCorrectionFactor())) / 4.0f;
		}
		else
		{
			camera.targetDistance = zoomTarget;
		}

		if (AUTO_CINEMATIC_TIME > 0)
		{
			timeToCinematic -= getRenderSmoothDeltaTime();
			if (timeToCinematic <= 0)
			{
				setCinematicEnabled(true);
			}
		}
	}
	else //cinematic camera
	{
		const float corrFactor = getRenderApproximateCorrectionFactor();
		camera.targetDistance += (zoomTarget - camera.targetDistance) / CINEMATIC_ZOOM_EASE * corrFactor * zoomEaseModifier;

		posActual.x = ease(posActual.x, posTarget.x, corrFactor / CINEMATIC_PAN_X_EASE);
		posActual.y = ease(posActual.y, posTarget.y, corrFactor / CINEMATIC_PAN_Y_EASE);
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
		// HACK: this is terrible and we need proper GUI and cursor capture shit
		// ofc this is still an issue with the queue stuff now :upside_down:
		MapVotesMenu@ mvm = null;
		this.get("MapVotesMenu", @mvm);

		if (mvm is null || !isMapVoteActive() || !mvm.screenPositionOverlaps(controls.getMouseScreenPos()))
        {
		    posActual += (mousePos - posActual) / 8.0f * getRenderApproximateCorrectionFactor();
            setCinematicEnabled(false);
        }
	}

	if (targetPlayer() !is null)
	{
		if (camera.getTarget() !is targetPlayer().getBlob() && !targetPlayer().isBot())
		{
			camera.setTarget(targetPlayer().getBlob());
			posActual = camera.getPosition();
		}
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
	float borderMarginX = map.tilesize * 2.0f / zoomTarget;
	float borderMarginY = map.tilesize * 2.0f / zoomTarget;
	posActual.x = Maths::Clamp(posActual.x, borderMarginX, mapDim.x - borderMarginX);
	posActual.y = Maths::Clamp(posActual.y, borderMarginY, mapDim.y - borderMarginY);

	//set camera position
	camera.setPosition(posActual);
}
