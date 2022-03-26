string getCountry(CPlayer@ player)
{
	return getRules().get_string(player.getNetworkID() + " country");
}

string getRegion(CPlayer@ player)
{
	return getRules().get_string(player.getNetworkID() + " region");
}

string getCountryCode(CPlayer@ player)
{
	return getRules().get_string(player.getNetworkID() + " code");
}
