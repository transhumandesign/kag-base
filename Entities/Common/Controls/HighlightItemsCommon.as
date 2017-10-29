const string[] classes = {"builder", "knight", "archer"};
const string[][] highlight_items = {
/* 0 */	{"mat_stone", "mat_wood", "mat_gold"}, //builder
/* 1 */	{"mat_bombs", "mat_waterbombs"}, //knight
/* 2 */	{"mat_firearrows", "mat_waterarrows", "mat_bombarrows"} //archer
};

int getClassIndex(CBlob@ blob)
{
	return classes.find(blob.getConfig());
}

bool shouldHighlightBlob(CBlob@ for_blob, CBlob@ item)
{
	int class_index = getClassIndex(for_blob);
	return highlight_items[class_index].find(item.getConfig()) >= 0;
}

bool shouldHighlightBlob(int class_index, CBlob@ item)
{
	return highlight_items[class_index].find(item.getConfig()) >= 0;
}