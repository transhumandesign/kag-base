#include "CinematicCommon.as";

#define CLIENT_ONLY

const bool FOCUS_ON_IMPORTANT_BLOBS = true;						//whether camera should focus on important blobs

const float CINEMATIC_PAN_X_EASE = 12.0f;						//amount of ease along the x-axis while cinematic
const float CINEMATIC_PAN_Y_EASE = 12.0f;						//amount of ease along the y-axis while cinematic

const float CINEMATIC_ZOOM_EASE = 14.0f;						//amount of ease when zooming while cinematic
const float CINEMATIC_CLOSEST_ZOOM = 1.5f;						//how close the camera can zoom in while cinematic (default is 2.0f)
const float CINEMATIC_FURTHEST_ZOOM = 0.75f;					//how far the camera can zoom out while cinematic (default is 0.5f)

const float AUTO_CINEMATIC_TIME = 0.0f;							//time until camera automatically becomes cinematic. set to zero to disable
const uint CINEMATIC_UPDATE_INTERVAL = 3 * getTicksASecond();	//how often the cinematic camera updates its target position/zoom

Vec2f posTarget;												//position which cinematic camera moves towards
float zoomTarget = 1.0f;										//zoom level which camera zooms towards
float timeToScroll = 0.0f;										//time until next able to scroll to zoom camera
float timeToCinematic = 0.0f;									//time until camera automatically becomes cinematic
uint currentTarget;											    //the current target blob
uint switchTarget;												//time when camera can move onto new target
CBlob@[] importantBlobs;										//a list of important blobs sorted from most to least important

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
	if (this.isGameOver() && this.hasScript("PostGameMapVotes")) 
	{
		return; //prevent camera movement while map voting
	}
	
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

		if (AUTO_CINEMATIC_TIME > 0)
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
		// prevent camera moving when clicking to vote for map
		if (!this.isGameOver() && !this.hasScript("PostGameMapVotes"))
        {
		    pos += (mousePos - pos) / 8.0f * getRenderApproximateCorrectionFactor();
            setCinematicEnabled(false);
        }
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
	float borderMarginX = map.tilesize * 2.0f / zoomTarget;
	float borderMarginY = map.tilesize * 2.0f / zoomTarget;
	pos.x = Maths::Clamp(pos.x, borderMarginX, mapDim.x - borderMarginX);
	pos.y = Maths::Clamp(pos.y, borderMarginY, mapDim.y - borderMarginY);

	//set camera position
	camera.setPosition(pos);
}
