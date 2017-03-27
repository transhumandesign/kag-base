// #include "UI.as"
// #include "UIButton.as"
// #include "UILabel.as"
// #include "UITextInput.as"

// namespace Auth
// {
//     funcdef void START_FUNCTION( CRules@ );

//     void Login( START_FUNCTION@ funcStart )
//     {
//         auth_remember = true;

//         UI::Clear();
//         UI::SetFont("hud");

//         UI::AddGroup("login", Vec2f(0.4f,0.4), Vec2f(0.6,0.6));
//             UI::Grid( 2, 2 );

//             UI::AddLabel("USERNAME");
//             UI::TextInput::Add( auth_login, Set_USERNAME );

//             UI::AddLabel("PASSWORD");
//             UI::TextInput::Add( auth_remember ? getUserPassword() : "", Set_PASSWORD, true );

//             UI::Transition( Vec2f( -1.0f, 0.0f ) );
//             UI::SetLastSelection(0);

//         UI::AddGroup("login buttons", Vec2f(0.33f,0.66), Vec2f(0.66,0.75));
//             UI::Grid( 1, 2 );

//             UI::AddButton("OK");
//                 UI::SetControlCallback( SelectOK );
//             UI::AddButton("QUIT");
//                 UI::SetControlCallback( SelectQuitGame );

//             UI::Transition( Vec2f( 0.0f, 1.0f ) );
//             UI::SetLastSelection(0);
//     }

//     void Set_USERNAME( const string &in caption ){
//         auth_login = caption;
//         printf("set login " + caption );
//     }

//     void Set_PASSWORD( const string &in caption ){
//         SetUserPassword( caption );
//         printf("set pass " + caption );
//     }

//     void SelectOK( CRules@ this, UI::Group@ group, UI::Control@ control )
//     {
//         // login
//         printf("login");

//         // StartAuthentication
//         //CallbackLoginFail        
//         //CallbackLoginSuccess        
//     }

//     void SelectQuitGame( CRules@ this, UI::Group@ group, UI::Control@ control )
//     {
//         QuitGame();
//         // bye bye
//     }
// }