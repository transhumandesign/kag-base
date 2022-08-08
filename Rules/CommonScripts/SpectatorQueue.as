/* Spectator Queue script written by Bunnie
   Uses custom GUI, because in-built kag GUI functions didn't really work well for this purpose
   Supports multiple teams
*/

#include "RulesCore.as";
#include "BaseTeamInfo.as";

const int QueuePaneWidth = 480;
const int QueuePaneHeight = 128;
const int QueueTeamHeight = 64;

// Client-side stuff
int client_queue_pos = -1; // Our current position in queue
int client_selected = -99; // Currently selected team 
bool hide = false; // Are we hiding the main queue GUI?

// Array of all currently queued players
QueueEntry[] queue;

class QueueEntry
{
	string username;
	int team_num;

	QueueEntry(string _username, int _team_num = -1)
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

		if (player !is null) return player;

		return null; 
	}
}

class QueueGUIHidden
{
	Vec2f origin;
	Vec2f size;
	bool hovered;

	QueueGUIHidden(Vec2f _origin, Vec2f _size)
	{
		origin = _origin;
		size = _size;
	}

	bool isHovered(Vec2f mousepos)
	{
		Vec2f tl = origin;
		Vec2f br = origin + size;

		return (mousepos.x > tl.x && mousepos.y > tl.y &&
		        mousepos.x < br.x && mousepos.y < br.y);
	}

	void RenderGUI()
	{
		SColor color = SColor(255, 200, 200, 200);

		if (client_selected >= 0)
		{
			CTeam@ team = getRules().getTeam(client_selected);
			color = team.color;
		}
		if (hovered)
		{
			f32 tint_factor = (client_selected >= 0 ? 0.20 : 0.80);
			color = color.getInterpolated(color_white, tint_factor);
		}

		string text = "Queue Position: " + (client_queue_pos == -1 ? "None" : "" + (client_queue_pos + 1));
		GUI::DrawPane(origin, origin+size, color);
		Vec2f text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2);
		GUI::DrawTextCentered(text, text_pos, color_white);
	}

	void Update(CControls@ controls)
	{
		Vec2f mousepos = controls.getMouseScreenPos();
		const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		hovered = this.isHovered(mousepos);
		if (hovered && mouseJustReleased)
		{
			hide = false;
			Sound::Play("buttonclick.ogg");
		}
	}
}

class QueueGUI
{
	Vec2f mainpane_origin;
	Vec2f mainpane_size;
	int team_count;
	ClickButton@[] clickbuttons;

	QueueGUI(Vec2f _mainpane_origin, Vec2f _mainpane_size, int _team_count)
	{
		mainpane_origin = _mainpane_origin;
		mainpane_size = _mainpane_size;
		team_count = _team_count;

		Vec2f tl = mainpane_origin;
		Vec2f size = mainpane_size;

		// pane is too small for text if we try to divide it by more than 4 
		int QueueTeamWidth = size.x / Maths::Min(team_count, 4);

		// "Any team" team button
		ClickButton@ anyteam = ClickButton(Vec2f(tl.x + (size.x / 2) - (QueueTeamWidth / 2), tl.y + size.y + QueueTeamHeight), Vec2f(QueueTeamWidth, QueueTeamHeight), -1);
		clickbuttons.push_back(anyteam);

		// "Hide" button 
		ClickButton@ hidegui = ClickButton(Vec2f(tl.x + (size.x / 2) - (QueueTeamWidth / 2), tl.y - QueueTeamHeight), Vec2f(QueueTeamWidth, QueueTeamHeight), -2);
		clickbuttons.push_back(hidegui);

		if (team_count > 4)
		{
			for (int i=4; i<team_count; ++i)
			{
				tl.x -= QueueTeamWidth / 2;
				size.x += QueueTeamWidth / 2;
			}
		}

		// Team panes
		for (uint team_num = 0; team_num < team_count; ++team_num)
		{
			clickbuttons.push_back(ClickButton( Vec2f(tl.x + team_num * QueueTeamWidth, tl.y + size.y), Vec2f(QueueTeamWidth, QueueTeamHeight), team_num) );
		}

	}

