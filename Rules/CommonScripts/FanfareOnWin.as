void onStateChange( CRules@ this, const u8 oldState )
{
	if (this.isGameOver() && this.getTeamWon() >= 0)
	{
		// only play for winners
		CPlayer@ localplayer = getLocalPlayer();
		if (localplayer !is null)
		{
			CBlob@ playerBlob = getLocalPlayerBlob();
			int teamNum = playerBlob !is null ? playerBlob.getTeamNum() : localplayer.getTeamNum() ; // bug fix (cause in singelplayer player team is 255)
			if (teamNum == this.getTeamWon())
			{
				Sound::Play("/FanfareWin.ogg");
			}
			else
			{
				Sound::Play("/FanfareLose.ogg");
			}
		}
	}
}
