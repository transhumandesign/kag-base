
bool isFavourite(APIServer@ s){
	Favourites::doInit();

	string key = s.serverIPv4Address+" "+s.serverPort;
	bool ret;
	return Favourites::favourites.get(key, ret) && ret;
}

void setFavourite(APIServer@ s, bool value){
	Favourites::doInit();

	string key = s.serverIPv4Address+" "+s.serverPort;
	if (value) {
		Favourites::favourites.set(key, true);
	} else {
		Favourites::favourites.set(key, false);
	}

	Favourites::saveCfg();
}

bool toggleFavourite(APIServer@ s){
	bool value = !isFavourite(s);
	setFavourite(s, value);
	return value;
}

namespace Favourites
{
	bool init = false;
	dictionary favourites;

	void doInit(){
		if (init) return;

		string[] strings;
		ConfigFile cfg;

		if (!cfg.loadFile("../Cache/Favourites.cfg")) {
			cfg.addArray_string("favourites", strings);
			cfg.saveFile("Favourites.cfg");
		}

		if(!cfg.readIntoArray_string(strings, "favourites")){ //borked file?
			cfg.addArray_string("favourites", strings);
			cfg.saveFile("Favourites.cfg");
		}

		for (int i = 0; i < strings.length; ++i)
		{
			favourites.set(strings[i], true);
			// print(strings[i]);
		}

		init = true;
	}

	void saveCfg(){
		string[] allKeys = favourites.getKeys();
		string[] active;
		for (int i = 0; i < allKeys.length; ++i){
			bool val;
			favourites.get(allKeys[i], val);
			if(val)
				active.push_back(allKeys[i]);
		}

		ConfigFile cfg;
		cfg.addArray_string("favourites", active);
		cfg.saveFile("Favourites.cfg");
	}

}
