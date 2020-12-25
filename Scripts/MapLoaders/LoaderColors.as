// LoaderColors.as

//////////////////////////////////////
// Alpha channel documentation
//////////////////////////////////////

// The last bit (128) is always true for comp-
// atability with most image editing software
// to ensure a minimum alpha of 128.

// The second to last bit (64) is always false
// so loadMap() can recognize when to branch
// to alpha functionality.

// The first six bits are free to be used for
// the pre-set functionality below or your own
// custom functionality.

// Example of a purple team diode rotated 90°
// purple(3) + right(16) + last bit(128) = 147
// SColor decimal(147, 255, 0, 255);
// SColor hexadecimal(0x93FF00FF);

// | num | team     | binary    | hex  | dec |
// -------------------XX---vvvv---------------
// |   0 | blue     | 0000 0000 | 0x00 |   0 |
// |   1 | red      | 0000 0001 | 0x01 |   1 |
// |   2 | green    | 0000 0010 | 0x02 |   2 |
// |   3 | purple   | 0000 0011 | 0x03 |   3 |
// |   4 | orange   | 0000 0100 | 0x04 |   4 |
// |   5 | teal     | 0000 0101 | 0x05 |   5 |
// |   6 | royal    | 0000 0110 | 0x06 |   6 |
// |   7 | stone    | 0000 0111 | 0x07 |   7 |
// | 255 | neutral  | 0000 1111 | 0x0F |  15 |

// | deg | dir      | binary    | hex  | dec |
// -------------------XXvv--------------------
// |   0 | up       | 0000 0000 | 0x00 |   0 |
// |  90 | right    | 0001 0000 | 0x10 |  16 |
// | 180 | down     | 0010 0000 | 0x20 |  32 |
// | 270 | left     | 0011 0000 | 0x30 |  48 |

// Methods for fetching useable information from
// the alpha channel.

// u8 getTeamFromChannel(u8 channel)
// u8 getChannelFromTeam(u8 team)

// u16 getAngleFromChannel(u8 channel)
// u8 getChannelFromAngle(u16 angle)

namespace map_colors
{
	enum color
	{
		// TILES
		tile_ground            = 0xFF844715, // ARGB(255, 132,  71,  21);
		tile_ground_back       = 0xFF3B1406, // ARGB(255,  59,  20,   6);
		tile_stone             = 0xFF8B6849, // ARGB(255, 139, 104,  73);
		tile_thickstone        = 0xFF42484B, // ARGB(255,  66,  72,  75);
		tile_bedrock           = 0xFF2D342D, // ARGB(255,  45,  52,  45);
		tile_gold              = 0xFFFEA53D, // ARGB(255, 254, 165,  61);
		tile_castle            = 0xFF647160, // ARGB(255, 100, 113,  96);
		tile_castle_back       = 0xFF313412, // ARGB(255,  49,  52,  18);
		tile_castle_moss       = 0xFF648F60, // ARGB(255, 100, 143,  96);
		tile_castle_back_moss  = 0xFF315212, // ARGB(255,  49,  82,  18);
		tile_ladder            = 0xFF2B1509, // ARGB(255,  43,  21,   9);
		tile_ladder_ground     = 0xFF42240B, // ARGB(255,  66,  36,  11);
		tile_ladder_castle     = 0xFF432F11, // ARGB(255,  67,  47,  17);
		tile_ladder_wood       = 0xFF453911, // ARGB(255,  69,  57,  17);
		tile_grass             = 0xFF649B0D, // ARGB(255, 100, 155,  13);
		tile_wood              = 0xFFC48715, // ARGB(255, 196, 135,  21);
		tile_wood_back         = 0xFF552A11, // ARGB(255,  85,  42,  17);
		water_air              = 0xFF2E81A6, // ARGB(255,  46, 129, 166);
		water_backdirt         = 0xFF335566, // ARGB(255,  51,  85, 102);
		tile_sand              = 0xFFECD590, // ARGB(255, 236, 213, 144);

		// OTHER
		sky                    = 0xFFA5BDC8, // ARGB(255, 165, 189, 200);
		unused                 = 0xFFA5BDC8, // ARGB(255, 165, 189, 200);

		// ALPHA MARKERS = THINGS THAT DEPEND ON THE MAP COLOR ALPHA
		alpha_flag             = 0xFFE000E0, // ARGB(255, 224,   0, 224);
		alpha_spawn            = 0xFFE010E0, // ARGB(255, 224,  16, 224);

