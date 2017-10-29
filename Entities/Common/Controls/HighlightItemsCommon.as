const string[] classes = {"builder", "knight", "archer"};
const string[][] highlight_items = {
/* 0 */	{"mat_stone", "mat_wood", "mat_gold"}, //builder
/* 1 */	{"mat_bombs", "mat_waterbombs"}, //knight
/* 2 */	{"mat_firearrows", "mat_waterarrows", "mat_bombarrows"} //archer
};

int getClassIndex(CBlob@ blob)
{
	string config_name = blob.getConfig();
	for (uint i = 0; i < classes.length(); i++)
	{
		if (classes[i] == config_name)
		{
			return i;
		}
	}
	return -1;
}

bool isItemToHighlight(CBlob@ for_blob, CBlob@ item)
{
	string item_config_name = item.getConfig();
	int class_index = getClassIndex(for_blob);
	for (uint i = 0; i < highlight_items[class_index].length(); i++)
	{
		if (item_config_name == highlight_items[class_index][i])
		{
			return true;
		}
	}
	return false;
}

bool isItemToHighlight(int class_index, CBlob@ item)
{
	string item_config_name = item.getConfig();
	for (uint i = 0; i < highlight_items[class_index].length(); i++)
	{
		if (item_config_name == highlight_items[class_index][i])
		{
			return true;
		}
	}
	return false;
}