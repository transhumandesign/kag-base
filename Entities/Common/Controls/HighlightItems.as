#define CLIENT_ONLY
#include "HighlightItemsCommon.as"
bool do_highlight = false;

//Disable highlighting for items, if their luminance is less than this variable.
const uint hide_luminance_level = 30;

void onTick(CSprite@ sprite)
{
	do_highlight = sprite.getBlob().isKeyPressed(key_pickup);
}

void onRender(CSprite@ sprite)
{
	if (do_highlight)
	{
		//Highlight items.
		highlightBlobs(getClassIndex(sprite.getBlob()));
	}
}

void highlightBlobs(int class_index)
{
	CCamera@ camera = getCamera();
	CMap@ map = getMap();
	if (camera is null || map is null) return;

	CBlob@[] blobs;
	if (getBlobs(@blobs))
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			//Highlight.
			if (shouldHighlightBlob(class_index, blob) && !blob.isInInventory())
			{
				float luminance = map.getColorLight(blob.getPosition()).getLuminance();
				//Don't highlight items in dark caves and places.
				if (luminance >= hide_luminance_level)
				{
					//Highlight like any normal pickup.
					blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(255,255,255,255), RenderStyle::outline_front);
					//But do a beautiful fading effect.
					float brightness_level = Maths::Abs(Maths::Sin(getGameTime() / 10.0f) * 255);
					printf("" + brightness_level);
					blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(brightness_level,255,255,0), RenderStyle::light);
					blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(brightness_level,255,255,255), RenderStyle::light);
				}
			}
		}
	}
}