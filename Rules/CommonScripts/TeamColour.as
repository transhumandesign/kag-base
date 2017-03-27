SColor getTeamColor(int team)
{
	SColor teamCol; //get the team colour of the attacker

	switch (team)
	{
		case 0: teamCol.set(0xff2cafde); break;

		case 1: teamCol.set(0xffd5543f); break;

		case 2: teamCol.set(0xff9dca22); break;

		case 3: teamCol.set(0xffd379e0); break;

		case 4: teamCol.set(0xfffea53d); break;

		case 5: teamCol.set(0xff2ee5a2); break;

		case 6: teamCol.set(0xff5f84ec); break;

		case 7: teamCol.set(0xffc4cfa1); break;

		default: teamCol.set(0xff888888);
	}
	return teamCol;
}
