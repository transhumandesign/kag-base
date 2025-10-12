void onInit(CSprite@ this)
{
	this.SetZ(500.0f);

	CSpriteLayer@ layer = this.addSpriteLayer("blood", this.getFilename(), 8, 16);
	if (layer !is null)
	{
		layer.SetFrameIndex(1);
		layer.SetOffset(Vec2f(0,-3));
		layer.SetVisible(false);
	}
}