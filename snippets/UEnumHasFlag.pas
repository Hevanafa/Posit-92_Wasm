unit UEnumHasFlag;

interface

function EnumHasFlag(const value, flag: integer): boolean;

implementation

function EnumHasFlag(const value, flag: integer): boolean;
begin
  EnumHasFlag := (value and flag) = flag
end;

end.