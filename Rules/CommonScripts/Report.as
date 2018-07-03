void test(string message)
{
    print("Hi, " + message);
}

void report(CPlayer@ reportedPlayer, string reportedName)
{
    print("Reporting " + reportedName);
    print("Reporting " + player.getUsername());
    print("Reporting " + player.getCharacterName());
    print("Reporting " + player.getTeamNum());
    print("Reporting " + reportedName);

    client_AddToChat("teeest", SColor(255, 255, 0, 0));
}