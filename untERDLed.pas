{
  untERDLed v1.0.0 - a simple led in the style of FL-Studio
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDLed;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDLedState = (lsOff, lsOn, lsGrayed);

  TERDLedToggleEvent = procedure(Sender: TObject; State: TERDLedState) of object;

  TERDLed = class(TCustomControl)
  private
    { Private declarations }
    FBorderWidth : Integer;
    FBorderColor : TColor;
    FLedOnColor  : TColor;
    FLedOffColor : TColor;
    FGrayedColor : TColor;
    FState       : TERDLedState;

    FToggleOnClick : Boolean;

    { Buffer - Avoid flickering }
    FBuffer      : TBitmap;
    FUpdateRect  : TRect;
    FRedraw      : Boolean;

    FOnLedToggle : TERDLedToggleEvent;

    procedure SetBorderWidth(const I: Integer);
    procedure SetBorderColor(const C: TColor);
    procedure SetOnColor(const C: TColor);
    procedure SetOffColor(const C: TColor);
    procedure SetGrayedColor(const C: TColor);
    procedure SetState(const S: TERDLedState);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property NeedsRedrawing: Boolean read FRedraw write FRedraw;
  published
    { Published declarations }
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $008F8A87;
    property LedOnColor: TColor read FLedOnColor write SetOnColor default $005C86FF;
    property LedOffColor: TColor read FLedOffColor write SetOffColor default $008F8A87;
    property LedGrayedColor: TColor read FGrayedColor write SetGrayedColor default $006B6860;
    property State: TERDLedState read FState write SetState default lsOff;

    property ToggleOnClick: Boolean read FToggleOnClick write FToggleOnClick default False;
    property OnLedToggle: TERDLedToggleEvent read FOnLedToggle write FOnLedToggle;

    property Align;
    property Anchors;
    property Color;
    property Constraints;
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

(******************************************************************************)
(*
(*  Led (TLed)
(*
(******************************************************************************)

constructor TERDLed.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We dont want the control to accept controls - but this might
    change in the future so we leave it here commented out. offcourse we
    like to get click, double click and mouse events. }
  ControlStyle := ControlStyle + [csOpaque{, csAcceptsControls},
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We dont want to get focus }
  TabStop := False;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Width / Height }
  Width  := 16;
  Height := 16;

  { Defaults }
  FBorderWidth := 1;
  FState       := lsOff;
  FBorderColor := $008F8A87;
  FLedOnColor  := $005C86FF;
  FLedOffColor := $008F8A87;
  FGrayedColor := $006B6860;

  { Draw for the first time }
  NeedsRedrawing := True;
end;

destructor TERDLed.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  inherited Destroy;
end;

procedure TERDLed.SetBorderWidth(const I: Integer);
begin
  if BorderWidth <> I then
  begin
    if I < 0 then
      FBorderWidth := 0
    else
      FBorderWidth := I;
    NeedsRedrawing := True;
    Invalidate;
  end;
end;

procedure TERDLed.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    NeedsRedrawing := True;
    Invalidate;
  end;
end;

procedure TERDLed.SetOnColor(const C: TColor);
begin
  if LedOnColor <> C then
  begin
    FLedOnColor := C;
    NeedsRedrawing := True;
    Invalidate;
  end;
end;

procedure TERDLed.SetOffColor(const C: TColor);
begin
  if LedOffColor <> C then
  begin
    FLedOffColor := C;
    NeedsRedrawing := True;
    Invalidate;
  end;
end;

procedure TERDLed.SetGrayedColor(const C: TColor);
begin
  if LedGrayedColor <> C then
  begin
    FGrayedColor := C;
    NeedsRedrawing := True;
    Invalidate;
  end;
end;

procedure TERDLed.SetState(const S: TERDLedState);
begin
  if State <> S then
  begin
    FState := S;
    NeedsRedrawing := True;
    Invalidate;
  end;
end;

procedure TERDLed.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDLed.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDLed.Paint;
var
  WorkRect: TRect;
  LedColor: TColor;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(ClipRect);
    end;
  end;

  procedure DrawBorder(var FGraphics: IGPGraphics);
  var
    FBorderBrush: IGPSolidBrush;
  begin
    { Create Solid Border Brush }
    FBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FBorderColor));
    { Draw background and border }
    FGraphics.FillEllipse(FBorderBrush, TGPRect.Create(WorkRect));
  end;

  procedure DrawLedBorder(var FGraphics: IGPGraphics);
  var
    FLedBorderBrush: IGPSolidBrush;
  begin
    InflateRect(WorkRect, -BorderWidth, -BorderWidth);
    { Create Solid Border Brush }
    FLedBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(LedColor, 50)));
    { Draw background and border }
    FGraphics.FillEllipse(FLedBorderBrush, TGPRect.Create(WorkRect));
    InflateRect(WorkRect, -1, -1);
    { Create Solid Border Brush }
    FLedBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(LedColor, 20)));
    { Draw background and border }
    FGraphics.FillEllipse(FLedBorderBrush, TGPRect.Create(WorkRect));
    InflateRect(WorkRect, -1, -1);
  end;

  procedure DrawLed(var FGraphics: IGPGraphics);
  var
    FFromColor    : TGPColor;
    FToColor      : TGPColor;
    FLedBrush     : IGPLinearGradientBrush;
    FLightColor   : TGPColor;
    FLightToColor : TGPColor;
    FLedLight     : IGPLinearGradientBrush;
    FLightRect    : TRect;
  begin
    { Create colors for gradient led face }
    FFromColor := TGPColor.CreateFromColorRef(LedColor);
    FToColor   := TGPColor.CreateFromColorRef(Brighten(LedColor, 80));
    FLedBrush  := TGPLinearGradientBrush.Create(TGPRect.Create(WorkRect), FFromColor, FToColor, 90);
    FGraphics.FillEllipse(FLedBrush, TGPRect.Create(WorkRect));
    { Create light overlay on the top of the led face }
    FLightColor    := TGPColor.CreateFromColorRef(Brighten(LedColor, 65));
    FLightColor.Alpha := 125;
    FLightToColor  := TGPColor.CreateFromColorRef(Brighten(LedColor, 20));
    FlightColor.Alpha := 125;
    FLightRect := WorkRect;
    InflateRect(FLightRect, -((Ceil(WorkRect.Width / 5) * 4) - 4), -1);
    FLightRect.Height := Ceil(WorkRect.Height / 4);
    FLedLight  := TGPLinearGradientBrush.Create(TGPRect.Create(FLightRect), FLightColor, FLightToColor, 90);
    FGraphics.FillEllipse(FLedLight, TGPRect.Create(FLightRect));
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  { Maintain width / height -ratio }
  if (csdesigning in componentstate) then
  if Height < Width then Height := Width else Width := Height;

  { Set Buffer size }
  FBuffer.SetSize(ClientWidth, ClientHeight);

  { Create GDI+ Graphic }
  FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
  FGraphics.SmoothingMode := SmoothingModeAntiAlias;
  FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

  { Redraw Buffer }
  if NeedsRedrawing then
  begin
    case State of
      lsOff    : LedColor := LedOffColor;
      lsOn     : LedColor := LedOnColor;
      lsGrayed : LedColor := LedGrayedColor;
    end;
    WorkRect := Rect(
      ClientRect.Left,
      ClientRect.Top,
      ClientRect.Right -1,
      ClientRect.Bottom - 1
    );
    NeedsRedrawing := False;
    try
      DrawBackground;
      DrawBorder(FGraphics);
      DrawLedBorder(FGraphics);
      DrawLed(FGraphics);
    except
      NeedsRedrawing := True;
    end;
  end;

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

procedure TERDLed.Resize;
begin
  NeedsRedrawing := True;
  inherited;
end;

procedure TERDLed.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDLed.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        if not Enabled then State := lsGrayed;
        Invalidate;
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        NeedsRedrawing := True;
        Invalidate;
      end;

  end;
end;

procedure TERDLed.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if ToggleOnClick then
  begin
    if State = lsOff then
      State := lsOn
    else
      State := lsOff;
    if Assigned(FOnLedToggle) then FOnLedToggle(Self, State);
  end;
  inherited;
end;

end.
