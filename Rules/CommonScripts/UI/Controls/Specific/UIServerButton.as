#include "UI.as"
#include "UICommonUpdates.as"
#include "UIButton.as"
#include "UIDialog.as"
#include "MainButtonRender.as"


namespace UI
{
	namespace ServerButton
	{
		Control@ scroll;

		void Add(APIServer@ s, int i){
			Control@ c = UI::RadioButton::Add( s.serverName, SelectServer, "servers");
			c.vars.set( "i", i );
			c.vars.set( "server", @s );
			if (isOfficial(s.serverIPv4Address, s.serverPort)){
				c.vars.set( "colour", SColor(255, 254, 238, 115) );
				c.vars.set( "colour selected", SColor(255, 254, 254, 209) );
			}
			else if (s.usingMods){
				c.vars.set( "colour", SColor(255, 175, 250, 254) );
				c.vars.set( "colour selected", SColor(255, 209, 229, 254) );
			}
			
			c.proxy.renderFunc = Render;
			c.input = Input;
			c.processMouse = ProcessMouseDoubleClick;
			c.proxy.align.Set(0.05f, 0.5f);
			@scroll = getGroup("Server browser scroll").controls[0][0];
		}

		void ProcessMouseDoubleClick( Proxy@ proxy, u8 state)
		{
			DefaultProcessMouse(proxy, state);

			if (state == MouseEvent::UP) {
				CRules@ rules = getRules();
				uint gameTime = getGameTime();
				uint clickTime = rules.get_u32("doubleclick time");
				if (clickTime + 10 > gameTime) {
					rules.set_u32("doubleclick time", 0);
					PlayServer(null, null);
				} else {
					rules.set_u32("doubleclick time", gameTime);
				}
			}
		}

		void PlayServer( UI::Group@ group, UI::Control@ control )
		{
			UI::Control@ selected;
			if (!getRules().get("radio set servers selection", @selected)) return;

			APIServer@ s;
			selected.vars.get( "server", @s );
			if (s.password) {
				UI::Dialog::Input("Password required:", PlayServerCallback, cl_password);
			} else {
				PlayServerCallback("");
			}
		}

		void PlayServerCallback( const string &in pass )
		{
			if (!pass.isEmpty())
				cl_password = pass;

			UI::Control@ selected;
			if (!getRules().get("radio set servers selection", @selected)) return;

			APIServer@ s;
			selected.vars.get( "server", @s );
			getNet().SafeConnect(s.serverIPv4Address +":"+ s.serverPort);
		}

		void Input( Control@ control, const s32 key, bool &out ok, bool &out cancel )
		{
			scroll.input(scroll, key, ok, cancel);
		}

		void SelectServer( Group@ group, Control@ control ){
			UI::Data@ data = UI::getData();

			APIServer@ s;
			control.vars.get( "server", @s );

			UI::Group@ active = data.activeGroup;
			UI::Group@ info = UI::getGroup(data, "Server browser info");
			@data.activeGroup = info;
			UI::ClearGroup(info);
			UI::ServerInfo::Add(@s);
			UI::Group@ map = UI::getGroup(data, "Server browser map preview");
			@data.activeGroup = map;
			UI::ClearGroup(map);
			UI::MapPreview::Add(@s);
			@data.activeGroup = active;
			s.loadMinimap();
		}

		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;
			UI::Button::Render(proxy);

			APIServer@ s;
			proxy.control.vars.get( "server", @s );

			int frame;

			if (!s.usingMods) {
				frame = 8;
			} else if (s.modsVerified) {
				frame = 28;
			} else {
				frame = 29;
			}
			if (s.serverName.find("[!]") != -1) {
				frame = 30;
			}
			DrawServerIcon(proxy, frame, 0.84);

