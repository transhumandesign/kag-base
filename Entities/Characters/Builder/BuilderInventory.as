// Builder logic

#include "BuilderCommon.as";
#include "PlacementCommon.as";
#include "Help.as";
#include "CommonBuilderBlocks.as";
#include "KnockedCommon.as";

namespace Builder
{
	enum Cmd
	{
		nil = 0,
		TOOL_CLEAR = 31,
		PAGE_SELECT = 32,

		make_block = 64,
		make_reserved = 99
	};

	enum Page
	{
		PAGE_ZERO = 0,
		PAGE_ONE,
		PAGE_TWO,
		PAGE_THREE,
		PAGE_COUNT
	};
}

const string[] PAGE_NAME =
{
	"Building",
	"Component",
	"Source",
	"Device"
};

const u8 GRID_SIZE = 48;
const u8 GRID_PADDING = 12;

const Vec2f MENU_SIZE(3, 4);
const u32 SHOW_NO_BUILD_TIME = 90;

const bool QUICK_SWAP_ENABLED = false;

void onInit(CInventory@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (!blob.exists(blocks_property))
	{
		BuildBlock[][] blocks;
		addCommonBuilderBlocks(blocks);
		blob.set(blocks_property, blocks);
	}

	if (!blob.exists(inventory_offset))
	{
		blob.set_Vec2f(inventory_offset, Vec2f(0, 174));
	}

	AddIconToken("$BUILDER_CLEAR$", "BuilderIcons.png", Vec2f(32, 32), 2);

	for(u8 i = 0; i < Builder::PAGE_COUNT; i++)
	{
		AddIconToken("$"+PAGE_NAME[i]+"$", "BuilderPageIcons.png", Vec2f(48, 24), i);
	}

	blob.set_Vec2f("backpack position", Vec2f_zero);

	blob.set_u8("build page", 0);

	blob.set_u8("buildblob", 255);
	blob.set_TileType("buildtile", 0);

	if (QUICK_SWAP_ENABLED)
	{
		blob.set_u8("current block", 255); // 255 for no block
		blob.set_u8("prev block", 255);
	}

	blob.set_u32("cant build time", 0);
	blob.set_u32("show build time", 0);

	this.getCurrentScript().removeIfTag = "dead";
}

void MakeBlocksMenu(CInventory@ this, const Vec2f &in INVENTORY_CE)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	BuildBlock[][]@ blocks;
	blob.get(blocks_property, @blocks);
	if (blocks is null) return;

	const Vec2f MENU_CE = Vec2f(0, MENU_SIZE.y * -GRID_SIZE - GRID_PADDING) + INVENTORY_CE;

	CGridMenu@ menu = CreateGridMenu(MENU_CE, blob, MENU_SIZE, getTranslatedString("Build"));
	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		const u8 PAGE = blob.get_u8("build page");

		for(u8 i = 0; i < blocks[PAGE].length; i++)
		{
			BuildBlock@ b = blocks[PAGE][i];
			if (b is null) continue;
			string block_desc = getTranslatedString(b.description);
			CGridButton@ button = menu.AddButton(b.icon, "\n" + block_desc, Builder::make_block + i);
			if (button is null) continue;

			button.selectOneOnClick = true;

			CBitStream missing;
			if (hasRequirements(this, b.reqs, missing, not b.buildOnGround))
			{
				button.hoverText = block_desc + "\n" + getButtonRequirementsText(b.reqs, false);
			}
			else
			{
				button.hoverText = block_desc + "\n" + getButtonRequirementsText(missing, true);
				button.SetEnabled(false);
			}

			CBlob@ carryBlob = blob.getCarriedBlob();
			if (carryBlob !is null && carryBlob.getName() == b.name)
			{
				button.SetSelected(1);
			}
			else if (b.tile == blob.get_TileType("buildtile") && b.tile != 0)
			{
				button.SetSelected(1);
			}
		}

		const Vec2f TOOL_POS = menu.getUpperLeftPosition() - Vec2f(GRID_PADDING, 0) + Vec2f(-1, 1) * GRID_SIZE / 2;

		CGridMenu@ tool = CreateGridMenu(TOOL_POS, blob, Vec2f(1, 1), "");
		if (tool !is null)
		{
			tool.SetCaptionEnabled(false);

			CBitStream params;
			params.write_u16(blob.getNetworkID());

			CGridButton@ clear = tool.AddButton("$BUILDER_CLEAR$", "", Builder::TOOL_CLEAR, Vec2f(1, 1), params);
			if (clear !is null)
			{
				clear.SetHoverText(getTranslatedString("Stop building\n"));
			}
		}

		// index menu only available in sandbox
		if (getRules().gamemode_name != "Sandbox") return;

		const Vec2f INDEX_POS = Vec2f(menu.getLowerRightPosition().x + GRID_PADDING + GRID_SIZE, menu.getUpperLeftPosition().y + GRID_SIZE * Builder::PAGE_COUNT / 2);

		CGridMenu@ index = CreateGridMenu(INDEX_POS, blob, Vec2f(2, Builder::PAGE_COUNT), "Type");
		if (index !is null)
		{
			index.deleteAfterClick = false;

			CBitStream params;
			params.write_u16(blob.getNetworkID());

			for(u8 i = 0; i < Builder::PAGE_COUNT; i++)
			{
				CGridButton@ button = index.AddButton("$"+PAGE_NAME[i]+"$", PAGE_NAME[i], Builder::PAGE_SELECT + i, Vec2f(2, 1), params);
				if (button is null) continue;

				button.selectOneOnClick = true;

				if (i == PAGE)
				{
					button.SetSelected(1);
				}
			}
		}
	}
}

