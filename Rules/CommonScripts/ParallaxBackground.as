#define CLIENT_ONLY

#include "ParallaxBackgroundCommon.as"

#ifdef STAGING
using namespace Render2D;

// hacky variable to avoid having duplicate Render:: calls when rebuilding
int activeRenderScript = -1;

void onInit(CRules@ rules)
{
    SetupRenderBackgroundCallback();
}

void onReload(CRules@ rules)
{
    SetupRenderBackgroundCallback();
}

// required because CRules render callbacks are called rather late, after the lightmap composition pass
// this causes visibly wrong blending for translucent things like dirt particles
void SetupRenderBackgroundCallback()
{
    activeRenderScript = Render::addScript(Render::layer_background, "ParallaxBackground.as", "RenderBackgroundCallback", 0);
}

const u32[] indices = {0, 1, 2, 2, 1, 3};

void RenderParallaxBackground(RepeatedParallaxBackground@ bg)
{
    Vec2f cameraPosition = getCamera().getPosition();

    SColor color = bg.baseColor;
    SColor ambient = getMap().ambientLight;
    color.setRed((color.getRed() * ambient.getRed()) / 255);
    color.setGreen((color.getGreen() * ambient.getGreen()) / 255);
    color.setBlue((color.getBlue() * ambient.getBlue()) / 255);

    const float mapHeight = getMap().getMapDimensions().y;
    const float minMapHeight = 600.0f; // reduce parallax effect on small maps, push the backgrounds more up

    Vertex[] vertices;
    vertices.resize(4);

    for (int repeat = Maths::Min(0, -bg.repeatCount); repeat < Maths::Max(1, bg.repeatCount); ++repeat)
    {
        Vec2f origin = cameraPosition;
        origin.x -= bg.absoluteScrollX * cameraPosition.x;
        origin.y -= (bg.relativeHeightScrollY * cameraPosition.y) / Maths::Max(mapHeight, minMapHeight);
        if (mapHeight < minMapHeight) {
            origin.y -= bg.relativeHeightScrollY * (minMapHeight - mapHeight) / Maths::Max(mapHeight, minMapHeight);
        }
        origin.x += repeat * bg.repeatEveryX;
        origin += bg.offset;

        vertices[0] = Vertex(origin.x,                origin.y,                bg.z, 0.0f, 0.0f, color);
        vertices[1] = Vertex(origin.x + bg.texSize.x, origin.y,                bg.z, 1.0f, 0.0f, color);
        vertices[2] = Vertex(origin.x,                origin.y + bg.texSize.y, bg.z, 0.0f, 1.0f, color);
        vertices[3] = Vertex(origin.x + bg.texSize.x, origin.y + bg.texSize.y, bg.z, 1.0f, 1.0f, color);

        CustomShape2D(bg.mat, vertices, indices)
            .shape
            .ZWrite(!bg.alphaBlending)
            .StrictOrdering(bg.alphaBlending)
            .RenderForWorld(bg.z, ZSetMode::OrderingHint);

        if (bg.stretchDown)
        {
            origin.y += bg.texSize.y;
            vertices[0] = Vertex(origin.x,                origin.y,           bg.z, 0.0f, 0.99f, color);
            vertices[1] = Vertex(origin.x + bg.texSize.x, origin.y,           bg.z, 1.0f, 0.99f, color);
            vertices[2] = Vertex(origin.x,                origin.y + 1000.0f, bg.z, 0.0f, 0.99f, color);
            vertices[3] = Vertex(origin.x + bg.texSize.x, origin.y + 1000.0f, bg.z, 1.0f, 0.99f, color);

            CustomShape2D(bg.mat, vertices, indices)
                .shape
                .ZWrite(!bg.alphaBlending)
                .StrictOrdering(bg.alphaBlending)
                .RenderForWorld(bg.z, ZSetMode::OrderingHint);
        }
    }
}

void RenderBackgroundCallback(int id)
{
    if (id != activeRenderScript)
    {
        Render::RemoveScript(id);
        return;
    }

    if (v_fastrender) { return; }

    CRules@ rules = @getRules();

    BackgroundLayer@[]@ backgrounds = @GetBackgroundList();
    if (backgrounds is null) { return; }
    if (getCamera() is null) { return; }

    for (int i = 0; i < backgrounds.length; ++i)
    {
        BackgroundLayer@ bg = @backgrounds[i];

        // yep, sorry
        RepeatedParallaxBackground@ bg_parallax = cast<RepeatedParallaxBackground@>(bg);
        if (bg_parallax !is null) { RenderParallaxBackground(@bg_parallax); }
    }
}
#endif

#ifndef STAGING
void foo() {} /* avoid error */
#endif