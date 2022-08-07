#include "RulesCore.as";
#include "BaseTeamInfo.as";

int client_queue_pos = -1;
QueueEntry[] queue;
ClickButton[] clickbuttons;

class QueueEntry
{
	string username;
	int team_num;

	QueueEntry(string _username, int _team_num=-1)
	{
		username = _username;
		team_num = _team_num;
	}

	int getTeam()
	{
		return team_num;
	}

	CPlayer@ getPlayer()
	{
		CPlayer@ player = getPlayerByUsername(username);

		if(player !is null) return player;

		return null; 
	}
}

class ClickButton
{
	Vec2f origin;
	Vec2f size;
	int team_num;
	bool selected;
	bool hovered;

	ClickButton(Vec2f _origin, Vec2f _size, int _team_num)
	{
		origin = _origin;
		size = _size;
		team_num = _team_num;
		selected = false;
		hovered = false;
	}

	bool isHovered(Vec2f mousepos)
	{
		Vec2f tl = origin;
		Vec2f br = origin + size;

		if (mousepos.x > tl.x && mousepos.y > tl.y &&
			 mousepos.x < br.x && mousepos.y < br.y)
		{
			return true;
		}
		return false;
	}

	void RenderGUI()
	{
		int frame;
		SColor color;

		if (team_num != -1)
		{
			CTeam@ team = getRules().getTeam(team_num);
			color = team.color;
		}
		else
		{
			color = SColor(255, 200, 200, 200);
		}

		string queue_text = "Queue to join";

		if(!selected) 
		{
			if (hovered)
			{
				f32 tint_factor = (team_num != -1 ? 0.20 : 0.80);
				color.set(255, 
					color.getRed() + (255 - color.getRed()) * tint_factor, 
					color.getGreen() + (255 - color.getGreen()) * tint_factor, 
					color.getBlue() + (255 - color.getBlue()) * tint_factor);
			}
		}
		else
		{
			queue_text = "Waiting to join";
			color = SColor(255, 131, 198, 123);
			if (hovered)
			{
				f32 tint_factor = 0.20;
				color.set(255, 
					color.getRed() + (255 - color.getRed()) * tint_factor, 
					color.getGreen() + (255 - color.getGreen()) * tint_factor, 
					color.getBlue() + (255 - color.getBlue()) * tint_factor);
			}
		}

		GUI::DrawPane(origin, origin+size, color);

		Vec2f queue_text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2 - 10);
		GUI::DrawTextCentered(queue_text, queue_text_pos, color_white);

		Vec2f team_text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2 + 10);
		string team_text = (team_num != -1 ? getRules().getTeam(team_num).getName() : "Any team");
		GUI::DrawTextCentered(team_text, team_text_pos, color_white);
	}

	void Update(CControls@ controls)
	{
		Vec2f mousepos = controls.getMouseScreenPos();
		const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		if (this.isHovered(mousepos))
		{
			if (!hovered)
			{
				hovered = true;
			}

			if (mouseJustReleased)
			{
				selected = !selected;
				Sound::Play("buttonclick.ogg");

				CPlayer@ player = getLocalPlayer();
				if (player is null) return;

				CBitStream params;
				params.write_string(player.getUsername());
				params.write_s32(team_num);
				params.write_bool(selected);

				getRules().SendCommand(getRules().getCommandID("queue action"), params);
			}
		}
		else if (hovered)
		{
			hovered = false;
		}
	}
}

void setupQueueGUI(CRules@ this)
{
	if (!isClient()) return;

	if (getLocalPlayer().getTeamNum() != this.getSpectatorTeamNum()) return;

	clickbuttons.clear();

	RulesCore@ core;
	this.get("core", @core);
	if (core is null) return;

	int width = getScreenWidth();
	int height = getScreenHeight();

	int half_width = width / 2;

	// Main pane
	Vec2f topleft_mainpane = Vec2f(half_width - 240, height - 300);
	Vec2f lowerright_mainpane = topleft_mainpane + Vec2f(480, 120);

	// Team panes
	Vec2f topleft_teampane = topleft_mainpane + Vec2f(0, 120);
	int team_count = core.teams.length;

	clickbuttons.push_back(ClickButton(Vec2f(topleft_mainpane.x + 120, topleft_mainpane.y + 184), Vec2f(240, 64), -1));

	for (uint team_num = 0; team_num < core.teams.length; ++team_num)
	{
		clickbuttons.push_back(ClickButton(topleft_teampane, Vec2f(480 / team_count, 64), team_num));

		topleft_teampane += Vec2f(480 / team_count, 0);
	}
}

int mainpane_width = 480;
int mainpane_height = 120;

