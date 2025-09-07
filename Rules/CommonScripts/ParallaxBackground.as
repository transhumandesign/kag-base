#define CLIENT_ONLY

#include "ParallaxBackgroundCommon.as"

#ifdef STAGING
using namespace Render2D;

SimpleMaterial GetBackgroundMaterial(const ParallaxBackground &in bg)
{
    SimpleMaterial mat;
    mat.SetTexture(bg.texture);
    mat.renderStyle = RenderStyle::normal_no_alpha_blending;
    mat.filter = Filter::None;
    mat.zTest = true;
    // HACK: we rely on the ordering logic from render2d to not require Z writes
    mat.zWrite = false;
    return mat;
}

Vec2f ElementMul(Vec2f a, Vec2f b)
{
    a *= b;
    return a;
}

// hacky variable to avoid having duplicate Render:: calls
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

void RenderBackgroundCallback(int id)
{
    if (id != activeRenderScript)
    {
        Render::RemoveScript(id);
        return;
    }

    if (v_fastrender) { return; }

    CRules@ rules = @getRules();

    CCamera@ camera = @getCamera();
    if (camera is null) { return; }

    ParallaxBackground[]@ backgrounds = @GetBackgroundList();
    if (backgrounds is null) { return; }

    Vec2f cameraPosition = camera.getPosition();
    float z = -9000.0f;

    const Vec2f[] offsets = {
        Vec2f(0.0f, 0.0f),
        Vec2f(1.0f, 0.0f),
        Vec2f(0.0f, 1.0f),
        Vec2f(1.0f, 1.0f)
    };

    const u32[] indices = {0, 1, 2, 2, 1, 3};

    for (int i = 0; i < backgrounds.length; ++i)
    {
        ParallaxBackground@ bg = @backgrounds[i];
        // const Vec2f texSize(Texture::width(bg.texture), Texture::height(bg.texture));
        Vec2f texSize(1000.0f, 500.0f);

        for (int repeat = -5; repeat < 5; ++repeat)
        {
            auto mat = GetBackgroundMaterial(bg);

            Vec2f panning = -bg.scrollSpeed;
            panning *= cameraPosition;
            panning /= texSize;
            panning += cameraPosition * 0.5;

            Vec2f origin = panning;
            origin.x -= repeat * texSize.x;

            Vertex[] vertices = {
                Vertex(origin + ElementMul(offsets[0], texSize), z, offsets[0], bg.baseColor),
                Vertex(origin + ElementMul(offsets[1], texSize), z, offsets[1], bg.baseColor),
                Vertex(origin + ElementMul(offsets[2], texSize), z, offsets[2], bg.baseColor),
                Vertex(origin + ElementMul(offsets[3], texSize), z, offsets[3], bg.baseColor),
            };

            CustomShape2D(mat, vertices, indices)
                .shape
                .ZWrite(false)
                .RenderForWorld(10000.0f, ZSetMode::OrderingHint);

            z -= 10.0f;
        }
    }
}
#endif

#ifndef STAGING
void foo() {} /* avoid error */
#endif