		// ALPHA BLOCKS
		alpha_ladder           = 0xFFD000D0, // ARGB(255, 208,    0, 208);
		alpha_spikes           = 0xFFD010D0, // ARGB(255, 208,   16, 208);
		alpha_stone_door       = 0xFFD020D0, // ARGB(255, 208,   32, 208);
		alpha_trap_block       = 0xFFD030D0, // ARGB(255, 208,   48, 208);
		alpha_bridge           = 0xFFD0DED0, // ARGB(255, 208,  222, 208);
		alpha_wooden_door      = 0xFFD040D0, // ARGB(255, 208,   64, 208);
		alpha_wooden_platform  = 0xFFD050D0, // ARGB(255, 208,   80, 208);

		// ALPHA NATURAL
		alpha_stalagmite       = 0xFFC000C0, // ARGB(255, 192,   0, 192);

		// ALPHA ITEMS
		alpha_chest            = 0xFFB000B0, // ARGB(255, 176,   0, 176);

		// ALPHA MECHANISMS
		alpha_lever            = 0xFF00FFFF, // ARGB(255,   0, 255, 255);
		alpha_pressure_plate   = 0xFF10FFFF, // ARGB(255,  16, 255, 255);
		alpha_push_button      = 0xFF20FFFF, // ARGB(255,  32, 255, 255);
		alpha_coin_slot        = 0xFF30FFFF, // ARGB(255,  48, 255, 255);
		alpha_sensor           = 0xFF40FFFF, // ARGB(255,  64, 255, 255);

		alpha_diode            = 0xFFFF00FF, // ARGB(255, 255,   0, 255);
		alpha_inverter         = 0xFFFF10FF, // ARGB(255, 255,  16, 255);
		alpha_junction         = 0xFFFF20FF, // ARGB(255, 255,  32, 255);
		alpha_magazine         = 0xFFFF30FF, // ARGB(255, 255,  48, 255);
		alpha_oscillator       = 0xFFFF40FF, // ARGB(255, 255,  64, 255);
		alpha_randomizer       = 0xFFFF50FF, // ARGB(255, 255,  80, 255);
		alpha_resistor         = 0xFFFF60FF, // ARGB(255, 255,  96, 255);
		alpha_toggle           = 0xFFFF70FF, // ARGB(255, 255, 112, 255);
		alpha_transistor       = 0xFFFF80FF, // ARGB(255, 255, 128, 255);
		alpha_wire             = 0xFFFF90FF, // ARGB(255, 255, 144, 255);
		alpha_emitter          = 0xFFFFA0FF, // ARGB(255, 255, 160, 255);
		alpha_receiver         = 0xFFFFB0FF, // ARGB(255, 255, 176, 255);
		alpha_elbow            = 0xFFFFC0FF, // ARGB(255, 255, 192, 255);
		alpha_tee              = 0xFFFFD0FF, // ARGB(255, 255, 208, 255);

		alpha_bolter           = 0xFFFFFF00, // ARGB(255, 255, 255,   0);
		alpha_dispenser        = 0xFFFFFF10, // ARGB(255, 255, 255,  16);
		alpha_lamp             = 0xFFFFFF20, // ARGB(255, 255, 255,  32);
		alpha_obstructor       = 0xFFFFFF30, // ARGB(255, 255, 255,  48);
		alpha_spiker           = 0xFFFFFF40, // ARGB(255, 255, 255,  64);

		// BLOCKS
		ladder                 = 0xFF42240B, // ARGB(255,  66,  36,  11);
		platform_up            = 0xFFFF9239, // ARGB(255, 255, 146,  57);
		platform_right         = 0xFFFF9238, // ARGB(255, 255, 146,  56);
		platform_down          = 0xFFFF9237, // ARGB(255, 255, 146,  55);
		platform_left          = 0xFFFF9236, // ARGB(255, 255, 146,  54);
		wooden_door_h_blue     = 0xFF1A4E83, // ARGB(255,  26,  78, 131);
		wooden_door_v_blue     = 0xFF1A4E82, // ARGB(255,  26,  78, 130);
		wooden_door_h_red      = 0xFF941B1B, // ARGB(255, 148,  27,  27);
		wooden_door_v_red      = 0xFF941B1A, // ARGB(255, 148,  27,  26);
		wooden_door_h_noteam   = 0xFF949494, // ARGB(255, 148, 148, 148);
		wooden_door_v_noteam   = 0xFF949493, // ARGB(255, 148, 148, 147);
		stone_door_h_blue      = 0xFF505AA0, // ARGB(255,  80,  90, 160);
		stone_door_v_blue      = 0xFF505A9F, // ARGB(255,  80,  90, 159);
		stone_door_h_red       = 0xFFA05A50, // ARGB(255, 160,  90,  80);
		stone_door_v_red       = 0xFFA05A4F, // ARGB(255, 160,  90,  79);
		stone_door_h_noteam    = 0xFFA0A0A0, // ARGB(255, 160, 160, 160);
		stone_door_v_noteam    = 0xFFA0A09F, // ARGB(255, 160, 160, 159);
		trapblock_blue         = 0xFF384C8E, // ARGB(255,  56,  76, 142);
		trapblock_red          = 0xFF8E3844, // ARGB(255, 142,  56,  68);
		trapblock_noteam       = 0xFF646464, // ARGB(255, 100, 100, 100);
		bridge_blue            = 0xFF384CDE, // ARGB(255,  56,  76, 222);
		bridge_red             = 0xFFDE3844, // ARGB(255, 222,  56,  68);
		bridge_noteam          = 0xFFDEDEDE, // ARGB(255, 222, 222, 222);
		spikes                 = 0xFFB42A11, // ARGB(255, 180,  42,  17);
		spikes_ground          = 0xFFB46111, // ARGB(255, 180,  97,  17);
		spikes_castle          = 0xFFB42A5E, // ARGB(255, 180,  42,  94);
		spikes_wood            = 0xFFC82A5E, // ARGB(255, 200,  42,  94);

