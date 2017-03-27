#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	namespace Label
	{
		Control@ Add( string caption, const f32 Z = 1.0f )
		{
			Data@ data = getData();
			Control@ control = AddControl( caption );
			control.selectable = false;
			@control.proxy = AddProxy( data, RenderCaption, NoTransitionUpdate, data.activeGroup, control, Z );
			return control;
		}
	}
}