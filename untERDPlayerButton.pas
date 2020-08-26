{
  untERDPlayerButton v1.0.0 - a button for use with a audio player
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDPlayerButton;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, Vcl.ExtCtrls, GDIPlus;

type
  TERDPlayerButtonState          = (bsNormal, bsHot, bsPressed, bsChecked);
  TERDPlayerButtonIndicatorShape = (bisStop, bisPlay, bisPause, bisNext,
    bisPrevious, bisEject, bisRecord, bisVolume, bisMute);

  TERDPlayerButtonIndicator = class(TPersistent)
  private
    { Private declarations }
    FShape    : TERDPlayerButtonIndicatorShape;
    FOnColor  : TColor;
    FOffColor : TColor;
    FWidth    : Integer;
    FHeight   : Integer;

    FOnChange : TNotifyEvent;

    procedure SetShape(const S: TERDPlayerButtonIndicatorShape);
    procedure SetOnColor(const C: TColor);
    procedure SetOffColor(const C: TColor);
    procedure SetWidth(const I: Integer);
    procedure SetHeight(const I: Integer);
  public
    { Public declarations }
    constructor Create; virtual;

    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Shape: TERDPlayerButtonIndicatorShape read FShape write SetShape default bisStop;
    property OnColor: TColor read FOnColor write SetOnColor default $00EAA900;
    property OffColor: TColor read FOffColor write SetOffColor default $00E5E5D5;
    property Width: Integer read FWidth write SetWidth default 16;
    property Height: Integer read FHeight write SetHeight default 16;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDPlayerButton = class(TCustomControl)
  private
    { Private declarations }
    FIndicator : TERDPlayerButtonIndicator;
    FOnClick   : TNotifyEvent;

    { Buffer - Avoid flickering }
    FBuffer        : TBitmap;
    FButtonBuffer  : TBitmap;
    FUpdateRect    : TRect;
    FRedraw        : Boolean;

    { Button State }
    FLastButton  : Boolean;
    FButtonState : TERDPlayerButtonState;
    FActive      : Boolean;
    FBlinking    : Boolean;
    FIsPressed   : Boolean;

    { Do we want a focus rect ? }
    FDrawFocusRect : Boolean;

    { Blinking Timer }
    FBlinkingTimer : TTimer;

    procedure SetIndicator(const I: TERDPlayerButtonIndicator);
    procedure SetActive(const B: Boolean);

    procedure SetLastButton(const B: Boolean);
    
    function GetBlinkingActive : Boolean;
    procedure SetBlinkingActive(const B: Boolean);
    function GetBlinkInterval : Integer;
    procedure SetBlinkInterval(const I: Integer);

    function GetChecked : Boolean;
    procedure SetChecked(const B: Boolean);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure SettingsChanged(Sender: TObject);
    procedure OnBlinkingTimer(Sender: TObject);

    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Redraw: Boolean read FRedraw write FRedraw;
    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property ButtonState: TERDPlayerButtonState read FButtonState;
  published
    { Published declarations }
    property Indicator: TERDPlayerButtonIndicator read FIndicator write SetIndicator;
    property Active: Boolean read FActive write SetActive default False;
    property Checked: Boolean read GetChecked write SetChecked default False;
    property Blinking: Boolean read GetBlinkingActive write SetBlinkingActive;
    property BlinkInterval: Integer read GetBlinkInterval write SetBlinkInterval default 1000;
    property LastButton: Boolean read FLastButton write SetLastButton default False;
    property DrawFocusRect: Boolean read FDrawFocusRect write FDrawFocusRect default True;

    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    
    property Align;
    property Anchors;
    property Color default $00444444;
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
(*  ERD Player Button Indicator (TERDPlayerButtonIndicator)
(*
(******************************************************************************)
constructor TERDPlayerButtonIndicator.Create;
begin
  inherited Create;
  FShape    := bisStop;
  FOnColor  := $00EAA900;
  FOffColor := $00E5E5D5;
  FWidth    := 16;
  FHeight   := 16;
end;

procedure TERDPlayerButtonIndicator.Assign(Source: TPersistent);
begin
  if Source is TERDPlayerButtonIndicator then
  begin
    FShape    := TERDPlayerButtonIndicator(Source).Shape;
    FOnColor  := TERDPlayerButtonIndicator(Source).OnColor;
    FOffColor := TERDPlayerButtonIndicator(Source).OffColor;
    FWidth    := TERDPlayerButtonIndicator(Source).Width;
    FHeight   := TERDPlayerButtonIndicator(Source).Height;
  end else
    inherited;
end;

procedure TERDPlayerButtonIndicator.SetShape(const S: TERDPlayerButtonIndicatorShape);
begin
  if Shape <> S then
  begin
    FShape := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDPlayerButtonIndicator.SetOnColor(const C: TColor);
begin
  if OnColor <> C then
  begin
    FOnColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDPlayerButtonIndicator.SetOffColor(const C: TColor);
begin
  if OffColor <> C then
  begin
    FOffColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDPlayerButtonIndicator.SetWidth(const I: Integer);
begin
  if Width <> I then
  begin
    FWidth := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDPlayerButtonIndicator.SetHeight(const I: Integer);
begin
  if Height <> I then
  begin
    FHeight := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

(******************************************************************************)
(*
(*  ERD Player Button (TERDPlayerButton)
(*
(******************************************************************************)
constructor TERDPlayerButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We don want the control to accept controls, this is a player display
    which will hold components. Offcourse we like to get click, double click
    and mouse events. }
  ControlStyle := ControlStyle + [csOpaque, {csAcceptsControls,}
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We do want to be able to get focus }
  TabStop := True;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;
  FBuffer.Canvas.Brush.Style := bsClear;
  FButtonBuffer := TBitmap.Create;
  FButtonBuffer.PixelFormat := pf32bit;

  { Settings }
  FIndicator := TERDPlayerButtonIndicator.Create;
  FIndicator.OnChange := SettingsChanged;

  { Blinking Timer }
  FBlinkingTimer := TTimer.Create(Self);
  FBlinkingTimer.Interval := 1000;
  FBlinkingTimer.Enabled := False;
  FBlinkingTimer.OnTimer := OnBlinkingTimer;

  { Width / Height }
  Width  := 81;
  Height := 57;

  { Defaults }
  Color          := $00444444;
  FButtonState   := bsNormal;
  FDrawFocusRect := True;

  { Initial Draw }
 SettingsChanged(Self);
end;

destructor TERDPlayerButton.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;
  FButtonBuffer.Free;

  { Free Blinking Timer }
  FBlinkingTimer.Free;

  { Free Settings }
  FIndicator.Free;

  inherited Destroy;
end;

procedure TERDPlayerButton.SetIndicator(const I: TERDPlayerButtonIndicator);
begin
  if Indicator <> I then
  begin
    FIndicator.Assign(I);
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerButton.SetActive(const B: Boolean);
begin
  if Active <> B then
  begin
    FActive := B;
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerButton.SetLastButton(const B: Boolean);
begin
  if LastButton <> B then
  begin
    FLastButton := B;
    SettingsChanged(Self);
  end;
end;

function TERDPlayerButton.GetBlinkingActive : Boolean;
begin
  Result := FBlinkingTimer.Enabled;
end;

procedure TERDPlayerButton.SetBlinkingActive(const B: Boolean);
begin
  if B <> FBlinkingTimer.Enabled then
  begin
    FBlinkingTimer.Enabled := B;
    if not B then FBlinking := False;
    Invalidate;
  end;
end;

function TERDPlayerButton.GetBlinkInterval : Integer;
begin
  Result := FBlinkingTimer.Interval;
end;

procedure TERDPlayerButton.SetBlinkInterval(const I: Integer);
begin
  if FBlinkingTimer.Interval <> I then
    FBlinkingTimer.Interval := I
end;

function TERDPlayerButton.GetChecked : Boolean;
begin
  Result := ButtonState = bsChecked;
end;

procedure TERDPlayerButton.SetChecked(const B: Boolean);
begin
  case B of
    True  : FButtonState := bsChecked;
    False : FButtonState := bsNormal;
  end;
  SettingsChanged(Self);
end;

procedure TERDPlayerButton.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDPlayerButton.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDPlayerButton.SettingsChanged(Sender: TObject);
begin
  Redraw := True;
  Invalidate;
end;

procedure TERDPlayerButton.OnBlinkingTimer(Sender: TObject);
begin
  FBlinking := not FBlinking;
  Invalidate;
end;

procedure TERDPlayerButton.Paint;
var
  WorkRect : TRect;

  procedure DrawBorder;
  begin
    with FButtonBuffer.Canvas do
    begin
      Brush.Style := bsSolid;
      Brush.Color := Darken(Color, 50);
      FillRect(WorkRect);
    end;
  end;

  function StopPath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddRectangle(TGPRect.Create(Rect));
    Path.CloseFigure;
    Result := Path;
  end;

  function PlayPath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddPolygon([
      TGPPoint.Create(Rect.Left, Rect.Top),
      TGPPoint.Create(Rect.Left, Rect.Bottom),
      TGPPoint.Create(Rect.Right, Rect.Top + Rect.Height div 2)
    ]);
    Path.CloseFigure;
    Result := Path;
  end;

  function PausePath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddRectangle(TGPRect.Create(Rect.Left, Rect.Top, (Rect.Width div 5) * 2, Rect.Height));
    Path.AddRectangle(TGPRect.Create(Rect.Right - ((Rect.Width div 5) * 2), Rect.Top, (Rect.Width div 5) * 2, Rect.Height));
    Path.CloseFigure;
    Result := Path;
  end;

  function NextPath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddPolygon([
      TGPPoint.Create(Rect.Left, Rect.Top),
      TGPPoint.Create(Rect.Left, Rect.Bottom),
      TGPPoint.Create(Rect.Right - (Rect.Width div 4), Rect.Top + Rect.Height div 2)
    ]);
    Path.AddRectangle(TGPRect.Create(Rect.Right - (Rect.Width div 4), Rect.Top, (Rect.Width div 4), Rect.Height));
    Path.CloseFigure;
    Result := Path;
  end;

  function PreviousPath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddRectangle(TGPRect.Create(Rect.Left, Rect.Top, (Rect.Width div 4), Rect.Height));
    Path.AddPolygon([
      TGPPoint.Create(Rect.Left + (Rect.Width div 4), Rect.Top + Rect.Height div 2),
      TGPPoint.Create(Rect.Right, Rect.Top),
      TGPPoint.Create(Rect.Right, Rect.Bottom)
    ]);
    Path.CloseFigure;
    Result := Path;
  end;

  function EjectPath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddPolygon([
      TGPPoint.Create(Rect.Left + (Rect.Width div 2), Rect.Top),
      TGPPoint.Create(Rect.Left, Rect.Top + ((Rect.Height div 5) * 3)),
      TGPPoint.Create(Rect.Right, Rect.Top + ((Rect.Height div 5) * 3))
    ]);
    Path.AddRectangle(TGPRect.Create(Rect.Left, Rect.Bottom - (Rect.Height div 5), Rect.Width, (Rect.Height div 5)));
    Path.CloseFigure;
    Result := Path;
  end;

  function RecordPath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddEllipse(TGPRect.Create(Rect));
    Path.CloseFigure;
    Result := Path;
  end;

  function VolumePath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    Path.AddPolygon([
      TGPPoint.Create(Rect.Left, Rect.Top + (Rect.Height div 4)),
      TGPPoint.Create(Rect.Left + (Rect.Width div 4),  Rect.Top + (Rect.Height div 4)),
      TGPPoint.Create(Rect.Left + (Rect.Width div 2), Rect.Top),
      TGPPoint.Create(Rect.Left + (Rect.Width div 2), Rect.Bottom),
      TGPPoint.Create(Rect.Left + (Rect.Width div 4),  Rect.Top + ((Rect.Height div 4) * 3)),
      TGPPoint.Create(Rect.Left, Rect.Top + ((Rect.Height div 4) * 3))
    ]);
    Path.AddArc(TGPRect.Create(
      Rect.Left + (Rect.Width div 2),
      Rect.Top,
      (Rect.Width div 2),
      Rect.Height), -90, 180);
    Path.CloseFigure;
    Result := Path;
  end;

  function MutePath(Rect: TRect) : IGPGraphicsPath;
  var
    Path : IGPGraphicsPath;
    R    : TRect;
  begin
    Path := TGPGraphicsPath.Create;
    R := Rect;
    InflateRect(R, -(Rect.Width div 8), 0);
    Path.AddPolygon([
      TGPPoint.Create(R.Left, R.Top + ((R.Height div 6) * 2)),
      TGPPoint.Create(R.Left + (R.Width div 2),  R.Top + ((R.Height div 6) * 2)),
      TGPPoint.Create(R.Right, R.Top),
      TGPPoint.Create(R.Right, R.Bottom),
      TGPPoint.Create(R.Left + (R.Width div 2),  R.Bottom - ((R.Height div 6) * 2)),
      TGPPoint.Create(R.Left, R.Bottom - ((R.Height div 6) * 2))
    ]);
    Path.CloseFigure;
    Result := Path;
  end;

  procedure DrawButtonFace(var FGraphics : IGPGraphics; const ButtonState: TERDPlayerButtonState);
  var
    FaceBrush      : IGPLinearGradientBrush;
    IndicatorBrush : IGPLinearGradientBrush;
    IndicatorRect  : TRect;
    XC, YC         : Integer;
  begin
    { Draw Button Face }
    if LastButton then WorkRect.Right := WorkRect.Right -1;
    InflateRect(WorkRect, -1, -1);
    if not Enabled then
    begin
      FaceBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(WorkRect),
        TGPColor.CreateFromColorRef(Brighten(Color, 10)),
        TGPColor.CreateFromColorRef(Darken(Color, 5)),
        90);
    end else
    case ButtonState of
      { Normal }
      bsNormal  : FaceBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(WorkRect),
        TGPColor.CreateFromColorRef(Color),
        TGPColor.CreateFromColorRef(Darken(Color, 30)),
        90);
      { Hot }
      bsHot     : FaceBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(WorkRect),
        TGPColor.CreateFromColorRef(Brighten(Color, 5)),
        TGPColor.CreateFromColorRef(Darken(Color, 20)),
        90);
      { Pressed }
      bsPressed : FaceBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(WorkRect),
        TGPColor.CreateFromColorRef(Darken(Color, 5)),
        TGPColor.CreateFromColorRef(Color),
        90);
      { Checked }
      bsChecked : FaceBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(WorkRect),
        TGPColor.CreateFromColorRef(Darken(Color, 5)),
        TGPColor.CreateFromColorRef(Brighten(Color, 5)),
        90);
    end;
    FGraphics.FillRectangle(FaceBrush, TGPRect.Create(WorkRect));
    with FButtonBuffer.Canvas do
    begin
      IndicatorRect := ClientRect;
      InflateRect(IndicatorRect, -1, -1);
      Brush.Style := bsClear;
      Pen.Width := 1;
      Pen.Color := Brighten(Color, 10);
      Rectangle(IndicatorRect);
    end;
    { Draw Indicator }
    XC := WorkRect.Left + Floor(WorkRect.Width / 2);
    YC := WorkRect.Top + Floor(WorkRect.Height / 2);
    IndicatorRect := Rect(
      XC - Floor(Indicator.Width / 2),
      YC - Floor(Indicator.Height / 2),
      XC + Floor(Indicator.Width / 2),
      YC + Floor(Indicator.Height / 2)
    );
    if not Enabled then
    begin
      IndicatorBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(IndicatorRect),
        TGPColor.CreateFromColorRef(Darken(Indicator.OffColor, 30)),
        TGPColor.CreateFromColorRef(Darken(Indicator.OffColor, 50)),
        90);
    end else
    case Active of
      { Active }
      True:  IndicatorBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(IndicatorRect),
        TGPColor.CreateFromColorRef(Brighten(Indicator.OnColor, 20)),
        TGPColor.CreateFromColorRef(Darken(Indicator.OnColor, 20)),
        90);
      { Not Active }
      False: IndicatorBrush := TGPLinearGradientBrush.Create(
        TGPRect.Create(IndicatorRect),
        TGPColor.CreateFromColorRef(Indicator.OffColor),
        TGPColor.CreateFromColorRef(Indicator.OffColor),
        90);
    end;
    case Indicator.Shape of
      bisStop     : FGraphics.FillPath(IndicatorBrush, StopPath(IndicatorRect));
      bisPlay     : FGraphics.FillPath(IndicatorBrush, PlayPath(IndicatorRect));
      bisPause    : FGraphics.FillPath(IndicatorBrush, PausePath(IndicatorRect));
      bisNext     : FGraphics.FillPath(IndicatorBrush, NextPath(IndicatorRect));
      bisPrevious : FGraphics.FillPath(IndicatorBrush, PreviousPath(IndicatorRect));
      bisEject    : FGraphics.FillPath(IndicatorBrush, EjectPath(IndicatorRect));
      bisRecord   : FGraphics.FillPath(IndicatorBrush, RecordPath(IndicatorRect));
      bisVolume   : FGraphics.FillPath(IndicatorBrush, VolumePath(IndicatorRect));
      bisMute     : FGraphics.FillPath(IndicatorBrush, MutePath(IndicatorRect));
    end;
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  if Redraw then
  begin
    Redraw := False;

    {  Create toggle clientrect }
    WorkRect := ClientRect;

    { Set Buffer size }
    FButtonBuffer.SetSize(ClientWidth, ClientHeight);
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FButtonBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Background }
    DrawBorder;
    DrawButtonFace(FGraphics, ButtonState);
  end;

  { Draw the Button to the Buffer }
  BitBlt(FBuffer.Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FButtonBuffer.Canvas.Handle, 0,  0, SRCCOPY);

  { Draw a square in the button if blinking is on }
  if FBlinking then
  with FBuffer.Canvas do
  begin
    WorkRect  := Rect(ClientRect.Left +1, ClientRect.Top +1, ClientRect.Right, ClientRect.Bottom);
    InflateRect(WorkRect, -4, -4);
    Pen.Color := Indicator.OnColor;
    Pen.Width := 3;
    Rectangle(WorkRect); 
  end;

  { Need a focus rect ? }
  if DrawFocusRect and Focused then
  with FBuffer.Canvas do
  begin
    WorkRect := ClientRect;
    InflateRect(WorkRect, -3, -3);
    DrawFocusRect(WorkRect);
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

