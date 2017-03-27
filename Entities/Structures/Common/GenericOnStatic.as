// adds removes support on the current tile

void onSetStatic(CBlob@ this, const bool isStatic)
{
	this.getShape().SetTileValue_Legacy(); // sorry

	// ladder should add lightsource

	//CMap@ map = getMap();
	//u32 offset = map.getTileOffset( this.getPosition() );
	//map.SetTileFlags_Legacy( offset );	   // sorry

	//const int support = this.getShape().getConsts().support;
	//int currentSupport = map.getTileSupport( offset );
	//currentSupport += isStatic ? support : -support;
	//currentSupport = Maths::Min( 255, Maths::Max( 0, currentSupport ) );
	//map.SetTileSupport( offset, currentSupport );

	////if (this.hasTag("blocks water"))
	//{
	//	if (isStatic) {
	//		map.RemoveTileFlag( offset, Tile::WATER_PASSES );
	//		map.server_setFloodWaterOffset( offset, false );
	//	}
	//	else {
	//		map.AddTileFlag( offset, Tile::WATER_PASSES );
	//	}
	//}
}
