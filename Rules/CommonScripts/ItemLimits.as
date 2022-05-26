// This rules script counts spawned items per team and sets a limit to them after which no more can be spawned in,
// so as to prevent the game lagging from too many spawned items/blobs.

#include "ItemLimitsCommon.as";

dictionary itemLimits;

void onInit(CRules@ this)
{
	resetLimitedItemsList();
	
	CRules@ rules = getRules();
	rules.set("item_limits", itemLimits);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	resetLimitedItemsList();
	print("hi");
	CRules@ rules = getRules();
	rules.set("item_limits", itemLimits);
}

void resetLimitedItemsList()
{
	itemLimits.deleteAll();

	CBlob@[] all;
	getBlobs(@all);
			
	for (uint b = 0; b < all.length(); ++b)
	{
		addLimitedItem(all[b]); // keep re-adding the pre-existing blobs as if they were spawned in consecutively
	}
}

void addLimitedItem(CBlob@ blob)
{
	string item = blob.getName();
	int team = blob.getTeamNum();
	if (team < 0 || team > 7) team = 8;
	
	if(itemLimits.exists(item)) // increase current count of item by 1
	{		
		int[] itemCounts;
		itemLimits.get(item, itemCounts);
		itemCounts[team]++;
		
		if (itemCounts[team] > itemCounts[9] && itemCounts[9] > 0) // current amount exceeds the maximum allowed, or there is no maximum
		{
			// despawn item and its inventory
			CInventory@ inv = blob.getInventory();
			if (inv !is null)
			{
				for (u8 i = 0; i < inv.getItemsCount(); i++)
				{
					inv.getItem(i).server_Die();
				}
			}
			blob.server_Die();

			sendChatWarningLimitedItem(itemCounts[9], item);
		}

		itemLimits.set(item, itemCounts);
	}
	else // add a new entry for this item
	{
		ConfigFile cfg = ConfigFile();
		cfg.loadFile("ItemLimits.cfg");
		s32 maximum = cfg.read_s32(item, 200); // set to specified maximum or if not existant default to 200
	
		int[] itemCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, maximum}; //teams 0-7, counter for items that aren't assigned to a team, and the maximum amount allowed
		itemCounts[team]++;
		itemLimits.set(item, itemCounts);	
	}
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	addLimitedItem(blob);
	
	CRules@ rules = getRules();
	rules.set("item_limits", itemLimits);
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	string item = blob.getName();
	int team = blob.getTeamNum();
	if (team < 0 || team > 7) team = 8;
	
	if(itemLimits.exists(item)) // decrease current count of item by 1
	{		
		int[] itemCounts;
		itemLimits.get(item, itemCounts);
		itemCounts[team]--;
		if (itemCounts[team] < 0) itemCounts[team] = 0;

		itemLimits.set(item, itemCounts);
	}
	
	CRules@ rules = getRules();
	rules.set("item_limits", itemLimits);
}