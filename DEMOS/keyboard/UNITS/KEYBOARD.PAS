unit Keyboard;

{$Mode TP}

interface

function isKeyDown(const scancode: byte): boolean; external 'env' name 'isKeyDown';

implementation

end.