unit Gamepad;

interface

function gamepadButton(const button: byte): boolean; external 'env' name 'gamepadButton';
function gamepadAxis(const axis: byte): single; external 'env' name 'gamepadAxis';


implementation

end.
