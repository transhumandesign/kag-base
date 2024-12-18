//voting generic update and render

#include "VoteCommon.as"

const string favour_string = "IN FAVOUR";
const string against_string = "AGAINST";

bool g_have_voted = false;
string favour_or_not = "";
bool hide_vote_menu = false;

//extended vote functionality
const Vec2f dim(200, 116);

Vec2f getTopLeft()
{
	return Vec2f(getScreenWidth() - 210, 182 + (Maths::Sin(getGameTime() / 10.0f) + 1.0f) * 3.0f);
}

//hooks

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	if (hide_vote_menu)
		return;
	
	if (!Rules_AlreadyHasVote(this)) return;

	VoteObject@ vote = Rules_getVote(this);
	CPlayer@ me = getLocalPlayer();

	const bool can_force_pass = vote.forcePassFeature != "" &&
	                            (getSecurity().checkAccess_Feature(me, vote.forcePassFeature) ||
	                             getSecurity().checkAccess_Command(me, vote.forcePassFeature));
	const bool can_cancel = getSecurity().checkAccess_Feature(me, "vote_cancel");

	if ((!CanPlayerVote(vote, me) && !can_force_pass && !can_cancel)) return;

	Vec2f tl = getTopLeft();
	Vec2f br = tl + dim;
	Vec2f text_dim;

	string vote_title = getTranslatedString(vote.title);
	if (vote.user_to_kick != "")
	{
		vote_title = vote_title.replace("{USER}", vote.user_to_kick);
	}

	GUI::SetFont("menu");
	GUI::GetTextDimensions(vote_title, text_dim);

	if (can_cancel || can_force_pass)
	{
		br += Vec2f(0, text_dim.y);
	}

	GUI::DrawPane(tl, br, SColor(0x80ffffff));
	GUI::DrawText(vote_title, tl + Vec2f(Maths::Max(dim.x / 2 - text_dim.x / 2, 3.0), 3), color_white);

	GUI::DrawText(getTranslatedString("Reason: {REASON}").replace("{REASON}", getTranslatedString(vote.reason)), tl + Vec2f(3, 3 + text_dim.y * 2), color_white);
	GUI::DrawText(getTranslatedString("Cast by: {USER}").replace("{USER}", vote.byuser), tl + Vec2f(3, 3 + text_dim.y * 3), color_white);
	GUI::DrawText(getTranslatedString("For: ") + vote.current_yes, tl + Vec2f(20, 3 + text_dim.y * 4), color_white);
	GUI::DrawText(getTranslatedString("Against: ") + vote.current_no, tl + Vec2f(110, 3 + text_dim.y * 4), color_white);
	if (!g_have_voted)
	{
		GUI::DrawText(getTranslatedString("[O] - Yes"), tl + Vec2f(20, 3 + text_dim.y * 5), SColor(0xff30bf30));
		GUI::DrawText(getTranslatedString("[P] - No"), tl + Vec2f(120, 3 + text_dim.y * 5), SColor(0xffbf3030));
	}
	else
	{
		f32 favour_offset = favour_or_not == favour_string ? 24 : 30; // using DrawTextCentered messes it up
		GUI::DrawText(getTranslatedString("Your vote: {OURVOTE}").replace("{OURVOTE}", getTranslatedString(favour_or_not)), tl + Vec2f(favour_offset, 3 + text_dim.y * 5), favour_or_not == favour_string ? SColor(0xff30bf30) : SColor(0xffbf3030));
	}

	if (can_force_pass)
	{
		GUI::DrawText(getTranslatedString("Ctrl+O Pass"), tl + Vec2f(3, 3 + text_dim.y * 6), SColor(0xff30bf30));
	}

	if (can_cancel)
	{
		GUI::DrawText(getTranslatedString("Ctrl+P Cancel"), tl + Vec2f(95, 3 + text_dim.y * 6), SColor(0xffbf3030));
	}

	GUI::DrawText(getTranslatedString("Click to close ({TIMELEFT}s)").replace("{TIMELEFT}", "" + Maths::Ceil(vote.timeremaining / 30.0f)), br - Vec2f(175, 7 + text_dim.y), color_white);
}

void onTick(CRules@ this)
{
	if (!Rules_AlreadyHasVote(this))
	{
		g_have_voted = false;
		hide_vote_menu = false;
		return;
	}

	VoteObject@ vote = Rules_getVote(this);

	vote.timeremaining--;

	CRules@ rules = getRules();

	if (isServer() && ((vote.timeremaining == 0) || Vote_Conclusive(vote)))	//time up or decision made
	{
		PassVote(vote);
		rules.SendCommand(rules.getCommandID(vote_end_id_client), CBitStream());
	}

	//--------------------------------- CLIENT ---------------------------------
	CPlayer@ me = getLocalPlayer();
	if (!isClient() || !CanPlayerVote(vote, me) || hide_vote_menu) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	u16 id = me.getNetworkID();
	bool voted = false; //voted yes or no
	bool favour = false;

	if (controls.mousePressed1)
	{
		Vec2f tl = getTopLeft();
		Vec2f br = tl + dim;
		Vec2f mousepos = controls.getMouseScreenPos();

		if (mousepos.x > tl.x && mousepos.y > tl.y - 6 &&
		        mousepos.x < br.x && mousepos.y < br.y + 6)
		{
			hide_vote_menu = true;
		}
	}

	if (controls.isKeyPressed(KEY_KEY_O))
	{
		if ((controls.isKeyPressed(KEY_LCONTROL) || controls.isKeyPressed(KEY_RCONTROL))
		        && vote.forcePassFeature != "" && (getSecurity().checkAccess_Feature(me, vote.forcePassFeature)
		                || getSecurity().checkAccess_Command(me, vote.forcePassFeature)))
		{
			CBitStream params;
			params.write_u16(id);
			rules.SendCommand(rules.getCommandID(vote_force_pass_id), params);
			g_have_voted = true;
			return;
		}
		if (!g_have_voted)
		{
			voted = true;
			favour = true;
		}
	}
	else if (controls.isKeyPressed(KEY_KEY_P))
	{
		if ((controls.isKeyPressed(KEY_LCONTROL) || controls.isKeyPressed(KEY_RCONTROL))
		        && getSecurity().checkAccess_Feature(me, "vote_cancel"))
		{
			CBitStream params;
			params.write_u16(id);
			rules.SendCommand(rules.getCommandID(vote_cancel_id), params);
			g_have_voted = true;
			return;
		}
		if (!g_have_voted)
		{
			voted = true;
			favour = false;
		}
	}

	if (voted)
	{
		favour_or_not = (favour == true ? favour_string : against_string);

		CBitStream params;
		rules.SendCommand(rules.getCommandID(favour ? vote_yes_id : vote_no_id), params);

		g_have_voted = true;
	}
}

