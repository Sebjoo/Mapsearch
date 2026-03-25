/*
====================================================================
    MAPMARKER SEARCH - CONFIG
====================================================================
*/

// Map Locations (Fetches cities and villages directly from the worldCfg)
MapSearch_UseWorldCFG = true;

// Map Markers (Fetches markers placed in the Eden Editor or via scripts)
MapSearch_UseMapMarkers = true;
MapSearch_IgnoreUserMarkers = true; // Ignores markers drawn on the map by players
MapSearch_IgnoreInvisible = true;   // Ignores markers with an alpha value of 0 (invisible)

// Custom Locations
MapSearch_UseCustomLocations = false;

/*
Custom Locations List ["Location Name", [X, Y, Z]]
*/
MapSearch_CustomLocationsList = [
    ["Athira", [14000, 18900, 0]],
    ["Kavala", [3600, 13000, 0]],
    ["Soilworks Sniffs", [10500, 9000, 0]]
];

/*
====================================================================
    DO NOT EDIT BELOW THIS LINE
====================================================================
*/
if (!hasInterface) exitWith {};

if (isNil "MapSearch_Draw3DEH") then {
    MapSearch_3DTargetPos = nil;
    MapSearch_Draw3DEH = addMissionEventHandler ["Draw3D", {
        if (!isNil "MapSearch_3DTargetPos") then {
            private _dist = player distance MapSearch_3DTargetPos;
            drawIcon3D [
                "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa", 
                [1, 1, 1, 1], 
                MapSearch_3DTargetPos,
                0.6, 
                0.6, 
                0,
                format ["%1m", round _dist], 
                2, 
                0.025, 
                "PuristaSemiBold" 
            ];
        };
    }];
};

MapSearch_fnc_Zoom = {
    params ["_dataString"];
    if (_dataString != "") then {
        playSound "Click"; 
        private _dataArr = parseSimpleArray _dataString; 
        private _pos = _dataArr select 0;
        private _name = _dataArr select 1;

        private _edit = uiNamespace getVariable ["MapSearch_CtrlEdit", controlNull];
        if (!isNull _edit) then { _edit ctrlSetText _name; };

        MapSearch_LastPos = _pos; 
        MapSearch_LastName = _name; 
        private _mapCtrl = (findDisplay 12) displayCtrl 51;
        _mapCtrl ctrlMapAnimAdd [1, 0.05, _pos]; 
        ctrlMapAnimCommit _mapCtrl;

        private _list = uiNamespace getVariable ["MapSearch_CtrlList", controlNull];
        if (!isNull _list) then { _list ctrlShow false; };
    };
};
uiNamespace setVariable ["MapSearch_fnc_Zoom", MapSearch_fnc_Zoom];

MapSearch_StaticLocations = [];

if (MapSearch_UseWorldCFG) then {
    private _locTypes = ["NameCityCapital", "NameCity", "NameVillage", "NameLocal", "NameMarine"];
    private _worldLocs = nearestLocations [[worldSize/2, worldSize/2, 0], _locTypes, worldSize];
    {
        private _name = text _x;
        MapSearch_StaticLocations pushBack [_name, locationPosition _x, toLower _name];
    } forEach _worldLocs;
};

if (MapSearch_UseCustomLocations) then {
    {
        _x params ["_name", "_pos"];
        MapSearch_StaticLocations pushBack [_name, _pos, toLower _name];
    } forEach MapSearch_CustomLocationsList;
};

MapSearch_LastPos = nil;
MapSearch_LastName = nil;

