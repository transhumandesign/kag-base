#define CLIENT_ONLY

f32 zoomTarget = 1.0f;
float timeToScroll = 0.0f;

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
	if(p is null) return;
	_targetPlayer = p.getUsername();
}

void Spectator(CRules@ this)
{
	CCamera@ camera = getCamera();
	CControls@ controls = getControls();

    if(this.get_bool("set new target"))
    {
        string newTarget = this.get_string("new target");
        _targetPlayer = newTarget;
        if(targetPlayer() !is null)
        {
            waitForRelease = true;
            this.set_bool("set new target", false);
        }

    }

	if (camera is null || controls is null)
		return;

	//Zoom in and out using mouse wheel
	if (timeToScroll <= 0)
	{
		if (controls.mouseScrollUp)
		{
			timeToScroll = 7;
			if (zoomTarget < 1.0f)
				zoomTarget = 1.0f;
			else
				zoomTarget = 2.0f;

		}
		else if (controls.mouseScrollDown)
		{
			timeToScroll = 7;
			if (zoomTarget > 1.0f)
				zoomTarget = 1.0f;
			else
				zoomTarget = 0.5f;

		}

	}
	else
	{
		timeToScroll -= getRenderApproximateCorrectionFactor();
	}

	Vec2f pos = camera.getPosition();

	if (Maths::Abs(camera.targetDistance - zoomTarget) > 0.001f)
	{
		camera.targetDistance = (camera.targetDistance * (3 - getRenderApproximateCorrectionFactor() + 1.0f) + (zoomTarget * getRenderApproximateCorrectionFactor())) / 4;
	}
	else
	{
		camera.targetDistance = zoomTarget;
	}

	f32 camSpeed = getRenderApproximateCorrectionFactor() * 15.0f / zoomTarget;

	//Move the camera using the action movement keys
	if (controls.ActionKeyPressed(AK_MOVE_LEFT))
	{
		pos.x -= camSpeed;
		SetTargetPlayer(null);
	}
	if (controls.ActionKeyPressed(AK_MOVE_RIGHT))
	{
		pos.x += camSpeed;
		SetTargetPlayer(null);
	}
	if (controls.ActionKeyPressed(AK_MOVE_UP))
	{
		pos.y -= camSpeed;
		SetTargetPlayer(null);
	}
	if (controls.ActionKeyPressed(AK_MOVE_DOWN))
	{
		pos.y += camSpeed;
		SetTargetPlayer(null);
	}

    if(controls.isKeyJustReleased(KEY_LBUTTON))
    {
        waitForRelease = false;

    }

	//Click on players to track them or set camera to mousePos
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
			if (blob.getName() == "migrant") // screw migrants
				continue;

			if (Maths::Pow(mousePos.x - bpos.x, 2) + Maths::Pow(mousePos.y - bpos.y, 2) <= Maths::Pow(blob.getRadius() * 2, 2) && camera.getTarget() !is blob)
			{
				//print("set player to track: " + (blob.getPlayer() is null ? "null" : blob.getPlayer().getUsername()));
				SetTargetPlayer(blob.getPlayer());
				camera.setTarget(blob);
				camera.setPosition(blob.getInterpolatedPosition());
				return;
			}
		}
	}
	else if (!waitForRelease && controls.isKeyPressed(KEY_LBUTTON) && camera.getTarget() is null) //classic-like held mouse moving
	{
		// prevent camera moving when clicking to vote for map
		if (!this.isGameOver() && !this.hasScript("PostGameMapVotes"))
		{
			pos += ((mousePos - pos) / 8.0f) * getRenderApproximateCorrectionFactor();
		}
	}

	if (targetPlayer() !is null)
	{
		if (camera.getTarget() !is targetPlayer().getBlob())
		{
			camera.setTarget(targetPlayer().getBlob());
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

	//Don't go to far off the map boundaries
	CMap@ map = getMap();
	if (map !is null)
	{
		f32 borderMarginX = map.tilesize * 2 / zoomTarget;
		f32 borderMarginY = map.tilesize * 2 / zoomTarget;

		if (pos.x < borderMarginX)
		{
			pos.x = borderMarginX;
		}
		if (pos.y < borderMarginY)
		{
			pos.y = borderMarginY;
		}
		if (pos.x > map.tilesize * map.tilemapwidth - borderMarginX)
		{
			pos.x = map.tilesize * map.tilemapwidth - borderMarginX;
		}
		if (pos.y > map.tilesize * map.tilemapheight - borderMarginY)
		{
			pos.y = map.tilesize * map.tilemapheight - borderMarginY;
		}
	}

	camera.setPosition(pos);

}