const string vote_yes_id = "vote: yes";									//client->server "yes" vote
const string vote_yes_id_client = "vote: yes client";					//server->client "yes" vote
const string vote_no_id = "vote: no";									//client->server "no" vote
const string vote_no_id_client = "vote: no client";						//server->client "no" vote
const string vote_cancel_id = "vote: cancel";							//client->server admin cancel vote
const string vote_cancel_id_client = "vote: cancel client";				//server->client admin cancel vote
const string vote_force_pass_id = "vote: force pass";					//client->server admin force pass vote
const string vote_force_pass_id_client = "vote: force pass client";		//server->client admin force pass vote
const string vote_end_id_client = "vote: ended client";					//server->client "vote over"

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	this.addCommandID(vote_yes_id);
	this.addCommandID(vote_yes_id_client);
	this.addCommandID(vote_no_id);
	this.addCommandID(vote_no_id_client);
	this.addCommandID(vote_cancel_id);
	this.addCommandID(vote_cancel_id_client);
	this.addCommandID(vote_force_pass_id);
	this.addCommandID(vote_force_pass_id_client);
	this.addCommandID(vote_end_id_client);

	if(Rules_AlreadyHasVote(this))
	{
		VoteObject@ vote = Rules_getVote(this);
		if(vote.cancel_on_restart)
			CancelVote(vote, null);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if (Rules_AlreadyHasVote(this))
	{
		VoteObject@ vote = Rules_getVote(this);
		if (vote.playerleave !is null)
		{
			vote.playerleave.PlayerLeft(vote, player);
		}
	}

	updateAdminOnline(player);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	updateAdminOnline(null);
}

void updateAdminOnline(CPlayer@ justleft)
{
	CSecurity@ security = getSecurity();
	bool adminOnline = false;
	for (int i = 0; i < getPlayersCount(); ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player !is justleft && security.checkAccess_Feature(player, "vote_cancel"))
		{
			adminOnline = true;
			break;
		}
	}

	getRules().set_bool("admin online", adminOnline);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	VoteObject@ vote = Rules_getVote(this);
	//always allow passing the vote, even if its expired
	if (cmd == this.getCommandID(vote_end_id_client) && isClient())
	{
		PassVote(vote);
	}

	if (!Rules_AlreadyHasVote(this))
	{
		return;
	}

	if ((cmd == this.getCommandID(vote_yes_id) || cmd == this.getCommandID(vote_no_id)) && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (CanPlayerVote(vote, player))
		{
			Vote(vote, player, cmd == this.getCommandID(vote_yes_id));

			u8 client_cmd = (cmd == this.getCommandID(vote_yes_id) ? this.getCommandID(vote_yes_id_client) : this.getCommandID(vote_no_id_client));

			CBitStream params;
			params.write_u16(player.getNetworkID());
			this.SendCommand(client_cmd, params);
		}
	}
	else if ((cmd == this.getCommandID(vote_yes_id_client) || cmd == this.getCommandID(vote_no_id_client)) && isClient())
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CPlayer@ player = getPlayerByNetworkId(id);
		if (player is null) return;

		Vote(vote, player, cmd == this.getCommandID(vote_yes_id_client));
	}
	else if (cmd == this.getCommandID(vote_cancel_id) && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (getSecurity().checkAccess_Feature(player, "vote_cancel")) //double-check to avoid hackers
		{
			CancelVote(vote, player);

			CBitStream params;
			params.write_u16(player.getNetworkID());
			this.SendCommand(this.getCommandID(vote_cancel_id_client), params);
		}
	}
	else if (cmd == this.getCommandID(vote_cancel_id_client) && isClient())
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CPlayer@ player = getPlayerByNetworkId(id);
		if (player is null) return;

		CancelVote(vote, player);
	}
	else if (cmd == this.getCommandID(vote_force_pass_id) && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		if (vote.forcePassFeature != "" && (getSecurity().checkAccess_Feature(player, vote.forcePassFeature)
		                                    || getSecurity().checkAccess_Command(player, vote.forcePassFeature)))  //double-check to avoid hackers
		{
			ForcePassVote(vote, player);

			CBitStream params;
			params.write_u16(player.getNetworkID());
			this.SendCommand(this.getCommandID(vote_force_pass_id_client), params);
		}
	}
	else if (cmd == this.getCommandID(vote_force_pass_id_client) && isClient())
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CPlayer@ player = getPlayerByNetworkId(id);
		if (player is null) return;

		ForcePassVote(vote, player);
	}
}
