#define CLIENT_ONLY

#include "ParallaxBackgroundCommon.as"

void onInit(CRules@ rules)
{
    SetDefaultBackgrounds(@rules);
}

void onReload(CRules@ rules)
{
    SetDefaultBackgrounds(@rules);
}

void SetDefaultBackgrounds(CRules@ rules)
{
    GetBackgroundList().clear();

    const float baseZ = -9000.0f;

    RepeatedParallaxBackground@ plains = AddScriptedBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, -200.0f), 80.0f, 100.0f, color_white, baseZ);
    RepeatedParallaxBackground@ trees = AddScriptedBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  -170.0f), 160.0f, 150.0f, color_white, baseZ + 10.0f);
    RepeatedParallaxBackground@ island = AddScriptedBackground("Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, -70.0f), 190.0f, 170.0f, color_white, baseZ + 20.0f);
    RepeatedParallaxBackground@ island2 = AddScriptedBackground("Sprites/Back/BackgroundIsland.png", Vec2f(-400.0f, -10.0f), 200.0f, 180.0f, color_white, baseZ + 30.0f);
    RepeatedParallaxBackground@ castle = AddScriptedBackground("Sprites/Back/BackgroundCastle.png", Vec2f(0.0f, -60.0f), 220.0f, 190.0f, color_white, baseZ + 40.0f);
    castle.stretchDown = true;

    const float cloudBehindParallaxAmplitude = 0.5;
    const float cloudInFrontParallaxAmplitude = 0.5;
    const int cloudBehindPlains = 20;
    const int cloudInFrontPlains = 15;

    for (int i = 0; i < cloudBehindPlains; ++i)
    {
        // behind plains
        const float parallaxAmplitude = 1.0 - (float(i) / cloudBehindPlains) * cloudBehindParallaxAmplitude;
        AddCloud(@plains, -5.0f + (i * 0.1f), Vec2f(0.0f, 225.0f), Vec2f(1024.0f, 70.0f), parallaxAmplitude, SColor(60, 242, 247, 250));
    }

    for (int i = 0; i < cloudInFrontPlains; ++i)
    {
        // in front of plains
        const float parallaxAmplitude = 1.0 + (float(i) / cloudInFrontPlains) * cloudInFrontParallaxAmplitude;
        AddCloud(@plains, 5.0f + (i * 0.1f), Vec2f(0.0f, 210.0f), Vec2f(1024.0f, 30.0f), parallaxAmplitude, SColor(30, 230, 235, 238));
    }

    // for (int i = 0; i < 5; ++i)
    // {
    //     AddCloud(@trees, -5.0f + (i * 0.1f), Vec2f(0.0f, 250.0f), Vec2f(1024.0f, 50.0f), 1.0f - i*0.1, SColor(40, 255, 255, 255));
    //     AddCloud(@trees, 5.0f + (i * 0.1f), Vec2f(0.0f, 250.0f), Vec2f(1024.0f, 50.0f), 1.0f + i*0.01, SColor(40, 255, 255, 255));
    // }

    // for (int i = 0; i < 3; ++i)
    // {
    //     AddCloud(@island, -5.0f + (i * 0.1f), Vec2f(200.0f, 240.0f), Vec2f(500.0f, 200.0f), 1.0f - i*0.01, SColor(20, 255, 255, 255));
    //     AddCloud(@island, 5.0f + (i * 0.1f), Vec2f(200.0f, 240.0f), Vec2f(500.0f, 100.0f), 1.0f + i*0.01, SColor(20, 255, 255, 255));
    //     AddCloud(@island2, -5.0f + (i * 0.1f), Vec2f(200.0f, 240.0f), Vec2f(500.0f, 200.0f), 1.0f - i*0.01, SColor(20, 255, 255, 255));
    //     AddCloud(@island2, 5.0f + (i * 0.1f), Vec2f(200.0f, 240.0f), Vec2f(500.0f, 100.0f), 1.0f + i*0.01, SColor(20, 255, 255, 255));
    // }

    // funky bottom clouds -- probably a bit expensive to put that many, but you could mess around this to make a different flying island landscape or something
    // for (int i = 0; i < 50; ++i)
    // {
    //     const float parallaxAmplitude = 1.0 - i * 0.003;
    //     AddCloud(@castle, 5.0f + (i * 0.1f), Vec2f(0.0f, 450.0f), Vec2f(1024.0f, 100.0f), parallaxAmplitude, SColor(20, 242, 247, 250));
    // }

    // for (int i = 0; i < 50; ++i)
    // {
    //     const float parallaxAmplitude = 1.0 - i * 0.003;
    //     AddCloud(@castle, 5.0f + (i * 0.1f), Vec2f(0.0f, 550.0f), Vec2f(1024.0f, 100.0f), parallaxAmplitude, SColor(110, 242, 247, 250));
    // }

    print("Configured " + GetBackgroundList().length + " background layers");
}