		// BUILDINGS
		knight_shop            = 0xFFFFBEBE, // ARGB(255, 255, 190, 190);
		builder_shop           = 0xFFBEFFBE, // ARGB(255, 190, 255, 190);
		archer_shop            = 0xFFFFFFBE, // ARGB(255, 255, 255, 190);
		boat_shop              = 0xFFC8BEFF, // ARGB(255, 200, 190, 255);
		vehicle_shop           = 0xFFE6E6E6, // ARGB(255, 230, 230, 230);
		quarters               = 0xFFF0BEFF, // ARGB(255, 240, 190, 255);
		storage_noteam         = 0xFFD9FFEF, // ARGB(255, 217, 255, 239);
		barracks_noteam        = 0xFFD9DAFF, // ARGB(255, 217, 218, 255);
		factory_noteam         = 0xFFFFD9ED, // ARGB(255, 255, 217, 237);
		tunnel_blue            = 0xFFDCD9FE, // ARGB(255, 220, 217, 254);
		tunnel_red             = 0xFFF3D9DC, // ARGB(255, 243, 217, 220);
		tunnel_noteam          = 0xFFF3D9FE, // ARGB(255, 243, 217, 254);
		kitchen                = 0xFFFFD9D9, // ARGB(255, 255, 217, 217);
		nursery                = 0xFFD9FFDF, // ARGB(255, 217, 255, 223);
		research               = 0xFFE1E1E1, // ARGB(255, 225, 225, 225);

		// MARKERS
		blue_main_spawn        = 0xFF00FFFF, // ARGB(255,   0, 255, 255);
		red_main_spawn         = 0xFFFF0000, // ARGB(255, 255,   0,   0);
		green_main_spawn       = 0xFF9DCA22, // ARGB(255, 157, 202,  34);
		purple_main_spawn      = 0xFFD379E0, // ARGB(255, 211, 121, 224);
		orange_main_spawn      = 0xFFCD6120, // ARGB(255, 205,  97,  32);
		aqua_main_spawn        = 0xFF2EE5A2, // ARGB(255,  46, 229, 162);
		teal_main_spawn        = 0xFF5F84EC, // ARGB(255,  95, 132, 236);
		gray_main_spawn        = 0xFFC4CFA1, // ARGB(255, 196, 207, 161);
		blue_spawn             = 0xFF00C8C8, // ARGB(255,   0, 200, 200);
		red_spawn              = 0xFFC80000, // ARGB(255, 200,   0,   0);
		green_spawn            = 0xFF649B0D, // ARGB(255, 100, 155,  13);
		purple_spawn           = 0xFF9E3ACC, // ARGB(255, 158,  58, 204);
		orange_spawn           = 0xFF844715, // ARGB(255, 132,  71,  21);
		aqua_spawn             = 0xFF4F9B7F, // ARGB(255,  79, 155, 127);
		teal_spawn             = 0xFF4149F0, // ARGB(255,  65,  73, 240);
		gray_spawn             = 0xFF97A792, // ARGB(255, 151, 167, 146);

		// MISC
		workbench              = 0xFF00FF00, // ARGB(255,   0, 255,   0);
		campfire               = 0xFFFBE28B, // ARGB(255, 251, 226, 139);
		saw                    = 0xFFCAA482, // ARGB(255, 202, 164, 130);