void onCreateInventoryMenu(CInventory@ this, CBlob@ forBlob, CGridMenu@ menu)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	const Vec2f INVENTORY_CE = this.getInventorySlots() * GRID_SIZE / 2 + menu.getUpperLeftPosition();
	blob.set_Vec2f("backpack position", INVENTORY_CE);

	blob.ClearGridMenusExceptInventory();

	MakeBlocksMenu(this, INVENTORY_CE);
}

void onCommand(CInventory@ this, u8 cmd, CBitStream@ params)
{
	string dbg = "BuilderInventory.as: Unknown command ";

	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (cmd >= Builder::make_block && cmd < Builder::make_reserved)
	{
		const bool isServer = getNet().isServer();

		BuildBlock[][]@ blocks;
		if (!blob.get(blocks_property, @blocks)) return;

		uint i = cmd - Builder::make_block;

		const u8 PAGE = blob.get_u8("build page");
		if (blocks !is null && i >= 0 && i < blocks[PAGE].length)
		{
			BuildBlock@ block = @blocks[PAGE][i];
			bool canBuildBlock = canBuild(blob, @blocks[PAGE], i) && !isKnocked(blob);
			if (!canBuildBlock)
			{
				if (blob.isMyPlayer())
				{
					blob.getSprite().PlaySound("/NoAmmo", 0.5);
				}

				return;
			}

			// put carried in inventory thing first
			if (isServer)
			{
				CBlob@ carryBlob = blob.getCarriedBlob();
				if (carryBlob !is null)
				{
					// check if this isn't what we wanted to create
					if (carryBlob.getName() == block.name)
					{
						return;
					}

					if (carryBlob.hasTag("temp blob"))
					{
						carryBlob.Untag("temp blob");
						carryBlob.server_Die();
					}
					else
					{
						// try put into inventory whatever was in hands
						// creates infinite mats duplicating if used on build block, not great :/
						if (!block.buildOnGround && !blob.server_PutInInventory(carryBlob))
						{
							carryBlob.server_DetachFromAll();
						}
					}
				}
			}

			if (block.tile == 0)
			{
				server_BuildBlob(blob, @blocks[PAGE], i);
			}
			else
			{
				blob.set_TileType("buildtile", block.tile);
			}

			if (blob.isMyPlayer())
			{
				SetHelp(blob, "help self action", "builder", getTranslatedString("$Build$Build/Place  $LMB$"), "", 3);
			}

			if (QUICK_SWAP_ENABLED && blob.get_u8("current block") != i)
			{
				if (block.name == "building")
				{
					u8 temp = blob.get_u8("current block");
					blob.set_u8("current block", blob.get_u8("prev block"));
					blob.set_u8("prev block", temp);
				}
				else
				{
					blob.set_u8("prev block", blob.get_u8("current block"));
					blob.set_u8("current block", i);
				}
			}
		}
	}
	else if (cmd == Builder::TOOL_CLEAR)
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ target = getBlobByNetworkID(id);
		if (target is null) return;

		target.ClearGridMenus();

		ClearCarriedBlock(target);

		if (QUICK_SWAP_ENABLED && blob.get_u8("current block") != 255)
		{
			blob.set_u8("prev block", blob.get_u8("current block"));
			blob.set_u8("current block", 255);
		}
	}
	else if (cmd >= Builder::PAGE_SELECT && cmd < Builder::PAGE_SELECT + Builder::PAGE_COUNT)
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ target = getBlobByNetworkID(id);
		if (target is null) return;

		target.ClearGridMenus();

		if (QUICK_SWAP_ENABLED && blob.get_u8("build page") != cmd - Builder::PAGE_SELECT)
		{
			blob.set_u8("prev block", 255);
			blob.set_u8("current block", 255);
		}

		target.set_u8("build page", cmd - Builder::PAGE_SELECT);

		ClearCarriedBlock(target);

		if (target is getLocalPlayerBlob())
		{
			target.CreateInventoryMenu(target.get_Vec2f("backpack position"));
		}
	}
	else if (cmd == blob.getCommandID("cycle") && QUICK_SWAP_ENABLED)
	{
		if (isServer()) //only send once - server will have lowest ping for this
		{
			if (blob.get_u8("prev block") == 255)
			{
				CBitStream params;
				params.write_u16(blob.getNetworkID());
				blob.SendCommand(Builder::TOOL_CLEAR, params);
			}
			else
			{
				blob.SendCommand(Builder::make_block + blob.get_u8("prev block"));
			}
		}

		if (blob.isMyPlayer())
		{
			Sound::Play("/CycleInventory.ogg");
		}
	}
}

