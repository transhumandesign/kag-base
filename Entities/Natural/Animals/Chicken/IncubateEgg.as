#include "EmotesCommon.as"
#include "CrouchCommon.as"


void onInit(CBlob@ this) {
	this.getCurrentScript().tickFrequency = 10;
}

void onTick(CBlob@ this) {
    if (this.hasTag("is_incubating_egg")) {
        set_emote(this, 51);  // do chicken emote

        if (!isIncubatingEgg(this)) {
            this.Untag("is_incubating_egg");
            set_emote(this, Emotes::off);
        }
    }
}

/* Check if we're incubating an egg. */
bool isIncubatingEgg(CBlob@ this) {
    if (!isCrouching(this))
        return false;

	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);

	for (int i=0; i < overlapping.length; ++i) {
		CBlob@ blob = overlapping[i];
		if (blob.getName() == "egg") {
			return true;
		}
	}
	return false;
}