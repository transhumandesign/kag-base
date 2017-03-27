string getCharFromKey( const s32 key, const bool shift )
{
	switch( key )
	{
		case KEY_KEY_0: return shift ? ")" : "0";
		case KEY_KEY_1: return shift ? "!" : "1";
		case KEY_KEY_2: return shift ? "@" : "2";
		case KEY_KEY_3: return shift ? "#" : "3";
		case KEY_KEY_4: return shift ? "$" : "4";
		case KEY_KEY_5: return shift ? "%" : "5";
		case KEY_KEY_6: return shift ? "^" : "6";
		case KEY_KEY_7: return shift ? "&" : "7";
		case KEY_KEY_8: return shift ? "*" : "8";
		case KEY_KEY_9: return shift ? "(" : "9";
		case KEY_KEY_A: return shift ? "A" : "a";
		case KEY_KEY_B: return shift ? "B" : "b";
		case KEY_KEY_C: return shift ? "C" : "c";
		case KEY_KEY_D: return shift ? "D" : "d";
		case KEY_KEY_E: return shift ? "E" : "e";
		case KEY_KEY_F: return shift ? "F" : "f";
		case KEY_KEY_G: return shift ? "G" : "g";
		case KEY_KEY_H: return shift ? "H" : "h";
		case KEY_KEY_I: return shift ? "I" : "i";
		case KEY_KEY_J: return shift ? "J" : "j";
		case KEY_KEY_K: return shift ? "K" : "k";
		case KEY_KEY_L: return shift ? "L" : "l";
		case KEY_KEY_M: return shift ? "M" : "m";
		case KEY_KEY_N: return shift ? "N" : "n";
		case KEY_KEY_O: return shift ? "O" : "o";
		case KEY_KEY_P: return shift ? "P" : "p";
		case KEY_KEY_Q: return shift ? "Q" : "q";
		case KEY_KEY_R: return shift ? "R" : "r";
		case KEY_KEY_S: return shift ? "S" : "s";
		case KEY_KEY_T: return shift ? "T" : "t";
		case KEY_KEY_U: return shift ? "U" : "u";
		case KEY_KEY_V: return shift ? "V" : "v";
		case KEY_KEY_W: return shift ? "W" : "w";
		case KEY_KEY_X: return shift ? "X" : "x";
		case KEY_KEY_Y: return shift ? "Y" : "y";
		case KEY_KEY_Z: return shift ? "Z" : "z";

		case KEY_SPACE: return shift ? " " : " ";
		case KEY_NUMPAD0: return shift ? "0" : "0";
		case KEY_NUMPAD1: return shift ? "1" : "1";
		case KEY_NUMPAD2: return shift ? "2" : "2";
		case KEY_NUMPAD3: return shift ? "3" : "3";
		case KEY_NUMPAD4: return shift ? "4" : "4";
		case KEY_NUMPAD5: return shift ? "5" : "5";
		case KEY_NUMPAD6: return shift ? "6" : "6";
		case KEY_NUMPAD7: return shift ? "7" : "7";
		case KEY_NUMPAD8: return shift ? "8" : "8";
		case KEY_NUMPAD9: return shift ? "9" : "9";
		case KEY_PLUS: return shift ? "+" : "=";
		case KEY_COMMA: return shift ? "," : "<";
		case KEY_MINUS: return shift ? "_" : "-";
		case KEY_PERIOD: return shift ? "." : ">";
		case KEY_MULTIPLY: return shift ? "*" : "*";
		case KEY_ADD: return shift ? "+" : "+";
		case KEY_SEPARATOR: return shift ? "\\" : "|";
		case KEY_SUBTRACT: return shift ? "-" : "-";
		case KEY_DECIMAL: return shift ? "." : ".";
		case KEY_DIVIDE: return shift ? "/" : "/";

		case 192: return shift ? "~" : "`";
		case 219: return shift ? "{" : "[";
		case 221: return shift ? "}" : "]";
		case 220: return shift ? "|" : "\\";
		case 186: return shift ? ":" : ";";
		case 222: return shift ? "\"" : "'";
		case 191: return shift ? "?" : "/";
		case 46: return shift ? "." : ".";

		case KEY_TAB: return shift ? "    " : "    ";
	}
    return "";
}