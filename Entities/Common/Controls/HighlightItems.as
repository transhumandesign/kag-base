#define CLIENT_ONLY

//Items to highlight.
const string[] classes = {"builder", "knight", "archer"};
const string[][] highlight_items = {
/* 0 */	{"mat_stone", "mat_wood", "mat_gold"}, //builder
/* 1 */	{"mat_bombs", "mat_waterbombs"}, //knight
/* 2 */	{"mat_firearrows", "mat_waterarrows", "mat_bombarrows"} //archer
};

//If button is pressed.
bool do_highlight = false;

//Disable highlighting for items, if their luminance is less than this variable.
const uint hide_luminance_level = 40;

void onTick(CSprite@ sprite)
{
	do_highlight = sprite.getBlob().isKeyPressed(key_pickup);
}

void onRender(CSprite@ sprite)
{
	if (do_highlight)
	{
		//Highlight items.
		CCamera@ camera = getCamera();
		CMap@ map = getMap();
		if (camera is null || map is null) return;

		//Index of array of items to highlight.
		int class_index = classes.find(sprite.getBlob().getConfig());
		CBlob@[] blobs;
		if (getBlobs(@blobs))
		{
			for (uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				CSprite@ blob_sprite = blob.getSprite();
				if (!blob.isInInventory() && blob_sprite !is null)
				{
					//Highlight.
					if (shouldHighlightBlob(class_index, blob) && blob_sprite.isOnScreen())
					{
						float luminance = map.getColorLight(blob.getPosition()).getLuminance();
						//Don't highlight items in dark caves and places.
						if (luminance >= hide_luminance_level)
						{
							//Make items darker in darkness.
							float luminance_modifier = luminance / 255.0f;
							//Highlight like any normal pickup.
							blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(255,luminance,luminance,luminance), RenderStyle::normal);
							//But do a beautiful fading effect.
							float range = 200.0f * luminance_modifier;
							uint brightness_level = Maths::Abs(Maths::Sin(getGameTime() / 20.0f)) * range;
							//Make it a bit darker in dark places, so it doesn't break your eyes.
							blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(brightness_level,255,255,0), RenderStyle::light);
							blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(brightness_level,255,255,255), RenderStyle::light);
						}
					}
				}
				
			}
		}
	}
}

//Finds a blob's config name in array.
bool shouldHighlightBlob(int class_index, CBlob@ item)
{
	if (class_index < 0) return false;
	return highlight_items[class_index].find(item.getConfig()) >= 0;
}
