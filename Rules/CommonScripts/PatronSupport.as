//// Handles patron user's joining a full server & sending over custom heads

const string PNG_FILENAME = "CustomHead.png"; // File to search for when looking for custom head
const string BIT_STREAM_NAME = "HeadBitStream-"; // CBitStream get/set name (+player.getUsername())
const string CUSTOM_TEXTURE_NAME = "CustomHead-"; // Texture name for custom head (+player.getUsername())
const int ALPHA_IGNORE_LIMIT = 50; // Any alpha pixel at or below this will not send the RGB value to server/clients
const int PATRON_EXTRA_SLOTS = 2;

namespace CustomCmdType
{
	enum SubCommands
	{
		CAN_SEND_HEAD = 0, // Server -> Client - Let's client know they can send their head
		SENDING_HEAD, // Client -> Server - Server process client's head
		HEAD_TO_PLAYER,
	}
}

//extra patron slots handling
int onProcessFullJoin(CRules@ this, APIPlayer@ user)
{
	this.set_u16("supportTier " + user.username, user.supportTier);

	//allow royal guard and up supporters in
	if(
		//user is good supporter
		user.supportTier >= SUPPORT_TIER_ROYALGUARD
		//not up to the extra slots yet
		&& getPlayersCount() < (sv_maxplayers + PATRON_EXTRA_SLOTS)
	) {
		return 1;
	}
	//ignore otherwise
	return -1;
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!isClient())
		return;

	u16 tier = this.get_u16("supportTier " + player.getUsername());

	if (tier >= SUPPORT_TIER_ROYALGUARD && // if we are high enough in the tier list
		this.getSpectatorTeamNum() == player.getTeamNum() && // and we are a spectator
		getPlayersCount_NotSpectator() + PATRON_EXTRA_SLOTS <= sv_maxplayers) // and there are still free slots for us
	{
		player.server_setTeamNum(255); // server will auto balance them
	}

	// Is client allowed to have a custom head?
	if (tier >= SUPPORT_TIER_ROUNDTABLE)
	{
		// Let them know they can send us a head
		CBitStream stream = CBitStream();
		stream.write_u8(CustomCmdType::CAN_SEND_HEAD);

		this.SendCommand(this.getCommandID("SendCustomHead"), stream, player);
	}

	// Check to see if there are any custom head's currently in game
	// If so, send it to the new guy
	for (int a = 0; a < getPlayerCount(); a++)
	{
		CPlayer@ p = getPlayer(a);

		if (p is null)
			continue;

		if (this.exists(BIT_STREAM_NAME + player.getUsername()))
		{
			CBitStream@ stream;
			this.get_CBitStream(BIT_STREAM_NAME + player.getUsername(), stream);

			this.SendCommand(this.getCommandID("SendCustomHead"), stream, player);
		}
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if (isServer())
	{
		if (this.exists(BIT_STREAM_NAME + player.getUsername()))
			this.set_CBitStream(BIT_STREAM_NAME + player.getUsername(), CBitStream());
	}

	if (isClient())
	{
		if (Texture::exists(CUSTOM_TEXTURE_NAME + player.getUsername()))
			Texture::destroy(CUSTOM_TEXTURE_NAME + player.getUsername());
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (this.getCommandID("SendCustomHead") != cmd)
		return;

	u8 type = params.read_u8();

	switch (type)
	{
		case CustomCmdType::CAN_SEND_HEAD:
			if (isClient())
				Client_SendCustomHead(this);
		break;

		case CustomCmdType::SENDING_HEAD:
			if (isServer())
				Server_ProcessHead(this, params);
		break;

		case CustomCmdType::HEAD_TO_PLAYER:
			if (isClient())
				Client_HeadToPlayer(this, params);
		break;
	}
}

ImageData@ deserializeHeadStream(CBitStream@ params)
{
	ImageData head(64, 16);

	for (int h = 0; h < 16; h++)
	{
		for (int w = 0; w < 48; w++)
		{
			u8 alpha = params.read_u8();
			u8 red = 0;
			u8 green = 0;
			u8 blue = 0;

			if (alpha > ALPHA_IGNORE_LIMIT)
			{
				red = params.read_u8();
				green = params.read_u8();
				blue = params.read_u8();
			}

			head.put(w, h, SColor(alpha, red, green, blue));
		}
	}

	return head;
}


void Client_SendCustomHead(CRules@ this)
{
	if (!isClient() || !Texture::createFromFile("TempHead", PNG_FILENAME))
		return;

	ImageData@ data = Texture::data("TempHead");

	if (data.height() != 16 || data.width() != 64)
	{
		error("Could not send " + PNG_FILENAME + ", ensure the width is 64 pixels, and height is 16");
		Texture::destroy("TempHead");
		return;
	}

	// Each frame is 16x16
	// We send each frame instead of each 64x16
	CBitStream stream = CBitStream();
	stream.write_u8(CustomCmdType::SENDING_HEAD);
	stream.write_u16(getLocalPlayer().getNetworkID());

	SColor color = color_white;
	
	for (int h = 0; h < 16; h++)
	{
		for (int w = 0; w < 48; w++)
		{
			color = data.get(w, h);

			stream.write_u8(color.getAlpha());

			// Don't send colour if alpha is too low
			if (color.getAlpha() > ALPHA_IGNORE_LIMIT)
			{
				stream.write_u8(color.getRed());
				stream.write_u8(color.getGreen());
				stream.write_u8(color.getBlue());
			}
		}
	}

	this.SendCommand(this.getCommandID("SendCustomHead"), stream);
	
	// Add head texture locally (Server does not send the stream back to us)
	AddHeadTexture(getLocalPlayer(), data);
	Texture::destroy("TempHead");
}


void Server_ProcessHead(CRules@ this, CBitStream@ params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());

	if (player is null)
		return;

	string streamUsername = player.getUsername();

	if (this.get_u16("supportTier " + streamUsername) <= SUPPORT_TIER_ROUNDTABLE)
	{
		warn("Player " + streamUsername + " has attempted to give us a custom head without having correct patreon tier...");
		return;
	}

	CBitStream stream = CBitStream();
	stream.write_u8(CustomCmdType::HEAD_TO_PLAYER);
	stream.write_u16(player.getNetworkID());
	stream.writeBitStream(params);

	this.set_CBitStream(BIT_STREAM_NAME + streamUsername, stream);

	for (int a = 0; a < getPlayerCount(); a++)
	{
		CPlayer@ p = getPlayer(a);

		if (p is null || p.getUsername() == streamUsername)
			continue;
		
		this.SendCommand(this.getCommandID("SendCustomHead"), stream, player);
	}
}


void Client_HeadToPlayer(CRules@ this, CBitStream params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());

	if (player is null)
		return;

	AddHeadTexture(player, deserializeHeadStream(params));
}

void AddHeadTexture(CPlayer@ player, ImageData@ data)
{
	Texture::createFromData(CUSTOM_TEXTURE_NAME + player.getUsername(), data);
}

