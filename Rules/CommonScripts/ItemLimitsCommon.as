void sendChatWarningLimitedItem(int maximum, string item)
{
	// send warning to chat
	CBitStream params;
	CPlayer@ player = getLocalPlayer();
	CRules@ rules = getRules();
			
	params.write_string("Can't create more than " + maximum + " " + item + "s.");

	// List is reverse so we can read it correctly into SColor when reading
	SColor errorColor = SColor(255,255,100,0);
	params.write_u8(errorColor.getBlue());
	params.write_u8(errorColor.getGreen());
	params.write_u8(errorColor.getRed());
	params.write_u8(errorColor.getAlpha());

	rules.SendCommand(rules.getCommandID("SendChatMessage"), params, player);
}