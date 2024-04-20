
// Change bloody spritelayers when g_kidssafe is toggled on/off

#define CLIENT_ONLY

#include "UpdateBloodySprite.as";

void onInit(CRules@ this)
{
	this.set_bool("g_kidssafe", g_kidssafe);
}

void onTick(CRules@ this)
{
	if (this.get_bool("g_kidssafe") != g_kidssafe)
	{
		CBlob@[] blobs;
		getBlobsByName("saw", @blobs);
		getBlobsByName("spikes", @blobs);
		getBlobsByName("spike", @blobs);
		
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			
			if (blob is null)	continue;
			
			UpdateBloodySprite(blob);
		}
		
		this.set_bool("g_kidssafe", g_kidssafe);
	}
}
