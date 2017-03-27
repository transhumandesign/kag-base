void LoadMap()
{
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	RegisterFileExtensionScript("Scripts/MapLoaders/GenerateFromKAGGen.as", "kaggen.cfg");

	LoadRules("Rules/Sandbox/gamemode.cfg");
	LoadMapCycle("Rules/Sandbox/mapcycle.cfg");
	LoadNextMap();
}

void onInit(CMap@ this)
{

}

void onRender(CMap@ this)
{
	const int time = getMap().getTimeSinceStart();
	const int endTime1 = getTicksASecond() * 4;
	const int endTime2 = getTicksASecond() * 15;

	bool draw = false;
	Vec2f ul, lr;
	string text = "";

	GUI::SetFont("menu");

	if (time < endTime1)
	{
		text = "Welcome to King Arthur's Gold";
		ul = Vec2f(getScreenWidth() / 2 - 70, 3 * getScreenHeight() / 4);
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		draw = true;
	}
	else if (time < endTime2)
	{
		text =  "This is a sandbox mode in which\n you are free to relax.\n\nPress ESC to see controls.\nHave Fun!";
		ul = Vec2f(getScreenWidth() / 2 - 70, 3 * getScreenHeight() / 4);
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		draw = true;
	}

	if (draw)
	{
		f32 wave = Maths::Sin(getGameTime() / 10.0f) * 5.0f;
		ul.y += wave;
		lr.y += wave;
		GUI::DrawButtonPressed(ul - Vec2f(10, 10), lr + Vec2f(10, 10));
		GUI::DrawText(text, ul, SColor(0xffffffff));
	}
}
