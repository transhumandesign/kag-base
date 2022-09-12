// Bank.as

#include "GenericButtonCommon.as"

const u16 BALANCE_LIMIT = 1000; // must be lower or equal to 32765

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getSprite().SetZ(-50);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 60;
	
	CSpriteLayer@ money = this.getSprite().addSpriteLayer("money dont jiggle", "BankIcons.png", 16, 16);
	if (money !is null)
	{
		{
			money.addAnimation("default", 0, false);
			int[] frames = {0, 1, 2};
			money.animation.AddFrames(frames);
		}
		money.SetOffset(Vec2f(0.0f, 3.0f));
		money.SetRelativeZ(1);
		money.SetVisible(false);
	}
	
	this.addCommandID("transaction");	// create menu
	this.addCommandID("withdraw");		// withdraw cash
	this.addCommandID("deposit");		// deposit cash
	
	int team = this.getTeamNum();
	AddIconToken("$bank_deposit_all$", "BankIcons.png", Vec2f(32, 32), 3, team);
	AddIconToken("$bank_deposit_hundred$", "BankIcons.png", Vec2f(32, 32), 4, team);
	AddIconToken("$bank_deposit_twenty$", "BankIcons.png", Vec2f(32, 32), 5, team);
	AddIconToken("$bank_withdraw_all$", "BankIcons.png", Vec2f(32, 32), 6, team);
	AddIconToken("$bank_withdraw_hundred$", "BankIcons.png", Vec2f(32, 32), 7, team);
	AddIconToken("$bank_withdraw_twenty$", "BankIcons.png", Vec2f(32, 32), 8, team);
	
	this.set_u16("coins in bank", 0);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (caller.getTeamNum() == this.getTeamNum() 
		&& caller.isOverlapping(this))
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CButton@ button = caller.CreateGenericButton(25, Vec2f(0,0), this, this.getCommandID("transaction"), getTranslatedString("Transaction"), params);
		if (button !is null)
		{
			button.SetEnabled(true);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("transaction"))
	{
		const u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
			BuildTransactionMenu(this, callerID);
	}
	else if (cmd == this.getCommandID("deposit"))
	{
		CBlob@ localBlob = getLocalPlayerBlob();	
		if (!localBlob.isOverlapping(this))	
		{
			CGridMenu@ menu = getGridMenuByName("Make a transaction");
			if (menu !is null)
				menu.kill = true;
			return;
		}
	
		CBlob@ caller 		= getBlobByNetworkID(params.read_u16());
		CPlayer@ p 			= caller.getPlayer();
		u16 coins_in_bank 	= this.get_u16("coins in bank");
		u16 coins_on_player	= p.getCoins();
		u16 step 			= params.read_u16();
		u16 amount 			= Maths::Min(coins_on_player, step);
		u16 available		= BALANCE_LIMIT - coins_in_bank;
		amount 				= (available < amount) ? available : amount;

		if (isServer())
		{
			p.server_setCoins(coins_on_player - amount);			// subtract from player
			this.set_u16("coins in bank", coins_in_bank + amount);	// add to bank
			this.Sync("coins in bank", true);
		}

		this.getSprite().PlaySound((amount > 0) ? "/ChaChing.ogg" : "/NoAmmo.ogg");

		updateLayers(this, coins_in_bank + amount);
	}
	else if (cmd == this.getCommandID("withdraw"))
	{
		CBlob@ localBlob = getLocalPlayerBlob();	
		if (!localBlob.isOverlapping(this))	
		{
			CGridMenu@ menu = getGridMenuByName("Make a transaction");
			if (menu !is null)
				menu.kill = true;
			return;
		}
	
		CBlob@ caller 		= getBlobByNetworkID(params.read_u16());
		CPlayer@ p 			= caller.getPlayer();
		u16 coins_in_bank 	= this.get_u16("coins in bank");
		u16 coins_on_player	= p.getCoins();
		u16 step 			= params.read_u16();
		u16 amount 			= Maths::Min(coins_in_bank, step);
		u16 available		= 32765 - coins_on_player;
		amount				= (available < amount) ? available : amount;

		if (isServer())
		{
			p.server_setCoins(coins_on_player + amount);			// add to player
			this.set_u16("coins in bank", coins_in_bank - amount);	// subtract from bank
			this.Sync("coins in bank", true);
		}
		
		this.getSprite().PlaySound((amount > 0) ? "/ChaChing.ogg" : "/NoAmmo.ogg");
	
		updateLayers(this, coins_in_bank - amount);
	}
}

