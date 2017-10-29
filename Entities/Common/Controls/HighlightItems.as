#define CLIENT_ONLY
#include "HighlightItemsCommon.as"
bool show_names = false;

//fading
uint brightness_level = 0;
int interval = 6;

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob !is null)
	{
		if (blob.isKeyPressed(key_pickup))
			show_names = true;
		else
			show_names = false;
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob !is null && show_names)
	{
		doFading();
		highlightBlobs(getClassIndex(blob));
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
			if (blob !is null)
			{
				//Highlight.
				if (isItemToHighlight(class_index, blob) && !blob.isInInventory())
				{
					float luminance = map.getColorLight(blob.getPosition()).getLuminance();
					//Don't highlight items in dark caves and places.
					if (luminance >= 30)
					{
						CSprite@ sprite = blob.getSprite();
						if (sprite !is null)
						{
							blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(255,255,255,255), RenderStyle::outline_front);
							blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(brightness_level,255,255,0), RenderStyle::light);
							blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(brightness_level,255,255,255), RenderStyle::light);

						}
					}
				}
			}
		}
	}
}

void doFading()
{
	int future_value = brightness_level + interval;
	if (future_value < 0)
	{
		brightness_level = 0;
		interval *= -1;
	}
	else if (future_value > 255)
	{
		brightness_level = 255;
		interval *= -1;
	}
	brightness_level += interval;
}