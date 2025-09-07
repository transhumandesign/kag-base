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
    AddScriptedBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, -40.0f), Vec2f(0.06f, 20.0f), color_white);
    AddScriptedBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  -100.0f), Vec2f(0.18f, 70.0f), color_white);
    AddScriptedBackground("Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, -220.0f), Vec2f(0.3f, 180.0f), color_white);
}