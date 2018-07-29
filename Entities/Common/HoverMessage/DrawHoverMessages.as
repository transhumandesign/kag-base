// thanks to Splittingred

#define CLIENT_ONLY

#include "HoverMessage.as"

void onRender(CSprite@ this)
{
	if (this.getBlob().isMyPlayer())
	{
		get_messages().render();
	}
}

void onTick(CBlob@ this)
{
	if (!this.isMyPlayer()) return;

	CPlayer@ player = this.getPlayer();

	if (player is null) return;

	//this is fairly expensive HOWEVER it's only for our player

	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	//gather applicable blobs
	CBlob@[] inv_and_hands;

	//hands
	{
		CBlob@ carried = this.getCarriedBlob();
		if (carried !is null && carried.hasTag("material"))
		{
			inv_and_hands.push_back(carried);
		}
	}

	//inv
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ invitem = inv.getItem(i);
		inv_and_hands.push_back(invitem);
	}

	//gather their names and amounts
	string[] names;
	int[] amounts;
	for (int i = 0; i < inv_and_hands.length; i++)
	{
		CBlob@ b = inv_and_hands[i];
		string name = b.getInventoryName();
		int amount = b.getQuantity();

		bool found = false;
		for (int j = 0; j < names.length; j++)
		{
			if (names[j] == name)
			{
				amounts[j] += amount;
				found = true;
				break;
			}
		}

		if (!found)
		{
			names.push_back(name);
			amounts.push_back(amount);
		}
	}

	//effectively assert
	if (names.length != amounts.length) return;

	//compare against previous

	const string namescache_propname = "_inv_names_cache";
	// Store this on player so class swaps show material drops as well
	// This has the side effect of keeping the information when you die...
	// which can be good, so you know how many materials you lost when you died.
	if(player.exists(namescache_propname))
	{
		string[] cached_names = player.get_string(namescache_propname).split(";;");
		for(int i = 0; i < cached_names.length; i++)
		{
			bool found = false;
			for (int j = 0; j < names.length; j++)
			{
				if(names[j] == cached_names[i])
				{
					found = true;
					break;
				}
			}
			//found a missing item
			if(!found)
			{
				names.push_back(cached_names[i]);
				amounts.push_back(0);
			}
		}
	}
	player.set_string(namescache_propname, join(names, ";;"));

	for (int i = 0; i < names.length; i++)
	{
		//if any different/missing, hovermessage!
		string name = names[i];
		int amount = amounts[i];

		string prop_string = "_inv_cache" + name;

		int difference = amount;
		if (player.exists(prop_string))
		{
			difference = amount - player.get_s16(prop_string);
		}
		player.set_s16(prop_string, amount);

		if (difference != 0)
		{
			add_message(MaterialMessage(name, difference));
		}
	}
}