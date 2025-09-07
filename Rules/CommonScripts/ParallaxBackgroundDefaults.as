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
    AddScriptedBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, -210.0f), 60.0f, 150.0f, color_white);
    AddScriptedBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  -200.0f), 120.0f, 148.0f, color_white);
    AddScriptedBackground("Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, -190.0f), 160.0f, 146.0f, color_white);
    AddScriptedBackground("Sprites/Back/BackgroundCastle.png", Vec2f(0.0f, -70.0f), 200.0f, 144.0f, color_white);
}