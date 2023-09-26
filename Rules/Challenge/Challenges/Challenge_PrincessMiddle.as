#include "ChallengesCommon.as"

bool myPlayerGotToTheEnd = false;
int checkpointCount = 0;

void Reset(CRules@ this)
{
	myPlayerGotToTheEnd = false;
	checkpointCount = 0;
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CMap@ this)
{
	CRules@ rules = getRules();
	SetIntroduction(rules, "Save the Princess");

	rules.set_s32("restart_rules_after_game_time", 30 * 2.5f); // no better place?

	if (getNet().isServer())
	{
		Vec2f endPoint;
		if (!this.getMarker("checkpoint", endPoint))
		{
			warn("End game checkpoint not found on map");
		}
		rules.set_Vec2f("endpoint", endPoint);
		rules.Sync("endpoint", true);
	}
	rules.set_bool("drop coins", true);
	rules.Tag("no auto fanfare");

	AddRulesScript(rules);
}

void onTick(CMap@ this)
{
	CRules@ rules = getRules();

	// local player check end

	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null)
	{
		Vec2f endPoint = rules.get_Vec2f("endpoint");
		if (!myPlayerGotToTheEnd && (localBlob.getPosition() - endPoint).getLength() < 32.0f)
		{
			myPlayerGotToTheEnd = true;
			Sound::Play("/VehicleCapture");
		}
	}

	// server check

	if (getNet().isServer())
	{
		Vec2f endPoint = rules.get_Vec2f("endpoint");
		CBlob@[] blobsNearEnd;
		if (this.getBlobsInRadius(endPoint, 32.0f, @blobsNearEnd))
		{
			for (uint i = 0; i < blobsNearEnd.length; i++)
			{
				CBlob @b = blobsNearEnd[i];
				if (b.getPlayer() !is null && !b.hasTag("checkpoint"))
				{
					b.Tag("checkpoint");
					checkpointCount++;

					if (checkpointCount == rules.get_u8("team 0 count")) // all players
					{
						rules.set_bool("played fanfare", true); //
						DefaultWin(rules, "");
					}
				}
			}
		}
	}
}

// render

void onRender(CRules@ this)
{
	//if (!myPlayerGotToTheEnd)
	{
		Vec2f endPoint = this.get_Vec2f("endpoint");
		//printf("endPoint " + endPoint.x + " " + endPoint.y + " " + myPlayerGotToTheEnd);
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(endPoint);
		pos2d.x -= 28.0f;
		pos2d.y -= 32.0f + 16.0f * Maths::Sin(getGameTime() / 4.5f);
		GUI::DrawIconByName("$DEFEND_THIS$",  pos2d);
	}

	// show stats

	//stats from rules

	Stats_Draw(this);
}