void drawQueue(CRules@ this)
{
	if (!isClient()) return;

	if (getLocalPlayer() is null) return;

	if (getLocalPlayer().getTeamNum() != this.getSpectatorTeamNum()) return;

	if (clickbuttons.length == 0) 
	{
		setupQueueGUI(this);
		return;
	}

	RulesCore@ core;
	this.get("core", @core);
	if (core is null) return;

	int width = getScreenWidth();
	int height = getScreenHeight();

	int half_width = width / 2;

	// Main pane
	Vec2f topleft_mainpane = Vec2f(half_width - mainpane_width / 2, height - 300);
	Vec2f lowerright_mainpane = topleft_mainpane + Vec2f(mainpane_width, mainpane_height);

	GUI::SetFont("slightly bigger text");

	GUI::DrawPane(topleft_mainpane, lowerright_mainpane, SColor(255, 200, 200, 200));
	Vec2f queue_text_pos = Vec2f(topleft_mainpane.x + mainpane_width / 2, topleft_mainpane.y + mainpane_height / 2 - 35);
	GUI::DrawTextCentered("Queue Position", queue_text_pos, color_white);

	GUI::SetFont("big text");

	string queue_pos = (client_queue_pos == -1 ? "None" : "" + (client_queue_pos + 1));

	Vec2f pos_text_pos = Vec2f(topleft_mainpane.x + mainpane_width / 2, topleft_mainpane.y + mainpane_height / 2 + 10);
	GUI::DrawTextCentered(queue_pos, pos_text_pos, color_white);

	// Team panes
	Vec2f topleft_teampane = topleft_mainpane + Vec2f(0, mainpane_height);
	int team_count = core.teams.length;

	for (uint i=0; i<clickbuttons.length; ++i)
	{
		GUI::SetFont("menu");
		clickbuttons[i].RenderGUI();
	}
}

void addToQueue(CPlayer@ player, int team=-1)
{
	QueueEntry@ queue_entry = QueueEntry(player.getUsername(), team);
	queue.push_back(queue_entry);

	if (isClient() && player.isMyPlayer())
		client_queue_pos = queue.length - 1;
}

void RemoveFromQueue(CPlayer@ player)
{
	for(int i=0; i<queue.length; ++i)
	{
		if(queue[i].username == player.getUsername())
		{
			queue.removeAt(i);

			if (isClient())
			{
				if (i == client_queue_pos) client_queue_pos = -1;
				else if (i < client_queue_pos) client_queue_pos--;
			}
		}
	}
}

// hooks

void onInit(CRules@ this)
{
	this.addCommandID("queue action");

	if (!GUI::isFontLoaded("slightly bigger text"))
	{
		string font = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("slightly bigger text", font, 36, true);
	}

	if (!GUI::isFontLoaded("big text")) 
	{
		string font = CFileMatcher("AveriaSerif-Regular.ttf").getFirst();
		GUI::LoadFont("big text", font, 60, true);
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	// automatically add to queue 
	if (this.getSpectatorTeamNum() == player.getTeamNum() && getPlayersCount_NotSpectator() >= sv_maxplayers)
	{
		addToQueue(player);
		setupQueueGUI(this);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if (player.getTeamNum() != this.getSpectatorTeamNum()) return;

	RemoveFromQueue(player);
}

void onPlayerChangedTeam( CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam )
{
	if (newteam == this.getSpectatorTeamNum())
	{
		setupQueueGUI(this);
	}

	if (oldteam != this.getSpectatorTeamNum()) return;

	RemoveFromQueue(player);
}

void onTick(CRules@ this)
{
	CControls@ controls = getControls();

	for (uint i=0; i<clickbuttons.length; ++i)
	{
		clickbuttons[i].Update(controls);
	}

	for (uint i=0; i<queue.length; ++i)
	{
		printf("user: " + queue[i].username +" , team: " + queue[i].team_num);
	}

	if (getPlayersCount_NotSpectator() < sv_maxplayers && getGameTime() % 150 == 0)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core is null) return;

		for (u16 i=0; i<queue.length; ++i)
		{
			QueueEntry@ queue_entry = queue[i];
			int team = queue_entry.getTeam();
			CPlayer@ player = queue_entry.getPlayer();

			if (player is null) // shouldn't happen in theory
			{
				queue.removeAt(i);
				--i;
				continue;
			}

			s32 newTeam;

			if (team == -1) // any team
			{
				newTeam = getSmallestTeam(core.teams);
			}
			else 
			{
				int smallestTeam = getSmallestTeam(core.teams);
				int ourSize = getTeamSize(core.teams, team);
				int smallestSize = getTeamSize(core.teams, smallestTeam);

				if(smallestSize == ourSize)
				{
					newTeam = team;
				}
				else
				{
					continue;
				}
			}

			core.ChangePlayerTeam(player, newTeam);
			Sound::Play("AchievementUnlocked.ogg"); // ?
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("queue action"))
	{
		string username;
		if (!params.saferead_string(username)) return;
		s32 team_num;
		if (!params.saferead_s32(team_num)) return;
		bool selected;
		if (!params.saferead_bool(selected)) return;

		CPlayer@ player = getPlayerByUsername(username);
		
		if (player is null) return;

		RemoveFromQueue(player);

		if (player.getTeamNum() != this.getSpectatorTeamNum()) return;

		// unselect all other buttons
		for (uint i=0; i<clickbuttons.length; ++i)
		{
			if (clickbuttons[i].team_num != team_num) clickbuttons[i].selected = false;
		}

		if (selected)
		{
			addToQueue(player, team_num);
		}
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording) return;

	drawQueue(this);
}