	void RenderGUI()
	{
		Vec2f tl = mainpane_origin;
		Vec2f br = mainpane_origin + mainpane_size;

		GUI::SetFont("slightly bigger text");
		GUI::DrawPane(tl, br, SColor(255, 200, 200, 200));
		Vec2f queue_text_pos = Vec2f(tl.x + mainpane_size.x / 2, tl.y + mainpane_size.y / 2 - 35);
		GUI::DrawTextCentered("Queue Position", queue_text_pos, color_white);

		GUI::SetFont("big text");
		string queue_pos = (client_queue_pos == -1 ? "None" : "" + (client_queue_pos + 1));
		Vec2f pos_text_pos = Vec2f(tl.x + mainpane_size.x / 2, tl.y + mainpane_size.y / 2 + 10);
		GUI::DrawTextCentered(queue_pos, pos_text_pos, color_white);

		GUI::SetFont("menu");
		for (int i=0; i<clickbuttons.length; ++i)
		{
			clickbuttons[i].RenderGUI();
		}
	}

	void Update(CControls@ controls)
	{
		for (int i=0; i<clickbuttons.length; ++i)
		{
			clickbuttons[i].Update(controls);
		}
	}

	ClickButton@[]@ getClickButtons()
	{
		return clickbuttons;
	}
}

class ClickButton
{
	Vec2f origin;
	Vec2f size;
	int id; // -2 hide; -1 any team; 0> teams
	bool hovered;

	ClickButton(Vec2f _origin, Vec2f _size, int _id)
	{
		origin = _origin;
		size = _size;
		id = _id;
		hovered = false;
	}

	bool isHovered(Vec2f mousepos)
	{
		Vec2f tl = origin;
		Vec2f br = origin + size;

		return (mousepos.x > tl.x && mousepos.y > tl.y &&
		        mousepos.x < br.x && mousepos.y < br.y);
	}

	void RenderGUI()
	{
		int frame;
		SColor color;

		if (id >= 0)
		{
			CTeam@ team = getRules().getTeam(id);
			color = team.color;
		}
		else
		{
			color = SColor(255, 200, 200, 200);
		}

		string queue_text = "Queue to join";

		if (client_selected != id) 
		{
			if (hovered)
			{
				f32 tint_factor = (id >= 0 ? 0.20 : 0.80);
				color = color.getInterpolated(color_white, tint_factor);
			}
		}
		else
		{
			queue_text = "Waiting to join";
			color = SColor(255, 131, 198, 123);
			if (hovered)
			{
				f32 tint_factor = 0.20;
				color = color.getInterpolated(color_white, tint_factor);
			}
		}

		GUI::DrawPane(origin, origin+size, color);

		if (id >= -1)
		{
			Vec2f queue_text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2 - 10);
			GUI::DrawTextCentered(queue_text, queue_text_pos, color_white);

			Vec2f team_text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2 + 10);
			string team_text = (id >= 0 ? getRules().getTeam(id).getName() : "Any team");
			GUI::DrawTextCentered(team_text, team_text_pos, color_white);
		}
		else if (id == -2)
		{
			Vec2f hide_text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2);
			GUI::DrawTextCentered("Hide", hide_text_pos, color_white);
		}

	}

	void Update(CControls@ controls)
	{
		if (controls is null) return;

		Vec2f mousepos = controls.getMouseScreenPos();
		const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		bool hovered = this.isHovered(mousepos);

		if (hovered && mouseJustReleased)
		{
			hide = false;
			Sound::Play("buttonclick.ogg");

			bool selected = (client_selected != id);

			if (selected) 
			{
				hide = true;
			}

			Sound::Play("buttonclick.ogg");

			if (id >= -1)
			{
				CPlayer@ player = getLocalPlayer();
				if (player is null) return;

				if (selected)
					client_selected = id;
				else
					client_selected = -99;

				CBitStream params;
				params.write_string(player.getUsername());
				params.write_s32(id);
				params.write_bool(selected);

				getRules().SendCommand(getRules().getCommandID("queue action"), params);
			}
		}
	}
}

void SetupQueueGUI(CRules@ this)
{
	if (!isClient()) return;

	int team_count = this.get_s32("core.teams.length");
	if (team_count == 0) return;

	int width = getScreenWidth();
	int height = getScreenHeight();

	int horizontal_center = width / 2;

	Vec2f tl = Vec2f(horizontal_center - (QueuePaneWidth / 2), height - 300);
	Vec2f lr = tl + Vec2f(QueuePaneWidth, QueuePaneHeight);

	QueueGUI@ GUI = QueueGUI(tl, Vec2f(QueuePaneWidth, QueuePaneHeight), team_count);
	this.set("queuegui", @GUI);

	QueueGUIHidden@ SmallGUI = QueueGUIHidden(Vec2f(width - 200, 30), Vec2f(180, 50));
	this.set("queueguismall", @SmallGUI);
}

