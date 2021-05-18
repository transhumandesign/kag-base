const string PNG_FILENAME = "CustomHead.png";
const int PATRON_EXTRA_SLOTS = 2;

enum CustomHeadCmd
{
	// Server -> Client - Can send customhead notice
	CAN_SEND_HEAD = 0,
	// Client -> Server - Sending png to server
	SENDING_HEAD,
	// Server -> Client - Sending texture to add to a player
	HEAD_TO_PLAYER,
}

void onInit(CRules@ this)
{
	this.addCommandID("SendCustomHead");
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
	u16 tier = this.get_u16("supportTier " + player.getUsername());
	if (tier >= SUPPORT_TIER_ROYALGUARD && // if we are high enough in the tier list
		this.getSpectatorTeamNum() == player.getTeamNum() && // and we are a spectator
		getPlayersCount_NotSpectator() + PATRON_EXTRA_SLOTS <= sv_maxplayers) // and there are still free slots for us
	{
		player.server_setTeamNum(255); // server will auto balance them
	}

	if (tier >= SUPPORT_TIER_ROUNDTABLE)
	{
		CBitStream stream = CBitStream();
		stream.write_u8(CAN_SEND_HEAD);

		this.SendCommand(this.addCommandID("SendCustomHead"), stream, player);
	}

}

// TEMP
void onTick(CRules@ this)
{
    CControls@ controls = getControls();
    if (controls.ActionKeyPressed(AK_MAP))
    {
        client_SendCustomHead(this);
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (this.getCommandID("SendCustomHead") != cmd)
		return;

	u8 type = params.read_u8();

	switch (type)
	{
		case CAN_SEND_HEAD:
			if (isClient())
				client_SendCustomHead(this);
		break;

		case SENDING_HEAD:
			if (isServer())
				server_ProcessHead(this, params);
		break;

		case HEAD_TO_PLAYER:
			if (isClient())
				client_HeadToPlayer(this, params);
		break;
	}
}

ImageData@ DeseralizeHead(CBitStream@ params)
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

			if (alpha > 50)
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


void client_SendCustomHead(CRules@ this)
{
	//TMEP
	Texture::destroy("customhead");

    if ( !isClient() || !Texture::createFromFile("customhead", PNG_FILENAME))
        return;

    ImageData@ data = Texture::data("customhead");

    if (data.height() != 16 || data.width() != 64)
    {
        print("Could not send " + PNG_FILENAME + ", ensure the width is 64 pixels, and height is 16");
        return;
    }

    // Each frame is 16x16
    // We send each frame instead of each 64x16
    CBitStream stream = CBitStream();
	stream.write_u8(SENDING_HEAD);
	stream.write_u16(getLocalPlayer().getNetworkID());

    SColor color = color_white;
    
    for (int h = 0; h < 16; h++)
    {
        for (int w = 0; w < 48; w++)
        {
            color = data.get(w, h);

            stream.write_u8(color.getAlpha());

            // Don't send colour if alpha is too low
            if (color.getAlpha() > 50)
            {
                stream.write_u8(color.getRed());
                stream.write_u8(color.getGreen());
                stream.write_u8(color.getBlue());
            }
        }
    }

	this.SendCommand(this.getCommandID("SendCustomHead"), stream);
	AddHeadTexture(getLocalPlayer(), data);
}


void server_ProcessHead(CRules@ this, CBitStream@ params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());

	if (player is null)
		return;

	string pat_username = player.getUsername();

	if (this.get_u16("supportTier " + pat_username) <= SUPPORT_TIER_ROUNDTABLE)
	{
		warn("Player " + pat_username + " has attempted to give us a custom head without having patreon..");
		return;
	}

	CBitStream stream = CBitStream();
	stream.write_u8(HEAD_TO_PLAYER);
	stream.write_u16(player.getNetworkID());
	stream.writeBitStream(params);

	this.set_CBitStream("head-bitstream-"+pat_username, stream);


	for (int a = 0; a < getPlayerCount(); a++)
	{
		CPlayer@ p = getPlayer(a);

		if (p is null || p.getUsername() == pat_username)
			continue;
		
		this.SendCommand(this.getCommandID("SendCustomHead"), stream, player);
	}
}


void client_HeadToPlayer(CRules@ this, CBitStream params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());

	if (player is null)
		return;

	AddHeadTexture(player, DeseralizeHead(params));
}

void AddHeadTexture(CPlayer@ player, ImageData@ data)
{
	Texture::createFromData("CustomHead-"+player.getUsername(), data);
}

