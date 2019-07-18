bool isGlobalTauntCategory(string category)
{
	//todo: make this faster, loading the cfg each time is wasteful and hits the disk
	//get cfg
	string filename = "TauntEntries.cfg";
	string cachefilename = "../Cache/" + filename;
	ConfigFile cfg;

	//attempt to load from cache first
	bool loaded = false;
	if (CFileMatcher(cachefilename).getFirst() == cachefilename && cfg.loadFile(cachefilename))
	{
		loaded = true;
	}
	else if (cfg.loadFile(filename))
	{
		loaded = true;
	}

	if (!loaded)
	{
		return false;
	}

	//read cfg
	string[] names;
	cfg.readIntoArray_string(names, "GLOBAL");

	//check cfg format
	if (names.length % 2 != 0)
	{
		error("TauntEntries.cfg is not in the form of visible_name; token;");
		return false;
	}

	//find match
	for (uint i = 1; i < names.length; i += 2)
	{
		if (names[i] == category)
		{
			return true;
		}
	}

	return false;
}
