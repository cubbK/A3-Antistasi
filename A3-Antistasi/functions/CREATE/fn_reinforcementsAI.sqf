private ["_airportsX","_reinfPlaces","_airportX","_numberX","_numGarr","_numReal","_sideX","_potentials","_countX","_siteX","_positionX"];
_airportsX = airportsX select {(sidesX getVariable [_x,sideUnknown] != teamPlayer) and (spawner getVariable _x == 2)};
if (count _airportsX == 0) exitWith {};
_reinfPlaces = [];
{
_airportX = _x;
_numberX = 8;
_numGarr = [_airportX] call A3A_fnc_garrisonSize;
_numReal = count (garrison getVariable _airportX);
_sideX = sidesX getVariable [_airportX,sideUnknown];
if (_numReal + 4 <= _numGarr) then
	{
	if (_numReal + 8 <= _numGarr) then
		{
		if (_sideX == Occupants) then {[selectRandom groupsNATOSquad,_sideX,_airportX,0] remoteExec ["A3A_fnc_garrisonUpdate",2]} else {[selectRandom groupsCSATSquad,_sideX,_airportX,0] remoteExec ["A3A_fnc_garrisonUpdate",2]};
		_numberX = 0;
		}
	else
		{
		if (_sideX == Occupants) then {[selectRandom groupsNATOmid,_sideX,_airportX,0] remoteExec ["A3A_fnc_garrisonUpdate",2]} else {[selectRandom groupsCSATmid,_sideX,_airportX,0] remoteExec ["A3A_fnc_garrisonUpdate",2]};
		_numberX = 4;
		};
	};
if ((_numberX >= 4) and (reinfPatrols <= 4)) then
	{
	_potentials = (outposts + seaports - _reinfPlaces - (killZones getVariable [_airportX,[]])) select {sidesX getVariable [_x,sideUnknown] == _sideX};
	if (_potentials isEqualTo []) then
		{
		_potentials = (resourcesX + factories - _reinfPlaces - (killZones getVariable [_airportX,[]])) select {sidesX getVariable [_x,sideUnknown] == _sideX};
		};
	_positionX = getMarkerPos _airportX;
	_potentials = _potentials select {((getMarkerPos _x distance2D _positionX) < distanceForAirAttack) and !(_x in forcedSpawn)};
	if (count _potentials > 0) then
		{
		_countX = 0;
		_siteX = "";
		{
		_numGarr = [_x] call A3A_fnc_garrisonSize;
		_numReal = count (garrison getVariable _x);
		if (_numGarr - _numReal > _countX) then
			{
			_countX = _numGarr - _numReal;
			_siteX = _x;
			};
		} forEach _potentials;
		if (_siteX != "") then
			{
			if ({(getMarkerPos _x distance2d getMarkerPos _siteX < distanceSPWN) and (sidesX getVariable [_x,sideUnknown] != _sideX)} count airportsX == 0) then
				{
				if ({(_x distance2D _positionX < (2*distanceSPWN)) or (_x distance2D (getMarkerPos _siteX) < (2*distanceSPWN))} count allPlayers == 0) then
					{
					_typeGroup = if (_sideX == Occupants) then {if (_numberX == 4) then {selectRandom groupsNATOmid} else {selectRandom groupsNATOSquad}} else {if (_numberX == 4) then {selectRandom groupsCSATmid} else {selectRandom groupsCSATSquad}};
					[_typeGroup,_sideX,_siteX,2] remoteExec ["A3A_fnc_garrisonUpdate",2];
					}
				else
					{
					_reinfPlaces pushBack _siteX;
					[[_siteX,_airportX,_numberX,_sideX],"A3A_fnc_patrolReinf"] call A3A_fnc_scheduler;
					};
				};
			};
		};
	};
if (count _reinfPlaces > 3) exitWith {};
} forEach _airportsX;

if ((count _reinfPlaces == 0) and (AAFpatrols <= 3)) then {[] spawn A3A_fnc_AAFroadPatrol};


{
		//Setting the number of recruitable units per ticks per airport
    garrison setVariable [format ["%1_recruit", _x], 12, true];
} forEach airportsX;

{
    //Setting the number of recruitable units per ticks per outpost
		garrison setVariable [format ["%1_recruit", _x], 8, true];
} forEach outposts;

//New reinf system (still reactive, so a bit shitty)
{
  _reinfMarker = if(_x == Occupants) then {reinforceMarkerOccupants} else {reinforceMarkerInvader};
	_canReinf = if(_x == Occupants) then {canReinforceOccupants} else {canReinforceInvader};
  diag_log format ["Side %1, needed %2, possible %3", _x, count _reinfMarker, count _canReinf];
	_counter = 0;
	_reinfMarker sort true;
	{
		_target = (_x select 1);
		_possibleBases = _canReinf select {[_x, _target] call A3A_fnc_shouldReinforce};
		if((count _possibleBases) != 0) then
		{
			_selectedBase = [_possibleBases, _target] call BIS_fnc_nearestPosition;
			//Found base to reinforce, selecting units now
			_units = [_selectedBase, _target] call A3A_fnc_selectReinfUnits;
			//Create convoy with selected units ==> Merge into convoy stuff first

			//For debug is direct placement
			diag_log format ["Reinforce %1 from %2 with %3", _target, _selectedBase, str _units];
			[_target, _units] call A3A_fnc_addGarrison;

			_counter = _counter + 1;
			if(_counter >= count _canReinf) exitWith {};
		};
	} forEach _reinfMarker;
} forEach [Occupants, Invaders];
hint "Reinforce AI done!";

//Replenish airports if possible
{
	[_x] call A3A_fnc_replenishGarrison;
} forEach airportsX;
