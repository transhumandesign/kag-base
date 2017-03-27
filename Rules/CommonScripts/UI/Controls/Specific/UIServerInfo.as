#include "UI.as"
#include "UICommonUpdates.as"


namespace UI
{
	namespace ServerInfo
	{
		Control@ Add(APIServer@ s){
			string caption;
			if (s is null) {
				caption = 
				 "GOLD = official server\n"
				+"BLUE = modded server\n"
				+"WHITE = vanilla server\n"
				+"\n"
				+"           Instant search\n"
				+"\n"
				+"Filter the server list down to those containing one of the following fields: name, description, game mode, IP address, player name (only entire names are matched).\n"
				+"\n"
				+"e.g. entering 'Shadlington' will find any servers that Shadlington is playing on or have 'Shadlington' in the name/description.\n"
				+"\n"
				+"Players (%) slider: Use this to set the min and max percent full you want servers to be.\n"
				+"e.g. set it to 1% min and 99% max to find servers that are not empty and not full, or set it to 50% to 99% to find servers that are 'at least half full'.\n"
				+"\n"
				+"Map Preview can be dragged.";
				// 				caption = 
				//  "GOLD = official server\n"
				// +"BLUE = modded server\n"
				// +"WHITE = vanilla server\n"
				// +"\n"
				// +"           Instant search\n"
				// +"\n"
				// +"Filter the server list down to those\n"
				// +"containing one of the following fields:\n"
				// +"name, description, game mode, IP\n"
				// +"address, player name (only entire\n"
				// +"names are matched).\n"
				// +"\n"
				// +"e.g. entering 'Shadlington' will find any\n"
				// +"servers that Shadlington is playing on or\n"
				// +"have 'Shadlington' in the name/description.\n"
				// +"\n"
				// +"Players (%) slider: Use this to set the\n"
				// +"min and max percent full you want\n"
				// +"servers to be.\n"
				// +"e.g. set it to 1% min and 99% max to find\n"
				// +"servers that are not empty and not full,\n"
				// +"or set it to 50% to 99% to find servers\n"
				// +"that are 'at least half full'.\n"
				// +"\n"
				// +"Map Preview can be dragged.";
			}
			Control@ control = AddControl( caption );
			control.selectable = false;
			control.vars.set( "server", @s );
			Data@ data = getData();
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1 );
			return control;
		}

		void Render( Proxy@ proxy ){
			if(proxy.control is null) return;

			APIServer@ s;
			proxy.control.vars.get( "server", @s );

			if (s is null) {
				RenderCaption(@proxy);
				return;
			}
			
			Vec2f dim, pos;
			string text;

			text = s.gameMode;
			GUI::GetTextDimensions( text, dim );
			pos = proxy.ul + Vec2f( Maths::Max((proxy.lr.x - proxy.ul.x - dim.x)/2, 0.0), 0 );
			GUI::DrawText( text, pos, proxy.lr, CAPTION_COLOR, false, false );

			string mapWord, pingWord;
			if (s.mapW > 400) {
				mapWord = "LARGE";
			} else if (s.mapW > 200) {
				mapWord = "MEDIUM";
			} else if (s.mapW > 100) {
				mapWord = "SMALL";
			} else {
				mapWord = "TINY";
			}

			if (s.ping == -2) {
				pingWord = "NOT RESPONDING";
			} else if (s.ping < 200) {
				pingWord = "GREAT";
			} else if (s.ping < 200) {
				pingWord = "OKAY";
			} else if (s.ping < 300) {
				pingWord = "LAGGY";
			} else {
				pingWord = "BAD";
			}

			text = "Players: " + s.currentPlayers + " / " + s.maxPlayers + (s.currentPlayers == s.maxPlayers ? " (FULL)\n" : "\n")
			//+ "Reserved slots: " + s.reservedPlayers + " / " + "kek" + "\n\n"
			+ "Map size: " + s.mapW + "x" + s.mapH +  " (" + mapWord + ")\n\n"
			+ "Ping: " + (s.ping == -2 ? pingWord : s.ping + "ms (" + pingWord + ")");
			GUI::GetTextDimensions( text, dim );
			pos = proxy.ul + Vec2f( 0, (proxy.lr.y - proxy.ul.y)*0.32 );
			GUI::DrawText( text, pos, CAPTION_COLOR );

			text = s.description;
			GUI::GetTextDimensions( text, dim );
			pos = proxy.ul + Vec2f( 0, (proxy.lr.y - proxy.ul.y)*0.5 );
			GUI::DrawText( text, pos, proxy.lr, CAPTION_COLOR, false, false );
		}
	}
}