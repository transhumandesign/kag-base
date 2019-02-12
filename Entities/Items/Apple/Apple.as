// Apple Logic
void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	this.Tag("on_tree");
}

void onInit(CSprite@ this)
{
	this.animation.frame = (this.getBlob().getNetworkID() % 3); // choses 1 of the 3 different frames from the default animation
	this.getCurrentScript().runFlags |= Script::remove_after_this; // once we've done that, remove it and don't do it again
}

// void on tick, if not touching tree, remove tag; if doesn't have on tree tag, do this.shape.SetGravityScale(1.0f);

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	this.shape.SetStatic(false);
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	this.shape.SetStatic(false);
	
	return damage;
}