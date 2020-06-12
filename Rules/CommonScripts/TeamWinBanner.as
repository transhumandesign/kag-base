#define CLIENT_ONLY

Vec2f bannerStart = Vec2f_zero;
Vec2f bannerPos = Vec2f_zero;
Vec2f bannerDest = Vec2f_zero;
u32 startTime = 0;
const f32 maxTime = 1;

bool minimap = true;

void onInit(CRules@ this)
{
    if (!GUI::isFontLoaded("AveriaSerif-Bold_48"))
    {
        string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
        GUI::LoadFont("AveriaSerif-Bold_32", AveriaSerif, 32, true);
    }

    minimap = this.minimap;
    onRestart(this);

}

void onRestart(CRules@ this)
{
    this.Untag("animateGameOver");
    bannerPos = Vec2f_zero;
    bannerDest = Vec2f_zero;
    startTime = 0;
    this.minimap = minimap;
}

void onStateChange(CRules@ this, const u8 oldState)
{
    if (this.isGameOver() && this.getTeamWon() >= 0)
    {
        Driver@ driver = getDriver();
        if (driver !is null)
        {
            bannerDest = Vec2f(driver.getScreenWidth()/2, driver.getScreenHeight()/3);
            bannerStart = bannerDest;
            bannerStart.y = 0;
            bannerPos = bannerStart;

            startTime = getGameTime();
            this.Tag("animateGameOver");
            this.minimap = false;
        }

    }
}

void onRender(CRules@ this)
{
    if (this.hasTag("animateGameOver"))
    {
        Driver@ driver = getDriver();
        if (driver !is null)
        {
            if (bannerPos != bannerDest)
            {
                f32 time = (float(getGameTime() - startTime)/float(getTicksASecond()))/maxTime;
                bannerPos = Vec2f_lerp(bannerStart, bannerDest, time);
            }
            DrawBanner(bannerPos, this.getTeamWon());

            this.SetGlobalMessage("");
        }
    }


}

void DrawBanner(Vec2f center, int team)
{
    string teamName = "Blue";
    Vec2f offset = Vec2f_zero;
    if (team == 1)
    {
        teamName = "Red";
        offset = Vec2f(-32, -16);
    }


    Vec2f tl = center - Vec2f(160, 32);
    Vec2f br = center + Vec2f(160, 32);
    GUI::DrawRectangle(tl, br);
    GUI::DrawIcon("TeamIcons.png", team, Vec2f(96, 96), center - Vec2f(96, 192) + offset, 1.0f, team);
    GUI::DrawIcon("MenuItems.png", 31, Vec2f(32, 32), center - Vec2f(192, 32), 1.0f, team);
    GUI::DrawIcon("MenuItems.png", 31, Vec2f(32, 32), center + Vec2f(128, -32), 1.0f, team);

    GUI::SetFont("AveriaSerif-Bold_32");
    string text = teamName + " team wins";
    GUI::DrawTranslatedTextCentered(text, center, SColor(255, 255, 255, 255));

}
