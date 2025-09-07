#ifdef STAGING
shared class ParallaxBackground
{
    string texture;
    Vec2f offset;
    float absoluteScrollX;
    float relativeHeightScrollY;
    SColor baseColor;
};

ParallaxBackground[]@ GetBackgroundList()
{
    ParallaxBackground[]@ list;
    getRules().get("parallax backgrounds", @list);
    if (list is null)
    {
        ParallaxBackground[] newList;
        getRules().set("parallax backgrounds", @newList);
        return @newList;
    }

    return @list;
}

void AddScriptedBackground(const string &in textureFilename, Vec2f offset, float absoluteScrollX, float relativeHeightScrollY, SColor baseColor)
{
    if (!isClient()) { return; }

    ParallaxBackground[]@ backgrounds = GetBackgroundList();
    backgrounds.push_back(ParallaxBackground());
    ParallaxBackground@ bg = @backgrounds[backgrounds.size() - 1];
    bg.texture = textureFilename;
    bg.offset = offset;
    bg.absoluteScrollX = absoluteScrollX;
    bg.relativeHeightScrollY = relativeHeightScrollY;
    bg.baseColor = baseColor;
}
#endif

#ifndef STAGING
void AddScriptedBackground(const string &in textureFilename, Vec2f offset, Vec2f scrollSpeed, SColor baseColor) {}
#endif