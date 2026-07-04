type Posit92ClassFactory = <T extends Constructor<Posit92>>(Base: T) => Constructor & T;  // was Constructor<IBigInt> & T

var BMFontMixin: Posit92ClassFactory;
var BigIntMixin: Posit92ClassFactory;
var GamepadMixin: Posit92ClassFactory;
var SoundsMixin: Posit92ClassFactory;
var WebGLMixin: Posit92ClassFactory;
