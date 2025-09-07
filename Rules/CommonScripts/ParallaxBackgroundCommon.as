#ifdef STAGING
shared class BackgroundLayer
{
    bool alphaBlending;
    string texture;
    Vec2f offset;
    float absoluteScrollX;
    float relativeHeightScrollY;
    SColor baseColor;
    float z;
    float repeatEveryX;
    int repeatCount;
};

shared class RepeatedParallaxBackground : BackgroundLayer
{
};

BackgroundLayer@[]@ GetBackgroundList()
{
    BackgroundLayer@[]@ list;
    getRules().get("parallax backgrounds", @list);
    if (list is null)
    {
        BackgroundLayer@[] newList;
        getRules().set("parallax backgrounds", @newList);
        return @newList;
    }

    return @list;
}

RepeatedParallaxBackground@ AddScriptedBackground(const string &in textureFilename, Vec2f offset, float absoluteScrollX, float relativeHeightScrollY, SColor baseColor, float z)
{
    if (!isClient()) { return null; }

    BackgroundLayer@[]@ backgrounds = GetBackgroundList();
    RepeatedParallaxBackground bg;
    backgrounds.push_back(@bg);
    bg.alphaBlending = false;
    bg.texture = textureFilename;
    bg.offset = offset;
    bg.absoluteScrollX = absoluteScrollX / Texture::width(textureFilename);
    bg.relativeHeightScrollY = relativeHeightScrollY;
    bg.baseColor = baseColor;
    bg.z = z;
    bg.repeatEveryX = Texture::width(textureFilename);
    bg.repeatCount = 4;
    return @bg;
}

BackgroundLayer@ AddCloud(BackgroundLayer@ hookOn, float relativeZ, Vec2f offset, Vec2f randomAmplitude, float scrollMultX, SColor color)
{
    if (!isClient()) { return null; }

    Random r(69420 + GetBackgroundList().length);

    for (int repeat = Maths::Min(0, -hookOn.repeatCount); repeat < Maths::Max(1, hookOn.repeatCount); ++repeat)
    {
        BackgroundLayer@[]@ backgrounds = GetBackgroundList();
        RepeatedParallaxBackground bg;
        backgrounds.push_back(@bg);
        bg.alphaBlending = true;
        bg.texture = CFileMatcher("Sprites/Back/Cloud?.png").getRandom();
        Vec2f jitter(r.NextFloat() * randomAmplitude.x, (r.NextFloat() - 0.5) * randomAmplitude.y);
        bg.offset = hookOn.offset + offset + Vec2f(repeat * hookOn.repeatEveryX, 0.0f) + jitter;
        bg.absoluteScrollX = hookOn.absoluteScrollX * scrollMultX;
        bg.relativeHeightScrollY = hookOn.relativeHeightScrollY;
        bg.baseColor = color;
        bg.z = hookOn.z + relativeZ;
        bg.repeatEveryX = 0;
        bg.repeatCount = 0;
    }

    return null;
}
#endif

#ifndef STAGING
void AddScriptedBackground(const string &in textureFilename, Vec2f offset, Vec2f scrollSpeed, SColor baseColor) {}
#endif