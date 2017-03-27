#include "ChallengesCommon.as"
#include "MakeSign.as"

int checkpointCount = 0;

void SetupTutorial(CMap@ this, const string &in tutName)
{
	CRules@ rules = getRules();
	SetIntroduction(rules, tutName);

	if (getNet().isServer())
	{
		rules.set_bool("repeat if dead", true);
		Vec2f endPoint;
		if (!this.getMarker("checkpoint", endPoint))
		{
			warn("End game checkpoint not found on map");
		}
		rules.set_Vec2f("endpoint", endPoint);
		rules.Sync("endpoint", true);
	}

	AddRulesScript(rules);

	rules.set_bool("repeat if dead", false);
	rules.set_s32("restart_rules_after_game_time", 30 * 5.5f);
}

void CheckEndmap(CMap@ this)
{
	CRules@ rules = getRules();

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
						//rules.set_bool("played fanfare", false); //
						Sound::Play("/FanfareWin.ogg");
						rules.SetCurrentState(GAME_OVER);
						rules.SetGlobalMessage("Well done. Loading next map...");
						sv_mapautocycle = true;
					}
				}
			}
		}
	}
}

void RenderEndmap(CRules@ this)
{
	Vec2f endPoint = this.get_Vec2f("endpoint");
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(endPoint);
	pos2d.x -= 28.0f;
	pos2d.y -= 32.0f + 16.0f * Maths::Sin(getGameTime() / 4.5f);
	GUI::DrawIconByName("$DEFEND_THIS$",  pos2d);
}