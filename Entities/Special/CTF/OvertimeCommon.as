// OvertimeCommon.as

void onTick (CBlob@ this) {
    CRules@ rules = getRules();
    s32 end_in = rules.get_s32("end_in");

    if (rules.getCurrentState() == GAME) {
        if (end_in <= 10) {
            if (this.hasTag("has attached to player")) {
                rules.add_u32("game_end_time", (60 * 30)); // add additional 60 sec for cap
                rules.Sync("game_end_time", true);
                
                // TODO: find suitable sounds
                //this.SendCommand(this.getCommandID("overtime sound"));
            }
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("overtime sound") && isClient()) {
        int random = XORRandom(4) + 1;
        Sound::Play("overtime" + random + ".ogg");
    }
}