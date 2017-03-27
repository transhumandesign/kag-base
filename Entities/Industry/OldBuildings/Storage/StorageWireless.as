// Storage

const Vec2f STORAGE_SIZE(20,6);
string LAST_LABEL;

void onInit( CBlob@ this )
{
	this.addCommandID("storage in");
	this.addCommandID("storage out");
	this.addCommandID("shipment");
}
			    
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	bool isServer = getNet().isServer();

	if (cmd == this.getCommandID("storage out"))
	{
		CBlob@ caller = getBlobByNetworkID( params.read_netid() );
		CBlob@ item = getBlobByNetworkID( params.read_netid() );
		if (caller !is null && item !is null )
		{
			if (canAccessStorage( this, caller))
			{											  
				this.server_PutOutInventory( item );
				item.setPosition( caller.getPosition() ); // put in on the player so it transfers even if it doesn't fit in inv
				if (!caller.server_PutInInventory( item ))	{
					caller.server_Pickup( item ); // didnt fit in put in hands
				}
			}
			else
				caller.ClearMenus();
		}
	}
    else if( cmd == this.getCommandID("shipment") )
	{
		CBlob@ localBlob = getLocalPlayerBlob();
		if (localBlob !is null && localBlob.getTeamNum() == this.getTeamNum()) {
			client_AddToChat( "Supplies will drop at your storage." );
		}															  
	}
}

bool canAccessStorage( CBlob@ this, CBlob@ caller )
{
	return ((this.getPosition() - caller.getPosition()).Length() < this.getRadius()*0.9f);
}
		 
void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16( caller.getNetworkID() );	 
	if (canAccessStorage(this, caller)) 
	{
		BuildSharedInventory( this, caller );
	}
}

CGridButton@ addItem( CGridMenu@ menu, CBlob@ caller, CBlob@ item, u8 cmdID )
{
	CBitStream params;
	params.write_netid( caller.getNetworkID() );
	params.write_netid( item !is null ? item.getNetworkID() : 0 );
	return menu.AddItemButton( item, cmdID, params );
}

void BuildSharedInventory( CBlob@ this, CBlob@ caller, CBlob@ justAddedBlob = null )
{
	if (caller !is null && caller.isMyPlayer())
	{
		//caller.ClearMenus();

		CBlob@[] storages;
		getBlobsByTag( "storage", @storages );
		uint count = 0;
		for (uint step = 0; step < storages.length; ++step)
		{
			CBlob@ storage = storages[step];
			if (storage.getTeamNum() == this.getTeamNum())
				count++;			
		}

		CControls@ controls = caller.getControls();
		if (count <= 1) {
			LAST_LABEL = "Storage";
		}
		else {
			LAST_LABEL = "Shared items from " + count + " storages";
		} 

		CGridMenu@ menu = CreateGridMenu( caller.getScreenPos() + Vec2f(0.0f, 180.0f), this, STORAGE_SIZE, LAST_LABEL );
		if (menu !is null) 
		{
			menu.deleteAfterClick = false;

			// add all storages items

			for (uint step = 0; step < storages.length; ++step)
			{
				CBlob@ storage = storages[step];
				if (storage.getTeamNum() == this.getTeamNum())
				{			
					CInventory@ inv = storage.getInventory();
					for (int i = 0; i < inv.getItemsCount(); i++) {
						CBlob@ item = inv.getItem(i);
						addItem( menu, caller, item, this.getCommandID("storage out") );
					}
				}
			}

			if (justAddedBlob !is null) {
				addItem( menu, caller, justAddedBlob, this.getCommandID("storage out") );
			}

			// click anywhere = put item or close t
			// this is done in engine somehow :/

			//CBlob@ carried = caller.getCarriedBlob();
			////( menu, caller, carried, this.getCommandID("storage in") );
		}
	}
}

void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	CBlob@ localBlob = getLocalPlayerBlob();

	CGridMenu@ menu = getGridMenuByName( LAST_LABEL );
	if (menu !is null && canAccessStorage( this, localBlob) ) 	
	{
		BuildSharedInventory( this, localBlob, blob );
	}

	this.getSprite().PlaySound("/StoreSound");
}

void onRemoveFromInventory( CBlob@ this, CBlob@ blob )
{
	CGridMenu@ menu = getGridMenuByName( LAST_LABEL );
	if (menu !is null) 	
	{
		BuildSharedInventory( this, getLocalPlayerBlob() );
	}
}
