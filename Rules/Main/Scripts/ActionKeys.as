class entry{
	entry(string _label, E_ACTIONKEYS _ak){ label = _label; ak = _ak; }
	string label;
	E_ACTIONKEYS ak;
};
 
array<entry> actionKeyLabels = {
	entry('Left',		AK_MOVE_LEFT	),
	entry('Right',		AK_MOVE_RIGHT	),
	entry('Up',			AK_MOVE_UP		),
	entry('Down', 		AK_MOVE_DOWN	),
	entry('Action 1',	AK_ACTION1		),
	entry('Action 2',	AK_ACTION2		),
	entry('Action 3',	AK_ACTION3		),
	entry('Inventory',	AK_INVENTORY	),
	entry('Use',		AK_USE			),
	entry('Pick up',	AK_PICKUP		),
	entry('Zoom in',	AK_ZOOMIN		),
	entry('Zoom out',	AK_ZOOMOUT		),
	entry('Emoticons',	AK_BUBBLES		),
	entry('Map',		AK_MAP			),
	entry('Taunts',		AK_TAUNTS		)
};