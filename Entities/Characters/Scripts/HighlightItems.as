#define CLIENT_ONLY
bool show_names = false;
const string[] classes = {"builder", "knight", "archer"};
const string[][] highlight_items = {
/* 0 */	{"mat_stone", "mat_wood", "mat_gold"}, //builder
/* 1 */	{"mat_bombs", "mat_waterbombs"}, //knight
/* 2 */	{"mat_firearrows", "mat_waterarrows", "mat_bombarrows"} //archer
};

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	if (blob.isKeyPressed(key_taunts))
		show_names = true;
	else
		show_names = false;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob !is null && show_names)
	{
		string class_name = blob.getConfig();
		//Get in index of items array for current class. !!! WILL BE DONE LATER WITH DICTIONARIES
		for (int i = 0; i < classes.length(); i++)
		{
			if (classes[i] == class_name)
			{
				highlightBlobs(i);
				break;
			}
		}
	}
}

void highlightBlobs(int items_index)
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
				//Check if blob's name exists in array of highlight_items.
				bool is_item_to_highlight = false;
				for (int j = 0; j < highlight_items[items_index].length(); j++)
				{
					if (blob.getConfig() == highlight_items[items_index][j])
					{
						is_item_to_highlight = true;
						break;
					}
				}
				//Highlight.
				if (is_item_to_highlight && !blob.isInInventory())
				{
					float luminance = map.getColorLight(blob.getPosition()).getLuminance();
					//Don't highlight items in dark caves and places.
					if (luminance >= 30)
					{
						CSprite@ sprite = blob.getSprite();
						if (sprite !is null)
						{
							blob.RenderForHUD(RenderStyle::outline_front);
							blob.RenderForHUD(RenderStyle::light);
						}
					}
				}
			}
		}
	}
}
