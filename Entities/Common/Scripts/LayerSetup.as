class LayerSetup
{
	int index;
	string name;
	string texture;
	Vec2f size;
	int[] frames;

	int teamnum;
	int skinnum;
	Vec2f offset;

	bool defaultvis;

	int frameTime;
	bool loops;

	u8 vars;
	f32 z;

	// cache
	f32 rotationCache;

	LayerSetup() { }
};

const int[] default_layers = {0};
LayerSetup makeLayerSetup(string _name = "MISSING",
                          string _texture = "MISSING",
                          Vec2f _size = Vec2f(),
                          int[] _frames = default_layers,
                          Vec2f _offset = Vec2f(),
                          int _team = 0,
                          int _skin = 0,
                          bool _visible = true,
                          u8 _vars = 0)
{
	LayerSetup setup;

	setup.index = -1;
	setup.name = _name;
	setup.texture = _texture;

	setup.size = _size;
	setup.frames = _frames;

	setup.teamnum = _team;
	setup.skinnum = _skin;

	setup.offset = _offset;

	setup.defaultvis = _visible;

	setup.vars = _vars;

	//TODO
	setup.frameTime = 0;
	setup.loops = false;

	setup.z = 0.1;

	return setup;
}

CSpriteLayer@ addLayerFromSetup(CSprite@ this, LayerSetup@ setup)
{
	CSpriteLayer@ layer = this.addSpriteLayer(setup.name, setup.texture, setup.size.x, setup.size.y, setup.teamnum, setup.skinnum);
	if (layer !is null)
	{
		layer.SetVisible(setup.defaultvis);
		layer.SetOffset(setup.offset);
		layer.SetRelativeZ(setup.z);
		Animation@ anim = layer.addAnimation("default", setup.frameTime, setup.loops);
		anim.AddFrames(setup.frames);

		setup.index = this.getSpriteLayerCount() - 1;
	}
	return layer;
}

CSpriteLayer@ getLayerFromSetup(CSprite@ this, LayerSetup@ setup)
{
	if (setup.index >= 0)
		return this.getSpriteLayer(setup.index);
	else
		return this.getSpriteLayer(setup.name);
}

void addLayersFromSetupArray(CSprite@ this, LayerSetup[]@ setups)
{
	for (uint step = 0; step < setups.length; ++step)
	{
		addLayerFromSetup(this, @setups[step]);
	}
}