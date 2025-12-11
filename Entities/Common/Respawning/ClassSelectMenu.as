//stuff for building respawn menus

//class for getting everything needed for swapping to a class at a building

shared class PlayerClass
{
	string name;
	string iconFilename;
	string iconName;
	string configFilename;
	string description;
};

const f32 CLASS_BUTTON_SIZE = 2;

//adding a class to a blobs list of classes

void addPlayerClass(CBlob@ this, string name, string iconName, string configFilename, string description)
{
	if (!this.exists("playerclasses"))
	{
		PlayerClass[] classes;
		this.set("playerclasses", classes);
	}

	PlayerClass p;
	p.name = name;
	p.iconName = iconName;
	p.configFilename = configFilename;
	p.description = description;
	this.push("playerclasses", p);
}

//helper for building menus of classes

void addClassesToMenu(CBlob@ this, CGridMenu@ menu, u16 callerID)
{
	PlayerClass[]@ classes;

	if (this.get("playerclasses", @classes))
	{
		for (uint i = 0 ; i < classes.length; i++)
		{
			PlayerClass @pclass = classes[i];

			CBitStream params;
			params.write_u8(i);

			CGridButton@ button = menu.AddButton(pclass.iconName, getTranslatedString(pclass.name), this.getCommandID("change class"), Vec2f(CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE), params);
			//button.SetHoverText( pclass.description + "\n" );
		}

		//keybinds
		array<EKEY_CODE> numKeys = { KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0 };
		uint keybindCount = Maths::Min(classes.length(), numKeys.length());

		for (uint i = 0; i < keybindCount; i++)
		{
			CBitStream params;
			params.write_u8(i);
			params.write_bool(true); //used hotkey?

			menu.AddKeyCommand(numKeys[i], this.getCommandID("change class"), params);
		}
	}
}

PlayerClass@ getDefaultClass(CBlob@ this)
{
	PlayerClass[]@ classes;

	if (this.get("playerclasses", @classes))
	{
		return classes[0];
	}
	else
	{
		return null;
	}
}
