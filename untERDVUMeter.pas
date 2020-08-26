{
  untERDVUMeter v1.0.0 - a simple VU meter
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDVUMeter;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, Vcl.ExtCtrls, GDIPlus;

type
  TERDVUMeterOrientation = (moVertical, moHorizontal);

  TERDVUMeter = class(TCustomControl)
  private
    { Private declarations }
    FBorder        : TColor;
    FBackground    : TColor;
    FOrientation   : TERDVUMeterOrientation;
    FPeakTimer     : TTimer;

    { VU Colors }
    FGreen  : TColor;
    FOrange : TColor;
    FRed    : TColor;

    { Start Position of VU Colors }
    FOrangeStart : Integer;
    FRedStart    : Integer;

    { Current VU Value }
    FVULeft    : Integer;
    FVURight   : Integer;
    FVUMax     : Integer;
    FPeakLeft  : Integer;
    FPeakRight : Integer;

    { Buffer - Avoid flickering }
    FBuffer       : TBitmap;
    FUpdateRect   : TRect;

    procedure SetBorder(const C: TColor);
    procedure SetBackground(const C: TColor);
    procedure SetOrientation(const O: TERDVUMeterOrientation);

    procedure SetGreen(const C: TColor);
    procedure SetOrange(const C: TColor);
    procedure SetRed(const C: TColor);

    procedure SetOrangeStart(const I: Integer);
    procedure SetRedStart(const I: Integer);

    procedure SetVULeft(const I: Integer);
    procedure SetVURight(const I: Integer);

    procedure SetPeakLeft(const I: Integer);
    procedure SetPeakRight(const I: Integer);
    function GetFallingPeakInterval : Integer;
    procedure SetFallingPeakInterval(const I: Integer);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure SettingsChanged(Sender: TObject);
    procedure OnPeakTimer(Sender: TObject);

    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property VUMax: Integer read FVUMax;
    property PeakLeft: Integer read FPeakLeft write SetPeakLeft;
    property PeakRight: Integer read FPeakRight write SetPeakRight;
  published
    { Published declarations }
    property Border: TColor read FBorder write SetBorder default $00494238;
    property Background: TColor read FBackground write SetBackground default $00554E3E;
    property Orientation: TERDVUMeterOrientation read FOrientation write SetOrientation default moVertical;

    property VUGreen: TColor read FGreen write SetGreen default $0014EB7A;
    property VUOrange: TColor read FOrange write SetOrange default $000080FF;
    property VURed: TColor read FRed write SetRed default $004B0DF2;

    property VUStartOrange: Integer read FOrangeStart write SetOrangeStart default 60;
    property VUStartRed: Integer read FRedStart write SetRedStart default 80;

    property VULeft: Integer read FVULeft write SetVULeft default 0;
    property VURight: Integer read FVURight write SetVURight default 0;

    property FallingPeakInterval: Integer read GetFallingPeakInterval write SetFallingPeakInterval default 50;

    property Align;
    property Anchors;
    property Color;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Touch;
    property Visible;
    property OnClick;
    property OnEnter;
    property OnExit;
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

const
  { Amount of leds on a VU Bar }
  LedHeight = 3;

(******************************************************************************)
(*
(*  ERD VU Meter (TERDVUMeter)
(*
(******************************************************************************)
constructor TERDVUMeter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We dont want the control to accept controls. offcourse we
    like to get click, double click and mouse events. }
  ControlStyle := ControlStyle + [csOpaque{, csAcceptsControls},
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We do want to be able to get focus }
  TabStop := True;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Create falling peak timer }
  FPeakTimer := TTimer.Create(Self);
  FPeakTimer.OnTimer  := OnPeakTimer;
  FPeakTimer.Interval := 50;

  { Width / Height }
  Width  := 56;
  Height := 316;

  { Defaults }
  FBorder      := $00494238;
  Font.Color   := $00494238;
  Font.Name    := 'Segoe UI';
  FBackground  := $00554E3E;
  FOrientation := moVertical;

  FGreen  := $0014EB7A;
  FOrange := $000080FF;
  FRed    := $004B0DF2;

  FOrangeStart := 60;
  FRedStart    := 80;
  FPeakLeft    := 0;
  FPeakRight   := 0;
end;

destructor TERDVUMeter.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  inherited Destroy;
end;

procedure TERDVUMeter.SetBorder(const C: TColor);
begin
  if Border <> C then
  begin
    FBorder := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetOrientation(const O: TERDVUMeterOrientation);
var
  R : Integer;
begin
  if Orientation <> O then
  begin
    FOrientation := O;
    if ((O = moVertical) and (Width > Height)) or ((O = moHorizontal) and (Height > Width)) then
    begin
      R      := Width;
      Width  := Height;
      Height := R;
    end;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetBackground(const C: TColor);
begin
  if Background <> C then
  begin
    FBackground := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetGreen(const C: TColor);
begin
  if VUGreen <> C then
  begin
    FGreen := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetOrange(const C: TColor);
begin
  if VUOrange <> C then
  begin
    FORange := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetRed(const C: TColor);
begin
  if  VURed <> C then
  begin
    FRed := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetOrangeStart(const I: Integer);
begin
  if VUStartOrange <> I then
  begin
    FOrangeStart := I;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetRedStart(const I: Integer);
begin
  if VUStartRed <> I then
  begin
    FRedStart := I;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetVULeft(const I: Integer);
begin
  if VULeft <> I then
  begin
    FVULeft := I;
    if PeakLeft < I then PeakLeft := I;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetVURight(const I: Integer);
begin
  if VURight <> I then
  begin
    FVURight := I;
    if PeakRight < I then PeakRight := I;
    SettingsChanged(Self);
  end;
end;

procedure TERDVUMeter.SetPeakLeft(const I: Integer);
begin
  if PeakLeft <> I then
  begin
    FPeakLeft := I;
    Invalidate;
  end;
end;

procedure TERDVUMeter.SetPeakRight(const I: Integer);
begin
  if PeakRight <> I then
  begin
    FPeakRight := I;
    Invalidate;
  end;
end;

function TERDVUMeter.GetFallingPeakInterval;
begin
  Result := FPeakTimer.Interval;
end;

procedure TERDVUMeter.SetFallingPeakInterval(const I: Integer);
begin
  if FPeakTimer.Interval <> I then
  begin
    if I < 25 then
      FPeakTimer.Interval := 25
    else
      FPeakTimer.Interval := I;
  end;
end;

procedure TERDVUMeter.SettingsChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TERDVUMeter.OnPeakTimer(Sender: TObject);
begin
  if (VULeft < PeakLeft) and (PeakLeft > 0) then PeakLeft := PeakLeft -1;
  if (VURight < PeakRight) and (PeakRight > 0) then PeakRight := PeakRight -1;
end;

procedure TERDVUMeter.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDVUMeter.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDVUMeter.Resize;
begin
  SettingsChanged(Self);
  inherited;
end;

procedure TERDVUMeter.Paint;
var
  WorkRect : TRect;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(ClientRect);
    end;
  end;

  procedure DrawVUBackground(var FGraphics: IGPGraphics; const VURect: TRect);
  var
    Brush : IGPLinearGradientBrush;
    Pen   : IGPPen;
  begin
    Pen := TGPPen.Create(TGPColor.CreateFromColorRef(Border), BorderWidth);
    Pen.Alignment := PenAlignmentInset;
    Brush := TGPLinearGradientBrush.Create(TGPRect.Create(VURect), TGPColor.CreateFromColorRef(Brighten(Background, 10)), TGPColor.CreateFromColorRef(Background), 90);
    FGraphics.FillRectangle(Brush, TGPRect.Create(VURect));
    FGraphics.DrawRectangle(Pen, TGPRect.Create(VURect));
  end;

  procedure DrawParts(var FGraphics: IGPGraphics; const VURect: TRect; const Position: Integer; const Peak: Integer);
  var
    Green1  : TGPColor;
    Green2  : TGPColor;
    Orange1 : TGPColor;
    Orange2 : TGPColor;
    Red1    : TGPColor;
    Red2    : TGPColor;

    GBrush1 : IGPSolidBrush;
    GBrush2 : IGPSolidBrush;
    OBrush1 : IGPSolidBrush;
    OBrush2 : IGPSolidBrush;
    RBrush1 : IGPSolidBrush;
    RBrush2 : IGPSolidBrush;

    I, O, R : Integer;
    LedRect : TRect;
    MaxPos  : Integer;
  begin
    case Orientation of
      moVertical:
      begin
        FVUMax := Round(VURect.Height / LedHeight);
      end;
      moHorizontal:
      begin
        FVUMax := Round(VURect.Width / LedHeight);
      end;
    end;
    { Calculate where the orange and red leds start }
    O := Round((VUMax / 100) * VUStartOrange);
    R := Round((VUMax / 100) * VUStartRed);
    { Calculate where the current position is }
    MaxPos := Round((VUMax / 100) * Position);
    { Create Colors }
    Green1  := TGPColor.CreateFromColorRef(Darken(VUGreen, 50));
    Green2  := TGPColor.CreateFromColorRef(VUGreen);
    Orange1 := TGPColor.CreateFromColorRef(Darken(VUOrange, 50));
    Orange2 := TGPColor.CreateFromColorRef(VUOrange);
    Red1    := TGPColor.CreateFromColorRef(Darken(VURed, 50));
    Red2    := TGPColor.CreateFromColorRef(VURed);
    { Create Brushes }
    GBrush1 := TGPSolidBrush.Create(Green1);
    GBrush2 := TGPSolidBrush.Create(Green2);
    OBrush1 := TGPSolidBrush.Create(Orange1);
    OBrush2 := TGPSolidBrush.Create(Orange2);
    RBrush1 := TGPSolidBrush.Create(Red1);
    RBrush2 := TGPSolidBrush.Create(Red2);
    { Draw Leds }
    for I := 0 to VUMax -1 do
    begin
      case Orientation of
        moVertical   : LedRect := Rect(VURect.Left +1, VURect.Bottom - ((I * LedHeight) + LedHeight), VURect.Right -1, VURect.Bottom - (I * LedHeight));
        moHorizontal : LedRect := Rect(VURect.Left + (I * LedHeight), VURect.Top + 1, VURect.Left + (I * LedHeight) + LedHeight, VURect.Bottom -1);
      end;
      { Red }
      if I >= R then
      begin
        if (MaxPos >= (I +1)) or (Peak = I +1) then
          FGRaphics.FillRectangle(RBrush2, TGPRect.Create(LedRect))
        else
          FGRaphics.FillRectangle(RBrush1, TGPRect.Create(LedRect));
      end else
      { Orange }
      if I >= O then
      begin
        if (MaxPos >= (I +1)) or (Peak = I +1) then
          FGRaphics.FillRectangle(OBrush2, TGPRect.Create(LedRect))
        else
          FGRaphics.FillRectangle(OBrush1, TGPRect.Create(LedRect));
      end else
      { Green }
      begin
        if (MaxPos >= (I +1)) or (Peak = I +1) then
          FGRaphics.FillRectangle(GBrush2, TGPRect.Create(LedRect))
        else
          FGRaphics.FillRectangle(GBrush1, TGPRect.Create(LedRect));
      end;
    end;
  end;

var
  RVULeft, RVURight : TRect;
var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  {  Create Pad Rect }
  WorkRect := ClientRect;
  InflateRect(WorkRect, -2, -2);

  { Set Buffer size }
  FBuffer.SetSize(ClientWidth, ClientHeight);

  { Create GDI+ Graphic }
  FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
  FGraphics.SmoothingMode := SmoothingModeAntiAlias;
  FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

  { Background }
  DrawBackground;

  { Set VU Rects }
  case Orientation of
    moVertical:
    begin
      RVULeft := WorkRect;
      RVULeft.Right := (WorkRect.Width div 2);
      RVURight := WorkRect;
      RVURight.Left := WorkRect.Right - RVULeft.Width;
    end;

    moHorizontal:
    begin
      RVULeft := WorkRect;
      RVULeft.Bottom := (WorkRect.Height div 2);
      RVURight := WorkRect;
      RVURight.Top := WorkRect.Bottom - RVULeft.Bottom;
    end;
  end;

  { Draw VU }
  DrawVUBackground(FGraphics, RVULeft);
  DrawVUBackground(FGraphics, RVURight);
  { Draw Ticks }
  DrawParts(FGraphics, RVULeft, VULeft, PeakLeft);
  DrawParts(FGraphics, RVURight, VURight, PeakRight);

  { Now draw the Buffer to the components surface }
  X := UpdateRect.Left;
  Y := UpdateRect.Top;
  W := UpdateRect.Right - UpdateRect.Left;
  H := UpdateRect.Bottom - UpdateRect.Top;
  if (W <> 0) and (H <> 0) then
    { Only update part - invalidated }
    BitBlt(Canvas.Handle, X, Y, W, H, FBuffer.Canvas.Handle, X,  Y, SRCCOPY)
  else
    { Repaint the whole buffer to the surface }
    BitBlt(Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, X,  Y, SRCCOPY);

  inherited;
end;

procedure TERDVUMeter.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDVUMeter.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        SettingsChanged(Self);
      end;

    { Focus is lost }
    WM_KILLFOCUS:
      begin
        {  }
        SettingsChanged(Self)
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        {  }
        SettingsChanged(Self)
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        SettingsChanged(Self);
      end;

    { Font changed }
    CM_FONTCHANGED:
      begin
        SettingsChanged(Self);
      end;

  end;
end;

end.
