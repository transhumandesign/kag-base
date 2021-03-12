// This script works with an external program that propagates bans to other connected servers
// This ensures banned players get banned on all other connected servers

void onBan(const string username, const int minutes, const string reason)
{
	tcpr("BAN " + username + " " + minutes + " " + reason);
}

void onUnban(const string username)
{
	tcpr("UNBAN " + username);
}
