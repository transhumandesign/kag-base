//chat filter

array<string> wordreplace =
{
	//swears
	"fucker", 	"flipper",
	"fuck", 	"flip",
	"shitt", 	"poop",
	"shit", 	"poop",
	"crapp", 	"poop",
	"crap", 	"poop",
	"faggy", 	"flowery",
	"faggot", 	"flower",
	"poofter", 	"flower",
	"poof", 	"flower",
	"dyke", 	"wall",
	"nigger", 	"friend",
	"gook", 	"friend",
	"sluts", 	"ladies",
	"slut", 	"lady",
	"bitches", 	"ladies",
	"bitch", 	"lady",
	"asshole", 	"butthole",
	"arsehole",	"butthole",
	"arses", 	"butts",
	"arse", 	"butt",
	"cunt", 	"cat",
	"minge", 	"cat",
	"twat", 	"cat",
	"pussy", 	"cat",
	"dick", 	"clown",
	"peen", 	"clown",
	"bastard", 	"kid",
	"wank", 	"sing",

	//obnoxious memes
	"rekt", 	"hugged",

	//begin nonvital section
	"NONVITAL",
	//these ones might be part of other words
	//(or at least, words we care about)

	//swears

	"rape", 	"hurt",
	"cock", 	"clown",
	"asses", 	"butts",
	"ass", 		"butt",
	//obnoxious memes
	"rek", 		"hug",
};



bool isupper(u8 c)
{
	return (c >= 0x41 && c <= 0x5A);
}

u8 tolower(u8 c)
{
	if (isupper(c))
		c += 0x20;
	return c;
}

string tolower(string s)
{
	int len = s.size();
	for (int i = 0; i < len; i++)
		s[i] = tolower(s[i]);
	return s;
}

string KidSafeText(const string &in textIn)
{
	string text = textIn;
	string comparetext = tolower(textIn);
	bool vital_mode = true;

	for (uint i = 0; i < wordreplace.length - 1; i += 2)
	{
		string replace = wordreplace[i];
		string rwith = wordreplace[i + 1];

		if (replace == "NONVITAL")
		{
			vital_mode = false;
			i--;
			continue;
		}

		int pos = 0;
		do
		{
			pos = comparetext.find(replace, pos);
			if (pos != -1)
			{
				//replace in lowercase search string
				string before = pos > 0 ? comparetext.substr(0, pos) : "";
				string after = comparetext.substr(pos + replace.size());
				//for nonvital swears, ONLY if this is the entire word
				if (vital_mode ||
				        ((before == "" || before.substr(before.size() - 1) == " ") &&
				         (after == "" || after.substr(0, 1) == " "))
				   )
				{
					comparetext = before + rwith + after;
					//replace in preserved-caps string
					before = pos > 0 ? text.substr(0, pos) : "";
					after = text.substr(pos + replace.size());
					text = before + rwith + after;
				}
				pos++;
			}
		}
		while (pos != -1);
	}

	return text;
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	if (!g_noswears) 		//no processing
	{
		textOut = textIn;
		return true;
	}

	textOut = KidSafeText(textIn);

	return true;
}

//can enable filter server-side too :)
bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	if (!g_noswears) 		//no processing
	{
		textOut = textIn;
		return true;
	}

	textOut = KidSafeText(textIn);

	return true;
}
