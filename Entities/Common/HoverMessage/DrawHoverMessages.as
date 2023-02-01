// thanks to Splittingred

#define CLIENT_ONLY

#include "HoverMessage.as"

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	if (this.getBlob().isMyPlayer())
	{
		HoverMessages@ messages = @get_messages();
		messages.garbage_collect();
		messages.render();
	}
}

class InventoryItemCache
{
	string blob_name;
	string name;
	int quantity;

	InventoryItemCache(
		const string&in p_blob_name,
		const string&in p_name,
		int p_quantity
	)
	{
		blob_name = p_blob_name;
		name = p_name;
		quantity = p_quantity;
	}
};

const string[] ignored_material_losses = {
	// Arrows. Intentionally left special arrows missing.
	"mat_arrows",

	"mat_bombs",
	"mat_waterbombs",
};

void updateCoinMessage(CPlayer@ player)
{
	string username = player.getUsername();

	const string prop_name = "old coin count " + username;

	CRules@ rules = getRules();

	if (rules.exists(prop_name))
	{
		const int quantity_diff = player.getCoins() - rules.get_u32(prop_name);

		if (Maths::Abs(quantity_diff) > 0)
		{
			add_message(MaterialMessage("Coins", quantity_diff));
		}
	}

	rules.set_u32(prop_name, player.getCoins());
}

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 5;
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
	for (uint i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ invitem = inv.getItem(i);
		inv_and_hands.push_back(invitem);
	}

	//gather their names and amounts
	InventoryItemCache[] current_caches;
	for (uint i = 0; i < inv_and_hands.length; i++)
	{
		CBlob@ b = inv_and_hands[i];
		string name = b.getInventoryName();
		string blob_name = b.getName();
		int quantity = b.getQuantity();

		bool found = false;
		for (uint j = 0; j < current_caches.length; j++)
		{
			if (current_caches[j].blob_name == blob_name)
			{
				current_caches[j].quantity += quantity;
				found = true;
				break;
			}
		}

		if (!found)
		{
			current_caches.push_back(InventoryItemCache(blob_name, name, quantity));
		}
	}

	string prop_string = "past inventory cache";

	InventoryItemCache[]@ past_caches;
	if (!this.get(prop_string, @past_caches))
	{
		// Initialize to default
		@past_caches = @InventoryItemCache[]();
	}

	// Insert a dummy cache item for items from the past caches missing in the current caches
	for (uint i = 0; i < past_caches.length; ++i)
	{
		bool found = false;
		for (uint j = 0; j < current_caches.length; ++j)
		{
			if (current_caches[j].blob_name == past_caches[i].blob_name)
			{
				found = true;
				break;
			}
		}

		if (!found)
		{
			current_caches.push_back(InventoryItemCache(past_caches[i].blob_name, past_caches[i].name, 0));
		}
	}

	// Find entries we can compare directly
	for (uint i = 0; i < current_caches.length; ++i)
	for (uint j = 0; j < past_caches.length; ++j)
	{
		if (past_caches[j].blob_name == current_caches[i].blob_name)
		{
			int quantity_diff = current_caches[i].quantity - past_caches[j].quantity;
			bool ignore_loss = ignored_material_losses.find(current_caches[i].blob_name) != -1;
			bool is_ignored_loss = quantity_diff < 0 && ignore_loss;
			bool do_reset_time = !is_ignored_loss;

			if (quantity_diff != 0)
			{
				MaterialMessage@ message = cast<MaterialMessage>(add_message(
					MaterialMessage(current_caches[i].name, quantity_diff),
					do_reset_time
				));

				if (message.quantity_change < 0 && ignore_loss)
				{
					message.force_gc = true;
				}
			}

			break;
		}
	}

	this.set(prop_string, @current_caches);
	
	updateCoinMessage(@player);
}
