// OneClassAvailable.as

#include "StandardRespawnCommand.as";

const string req_class = "required class";

void onInit(CBlob@ this)
{
	this.Tag("change class drop inventory");
	if(!this.exists("class offset"))
		this.set_Vec2f("class offset", Vec2f_zero);

	if(!this.exists("class button radius"))
	{
		CShape@ shape = this.getShape();
		if(shape !is null)
		{
			this.set_u8("class button radius", Maths::Max(this.getRadius(), (shape.getWidth() + shape.getHeight()) / 2));
		}
		else
		{
			this.set_u8("class button radius", 16);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if(!this.exists(req_class))
	{
		return;
	}

	string cfg = this.get_string(req_class);
	if(canChangeClass(this, caller) && caller.getName() != cfg)
	{
		CBitStream params;
		write_classchange(params, caller.getNetworkID(), cfg);

		CButton@ button = caller.CreateGenericButton(
		"$change_class$",                           // icon token
		this.get_Vec2f("class offset"),             // button offset
		this,                                       // button attachment
		SpawnCmd::changeClass,                      // command id
		getTranslatedString("Swap Class"),                               // description
		params);                                    // bit stream

		button.enableRadius = this.get_u8("class button radius");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}