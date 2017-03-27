void onInit(CSprite@ this)
{
	this.SetZ(-50); //background

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename() , 48, 32, blob.getTeamNum(), blob.getSkinNum());

	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		anim.AddFrame(2);
		front.SetRelativeZ(1000);
	}
}
