// resets quarry output rate, actual values for output are set in Quarry.as
// this script has to be added to gamemode.cfg for quarry output to decrease 

#define SERVER_ONLY

void onRestart(CRules@ this)
{
	for (int team = 0; team < this.getTeamsCount(); team++)
	{
		this.set_s32("current_quarry_output_" + team, -1);
	}
}