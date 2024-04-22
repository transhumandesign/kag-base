// CommonBuilderBlocks.as

//////////////////////////////////////
// Builder menu documentation
//////////////////////////////////////

// To add a new page;

// 1) initialize a new BuildBlock array,
// example:
// BuildBlock[] my_page;
// blocks.push_back(my_page);

// 2)
// Add a new string to PAGE_NAME in
// BuilderInventory.as
// this will be what you see in the caption
// box below the menu

// 3)
// Extend BuilderPageIcons.png with your new
// page icon, do note, frame index is the same
// as array index

// To add new blocks to a page, push_back
// in the desired order to the desired page
// example:
// BuildBlock b(0, "name", "icon", "description");
// blocks[3].push_back(b);

#include "BuildBlock.as"
#include "Requirements.as"
#include "Costs.as"
#include "TeamIconToken.as"

const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addCommonBuilderBlocks(BuildBlock[][]@ blocks, int team_num = 0, const string&in gamemode_override = "")
{
	InitCosts();
	CRules@ rules = getRules();

	string gamemode = rules.gamemode_name;
	if (gamemode_override != "")
	{
		gamemode = gamemode_override;
	}

	const bool CTF = gamemode == "CTF";
	const bool SCTF = gamemode == "SmallCTF";
	const bool TTH = gamemode == "TTH";
	const bool SBX = gamemode == "Sandbox";

	BuildBlock[] page_0;
	blocks.push_back(page_0);
	{
		BuildBlock b(CMap::tile_castle, "stone_block", "$stone_block$", "Stone Block", "Basic building block.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::stone_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_back, "back_stone_block", "$back_stone_block$", "Back Stone Wall", "Extra support.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::back_stone_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_door", getTeamIcon("stone_door", "1x1StoneDoor.png", team_num, Vec2f(16, 8)), "Stone Door", "Place next to walls.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::stone_door);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood, "wood_block", "$wood_block$", "Wood Block", "Cheap block. Watch out for fire!");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wood_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood_back, "back_wood_block", "$back_wood_block$", "Back Wood Wall", "Cheap extra support.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::back_wood_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_door", getTeamIcon("wooden_door", "1x1WoodDoor.png", team_num, Vec2f(16, 8)), "Wooden Door", "Place next to walls.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wooden_door);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "bridge", getTeamIcon("bridge", "Bridge.png", team_num), "Trap Bridge", "Only your team can stand on it.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::bridge);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "ladder", "$ladder$", "Ladder", "Anyone can climb it.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::ladder);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_platform", "$wooden_platform$", "Wooden Platform", "One way platform.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wooden_platform);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "spikes", "$spikes$", "Spikes", "Place on Stone Block for Retracting Trap.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::spikes);
		blocks[0].push_back(b);
	}

	if (CTF || SCTF)
	{
		BuildBlock b(0, "building", "$building$", "Workshop", "Stand in an open space and tap this button.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", CTFCosts::workshop_wood);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[0].insertAt(9, b);
	}
	else if (TTH)
	{
		{
			BuildBlock b(0, "factory", "$building$", "Factory", "An item-producing factory. Requires a migrant.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", WARCosts::factory_wood);
			b.buildOnGround = true;
			b.size.Set(40, 24);
			blocks[0].insertAt(9, b);
		}
		{
			BuildBlock b(0, "workbench", "$workbench$", "Workbench", "Create different items.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", WARCosts::workbench_wood);
			b.buildOnGround = true;
			b.size.Set(32, 16);
			blocks[0].push_back(b);
		}
	}
	else if (SBX)
	{
		{
			BuildBlock b(0, "building", "$building$", "Workshop", "Stand in an open space and tap this button.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 150);
			b.buildOnGround = true;
			b.size.Set(40, 24);
			blocks[0].insertAt(9, b);
		}	
		{
			BuildBlock b(0, "trap_block", getTeamIcon("trap_block", "TrapBlock.png", team_num), "Trap Block", "Only enemies can pass.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::trap_block);
			blocks[0].push_back(b);
		}

		BuildBlock[] page_1;
		blocks.push_back(page_1);
		{
			BuildBlock b(0, "wire", getTeamIcon("wire", "Wire.png", team_num, Vec2f(16, 16), 3), "Wire", "Carries power to components and devices.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "elbow", getTeamIcon("elbow", "Elbow.png", team_num, Vec2f(16, 16), 3), "Elbow", "Carries power to components and devices.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "tee", getTeamIcon("tee", "Tee.png", team_num, Vec2f(16, 16), 7), "Tee", "Carries power to components and devices.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "junction", getTeamIcon("junction", "Junction.png", team_num, Vec2f(16, 16), 3), "Junction", "Carries power to components and devices.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "display", "$display$", "Display", "Displays the current power level.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "diode", getTeamIcon("diode", "Diode.png", team_num, Vec2f(8, 16), 3), "Diode", "Acts as a one-way wire.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "resistor", getTeamIcon("resistor", "Resistor.png", team_num, Vec2f(8, 16), 3), "Resistor", "Halves power.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "inverter", getTeamIcon("inverter", "Inverter.png", team_num, Vec2f(8, 16), 3), "Inverter", "Always on until signal passes through.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "oscillator", getTeamIcon("oscillator", "Oscillator.png", team_num, Vec2f(8, 16), 7), "Oscillator", "Adds a delay before signal passes through.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "transistor", getTeamIcon("transistor", "Transistor.png", team_num, Vec2f(16, 16), 3), "Transistor", "Signal passes through if both sides have power.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "toggle", getTeamIcon("toggle", "Toggle.png", team_num, Vec2f(8, 16), 3), "Toggle", "Turns on or off when receiving power.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
			blocks[1].push_back(b);
		}
		{
			BuildBlock b(0, "randomizer", getTeamIcon("randomizer", "Randomizer.png", team_num, Vec2f(8, 16), 7), "Randomizer", "Passes signal at a 50% chance.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
			blocks[1].push_back(b);
		}

		BuildBlock[] page_2;
		blocks.push_back(page_2);
		{
			BuildBlock b(0, "lever", getTeamIcon("lever", "Lever.png", team_num, Vec2f(8, 16), 3), "Lever", "Keeps sending power when turned on.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[2].push_back(b);
		}
		{
			BuildBlock b(0, "push_button", "$pushbutton$", "Button", "Sends power for one second when pressed.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
			blocks[2].push_back(b);
		}
		{
			BuildBlock b(0, "coin_slot", "$coin_slot$", "Coin Slot", "Sends power for three seconds when receiving 60 coins.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
			blocks[2].push_back(b);
		}
		{
			BuildBlock b(0, "pressure_plate", "$pressureplate$", "Pressure Plate", "Activates when pushed against.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[2].push_back(b);
		}
		{
			BuildBlock b(0, "sensor", "$sensor$", "Motion Sensor", "Activates when detecting movement.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
			blocks[2].push_back(b);
		}
		{
			BuildBlock b(0, "solar_panel", "$solarpanel$", "Solar Panel", "Sends power depending on light.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[2].push_back(b);
		}

		BuildBlock[] page_3;
		blocks.push_back(page_3);
		{
			BuildBlock b(0, "lamp", getTeamIcon("lamp", "Lamp.png", team_num, Vec2f(16, 16), 3), "Lamp", "Lights up a dark area.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "emitter", getTeamIcon("emitter", "Emitter.png", team_num, Vec2f(16, 16), 3), "Emitter", "Sends signal to Receivers.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "receiver", getTeamIcon("receiver", "Receiver.png", team_num, Vec2f(16, 16), 3), "Receiver", "Receives signal from Emitters.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "magazine", "$magazine$", "Magazine", "Can store an item.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 20);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "bolter", "$bolter$", "Bolter", "Shoots arrow projectiles from adjacent Magazine.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "dispenser", "$dispenser$", "Dispenser", "Drops item from adjacent Magazine.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "obstructor", "$obstructor$", "Obstructor", "Becomes solid when powered.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "spiker", "$spiker$", "Spiker", "Stabs forward when powered.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "bell", getTeamIcon("bell", "Bell.png", team_num, Vec2f(16, 16), 3), "Bell", "Rings when powered.");
			AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
			blocks[3].push_back(b);
		}
		{
			BuildBlock b(0, "flamer", "$flamer$", "Flamer", "Throws flames when powered.");
			AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
			blocks[3].push_back(b);
		}
	}
}

ConfigFile@ openBlockBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/BlockBindings.cfg"))
	{
		// write EmoteBinding.cfg to Cache
		cfg.saveFile("BlockBindings.cfg");

	}

	return cfg;
}

u8 read_block(ConfigFile@ cfg, string name, u8 default_value)
{
	u8 read_val = cfg.read_u8(name, default_value);
	return read_val;
}
