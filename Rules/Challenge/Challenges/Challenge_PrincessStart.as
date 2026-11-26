#include "ChallengesCommon.as"
#include "Challenge_PrincessMiddle.as" // oo !!!!

const string INTRO_TEXT =
    "   High atop a craggy cliff, guarded by an army of fierce warriors, stands the fortress of the evil warlord Sedgewick. Deep in the darkest dungeon of the castle, Sedgwick gloats over his lovely captive, the princess Geti.\n\n   You are a King's Knight. Alone, with only your sword and shield, you must defeat Sedgwick and rescue the beautiful Geti.\n\n   Put fear and self-concern behind you. Focus your will on your objective, accept death as a possibility, and stay strong. This is the way of the Knight.";

const int introEndTime = getTicksASecond() * 30;

int _actualEndTime = introEndTime; //set in onInit
bool introDone = false;

void onInit(CRules@ this)
{
	Reset(this);

	SetIntroduction(this, "Save the Princess!");
	sv_mapcycle_shuffle = false;
	this.set_s32("restart_rules_after_game_time", 30 * 2.5f); // no better place?

	_actualEndTime = introEndTime;
	introDone = false;
	this.set_bool("drop coins", true);
	this.Tag("no auto fanfare");
}

void onRender(CMap@ this)
{
	const int time = getMap().getTimeSinceStart();

	// start
	//		 printf("introEndTime " + introEndTime
	if (!introDone && time < _actualEndTime)
	{
		const f32 right = getScreenWidth();
		const f32 middle = right / 2.0f;
		const f32 bottom = getScreenHeight();
		const f32 timeRatio = float(time) / float(_actualEndTime);

		// black fade
		const uint alpha = 255;
		if (time > _actualEndTime - 128)
			(_actualEndTime - time) * 2;

		GUI::DrawRectangle(Vec2f_zero, Vec2f(right, bottom),
		                   SColor(alpha, 0, 0, 0));

		Vec2f ul(middle - 170.0f, bottom - 90.0f - timeRatio * 840.0f);
		Vec2f lr(middle + 170.0f, bottom + 400.0f);

		GUI::SetFont("menu");
		GUI::DrawText(getTranslatedString(INTRO_TEXT),
		              ul, lr,
		              SColor(alpha, 255, 255, 255),
		              false, false, false);

		GUI::DrawIcon("GUI/BottomFade.png", 0, Vec2f(400, 256), Vec2f(ul.x - 200.0f, bottom - 2 * 256 + 150.0f), 1.0f);

		// scroll faster

		if (getControls().isKeyPressed(KEY_SPACE) ||
		        getControls().isKeyPressed(KEY_LBUTTON) ||		//interfers with helps
		        getControls().isKeyPressed(KEY_RBUTTON))
		{
			_actualEndTime -= 60;
		}
	}
	else
	{
		introDone = true;
	}
}
