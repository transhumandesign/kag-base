
// Change bloody spritelayers when g_kidssafe is toggled on/off

#define CLIENT_ONLY

void OnCloseMenu(CRules@ this)
{
	CBlob@[] blobs;
	getBlobsByName("saw", @blobs);
	getBlobsByName("spikes", @blobs);
	getBlobsByName("spike", @blobs);
	
	for (int i = 1; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		
		if (blob is null)	continue;
		
		string name = blob.getName();
		CSprite@ sprite = blob.getSprite();
		
		if (name == "saw")
		{
			CSpriteLayer@ chop = sprite.getSpriteLayer("chop");

			if (chop !is null)
			{	
				chop.animation.frame = blob.hasTag("bloody") && !g_kidssafe ? 1 : 0;
			}
		}
		else if (name == "spikes")
		{
			f32 hp = blob.getHealth();
			f32 full_hp = blob.getInitialHealth();
			int frame = (hp > full_hp * 0.9f) ? 0 : ((hp > full_hp * 0.4f) ? 1 : 2);
	
			if (blob.hasTag("bloody") && !g_kidssafe)
			{
				frame += 3;
			}
			sprite.animation.frame = frame;
		}
		else if (name == "spike")
		{
			sprite.animation.frame = blob.hasTag("bloody") && !g_kidssafe ? 1 : 0;
		}
	}
}