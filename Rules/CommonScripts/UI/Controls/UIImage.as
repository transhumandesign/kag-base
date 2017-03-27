#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	namespace Image
	{
		Control@ Add( string filename )
	    {
	    	Data@ data = getData();
	    	Control@ control = AddControl( filename );
	   		Proxy@ proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1.5f );
	   		control.selectable = false;
	   		proxy.image = filename;
	   		GUI::GetImageDimensions( filename, proxy.imageSize );
	   		return control;
	    }
	}
}