u8[] blockBinds = {
	0, 1, 2, 3, 4, 5, 6, 7, 8
};

void onInit(CBlob@ this)
{
	ConfigFile@ cfg = openBlockBindingsConfig();

	for (uint i = 0; i < 9; i++)
	{
		blockBinds[i] = read_block(cfg, "block_" + (i + 1), blockBinds[i]);
	}

}

void onTick(CBlob@ this)
{
	if (this !is getLocalPlayerBlob())
	{
		return;
	}

	if (this.hasTag("reload blocks"))
	{
		this.Untag("reload blocks");
		onInit(this);
	}

	CControls@ controls = getControls();
	if (controls.ActionKeyPressed(AK_BUILD_MODIFIER))
	{
		for (uint i = 0; i < 9; i++)
		{
			if (controls.isKeyJustPressed(KEY_KEY_1 + i))
			{
				this.SendCommand(Builder::make_block + blockBinds[i]);
			}
		}

	}
}

void onRender(CSprite@ this)
{
	CMap@ map = getMap();

	CBlob@ blob = this.getBlob();
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is blob)
	{
		// no build zone show
		const bool onground = blob.isOnGround();
		const u32 time = blob.get_u32( "cant build time" );
		if (time + SHOW_NO_BUILD_TIME > getGameTime())
		{
			Vec2f space = blob.get_Vec2f( "building space" );
			Vec2f offsetPos = getBuildingOffsetPos(blob, map, space);

			const f32 scalex = getDriver().getResolutionScaleFactor();
			const f32 zoom = getCamera().targetDistance * scalex;
			Vec2f aligned = getDriver().getScreenPosFromWorldPos( offsetPos );

			for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
			{
				for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
				{
					Vec2f temp = ( Vec2f( step_x + 0.5, step_y + 0.5 ) * map.tilesize );
					Vec2f v = offsetPos + temp;
					Vec2f pos = aligned + (temp - Vec2f(0.5f,0.5f)* map.tilesize) * 2 * zoom;
					if (!onground || map.getSectorAtPosition(v , "no build") !is null || map.isTileSolid(v) || blobBlockingBuilding(map, v))
					{
						// draw red
						GUI::DrawIcon( "CrateSlots.png", 5, Vec2f(8,8), pos, zoom );
					}
					else
					{
						// draw white
						GUI::DrawIcon( "CrateSlots.png", 9, Vec2f(8,8), pos, zoom );
					}
				}
			}
		}

		// show cant build
		if (blob.isKeyPressed(key_action1) || blob.get_u32("show build time") + 15 > getGameTime())
		{
			if (blob.isKeyPressed(key_action1))
			{
				blob.set_u32( "show build time", getGameTime());
			}

			Vec2f cam_offset = getCamera().getInterpolationOffset();

			BlockCursor @bc;
			blob.get("blockCursor", @bc);
			if (bc !is null)
			{
				if (bc.blockActive || bc.blobActive)
				{
					Vec2f pos = blob.getPosition();
					Vec2f myPos =  blob.getInterpolatedScreenPos() + Vec2f(0.0f,(pos.y > blob.getAimPos().y) ? -blob.getRadius() : blob.getRadius());
					Vec2f aimPos2D = getDriver().getScreenPosFromWorldPos( blob.getAimPos() + cam_offset );

					if (!bc.hasReqs)
					{
						const string missingText = getButtonRequirementsText( bc.missing, true );
						Vec2f boxpos( myPos.x, myPos.y - 120.0f );
						GUI::DrawText( getTranslatedString("Requires\n") + missingText, Vec2f(boxpos.x - 50, boxpos.y - 15.0f), Vec2f(boxpos.x + 50, boxpos.y + 15.0f), color_black, false, false, true );
					}
					else if (bc.cursorClose)
					{
						if (bc.rayBlocked)
						{
							Vec2f blockedPos2D = getDriver().getScreenPosFromWorldPos(bc.rayBlockedPos + cam_offset);
							GUI::DrawArrow2D( aimPos2D, blockedPos2D, SColor(0xffdd2212) );
						}

						if (!bc.buildableAtPos && !bc.sameTileOnBack) //no build indicator drawing
						{
							CMap@ map = getMap();
							Vec2f middle = blob.getAimPos() + Vec2f(map.tilesize*0.5f, map.tilesize*0.5f);
							CMap::Sector@ sector = map.getSectorAtPosition( middle, "no build");
							if (sector !is null)
							{
								GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(sector.upperleft), getDriver().getScreenPosFromWorldPos(sector.lowerright), SColor(0x65ed1202) );
							}
							else
							{
								CBlob@[] blobsInRadius;
								if (map.getBlobsInRadius( middle, map.tilesize, @blobsInRadius ))
								{
									for (uint i = 0; i < blobsInRadius.length; i++)
									{
										CBlob @b = blobsInRadius[i];
										if (!b.isAttached())
										{
											Vec2f bpos = b.getInterpolatedPosition();
											float w = b.getWidth();
											float h = b.getHeight();

											if (b.getAngleDegrees() % 180 != 0) //swap dimentions
											{
												float t = w;
												w = h;
												h = t;
											}

											GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(bpos + Vec2f(w/-2.0f, h/-2.0f)),
																getDriver().getScreenPosFromWorldPos(bpos + Vec2f(w/2.0f, h/2.0f)),
																SColor(0x65ed1202) );
										}
									}
								}
							}
						}
					}
					else
					{
						const f32 maxDist = getMaxBuildDistance(blob) + 8.0f;
						Vec2f norm = aimPos2D - myPos;
						const f32 dist = norm.Normalize();
						norm *= (maxDist - dist);
						GUI::DrawArrow2D( aimPos2D, aimPos2D + norm, SColor(0xffdd2212) );
					}
				}
			}
		}
	}
}

bool blobBlockingBuilding(CMap@ map, Vec2f v)
{
	CBlob@[] overlapping;
	map.getBlobsAtPosition(v, @overlapping);
	for(uint i = 0; i < overlapping.length; i++)
	{
		CBlob@ o_blob = overlapping[i];
		CShape@ o_shape = o_blob.getShape();
		if (o_blob !is null &&
			o_shape !is null &&
			!o_blob.isAttached() &&
			o_shape.isStatic() &&
			!o_shape.getVars().isladder)
		{
			return true;
		}
	}
	return false;
}