			if (s.currentPlayers == 0) {
				frame = 8;
			} else if (s.currentPlayers == s.maxPlayers) {
				frame = 12;
			} else if (s.currentPlayers > 20) {
				frame = 11;
			} else if (s.currentPlayers > 8) {
				frame = 10;
			} else {
				frame = 9;
			}
			// } else {
			// 	float ratio = float(s.currentPlayers) / s.maxPlayers;
			// 	if (ratio < 0.33) {
			// 		frame = 9;
			// 	} else if (ratio < 0.66) {
			// 		frame = 10;
			// 	} else {
			// 		frame = 11;
			// 	}
			// }
			DrawServerIcon(proxy, frame, 0.87);

			if (s.ping == -2) {
				frame = 8;
			} else if (s.ping <= 50) {
				frame = 3;
			} else if (s.ping <= 100) {
				frame = 4;
			} else if (s.ping <= 200) {
				frame = 5;
			} else if (s.ping <= 300) {
				frame = 6;
			} else {
				frame = 7;
			}
			DrawServerIcon(proxy, frame, 0.90);

			if (s.gameMode == "CTF" || s.gameMode == "Capture the Flag") {
				frame = 13;
			} else if (s.gameMode == "TTH" || s.gameMode == "Take the Halls") {
				frame = 20;
			} else if (s.gameMode == "Team Deathmatch") {
				frame = 16;
			} else if (s.gameMode == "Challenge" || s.gameMode == "Challenges") {
				frame = 21;
			} else if (s.gameMode == "Sandbox" || s.gameMode == "Roleplay" || s.gameMode == "RP") {
				frame = 15;
			} else if (s.gameMode == "Zombies" || s.gameMode == "Zombie Fortress") {
				frame = 18;
			} else {
				frame = 17;
			}
			DrawServerIcon(proxy, frame, 0.93);

			if (!s.password) {
				frame = 8;
			} else {
				frame = 2;
			}
			DrawServerIcon(proxy, frame, 0.96);
		}

		void DrawServerIcon( Proxy@ proxy, int frame, float x ){
			float scale = getScreenHeight()/720.0/2;
			Vec2f size(16, 16);
			Vec2f iconPos = proxy.ul;
			iconPos += Vec2f( (proxy.lr.x - proxy.ul.x)*x - size.x*scale, (proxy.lr.y - proxy.ul.y)/2 - size.y*scale );
			bool pressed = false;
			if(proxy.control.vars.get("pressed", pressed) && pressed)
				iconPos.y += 1;

			GUI::DrawIcon("server_icons", frame, size, iconPos, scale);
		}

		bool isOfficial(string ip, uint16 port){
			if (ip == "88.198.8.206") // Servers in Germany
			{
				if(port == 10592 ||
					port == 10593 ||
					port == 10594 ||
					port == 10595 ||
					port == 10596 ||
					port == 10600 || 
					port == 10634)
				{
					return true;
				}
			}
		 
			if(ip == "162.221.187.210") // Servers in USA
			{
				if( port == 10609 ||
					port == 10610 ||
					port == 10611 ||
					port == 10612 ||
					port == 10615 ||
					port == 10616 ||
					port == 10617 ||
					port == 10618)
				{
					return true;
				}
			}
		 
			if (ip == "125.63.57.72") // Servers in Australia
			{
				if (port == 10649 ||
					port == 10650 ||
					port == 10651)
				{
					return true;
				}
			}
			return false;
		}
	}

	#include "Favourites.as"

	namespace FavouriteButton
	{
		void Add(APIServer@ s){
			Control@ c = UI::Button::Add( "", Toggle, "Toggle favourite", 1.1);
			c.vars.set( "server", @s );

			c.proxy.renderFunc = Render;
			c.input = UI::ServerButton::Input;
			c.proxy.align.Set(0.5f, 0.5f);
		}

		void Toggle( Group@ group, Control@ control ){
			APIServer@ s;
			control.vars.get( "server", @s );
			toggleFavourite(s);
		}

		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			if (proxy.selected)	{
				GUI::DrawRectangle(proxy.ul, proxy.lr, CONTROL_HOVER_COLOR);
			}

			APIServer@ s;
			proxy.control.vars.get( "server", @s );

			UI::ServerButton::DrawServerIcon(proxy, isFavourite(s) ? 0 : 1, 0.5);
		}
	}
}