addMissionEventHandler ["Map", {
    params ["_mapIsOpened", "_mapIsForced"];

    if (_mapIsOpened) then {
        [] spawn {
            disableSerialization;
            waitUntil {!isNull (findDisplay 12)};
            private _disp = findDisplay 12;
            private _mapCtrl = _disp displayCtrl 51;

            private _wTotal = 0.485; 
            private _xPos = 0.5 - (_wTotal / 2); 
            private _yPos = safeZoneY + 0.08; 
            private _hElem = 0.04;
            private _pad = 0.005; 

            private _bgOutline = _disp ctrlCreate ["RscText", -1];
            _bgOutline ctrlSetPosition [_xPos - 0.002, _yPos - 0.002, _wTotal + 0.004, _hElem + (_pad * 2) + 0.004];
            _bgOutline ctrlSetBackgroundColor [0, 0, 0, 1]; 
            _bgOutline ctrlCommit 0;

            private _bg = _disp ctrlCreate ["RscText", -1];
            _bg ctrlSetPosition [_xPos, _yPos, _wTotal, _hElem + (_pad * 2)];
            _bg ctrlSetBackgroundColor [0.5, 0.1, 0.1, 0.95]; 
            _bg ctrlCommit 0;

            private _wX = 0.03;
            private _posX1 = _xPos + _pad;
            
            private _btnX = _disp ctrlCreate ["RscActivePicture", -1];
            _btnX ctrlSetPosition [_posX1, _yPos + _pad, _wX, _hElem];
            _btnX ctrlSetText "\A3\ui_f\data\map\markers\military\objective_CA.paa";
            _btnX ctrlSetTooltip "Abort Search / Clear Marker"; 
            _btnX ctrlCommit 0;

            private _wEdit = 0.30;
            private _posEdit = _posX1 + _wX + _pad;

            private _edit = _disp ctrlCreate ["RscEdit", -1];
            _edit ctrlSetPosition [_posEdit, _yPos + _pad, _wEdit, _hElem];
            _edit ctrlSetBackgroundColor [0.05, 0.05, 0.05, 1];
            _edit ctrlSetFontHeight (_hElem * 0.8); 
            _edit ctrlSetText ""; 
            _edit ctrlCommit 0;

            private _wSearch = 0.10;
            private _posSearch = _posEdit + _wEdit + _pad;

            private _btnSearch = _disp ctrlCreate ["RscButton", -1];
            _btnSearch ctrlSetPosition [_posSearch, _yPos + _pad, _wSearch, _hElem];
            _btnSearch ctrlSetText "Search";
            _btnSearch ctrlSetFont "PuristaSemiBold"; 
            _btnSearch ctrlSetFontHeight (_hElem * 0.8); 
            _btnSearch ctrlSetTooltip "Search for destination"; 
            _btnSearch ctrlCommit 0;

            private _wIcon = 0.03;
            private _posIcon = _posSearch + _wSearch + _pad;

            private _btnIcon = _disp ctrlCreate ["RscActivePicture", -1];
            _btnIcon ctrlSetPosition [_posIcon, _yPos + _pad, _wIcon, _hElem];
            _btnIcon ctrlSetText "\A3\ui_f\data\map\markers\military\end_CA.paa";
            _btnIcon ctrlSetTooltip "Set a 3D-Marker to your destination"; 
            _btnIcon ctrlCommit 0;

            private _listBox = _disp ctrlCreate ["RscListBox", -1];
            _listBox ctrlSetPosition [_posEdit, _yPos + _hElem + (_pad * 2) + 0.005, _wEdit, 0];
            _listBox ctrlSetBackgroundColor [0.1, 0.1, 0.1, 0.95];
            _listBox ctrlSetFontHeight (_hElem * 0.8); 
            _listBox ctrlShow false;
            _listBox ctrlCommit 0;

            uiNamespace setVariable ["MapSearch_CtrlEdit", _edit];
            uiNamespace setVariable ["MapSearch_CtrlList", _listBox];

            private _currentLocations = +MapSearch_StaticLocations; 
            
            if (MapSearch_UseMapMarkers) then {
                {
                    private _mText = markerText _x;
                    if (_mText != "") then {
                        private _alpha = markerAlpha _x;
                        private _isUser = (_x select [0,15] == "_USER_DEFINED #");
                        
                        private _add = true;
                        if (MapSearch_IgnoreInvisible && _alpha == 0) then { _add = false; };
                        if (MapSearch_IgnoreUserMarkers && _isUser) then { _add = false; };
                        
                        if (_add) then {
                            _currentLocations pushBack [_mText, markerPos _x, toLower _mText];
                        };
                    };
                } forEach allMapMarkers;
            };
            uiNamespace setVariable ["MapSearch_CurrentLocations", _currentLocations];

            _btnX ctrlAddEventHandler ["ButtonClick", {
                playSound "Click"; 
                private _edit = uiNamespace getVariable ["MapSearch_CtrlEdit", controlNull];
                private _list = uiNamespace getVariable ["MapSearch_CtrlList", controlNull];
                _edit ctrlSetText "";
                _list ctrlShow false;
                MapSearch_LastPos = nil; 
                MapSearch_LastName = nil;
                
                MapSearch_3DTargetPos = nil;
                deleteMarkerLocal "MapSearch_UserMarker"; 
            }];

            _edit ctrlAddEventHandler ["KeyDown", {
                params ["_ctrl", "_key"];
                if (_key == 28 || _key == 156) then {
                    private _list = uiNamespace getVariable ["MapSearch_CtrlList", controlNull];
                    if (ctrlShown _list && {lbSize _list > 0}) then {
                        private _data = _list lbData 0;
                        [_data] call (uiNamespace getVariable "MapSearch_fnc_Zoom");
                    };
                };
            }];

            _edit ctrlAddEventHandler ["KeyUp", {
                params ["_ctrl", "_key"];
                if (_key == 28 || _key == 156) exitWith {}; 

                private _text = toLower (ctrlText _ctrl);
                private _list = uiNamespace getVariable ["MapSearch_CtrlList", controlNull];

                if (_text == "") exitWith { _list ctrlShow false; };

                private _matches = [];
                private _locsToSearch = uiNamespace getVariable ["MapSearch_CurrentLocations", []];
                
                {
                    _x params ["_name", "_pos", "_nameLower"];
                    if (_nameLower find _text >= 0) then {
                        _matches pushBack [player distance2D _pos, _name, _pos];
                    };
                } forEach _locsToSearch;

                _matches sort true; 

                lbClear _list;
                if (count _matches > 0) then {
                    private _limit = 10 min (count _matches); 
                    for "_i" from 0 to (_limit - 1) do {
                        private _match = _matches select _i;
                        _match params ["_dist", "_name", "_pos"];
                        
                        private _idx = _list lbAdd format ["%1 (%2m)", _name, round _dist];
                        _list lbSetData [_idx, str [_pos, _name]]; 
                    };

                    private _h = (_limit * 0.04) + 0.01;
                    private _posL = ctrlPosition _list;
                    _list ctrlSetPosition [_posL select 0, _posL select 1, _posL select 2, _h];
                    _list ctrlCommit 0;
                    _list ctrlShow true;
                } else {
                    _list ctrlShow false;
                };
            }];

            _listBox ctrlAddEventHandler ["LBSelChanged", {
                params ["_control", "_selectedIndex"];
                private _data = _control lbData _selectedIndex;
                [_data] call (uiNamespace getVariable "MapSearch_fnc_Zoom");
            }];

            _btnSearch ctrlAddEventHandler ["ButtonClick", {
                private _list = uiNamespace getVariable ["MapSearch_CtrlList", controlNull];
                if (ctrlShown _list && {lbSize _list > 0}) then {
                    private _data = _list lbData 0;
                    [_data] call (uiNamespace getVariable "MapSearch_fnc_Zoom");
                };
            }];
            
            _btnIcon ctrlAddEventHandler ["ButtonClick", {
                private _list = uiNamespace getVariable ["MapSearch_CtrlList", controlNull];
                
                if (!isNil "MapSearch_LastPos") then {
                    playSound "Click";
                    private _posToMark = MapSearch_LastPos;
                    
                    if (count _posToMark == 2) then { 
                        _posToMark pushBack 1.5; 
                    } else { 
                        _posToMark set [2, 1.5]; 
                    };
                    
                    MapSearch_3DTargetPos = _posToMark;
                    
                    deleteMarkerLocal "MapSearch_UserMarker";
                    private _mkr = createMarkerLocal ["MapSearch_UserMarker", _posToMark];
                    _mkr setMarkerShapeLocal "ICON";
                    _mkr setMarkerTypeLocal "hd_objective"; 
                    _mkr setMarkerColorLocal "ColorRed";
                    _mkr setMarkerTextLocal " Destination";

                    private _locName = missionNamespace getVariable ["MapSearch_LastName", "Unknown Location"]; private _pName = name player; private _pUID = getPlayerUID player; private _tGrid = mapGridPosition _posToMark; private _tPos = _posToMark; private _dist2D = round (player distance2D _posToMark); private _pGrid = mapGridPosition player; private _pPos = getPos player;

                    private _logMessage = format ["%1 (%2) [(Exile Player) set a 3D Mapsearch marker at [%3] %4 %5, which is currently %6m away from his current location %7 %8]", _pName, _pUID, _locName, _tGrid, _tPos, _dist2D, _pGrid, _pPos];
                    
                    ["doLog", [_logMessage]] call ExileClient_system_network_send;
                };
            }];
        };
    };
}];