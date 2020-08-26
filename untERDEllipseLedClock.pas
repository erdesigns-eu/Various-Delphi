{
  untERDEllipseLedClock v1.0.0 - a led clock like found in radio studio's
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDEllipseLedClock;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, Vcl.ExtCtrls, GDIPlus;

type
  TERDEllipseLedClockTimeEvent = procedure(Sender: TObject; Hours, Minutes, Seconds: Integer) of object;

  TERDEllipseLedClockStyle = (csSimple, csLed);

  TERDEllipseLedClock = class(TGraphicControl)
  private
    { Private declarations }
    FStyle     : TERDEllipseLedClockStyle;
    FOnColor   : TColor;
    FOffColor  : TColor;
    FTickSize  : Integer;
    FPosition  : Integer;

    { Buffer - Avoid flickering }
    FBuffer : TBitmap;
    FRedraw : Boolean;

    { Clock Timer }
    FTime        : TTime;
    FClockTimer  : TTimer;
    FOnTimeEvent : TERDEllipseLedClockTimeEvent;

    procedure SetStyle(const S: TERDEllipseLedClockStyle);
    procedure SetOnColor(const C: TColor);
    procedure SetOffColor(const C: TColor);
    procedure SetTickSize(const I: Integer);
    procedure SetPosition(const I: Integer);

    function GetActive : Boolean;
    procedure SetActive(const B: Boolean);
  protected
    { Protected declarations }
    procedure SetTime(T: TTime);
    procedure OnClockTimer(Sender: TObject);
    procedure Paint; override;
    procedure Resize; override;
    procedure WndProc(var Message: TMessage); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Redraw: Boolean read FRedraw write FRedraw;
  published
    { Published declarations }
    property Active: Boolean read GetActive write SetActive default False;
    property Style: TERDEllipseLedClockStyle read FStyle write SetStyle default csSimple;
    property OnColor: TColor read FOnColor write SetOnColor default $005C86FF;
    property OffColor: TColor read FOffColor write SetOffColor default $00EAA900;
    property TickSize: Integer read FTickSize write SetTickSize default 4;
    property Position: Integer read FPosition write SetPosition default 1;

    property OnTime: TERDEllipseLedClockTimeEvent read FOnTimeEvent write FOnTimeEvent;

    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property OnClick;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

implementation

uses System.Math, untERDMidiCommon;

(******************************************************************************)
(*
(*  ERD Ellipse Led Clock (TERDEllipseLedClock)
(*
(******************************************************************************)
constructor TERDEllipseLedClock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Transparent background }
  ControlStyle := ControlStyle + [csOpaque];

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Defaults }
  FStyle    := csSimple;
  FOnColor  := $00EAA900;
  FOffColor := $008F8A87;
  FTickSize := 4;
  FPosition := 1;

  { Set default width and height }
  Width  := 201;
  Height := 201;

  { Clock Timer }
  FClockTimer := TTimer.Create(Self);
  FClockTimer.OnTimer := OnClockTimer;
  FClockTimer.Enabled := False;

  { Draw for the first time }
  Redraw := True;
end;

destructor TERDEllipseLedClock.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  { Free Clock Timer }
  FClockTimer.Free;

  inherited Destroy;
end;

procedure TERDEllipseLedClock.SetStyle(const S: TERDEllipseLedClockStyle);
begin
  if Style <> S then
  begin
    FStyle := S;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDEllipseLedClock.SetOnColor(const C: TColor);
begin
  if OnColor <> C then
  begin
    FOnColor := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDEllipseLedClock.SetOffColor(const C: TColor);
begin
  if OffColor <> C then
  begin
    FOffColor := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDEllipseLedClock.SetTickSize(const I: Integer);
begin
  if TickSize <> I then
  begin
    FTickSize := I;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDEllipseLedClock.SetPosition(const I: Integer);
begin
  if Position <> I then
  begin
    if (I < 0) then
      FPosition := 0
    else
    if I > 59 then
      FPosition := 59
    else
      FPosition := I;
    Redraw := True;
    Invalidate;
  end;
end;

function TERDEllipseLedClock.GetActive : Boolean;
begin
  Result := FClockTimer.Enabled;
end;

procedure TERDEllipseLedClock.SetActive(const B: Boolean);
begin
  if B then FTime := Now;
  FClockTimer.Enabled := B;
end;

procedure TERDEllipseLedClock.SetTime(T: TTime);
var
  Hours: Word;
  Mins: Word;
  Secs: Word;
  MSecs: Word;
begin
  if FTime <> T then
  begin
    FTime := T;
    DecodeTime(FTime, Hours, Mins, Secs, MSecs);
    if Assigned(FOnTimeEvent) then FOnTimeEvent(Self, Hours, Mins, Secs);
    Position := Secs;
  end;
end;

procedure TERDEllipseLedClock.OnClockTimer(Sender: TObject);
begin
  SetTime(FTime + 1/SecsPerDay);
end;

procedure TERDEllipseLedClock.Paint;
const
  TAU = PI * 2;
var
  WorkRect   : TRect;
  TickOffset : Double;
  TS         : Integer;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(ClipRect);
    end;
  end;

  procedure DrawTick(var FGraphics: IGPGraphics; const Rect: TRect; const TickColor: TColor);
  var
    Brush : IGPSolidBrush;
  begin
    { Create Solid Brush }
    Brush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(TickColor));
    { Draw Tick }
    FGraphics.FillEllipse(Brush, TGPRect.Create(Rect));
  end;

  procedure DrawTickLed(var FGraphics: IGPGraphics; const Rect: TRect; const TickColor: TColor);
  var
    FFromColor      : TGPColor;
    FToColor        : TGPColor;
    FLedBrush       : IGPLinearGradientBrush;
    FLightColor     : TGPColor;
    FLightToColor   : TGPColor;
    FLedLight       : IGPLinearGradientBrush;
    FLightRect      : TRect;
    FLedBorderBrush : IGPSolidBrush;
    LedRect         : TRect;
  begin
    LedRect := Rect;
    FLedBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(TickColor, 50)));
    { Draw background and border }
    FGraphics.FillEllipse(FLedBorderBrush, TGPRect.Create(LedRect));
    InflateRect(LedRect, -1, -1);
    { Create Solid Border Brush }
    FLedBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(TickColor, 20)));
    { Draw background and border }
    FGraphics.FillEllipse(FLedBorderBrush, TGPRect.Create(LedRect));
    InflateRect(LedRect, -1, -1);
    { Create colors for gradient led face }
    FFromColor := TGPColor.CreateFromColorRef(TickColor);
    FToColor   := TGPColor.CreateFromColorRef(Brighten(TickColor, 80));
    FLedBrush  := TGPLinearGradientBrush.Create(TGPRect.Create(Rect), FFromColor, FToColor, 90);
    FGraphics.FillEllipse(FLedBrush, TGPRect.Create(LedRect));
    { Create light overlay on the top of the led face }
    FLightColor    := TGPColor.CreateFromColorRef(Brighten(TickColor, 65));
    FLightColor.Alpha := 125;
    FLightToColor  := TGPColor.CreateFromColorRef(Brighten(TickColor, 20));
    FlightColor.Alpha := 125;
    FLightRect := LedRect;
    InflateRect(FLightRect, -((Ceil(LedRect.Width / 5) * 4) - 4), -1);
    FLightRect.Height := Ceil(LedRect.Height / 4);
    FLedLight  := TGPLinearGradientBrush.Create(TGPRect.Create(Rect), FLightColor, FLightToColor, 90);
    FGraphics.FillEllipse(FLedLight, TGPRect.Create(FLightRect));
  end;

  procedure DrawTicks(var FGraphics: IGPGraphics);
  var
    A          : Double;
    I, X, Y, R : Integer;
    C          : TColor;
  begin
    R := Round(WorkRect.Width / 2);
    for I := 0 to 59 do
    begin
      A := TAU * I / 60;
      X := (R + Ceil(Cos(A - TickOffset) * R) + TickSize);
      Y := (R + Ceil(Sin(A - TickOffset) * R) + TickSize);
      if Position <= I -1 then
        C := OffColor
      else
        C := OnColor;
      case Style of
        csSimple:
        begin
          if (I mod 5 = 0) or (Position >= I) then
            DrawTick(FGraphics, Rect(X - TickSize, Y - TickSize, X + TickSize, Y + TickSize), C)
          else
            DrawTick(FGraphics, Rect(X - TS, Y - TS, X + TS, Y + TS), C);
        end;

        csLed:
        begin
          if (I mod 5 = 0) or (Position >= I ) then
            DrawTickLed(FGraphics, Rect(X - TickSize, Y - TickSize, X + TickSize, Y + TickSize), C)
          else
            DrawTickLed(FGraphics, Rect(X - TS, Y - TS, X + TS, Y + TS), C);
        end;
      end;

    end;
  end;

var
  FGraphics : IGPGraphics;
begin

  { Redraw Buffer}
  if Redraw then
  begin
    Redraw := False;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    WorkRect := ClientRect;
    TS := Round(TickSize / 2);
    InflateRect(WorkRect, -(TickSize +1), -(TickSize +1));

    { Tick Offset }
    TickOffset := PI * 4 / 8;

    { Draw the clock to the buffer }
    DrawBackground;
    DrawTicks(FGraphics);
  end;

  { Draw the whole buffer to the surface }
  BitBlt(Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0,  0, SRCCOPY);

  inherited;
end;

procedure TERDEllipseLedClock.Resize;
begin
  Redraw := True;
  inherited;
end;

procedure TERDEllipseLedClock.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        {  }
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        Redraw := True;
        Invalidate
      end;
  end;
end;

end.