		// FLORA
		tree                   = 0xFF0D6722, // ARGB(255,  13, 103,  34);
		bush                   = 0xFF5B7E18, // ARGB(255,  91, 126,  24);
		grain                  = 0xFFA2B716, // ARGB(255, 162, 183,  22);
		flowers                = 0xFFFF66FF, // ARGB(255, 255, 102, 255);
		log                    = 0xFFA08C28, // ARGB(255, 160, 140,  40);

		// FAUNA
		shark                  = 0xFF2CAFDE, // ARGB(255,  44, 175, 222);
		fish                   = 0xFF79A8A3, // ARGB(255, 121, 168, 163);
		bison                  = 0xFFB75646, // ARGB(255, 183,  86,  70);
		chicken                = 0xFF8D2614, // ARGB(255, 141,  38,  20);

		// ITEMS
		chest                  = 0xFFF0C150, // ARGB(255, 240, 193,  80);
		drill                  = 0xFFD27800, // ARGB(255, 210, 120,   0);
		trampoline             = 0xFFBB3BFD, // ARGB(255, 187,  59, 253);
		lantern                = 0xFFF1E7B1, // ARGB(255, 241, 231,  11);
		crate                  = 0xFF660000, // ARGB(255, 102,   0,   0);
		bucket                 = 0xFFFFDC78, // ARGB(255, 255, 220, 120);
		sponge                 = 0xFFDC00B4, // ARGB(255, 220,   0, 180);
		steak                  = 0xFFDB8867, // ARGB(255, 219, 136, 103);
		burger                 = 0xFFCD8E4B, // ARGB(255, 205, 142,  75);
		heart                  = 0xFFFF2850, // ARGB(255, 255,  40,  80);
		bombs                  = 0xFFFBF157, // ARGB(255, 251, 241,  87);
		waterbombs             = 0xFFD2C878, // ARGB(255, 210, 200, 120);
		arrows                 = 0xFFC8D246, // ARGB(255, 200, 210,  70);
		waterarrows            = 0xFFC8A00A, // ARGB(255, 200, 160,  10);
		firearrows             = 0xFFE6D246, // ARGB(255, 230, 210,  70);
		bombarrows             = 0xFFC8B40A, // ARGB(255, 200, 180,  10);
		bolts                  = 0xFFE6E6AA, // ARGB(255, 230, 230, 170);
		blue_mine              = 0xFF5A64FF, // ARGB(255,  90, 100, 255);
		red_mine               = 0xFFFFA05A, // ARGB(255, 255, 160,  90);
		mine_noteam            = 0xFFD74BFF, // ARGB(255, 215,  75, 255);
		boulder                = 0xFFA19585, // ARGB(255, 161, 149, 133);
		satchel                = 0xFFAA6400, // ARGB(255, 170, 100,   0);
		keg                    = 0xFFDC3C3C, // ARGB(255, 220,  60,  60);

		// VEHICLES
		mountedbow             = 0xFF38E8B8, // ARGB(255,  56, 232, 184);
		catapult               = 0xFF67E5A5, // ARGB(255, 103, 229, 165);
		ballista               = 0xFF64D2A0, // ARGB(255, 100, 210, 160);
		raft                   = 0xFF466E9B, // ARGB(255,  70, 110, 155);
		dinghy                 = 0xFFC99EF6, // ARGB(255, 201, 158, 246);
		longboat               = 0xFF0033FF, // ARGB(255,   0,  51, 255);
		warboat                = 0xFF328CFF, // ARGB(255,  50, 140, 255);
		airship                = 0xFFFFAF00, // ARGB(255, 255, 175,   0);
		bomber                 = 0xFFFFBE00, // ARGB(255, 255, 190,   0);

		// MATERIALS
		gold                   = 0xFFFFF0A0, // ARGB(255, 255, 240, 160);
		stone                  = 0xFFBEBEAF, // ARGB(255, 190, 190, 175);
		wood                   = 0xFFC8BE8C, // ARGB(255, 200, 190, 140);

		// CHARACTERS
		princess               = 0xFFFB87FF, // ARGB(255, 251, 135, 255);
		necromancer            = 0xFF9E3ABB, // ARGB(255, 158,  58, 187);
		necromancer_teleport   = 0xFF621A83, // ARGB(255,  98,  26, 131);
		mook_knight            = 0xFFFF5F19, // ARGB(255, 255,  95,  25);
		mook_archer            = 0xFF19FFB6, // ARGB(255,  25, 255, 182);
		mook_spawner           = 0xFF3E0100, // ARGB(255,  62,   1,   0);
		mook_spawner_10        = 0xFF56062C, // ARGB(255,  86,   6,  44);

		// TUTORIAL
		dummy                  = 0xFFE78C43, // ARGB(255, 231, 140,  67);

		// RED BARRIER
		redbarrier			   = 0xFFE43771
	};
}
