// MechanismsReader.as

#include "MechanismsCommon.as";

/////////////////////////////////////
// Mechanisms packet reader,
// reads packets sent from server,
// performs actions based on
// packet type and component
// functionality
/////////////////////////////////////

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	this.addCommandID("mechanisms_packet_client");
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("mechanisms_packet_client") && isClient())
	{
		packet_RecvStream(this, params);
	}
}