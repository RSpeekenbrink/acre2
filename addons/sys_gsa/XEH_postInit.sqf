#include "script_component.hpp"

[QGVAR(disconnectGsa), {
    params ["_gsa", "_unit"];

    private _success = false;
    private _radioId = _gsa getVariable [QGVAR(connectedRadio), ""];
    if (_radioId isEqualTo "") exitWith {
        ERROR("Emtpy unique radio ID");
        _success
    };

    private _parentComponentClass = configFile >> "CfgAcreComponents" >> BASE_CLASS_CONFIG(_radioId);
    {
        _x params ["_connector", "_component"];

        private _componentType = getNumber (configFile >> "CfgAcreComponents" >> _component >> "type");
        if (_componentType == ACRE_COMPONENT_ANTENNA) then {

            _success = [_radioId, 0, _component, [], true] call EFUNC(sys_components,attachSimpleComponent);
            if (_success) exitWith {
                _gsa setVariable [QGVAR(connectedRadio), "", true];
                [_radioId, "setState", ["externalAntennaConnected", [false, objNull]]] call EFUNC(sys_data,dataEvent);

                call compile format [QUOTE([ARR_1(GVAR(%1))] call CBA_fnc_removePerFrameHandler;), _radioId];

                if (_unit isKindOf "CAManBase" || {!(crew _unit isEqualTo [])}) then {
                    if (_unit isKindOf "CAManBase") then {
                        [QGVAR(notifyPlayer), [localize LSTRING(disconnected)], _unit] call CBA_fnc_targetEvent;
                    } else {
                        {
                            [QGVAR(notifyPlayer), [localize LSTRING(disconnected)], _unit] call CBA_fnc_targetEvent;
                        } forEach (crew _unit);
                    };
                };
            };
        };
    } forEach (getArray (_parentComponentClass >> "defaultComponents"));
}] call CBA_fnc_addEventHandler;

[QGVAR(connectGsa), {
    params ["_gsa", "_radioId", "_player"];

    private _classname = typeOf _gsa;
    private _componentName = getText (configFile >> "CfgVehicles" >> _classname >> "AcreComponents" >> "componentName");

    // Check if the antenna was connected somewhere else
    private _connectedGsa = [_radioId, "getState", "externalAntennaConnected"] call EFUNC(sys_data,dataEvent);

    // Do nothing if the antenna is already connected
    if (_connectedGsa select 0) exitWith {
        [QGVAR(notifyPlayer), [localize LSTRING(alreadyConnected)], _player] call CBA_fnc_targetEvent;
    };

    // Force attach the ground spike antenna
    [_radioId, 0, _componentName, [], true] call EFUNC(sys_components,attachSimpleComponent);

    _gsa setVariable [QGVAR(connectedRadio), _radioId, true];
    [_radioId, "setState", ["externalAntennaConnected", [true, _gsa]]] call EFUNC(sys_data,dataEvent);

    [QGVAR(notifyPlayer), [localize LSTRING(connected)], _player] call CBA_fnc_targetEvent;

    call compile format [QUOTE(GVAR(%1) = [ARR_3(DFUNC(externalAntennaPFH), 1.0, [ARR_2(_gsa, _radioId)])] call CBA_fnc_addPerFrameHandler;), _radioId];
}] call CBA_fnc_addEventHandler;

[QGVAR(notifyPlayer), {
    params ["_text"];

    [_text, ICON_RADIO_CALL] call EFUNC(sys_core,displayNotification);
}] call CBA_fnc_addEventHandler;