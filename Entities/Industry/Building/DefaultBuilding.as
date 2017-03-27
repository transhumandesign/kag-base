// A default building init script

const f32 allow_overlap = 2.0f;

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().getConsts().accurateLighting = true;
	this.Tag("building");

	//this.SetLight(true);
	//this.SetLightRadius( 30.0f );
}


void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 10)
	{
		// make window
		Vec2f tilepos = this.getPosition() - Vec2f(0, 4);
		getMap().server_SetTile(tilepos, CMap::tile_empty);

		//check for overlapping buildings
		CBlob@[] buildings;
		if (getBlobsByTag("building", buildings))
		{
			CShape@ myshape = this.getShape();
			if (myshape is null)
				return;

			Vec2f mypos = this.getPosition();
			Vec2f myhalfsize = Vec2f(myshape.getWidth(), myshape.getHeight()) * 0.5f;

			for (uint i = 0; i < buildings.length; ++i)
			{
				CBlob@ _b = buildings[i];
				if (_b is this)
					continue;

				CShape@ theirshape = _b.getShape();
				if (theirshape is null)
					continue;

				Vec2f theirpos = _b.getPosition();
				Vec2f theirhalfsize = Vec2f(theirshape.getWidth(), theirshape.getHeight()) * 0.5f;

				Vec2f dif = Vec2f(Maths::Abs(theirpos.x - mypos.x), Maths::Abs(theirpos.y - mypos.y));
				Vec2f totalsize = theirhalfsize + myhalfsize;

				Vec2f sep = totalsize - dif;
				//aabb check
				if (sep.x > allow_overlap &&
				        sep.y > allow_overlap)
				{
					this.server_Die();
					break;
				}
			}
		}

		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

// SPRITE

//void onInit(CSprite@ this)
//{
//	CBlob@ blob = this.getBlob();
//	CSpriteLayer@ lantern = this.addSpriteLayer( "lantern", "Lantern.png" , 8, 8, blob.getTeamNum(), blob.getSkinNum() );
//
//	if (lantern !is null)
//    {
//		lantern.SetOffset(Vec2f(9,-5));
//
//        Animation@ anim = lantern.addAnimation( "default", 3, true );
//        anim.AddFrame(0);
//        anim.AddFrame(1);
//        anim.AddFrame(2);
//
//        blob.SetLight(true);
//		blob.SetLightRadius( 32.0f );
//    }
//}
