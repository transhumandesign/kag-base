string getTeamIcon(string icon, string file_name, int team_num, Vec2f frame_size = Vec2f(8,8), int frame_num = 0)
{
	if (!GUI::hasIconName("$" + icon + "$"))
	{
		return "$" + icon + "$";
	}

	string team_icon_name = "$" + icon + team_num + "$";
	if (GUI::hasIconName(team_icon_name))
	{
		return team_icon_name;
	}

	GUI::AddIconToken(team_icon_name, file_name, frame_size, frame_num, team_num);
	return team_icon_name;

}
