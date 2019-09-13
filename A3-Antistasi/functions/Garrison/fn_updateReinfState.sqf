params ["_marker"];

/*  Updates the reinf state if the marker, decides whether it can reinforce others and/or needs reinforcement
*   Params:
*     _marker: STRING : The name of the marker
*
*   Returns:
*     Nothing
*/

private ["_ratio", "_side", "_reinfMarker", "_canReinf", "_index"];

_ratio = [_marker] call A3A_fnc_getGarrisonRatio;
_side = sidesX getVariable [_marker, sideUnknown];

_reinfMarker = if(_side == Occupant) then {reinforceMarkerOccupant} else {reinforceMarkerInvader};
_canReinf = if(_side == Occupant) then {canReinforceOccupant} else {canReinforceInvader};

_index = _reinfMarker findIf {(_x select 0) == _marker};
if(_ratio != 1) then
{
  if(_index == -1) then
  {
    //Marker not in _reinfMarker
    _reinfMarker pushBack [_marker, _ratio];
  }
  else
  {
    //Marker in it, replace
    _reinfMarker set [_index, [_marker, _ratio]];
  };
}
else
{
  if(_index != -1) then
  {
    //Delete marker
    _reinfMarker deleteAt _index;
  };
};
//In desperate need of reinforcements, can't send own
if((_marker in airportsX && _ratio <= 0.4) || {_marker in outposts && _ratio <= 0.8}) then
{
  _canReinf = _canReinf - [_marker];
}
else
{
  _canReinf pushBackUnique _marker;
};
