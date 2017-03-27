
shared class TraderWantedList
{
	CPlayer@[] kill;

	TraderWantedList() {}

	void addPlayer(CPlayer@ tokill)
	{
		if (!hasPlayer(tokill))
		{
			kill.push_back(tokill);
		}
	}

	bool hasPlayer(CPlayer@ p)
	{
		return (p !is null && kill.find(p) != -1);
	}

};

void EnsureWantedList()
{
	CRules@ rules = getRules();
	if (rules !is null)
	{
		TraderWantedList@ hits = null;
		rules.get("trader wanted list", @hits);
		if (hits is null)
		{
			rules.set("trader wanted list", TraderWantedList());
		}
	}
}

TraderWantedList@ getWantedList()
{
	CRules@ rules = getRules();
	if (rules !is null)
	{
		TraderWantedList@ hits = null;
		rules.get("trader wanted list", @hits);
		if (hits !is null)
		{
			return hits;
		}
	}
	return null;
}
