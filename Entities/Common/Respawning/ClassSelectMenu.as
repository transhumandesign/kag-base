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
