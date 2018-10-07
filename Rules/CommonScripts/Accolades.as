///////////////////////////////////////////////////////////////////////////////
//
//  Accolades system
//
//      a way to give recognition to prominent players and contributors
//      past and present
//
///////////////////////////////////////////////////////////////////////////////

//a container and parser for the specific accolades awarded to a player
class Accolades
{
	//player these accolades are for
	string username = "";

	//tourney medal counts
	int gold = 0;
	int silver = 0;
	int bronze = 0;
	int participation = 0;

	//custom head info
	int customHeadAwarded = 0;              //(remains zero for non-custom-heads)
	string customHeadTexture = "";          //the head texture to use
	int customHeadIndex = 0;                //the index into the relevant texture
	int customHeadMonths = 0;               //"months"; really multiples of 31 days

	bool github_contributor = false;        //PR accepted
	bool community_contributor = false;     //forum/game mods, tourney organisers
	bool map_contributor = false;           //official mapcycle (at any point)

	Accolades(ConfigFile@ cfg, string _username)
	{
		username = _username;

		array<string> slices;
		if(cfg.readIntoArray_string(slices, username))
		{
			for(int i = 0; i < slices.length; i++)
			{
				//parse out accolades
				array <string>@ chunks = slices[i].split(" ");

				//1-part accolades
				if (chunks.length == 0) continue;

				string s1 = chunks[0];
				chunks.removeAt(0);

				//(simple "inclusion basis" accolades)
				if (s1 == "github") {
					github_contributor = true;
				} else if (s1 == "community") {
					community_contributor = true;
				} else if (s1 == "map") {
					map_contributor = true;
				}

				//2-part accolades
				if (chunks.length == 0) continue;

				string s2 = chunks[0];
				chunks.removeAt(0);

				//(medals)
				if (s1 == "gold") {
					gold = parseInt(s2);
				} else if (s1 == "silver") {
					silver = parseInt(s2);
				} else if (s1 == "bronze") {
					bronze = parseInt(s2);
				} else if (s1 == "participation") {
					participation = parseInt(s2);
				}

				//3-part accolades
				if (chunks.length == 0) continue;

				string s3 = chunks[0];
				chunks.removeAt(0);

				//4-part accolades
				if (chunks.length == 0) continue;

				string s4 = chunks[0];
				chunks.removeAt(0);

				//5-part accolades
				if (chunks.length == 0) continue;

				string s5 = chunks[0];
				chunks.removeAt(0);

				if (s1 == "customhead") {
					customHeadTexture = s2;
					customHeadIndex = parseInt(s3);
					customHeadAwarded = parseInt(s4);
					customHeadMonths = parseInt(s5);
				}
			}
		}
		else
		{
			//(defaults)
		}
	}

	bool hasCustomHead()
	{
		return
			//sanity check
			customHeadAwarded > 0 &&
			//actual days measurement
			Time_DaysSince(customHeadAwarded) <= 31 * customHeadMonths;
	}

};

//we keep a limit on the accolades kept in memory
//there's not much harm storage-wise but this getting too big can degrade perf
//on servers in the long run, as there's a lot of slow linear searches on the array
const int accolades_limit = 100;

//used to lazy-load the accolades config and array as needed
//(this means we dont need to be added to any gamemode specifically)
void LoadAccolades()
{
	CRules@ r = getRules();
	//
	if (!r.exists("accolades_cfg"))
	{
		ConfigFile cfg;
		cfg.loadFile("accolade_data.cfg");
		r.set("accolades_cfg", @cfg);
	}

	if(!r.exists("accolades_array"))
	{
		//todo: consider if this would be better just holding handles
		//      per-player in separate dictionary entries rather than searching
		//      each time
		array<Accolades> a;
		r.set("accolades_array", a);
	}
}

//get the config of accolades
//(you normally wont need to do this directly)
ConfigFile@ getAccoladesConfig()
{
	ConfigFile@ cfg = null;
	if(!getRules().get("accolades_cfg", @cfg))
	{
		error("accolades config missing - has LoadAccolades been called?");
	}
	return cfg;
}

//get the array of accolades
//(you normally wont need to do this directly)
array<Accolades>@ getAccoladesArray()
{
	array<Accolades>@ a = null;
	if(!getRules().get("accolades_array", @a))
	{
		error("accolades array missing - has LoadAccolades been called?");
	}
	return a;
}

//get the accolades for a given player by username
//(this is probably the function you're interested in!)
Accolades@ getPlayerAccolades(string username)
{
	LoadAccolades();
	array<Accolades>@ a = getAccoladesArray();

	//check for previous accolade
	for(int i = 0; i < a.length; i++)
	{
		if(a[i].username == username)
		{
			return a[i];
		}
	}

	//we haven't got a record for this player, construct anew!
	Accolades ac(getAccoladesConfig(), username);
	a.push_back(ac);

	//shift out "last added" if it's not used
	//todo: use a LRU elimination scheme
	//note: as handles are returned and these are AS objects
	//      there's no harm in this; live handles will not be erased
	if(a.length > accolades_limit)
	{
		a.removeAt(0);
	}

	//get a handle to the in-array element
	Accolades@ h = a[a.length - 1];

	return h;
}