void onDie(CBlob@ this)
{
	if (!isServer())	return;

	u16 coins_in_bank = this.get_u16("coins in bank");

	if (coins_in_bank > 0)
		server_DropCoins(this.getPosition(), coins_in_bank);
}

void updateLayers(CBlob@ this, u16 balance)
{
	CSpriteLayer@ money = this.getSprite().getSpriteLayer("money dont jiggle");
	
	if (money !is null)
	{
		if (balance > 400)
		{
			money.SetFrameIndex(2);
			money.SetVisible(true);
		}
		else if (balance > 100)
		{
			money.SetFrameIndex(1);
			money.SetVisible(true);
		}
		else if (balance > 0)
		{
			money.SetFrameIndex(0);
			money.SetVisible(true);
		}
		else
		{
			money.SetVisible(false);
		}
	}
}

const int BUTTON_SIZE = 2;

const u16[] TRANSACTION_AMOUNTS = {32765, 100, 20};
	
const string[] TRANSACTION_STRINGS =
{
	"$bank_deposit_all$",
	"$bank_deposit_hundred$",
	"$bank_deposit_twenty$",
	"$bank_withdraw_all$",
	"$bank_withdraw_hundred$",
	"$bank_withdraw_twenty$"
};

const string[] TRANSACTION_DESCRIPTIONS =
{
	"Deposit all your coins",
	"Deposit 100 coins",
	"Deposit 20 coins",
	"Withdraw all coins",
	"Withdraw 100 coins",
	"Withdraw 20 coins"
};

void BuildTransactionMenu(CBlob@ this, const u16 callerID)
{
	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), this, Vec2f(3 * BUTTON_SIZE, 2 * BUTTON_SIZE), getTranslatedString("Make a transaction"));
	if (menu !is null)
	{
		for (uint i = 0; i < 6; i++)
		{
			CBitStream params;
			params.write_u16(callerID);
			params.write_u16(TRANSACTION_AMOUNTS[i % 3]);
			
			string s = (i < 3) ? "deposit" : "withdraw";
			
			menu.AddButton(TRANSACTION_STRINGS[i], getTranslatedString(TRANSACTION_DESCRIPTIONS[i]), this.getCommandID(s), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
		
		menu.deleteAfterClick = false;
		this.Tag("show balance");
	}
}

void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	CBlob@ blob = this.getBlob();	
	CGridMenu@ menu = getGridMenuByName("Make a transaction");

	if (localBlob is null || menu is null || localBlob.isKeyPressed(key_inventory) ||
		localBlob.isKeyJustPressed(key_left) || localBlob.isKeyJustPressed(key_right) || localBlob.isKeyJustPressed(key_up) ||
		localBlob.isKeyJustPressed(key_down) || localBlob.isKeyJustPressed(key_action2) || localBlob.isKeyJustPressed(key_action3))
	{
		blob.Untag("show balance");
		getHUD().menuState = 0;
		if (menu !is null)	
			menu.kill = true;
		
		return;
	}
	
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	if (blob.hasTag("show balance"))
	{
		CHUD@ hud = getHUD();
		hud.menuState = 1;
		hud.disableButtonsForATick = true; // no buttons while drawing this

		Vec2f pos 	= getDriver().getScreenCenterPos();
		Vec2f tl 	= Vec2f(pos.x - 150, pos.y - 180);
		Vec2f br	= Vec2f(pos.x + 150, pos.y - 100);
		
		u16 coins_in_bank = blob.get_u16("coins in bank");
		u16 coins_on_hand = getLocalPlayer().getCoins();
		string balance_string = getTranslatedString("Bank Balance:");
		string on_hand_string = getTranslatedString("Coins on Hand:");
		
		GUI::DrawRectangle(tl, br);
		
		GUI::SetFont("menu");
		GUI::DrawText( balance_string, tl + Vec2f(50, 20), SColor(0xffffffff));
		GUI::DrawText( coins_in_bank + "", tl + Vec2f(150 + balance_string.length() * 4, 20), SColor(0xffffffff));
		GUI::DrawText( on_hand_string, tl + Vec2f(50, 40), SColor(0xffffffff));
		GUI::DrawText( coins_on_hand + "", tl + Vec2f(150 + on_hand_string.length() * 4, 40), SColor(0xffffffff));
	}  
}

// test online
// ability to have different accounts
// send money to other player?