void AddToQueue(CPlayer@ player, int team = -1)
{
	queue.push_back(QueueEntry(player.getUsername(), team));

	if (isClient() && player.isMyPlayer())
		client_queue_pos = queue.length - 1;
}

void RemoveFromQueue(CPlayer@ player)
{
	for (int i=0; i<queue.length; ++i)
	{
		if (queue[i].username == player.getUsername())
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

int screenheight;
int screenwidth;

void onInit(CRules@ this)
{
	// for staging (resolution change support)
	if (isClient() && getLocalPlayer() !is null)
	{
		if (getLocalPlayer().isMyPlayer())
		{
			screenwidth = getScreenWidth();
			screenheight = getScreenHeight();
		}
	}

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

	RulesCore@ core;
	this.get("core", @core);
	if (core !is null)
	{
		this.set_s32("core.teams.length", core.teams.length);
		this.Sync("core.teams.length", true);
	}
}

void onReload(CRules@ this)
{
	onInit(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	// automatically add to queue 
	if (this.getSpectatorTeamNum() == player.getTeamNum())
	{
		SetupQueueGUI(this);

		if (getPlayersCount_NotSpectator() >= sv_maxplayers)
		{
			AddToQueue(player);
		}
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if (player.getTeamNum() != this.getSpectatorTeamNum()) return;

	RemoveFromQueue(player);
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	if (newteam == this.getSpectatorTeamNum())
	{
		SetupQueueGUI(this);
	}

	if (oldteam != this.getSpectatorTeamNum() && player.isMyPlayer()) 
	{
		hide = true;
		return;
	}

	if (this.get_bool(player.getUsername() + "_playsound"))
	{
		if (isClient() && player.isMyPlayer())
		{
			Sound::Play("AchievementUnlocked.ogg"); // TODO: different, distinct sound
		}

		this.set_bool(player.getUsername() + "_playsound", false);
	}

	client_selected = -99;
	RemoveFromQueue(player);
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

		if (selected)
		{
			AddToQueue(player, team_num);
		}

		QueueGUI@ GUI;
		this.get("queuegui", @GUI);
		if (GUI is null) return;
	}
}

void onTick(CRules@ this)
{
	// GUI update logic
	if (!g_videorecording)
	{
		// for staging (resolution change support)
		if (getScreenHeight() != screenheight || getScreenWidth() != screenwidth)
		{
			screenheight = getScreenHeight();
			screenwidth = getScreenWidth();

			QueueGUI@ GUI;
			this.get("queuegui", @GUI);
			SetupQueueGUI(this);
		}

		if (getLocalPlayer() !is null)
		{
			CControls@ controls = getControls();

			if (this.getSpectatorTeamNum() == getLocalPlayer().getTeamNum())
			{
				if (!hide)
				{
					QueueGUI@ GUI;
					this.get("queuegui", @GUI);
					if (GUI is null) 
					{
						SetupQueueGUI(this);
						return;
					}

					GUI.Update(controls);
				}
				else
				{
					QueueGUIHidden@ GUI;
					this.get("queueguismall", @GUI);
					if (GUI is null) 
					{
						SetupQueueGUI(this);
						return;
					}

					GUI.Update(controls);
				}
			}
		}
	}

	// Queue checking logic
	if (getPlayersCount_NotSpectator() < sv_maxplayers)
	{
		RulesCore@ core;
		this.get("core", @core);
		if (core is null) return; // core will be null on client

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

				if (smallestSize == ourSize)
				{
					newTeam = team;
				}
				else
				{
					continue;
				}
			}

			// disgusting workaround to play sound (didn't want to add a command just for a team change & sound)
			this.set_bool(player.getUsername() + "_playsound", false);
			this.SyncToPlayer(player.getUsername() + "_playsound", player);
			this.set_bool(player.getUsername() + "_playsound", true);
			this.SyncToPlayer(player.getUsername() + "_playsound", player);
			core.ChangePlayerTeam(player, newTeam);
			break;
		}
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording) return;

	if (getLocalPlayer() !is null)
	{
		if (this.getSpectatorTeamNum() == getLocalPlayer().getTeamNum())
		{
			if (!hide)
			{
				QueueGUI@ GUI;
				this.get("queuegui", @GUI);
				if (GUI is null) return;

				GUI.RenderGUI();
			}
			else
			{
				QueueGUIHidden@ GUI;
				this.get("queueguismall", @GUI);
				if (GUI is null) return;

				GUI.RenderGUI();
			}
		}
	}
}