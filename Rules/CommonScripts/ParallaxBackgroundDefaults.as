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

    RepeatedParallaxBackground@ plains = AddScriptedBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, -70.0f), 80.0f, 400.0f, color_white, baseZ);
    RepeatedParallaxBackground@ trees = AddScriptedBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  -60.0f), 160.0f, 425.0f, color_white, baseZ + 10.0f);
    RepeatedParallaxBackground@ island = AddScriptedBackground("Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, 0.0f), 190.0f, 450.0f, color_white, baseZ + 20.0f);
    RepeatedParallaxBackground@ castle = AddScriptedBackground("Sprites/Back/BackgroundCastle.png", Vec2f(0.0f, 100.0f), 220.0f, 475.0f, color_white, baseZ + 30.0f);
    castle.stretchDown = true;

    const float cloudParallaxAmplitude = 0.5;
    const int cloudBehindPlains = 22;
    const int cloudInFrontPlains = 12;

    for (int i = 0; i < cloudBehindPlains; ++i)
    {
        // behind plains
        const float parallaxAmplitude = 1.0 - (float(i) / cloudBehindPlains) * cloudParallaxAmplitude;
        AddCloud(@plains, -5.0f + (i * 0.1f), Vec2f(0.0f, 220.0f), Vec2f(1024.0f, 70.0f), parallaxAmplitude, SColor(85, 242, 247, 250));
    }

    for (int i = 0; i < cloudInFrontPlains; ++i)
    {
        // in front of plains
        const float parallaxAmplitude = 1.0 + (float(i) / cloudInFrontPlains) * cloudParallaxAmplitude;
        AddCloud(@plains, 5.0f + (i * 0.1f), Vec2f(0.0f, 190.0f), Vec2f(1024.0f, 50.0f), parallaxAmplitude, SColor(50, 230, 235, 238));
    }

    // for (int i = 0; i < 20; ++i)
    // {
    //     AddCloud(@trees, -5.0f + (i * 0.1f), Vec2f(0.0f, 300.0f), Vec2f(1024.0f, 100.0f), i*0.01 + 1.05f, SColor(80, 255, 255, 255));
    // }

    // for (int i = 0; i < 20; ++i)
    // {
    //     AddCloud(@island, -5.0f + (i * 0.1f), Vec2f(200.0f, 240.0f), Vec2f(500.0f, 200.0f), i*0.01 + 0.95f, SColor(60, 255, 255, 255));
    //     AddCloud(@island, 5.0f + (i * 0.1f), Vec2f(200.0f, 240.0f), Vec2f(500.0f, 100.0f), i*0.01 + 1.05f, SColor(60, 255, 255, 255));
    // }

    print("Configured " + GetBackgroundList().length + " background layers");
}