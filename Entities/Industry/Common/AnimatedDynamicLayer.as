void onInit(CSprite@ this)
{
	this.SetZ(-50); //background

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename() , this.getFrameWidth(), this.getFrameHeight(), blob.getTeamNum(), blob.getSkinNum());

	if (front !is null)
	{
		blob.Tag("animated front");
		Animation@ anim = front.addAnimation("default", 0, false);
		anim.AddFrame(3);
		anim.AddFrame(4);
		front.SetRelativeZ(1000);
	}
}
