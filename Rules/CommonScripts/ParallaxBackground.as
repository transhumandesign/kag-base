#define CLIENT_ONLY

#include "ParallaxBackgroundCommon.as"

#ifdef STAGING
using namespace Render2D;

SimpleMaterial GetBackgroundMaterial(const BackgroundLayer &in bg)
{
    SimpleMaterial mat;
    mat.SetTexture(bg.texture);
    mat.renderStyle = bg.alphaBlending ? RenderStyle::normal : RenderStyle::normal_no_alpha_blending;
    mat.filter = Filter::None;
    mat.zTest = true;
    mat.zWrite = !bg.alphaBlending;
    return mat;
}

Vec2f ElementMul(Vec2f a, Vec2f b)
{
    a *= b;
    return a;
}

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

const Vec2f[] offsets = {
    Vec2f(0.0f, 0.0f),
    Vec2f(1.0f, 0.0f),
    Vec2f(0.0f, 1.0f),
    Vec2f(1.0f, 1.0f)
};

const u32[] indices = {0, 1, 2, 2, 1, 3};

void RenderParallaxBackground(RepeatedParallaxBackground@ bg)
{
    Vec2f cameraPosition = getCamera().getPosition();

    const Vec2f texSize(Texture::width(bg.texture), Texture::height(bg.texture));

    SColor color = bg.baseColor;
    SColor ambient = getMap().ambientLight;
    color.setRed((color.getRed() * ambient.getRed()) / 255);
    color.setGreen((color.getGreen() * ambient.getGreen()) / 255);
    color.setBlue((color.getBlue() * ambient.getBlue()) / 255);

    for (int repeat = Maths::Min(0, -bg.repeatCount); repeat < Maths::Max(1, bg.repeatCount); ++repeat)
    {
        auto mat = GetBackgroundMaterial(bg);

        float parallaxPanningX = (-bg.absoluteScrollX * cameraPosition.x);
        float parallaxPanningY = (-bg.relativeHeightScrollY * cameraPosition.y) / getMap().getMapDimensions().y;

        Vec2f repeatOffset(repeat * bg.repeatEveryX, 0.0f);

        Vec2f origin = cameraPosition + Vec2f(parallaxPanningX, parallaxPanningY) + repeatOffset + bg.offset;

        Vertex[] vertices = {
            Vertex(origin + ElementMul(offsets[0], texSize), bg.z, offsets[0], color),
            Vertex(origin + ElementMul(offsets[1], texSize), bg.z, offsets[1], color),
            Vertex(origin + ElementMul(offsets[2], texSize), bg.z, offsets[2], color),
            Vertex(origin + ElementMul(offsets[3], texSize), bg.z, offsets[3], color),
        };

        CustomShape2D(mat, vertices, indices)
            .shape
            .ZWrite(!bg.alphaBlending)
            .StrictOrdering(bg.alphaBlending)
            .RenderForWorld(bg.z, ZSetMode::OrderingHint);
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
        RepeatedParallaxBackground@ bg_parallax = cast<RepeatedParallaxBackground>(bg);
        if (bg_parallax !is null) { RenderParallaxBackground(@bg_parallax); }
    }
}
#endif

#ifndef STAGING
void foo() {} /* avoid error */
#endif