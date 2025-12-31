unit Gamepad;

interface

const
  BTN_A = 0;
  BTN_B = 1;
  BTN_X = 2;
  BTN_Y = 3;

  BTN_LB = 4;
  BTN_RB = 5;
  BTN_LT = 6;
  BTN_RT = 7;

  BTN_BACK = 8;
  BTN_START = 9;

  BTN_DPAD_UP = 12;
  BTN_DPAD_DOWN = 13;
  BTN_DPAD_LEFT = 14;
  BTN_DPAD_RIGHT = 15;


function gamepadButton(const button: byte): boolean; external 'env' name 'gamepadButton';
function gamepadAxis(const axis: byte): single; external 'env' name 'gamepadAxis';


implementation

end.
