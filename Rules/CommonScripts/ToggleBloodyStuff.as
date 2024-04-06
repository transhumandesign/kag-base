
// Change bloody spritelayers when g_kidssafe is toggled on/off

#define CLIENT_ONLY

#include "UpdateBloodySprite.as";

void OnCloseMenu(CRules@ this)
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
}
