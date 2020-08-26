unit untERDMidiCommon;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types;

function Brighten(Color: TColor; Factor: Integer): TColor;
function Darken(Color: TColor; Factor: Integer): TColor;

implementation

const
  MaxFactor = 100;

// Factor 0..MaxFactor
function Brighten(Color: TColor; Factor: Integer): TColor;
begin
  Color := ColorToRGB(Color);
  if 0 < Factor then             // 0 = no changes
  begin
    if Factor > MaxFactor then
      Factor := MaxFactor;
    Result := (          (((255 - ((Color shr 16) and $FF)) * Factor)
div MaxFactor)) shl 8;
    Result := (Result or (((255 - ((Color shr  8) and $FF)) * Factor)
div MaxFactor)) shl 8;
    Result := (Result or (((255 - ( Color         and $FF)) * Factor)
div MaxFactor));
    Result := Color + Result;
  end
  else
    Result := Color;
end;

// Factor 0..MaxFactor
function Darken(Color: TColor; Factor: Integer): TColor;
begin
  Color := ColorToRGB(Color);
  if 0 < Factor then             // 0 = no changes
  begin
    if Factor > MaxFactor then
      Factor := MaxFactor;
    Result := (          ((((Color shr 16) and $FF) * Factor) div
MaxFactor)) shl 8;
    Result := (Result or ((((Color shr  8) and $FF) * Factor) div
MaxFactor)) shl 8;
    Result := (Result or ((( Color         and $FF) * Factor) div
MaxFactor));
    Result := Color - Result;
  end
  else
    Result := Color;
end;

// Factor -MaxFactor..MaxFactor
function ChangeBrightness(Color: TColor; Factor: Integer): TColor;
var
  DstValue: Integer;
begin
  Color := ColorToRGB(Color);
  if Factor <> 0 then             // 0 = no changes
  begin
    if Factor > 0 then
    begin
      DstValue := 255;
    end
    else
    begin
      DstValue := 0;
      Factor := -Factor;
    end;
    if Factor > MaxFactor then
      Factor := MaxFactor;
    Result := (         (((DstValue - ((Color shr 16) and $FF)) *
Factor) div MaxFactor)) shl 8;
    Result := (Result + (((DstValue - ((Color shr  8) and $FF)) *
Factor) div MaxFactor)) shl 8;
    Result := (Result + (((DstValue - ( Color         and $FF)) *
Factor) div MaxFactor));
    Result := Color + Result;
  end
  else
    Result := Color;
end;

// Value: 0..255 RGB value
// CurrentLum: 0..510, current luminance
// NewLum: 0..510, destination luminance
function SetLuminanceToRGBValue(Value, CurrentLum, NewLum: Integer):
Byte;
begin
  if (0 <= Value) and (Value <= 255) and (0 <= CurrentLum) and
     (CurrentLum <= 510) and (0 <= NewLum) and (NewLum <= 510) then
  begin
    case CurrentLum of
      1..255:
        begin
          if NewLum <= 255 then             // lower segment
            Result := (Value * NewLum) div CurrentLum
          else                              // lower -> upper segment
            Result := NewLum - 255 + (Value * (510 - NewLum)) div
CurrentLum;
        end;
      256..509:
        begin
          Value := 255 - Value;
          CurrentLum := 510 - CurrentLum;
          if NewLum <= 255 then             // upper -> lower segment
            Result := NewLum - (Value * NewLum) div CurrentLum
          else                              // upper segment
            Result := 255 - (Value * (510 - NewLum)) div CurrentLum;
        end;
    else      // black or white
      Result := NewLum div 2;
    end;
  end
  else   // wrong value for Value, CurrentLum or NewLum
    Result := Value;
end;

// for fast calculation, you must precalculate CurrentLum
// and convert Color to RGB
function SetLuminanceToRGBValues(Color: TColor; CurrentLum, NewLum:
Integer): TColor;
begin
  Result := SetLuminanceToRGBValue((Color shr 16) and $FF, CurrentLum,
NewLum) shl 8;
  Result := (Result or SetLuminanceToRGBValue((Color shr 8) and $FF,
CurrentLum, NewLum)) shl 8;
  Result := Result or SetLuminanceToRGBValue(Color and $FF, CurrentLum,
NewLum);
end;

// Result 0..510
function RGBToLuminance(Color: TColor): Integer;
var
  R, G, B: Integer;
  Max, Min : Integer;
begin
  Color := ColorToRGB(Color);
  R := Color and $FF;
  Min := R;
  Max := R;
  Color := Color shr 8;
  G := Color and $FF;
  if Min > G then
    Min := G;
  if Max < G then
    Max := G;
  Color := Color shr 8;
  B := Color and $FF;
  if Min > B then
    Min := B;
  if Max < B then
    Max := B;
  Result := Min + Max;
end;

function SetLuminanceToRGB(Color: TColor; NewLum: Integer): TColor;
var
  R, G, B: Integer;
  Max, Min : Integer;
  CurrentLum: Integer;
begin
  Color := ColorToRGB(Color);
  R := Color and $FF;
  Min := R;
  Max := R;
  Color := Color shr 8;
  G := Color and $FF;
  if Min > G then
    Min := G;
  if Max < G then
    Max := G;
  Color := Color shr 8;
  B := Color and $FF;
  if Min > B then
    Min := B;
  if Max < B then
    Max := B;
  CurrentLum := Min + Max;
  Result := SetLuminanceToRGBValue(B, CurrentLum, NewLum) shl 8;
  Result := (Result or SetLuminanceToRGBValue(G, CurrentLum, NewLum))
shl 8;
  Result := Result or SetLuminanceToRGBValue(R, CurrentLum, NewLum);
end;

end.