procedure TERDPlayerButton.Resize;
begin
  SettingsChanged(Self);
  inherited;
end;

procedure TERDPlayerButton.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDPlayerButton.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        if (not Enabled) and (ButtonState <> bsNormal) then FButtonState := bsNormal;
        SettingsChanged(Self);
      end;

    { Focus is lost }
    WM_KILLFOCUS:
      begin
        Invalidate;
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        Invalidate;
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        SettingsChanged(Self);
      end;

    CM_MOUSEENTER:
      if not (csDesigning in ComponentState) then
      if (not FIsPressed) and (not Checked) and (ButtonState <> bsHot) then
      begin
        FButtonState := bsHot;
        SettingsChanged(Self);
      end;

    CM_MOUSELEAVE:
      if not (csDesigning in ComponentState) then
      if (not FIsPressed) and (not Checked) and (ButtonState <> bsNormal) then
      begin
        FButtonState := bsNormal;
        SettingsChanged(Self);
      end;
  end;
end;

procedure TERDPlayerButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if CanFocus and (not Focused) then SetFocus;
  if (not Checked) and (not FIsPressed) then
  begin
    if Assigned(FOnClick) then FOnClick(Self);
    FIsPressed   := True;
    FButtonState := bsPressed;
    SettingsChanged(Self);
  end;
  inherited;
end;

procedure TERDPlayerButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (FIsPressed) then FIsPressed := False;
  if (not FIsPressed) and (not Checked) and (not PtInRect(ClientRect, Point(X, Y))) then
  begin
    FButtonState := bsNormal;
    SettingsChanged(Self);
  end;
  if (not FIsPressed) and (not Checked) and PtInRect(ClientRect, Point(X, Y)) and (ButtonState <> bsHot) then
  begin
    FButtonState := bsHot;
    SettingsChanged(Self);    
  end;
  inherited;
end;

procedure TERDPlayerButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (not Checked) and (not FIsPressed) then
  if (Key = VK_RETURN) or (Key = VK_SPACE) then
  begin
    if Assigned(FOnClick) then FOnClick(Self);
    FIsPressed   := True;
    FButtonState := bsPressed;
    SettingsChanged(Self);
  end;
  inherited;
end;

procedure TERDPlayerButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if (FIsPressed) then FIsPressed := False;
  if (Key = VK_RETURN) or (Key = VK_SPACE) then
  begin
    if Assigned(FOnClick) then FOnClick(Self);
    FButtonState := bsNormal;
    SettingsChanged(Self);
  end;
  inherited;
end;

end.
