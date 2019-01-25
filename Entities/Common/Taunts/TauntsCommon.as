bool isGlobalTauntCategory(string category)
{
	//get cfg
	ConfigFile cfg;
	if (!cfg.loadFile("../Cache/TauntEntries.cfg")
	 && !cfg.loadFile("TauntEntries.cfg"))
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
