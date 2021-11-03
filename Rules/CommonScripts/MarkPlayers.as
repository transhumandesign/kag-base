
// shows indicators above clanmates and players of interest

#define CLIENT_ONLY

MarkInfo@[] marked;
bool pressed = false;

class MarkInfo
{
	string player_username;
	bool clanMate;
	bool active;

	MarkInfo() {};
	MarkInfo(CPlayer@ _player, bool _clanMate)
	{
		player_username = _player.getUsername();
		clanMate = _clanMate;
		active = true;
	};

	CPlayer@ player() {
		return getPlayerByUsername(player_username); 
	}
};

void onRestart(CRules@ this)
{
	updateMarked();
}

void onInit(CRules@ this)
{
	updateMarked();
}

void onTick(CRules@ this)
{
	if (getControls().ActionKeyPressed(AK_PARTY) && !pressed)
		markPlayer();
	
	pressed = getControls().ActionKeyPressed(AK_PARTY);
}

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	if ((getGameTime() % (5 * 30)) == 0)
	{
		updateMarked();
	}

	CMap@ map = getMap();
	if (map is null) 
		return;

	int deltaY = -2 + Maths::FastSin(getGameTime() / 4.5f) * 3.0f;
	for (uint i = 0; i < marked.length; i++)
	{
		if(marked[i].player() is null) break;

		CBlob@ blob = marked[i].player().getBlob();
		if (blob !is null && marked[i].active)
		{
			if (map.getTile(blob.getInterpolatedPosition()).light < 0x20 && blob !is getLocalPlayerBlob())
			{
				blob.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
				continue;
			}

			Vec2f p = blob.getInterpolatedPosition() + Vec2f(0.0f, -blob.getHeight() * 3.0f);
			p.x -= 8;
			Vec2f pos = getDriver().getScreenPosFromWorldPos(p);
			pos.y += deltaY;
			GUI::DrawIcon("GUI/PartyIndicator.png", marked[i].clanMate ? 2 : 1, Vec2f(16, 16), pos, getCamera().targetDistance);

			blob.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 0, Vec2f(8, 8)); 
		}
	}
}

void markPlayer()
{
	CMap@ map = getMap();
	CControls@ controls = getControls();
	CPlayer@ local = getLocalPlayer();

	if (map is null || controls is null || local is null) 
		return;
	
	CBlob@[] targets;
	if (!map.getBlobsInRadius(controls.getMouseWorldPos(), 8.0f, @targets))
		return;

	for (uint i = 0; i < targets.length; i++)
	{
		CBlob@ b = targets[i];
		if (b is null || b.getPlayer() is null)
			continue;

		CPlayer@ p = b.getPlayer();
		MarkInfo@ info = getMarkInfo(p);

		if (info is null)
		{
			bool clan = isClan(p); 
			marked.push_back(MarkInfo(p, clan));
		}
		else
		{
			info.active = !info.active;
			if (!info.active)
			{
				CBlob@ blob = info.player().getBlob();
				if (blob !is null)
				{
					blob.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
				}
			}
		}
		break;
	}
	
}

bool isClan(CPlayer@ p)
{
	return p.isMyPlayer() || p.getClantag() != "" && p.getClantag() == getLocalPlayer().getClantag(); 	
}

void updateMarked()
{
	CPlayer@ local = getLocalPlayer();
	if (local is null || !local.isMyPlayer())
		return;

	if (marked.length == 0)
	{
		marked.push_back(MarkInfo(local, true)); //push local player marker
	}

	if (local.getClantag() != "")
	{
		int count = getPlayerCount();
		for (uint i = 0; i < count; i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p.getClantag() == local.getClantag() && p !is local)
			{
				MarkInfo@ info = getMarkInfo(p);
				if (info is null)
				{
					marked.push_back(MarkInfo(p, true));
				}
			}
		}
	}

	//remove missing players and check for clantag changes
	for (uint i = 0; i < marked.length; i++)
	{
		CPlayer@ p = marked[i].player();
		if (p is null)
		{
			marked.erase(uint(i--));
		} 
		else 
		{
			marked[i].clanMate = isClan(p);
		}
	}
}

MarkInfo@ getMarkInfo(CPlayer@ player)
{
	string name = player.getUsername();
	for (uint i = 0; i < marked.length; i++)
	{
		if (marked[i].player_username == name)
		{
			return marked[i];
		}
	}
	return null;
}
