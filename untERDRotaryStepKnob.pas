{
  untERDRotaryStepKnob v1.0.0 - a simple rotary step knob in the style of FL-Studio
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDRotaryStepKnob;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDRotaryStepKnobChangeEvent = procedure(Sender: TObject; Position: Integer) of object;

  TTickPoint = record
    X1: FixedInt;
    Y1: FixedInt;
    X2: FixedInt;
    Y2: FixedInt;
  public
    constructor Create(const X1, Y1, X2, Y2 : Integer);
  end;
  TTickPointArray = array of TTickPoint;

  TERDTickStyle = (tsLine, tsEllipse);

  TERDRotaryStepKnob = class(TCustomControl)
  private
    { Private declarations }
    FTickPoints    : TTickPointArray;
    FFaceColor     : TColor;
    FTickColor     : TColor;
    FPositionColor : TColor;
    FBorderColor   : TColor;

    FBorderWidth    : Integer;
    FPosition       : Integer;
    FMaxTicks       : Integer;
    FTickLength     : Integer;
    FBorderAlpha    : Integer;
    FTickWidth      : Integer;
    FFaceTickLength : Integer;
    FFaceTickWidth  : Integer;
    FTickStyle      : TERDTickStyle;
    FFaceTickStyle  : TERDTickStyle;
    FDrawFocusRect  : Boolean;

    { Buffer - Avoid flickering }
    FBuffer      : TBitmap;
    FUpdateRect  : TRect;
    FRedraw      : Boolean;

    { Twist the Button - Drag by Mouse }
    FIsDraggingFace : Boolean;

    FOnChange : TERDRotaryStepKnobChangeEvent;

    procedure SetFaceColor(const C: TColor);
    procedure SetTickColor(const C: TColor);
    procedure SetPositionColor(const C: TColor);
    procedure SetBorderColor(const C: TColor);

    procedure SetBorderWidth(const I: Integer);
    procedure SetPosition(const I: Integer);
    procedure SetMaxTicks(const I: Integer);
    procedure SetTickLength(const I: Integer);
    procedure SetBorderAlpha(const I: Integer);
    procedure SetTickWidth(const I: Integer);
    procedure SetFaceTickLength(const I: Integer);
    procedure SetFaceTickWidth(const I: Integer);
    procedure SetTickStyle(const S: TERDTickStyle);
    procedure SetFaceTickStyle(const S: TERDTickStyle);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    function FindClosestTick(const X, Y: Integer) : Integer;
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property RedrawKnob: Boolean read FRedraw write FRedraw;
    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property TickPoints: TTickPointArray read FTickPoints write FTickPoints;
  published
    { Published declarations }
    property FaceColor: TColor read FFaceColor write SetFaceColor default $00554E44;
    property TickColor: TColor read FTickColor write SetTickColor default $00464137;
    property PositionColor: TColor read FPositionColor write SetPositionColor default $003EC3FF;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00464137;

    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 12;
    property Position: Integer read FPosition write SetPosition default 1;
    property MaxTicks: Integer read FMaxTicks write SetMaxTicks default 5;
    property TickLength: Integer read FTickLength write SetTickLength default 10;
    property BorderAlpha: Integer read FBorderAlpha write SetBorderAlpha default 100;
    property TickWidth: Integer read FTickWidth write SetTickWidth default 2;
    property FaceTickLength: Integer read FFaceTickLength write SetFaceTickLength default 12;
    property FaceTickWidth: Integer read FFaceTickWidth write SetFaceTickWidth default 2;

    property TickStyle: TERDTickStyle read FTickStyle write SetTickStyle default tsLine;
    property FaceTickStyle: TERDTickStyle read FFaceTickStyle write SetFaceTickStyle default tsLine;
    property DrawFocusRect: Boolean read FDrawFocusRect write FDrawFocusRect default True;

    property OnChange: TERDRotaryStepKnobChangeEvent read FOnChange write FOnChange;

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
(*  Tick Point (TTickPoint)
(*
(******************************************************************************)

constructor TTickPoint.Create(const X1, Y1, X2, Y2: Integer);
begin
  Self.X1 := X1;
  Self.Y1 := Y1;
  Self.X2 := X2;
  Self.Y2 := Y2;
end;

(******************************************************************************)
(*
(*  Rotary Step Knob (TRotaryStepKnob)
(*
(******************************************************************************)

constructor TERDRotaryStepKnob.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We dont want the control to accept controls - but this might
    change in the future so we leave it here commented out. offcourse we
    like to get click, double click and mouse events. }
  ControlStyle := ControlStyle + [csOpaque{, csAcceptsControls},
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We do want to be able to get focus, which is needed for the scroll wheel }
  TabStop := True;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Width / Height }
  Width  := 65;
  Height := 65;

  { Defaults }
  FFaceColor      := $00554E44;
  FBorderColor    := $00464137;
  FTickColor      := $00464137;
  FPositionColor  := $003EC3FF;
  FBorderWidth    := 12;
  FPosition       := 1;
  FMaxTicks       := 5;
  FTickLength     := 10;
  FBorderAlpha    := 100;
  FTickWidth      := 2;
  FFaceTickLength := 12;
  FFaceTickWidth  := 2;
  FDrawFocusRect  := True;

  { Initial Draw }
  RedrawKnob := True;
end;

destructor TERDRotaryStepKnob.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  inherited Destroy;
end;

procedure TERDRotaryStepKnob.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDRotaryStepKnob.SetFaceColor(const C: TColor);
begin
  if FaceColor <> C then
  begin
    FFaceColor := C;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetTickColor(const C: TColor);
begin
  if TickColor <> C then
  begin
    FTickColor := C;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetPositionColor(const C: TColor);
begin
  if PositionColor <> C then
  begin
    FPositionColor := C;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetBorderWidth(const I: Integer);
var
  MaxB: Integer;
begin
  if BorderWidth <> I then
  begin
    MaxB := ((ClientWidth div 2) - 4);
    if I < 0 then
      FBorderWidth := 0
    else
    if I > MaxB then
      FBorderWidth := MaxB
    else
      FBorderWidth := I;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetPosition(const I: Integer);
begin
  if Position <> I then
  begin
    if I > MaxTicks then
      FPosition := MaxTicks
    else
    if I < 1 then
      FPosition := 1
    else
      FPosition := I;
    RedrawKnob := True;
    Invalidate;
    if Assigned(FOnChange) then FOnChange(Self, I);
  end;
end;

procedure TERDRotaryStepKnob.SetMaxTicks(const I: Integer);
begin
  if MaxTicks <> I then
  begin
    if I < 2 then
      FMaxTicks := 2
    else
      FMaxTicks := I;
    if MaxTicks < Position then
      Position := MaxTicks;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetTickLength(const I: Integer);
begin
  if TickLength <> I then
  begin
    if I > BorderWidth then
      FTickLength := BorderWidth
    else
    if I < 1 then
      FTickLength := 1
    else
      FTickLength := I;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetBorderAlpha(const I: Integer);
begin
  if BorderAlpha <> I then
  begin
    if I < 1 then
      FBorderAlpha := 1
    else
    if I > 255 then
      FBorderAlpha := 255
    else
      FBorderAlpha := I;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetTickWidth(const I: Integer);
begin
  if TickWidth <> I then
  begin
    if I < 1 then
      FTickWidth := 1
    else
      FTickWidth := I;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetFaceTickLength(const I: Integer);
begin
  if FaceTickLength <> I then
  begin
    if I < 1 then
      FFaceTickLength := 1
    else
      FFaceTickLength := I;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetFaceTickWidth(const I: Integer);
begin
  if FaceTickWidth <> I then
  begin
    if I < 1 then
      FFaceTickWidth := 1
    else
      FFaceTickWidth := I;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetTickStyle(const S: TERDTickStyle);
begin
  if TickStyle <> S then
  begin
    FTickStyle := S;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.SetFaceTickStyle(const S: TERDTickStyle);
begin
  if FaceTickStyle <> S then
  begin
    FFaceTickStyle := S;
    RedrawKnob := True;
    Invalidate;
  end;
end;

procedure TERDRotaryStepKnob.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

function TERDRotaryStepKnob.FindClosestTick(const X, Y: Integer) : Integer;

  function Distance2D(X1, Y1, X2, Y2 : double) : double;
  var a,b,c:double;
  begin
   a:=abs(x1-x2);
   b:=abs(y1-y2);
   c:=sqr(a)+sqr(b);
   if c>0 then result:=sqrt(c) else result:=0;
  end;

var
  I    : Integer;
  O, N : Double;
begin
  Result := 1;
  O := Distance2D(TickPoints[0].X1, TickPoints[0].Y1, X, Y);
  for I := Low(TickPoints) to High(TickPoints) do
  begin
    N := Distance2D(TickPoints[I].X1, TickPoints[I].Y1, X, Y);
    if N < O then
    begin
      Result := I +1;
      O := N;
    end;
  end;
end;

procedure TERDRotaryStepKnob.Paint;
const
  TAU = PI * 2;
var
  TickOffset  : Double;
  WorkRect    : TRect;
  Radius      : Integer;
  InnerRadius : Integer;
  OuterRadius : Integer;

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
    FBorder       : TGPColor;
    FBorder2      : TGPColor;
    FInnerBrush   : IGPSolidBrush;
    FBorderBrush  : IGPSolidBrush;
    FBorder2Brush : IGPSolidBrush;
  var
    R, R2 : TRect;
  begin
    { Create Solid Border Brush }
    FBorder := TGPColor.CreateFromColorRef(BorderColor);
    FBorder.Alpha := BorderAlpha;
    FBorder2 := TGPColor.CreateFromColorRef(Darken(BorderColor, 80));
    FBorder2.Alpha := 80;
    FBorderBrush  := TGPSolidBrush.Create(FBorder);
    FBorder2Brush := TGPSolidBrush.Create(FBorder2);
    FInnerBrush   := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Color));
    { Draw background and border }
    FGraphics.FillEllipse(FBorderBrush, TGPRect.Create(WorkRect));
    { Draw Border line }
    R  := WorkRect;
    InflateRect(R, -BorderWidth, -BorderWidth);
    R2 := R;
    FGraphics.FillEllipse(FInnerBrush, TGPRect.Create(R));
    R.Bottom := WorkRect.Bottom;
    FGraphics.FillEllipse(FBorder2Brush, TGPRect.Create(R));
    WorkRect := R2;
  end;

  procedure DrawTick(var FGraphics: IGPGraphics; const TickColor: TColor; X1, Y1, X2, Y2: Integer; const Style: TERDTickStyle; const IsFace: Boolean = false);
  var
    FBrushR : TRect;
    FBrush  : IGPSolidBrush;
    FBrushS : IGPSolidBrush;
    FPen    : IGPPen;
    FHSize  : Integer;
  begin
    case Style of
      { Tick Line }
      tsLine:
      begin
        if IsFace then
        begin
          FPen := TGPPen.Create(TGPColor.CreateFromColorRef(TickColor), FaceTickWidth);
        end else
        begin
          FPen := TGPPen.Create(TGPColor.CreateFromColorRef(TickColor), TickWidth);
        end;
        FGraphics.DrawLine(FPen, X1 -1, Y1, X2 -1, Y2);
      end;

      { Tick Ellipse }
      tsEllipse:
      begin
        FBrushR.Left  := FBrushR.Left -1;
        FBrushR.Right := FBrushR.Right -1;
        FBrush  := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Brighten(TickColor, 35)));
        FBrushS := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(TickColor));
        if IsFace then
          FHSize := Round(FaceTickWidth / 2)
        else
          FHSize := Round(TickWidth / 2);
        FBrushR := Rect(
          X2 - FHSize,
          Y2 - FHSize,
          X2 + FHSize,
          Y2 + FHSize
        );
        if (FHSize > 0) and IsFace then
        begin
          InflateRect(FBrushR, 1, 1);
          FGraphics.FillEllipse(FBrushS, TGPRect.Create(FBrushR));
          InflateRect(FBrushR, -1, -1);
        end;
        if IsFace then
        begin
          FGraphics.FillEllipse(FBrush, TGPRect.Create(FBrushR));
        end else
        begin
          FGraphics.FillEllipse(FBrush, TGPRect.Create(FBrushR));
        end;
      end;
    end;
  end;

  procedure DrawTicks(var FGraphics: IGPGraphics);
  var
    A : Double;
    I, X1, Y1, X2, Y2 : Integer;
  begin
    SetLength(FTickPoints, MaxTicks);
    for I := 0 to MaxTicks -1 do
    begin
      A  := TAU * I / MaxTicks;
      X1 := Radius + Ceil(Cos(A - TickOffset) * OuterRadius);
      Y1 := Radius + Ceil(Sin(A - TickOffset) * OuterRadius);
      X2 := Radius + Ceil(Cos(A - TickOffset) * InnerRadius);
      Y2 := Radius + Ceil(Sin(A - TickOffset) * InnerRadius);
      TickPoints[I] := TTickPoint.Create(X1, Y1, X2, Y2);
      if I = (Position - 1) then
        DrawTick(FGraphics, PositionColor, X1, Y1, X2, Y2, TickStyle)
      else
        DrawTick(FGraphics, TickColor, X1, Y1, X2, Y2, TickStyle);
    end;
  end;

  procedure DrawFaceTick(var FGraphics: IGPGraphics);
  var
    A    : Double;
    O, I : Integer;
  begin
    O := Round(WorkRect.Width / 2);
    I := O - FaceTickLength;
    A := TAU * (Position -1) / MaxTicks;
    DrawTick(FGraphics, PositionColor,
      Radius + Ceil(Cos(A - TickOffset) * O),
      Radius + Ceil(Sin(A - TickOffset) * O),
      Radius + Ceil(Cos(A - TickOffset) * I),
      Radius + Ceil(Sin(A - TickOffset) * I),
      FaceTickStyle,
      True
    );
  end;

  procedure DrawFace(var FGraphics: IGPGraphics);
  var
    FBorderBrush : IGPSolidBrush;
    FGrad1Brush  : IGPLinearGradientBrush;
    FGrad2Brush  : IGPLinearGradientBrush;
    FGrad3Brush  : IGPLinearGradientBrush;
    FGrad3From   : TGPColor;
    FGrad3To     : TGPColor;
  begin
    { Create Face Border Brush }
    FBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FaceColor));
    { Draw Face Border }
    FGraphics.FillEllipse(FBorderBrush, TGPRect.Create(WorkRect));
    { Draw Face Gradient 1 (Lighter) }
    FGrad1Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(WorkRect),
      TGPColor.CreateFromColorRef(Brighten(FaceColor, 50)),
      TGPColor.CreateFromColorRef(Brighten(FaceColor, 30)),
      90);
    InflateRect(WorkRect, -2, -2);
    FGraphics.FillEllipse(FGrad1Brush, TGPRect.Create(WorkRect));
    { Draw Face Gradient 2 (Darker) }
    FGrad2Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(WorkRect),
      TGPColor.CreateFromColorRef(FaceColor),
      TGPColor.CreateFromColorRef(Darken(FaceColor, 70)),
      90);
    { Overlay }
    FGrad3From   := TGPColor.CreateFromColorRef(Darken(FaceColor, 50));
    FGrad3From.Alpha := 10;
    FGrad3To     := TGPColor.CreateFromColorRef(Darken(FaceColor, 70));
    FGrad3To.Alpha := 10;
    FGrad3Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(WorkRect),
      FGrad3From,
      FGrad3To,
      90);
    FGraphics.FillEllipse(FGrad3Brush, TGPRect.Create(WorkRect));
    InflateRect(WorkRect, -1, -1);
    { Draw Active Tick on the Knob Face }
    DrawFaceTick(FGraphics);
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  { Maintain width / height -ratio }
  if (csdesigning in componentstate) then
  if Height < Width then Height := Width else Width := Height;

  if RedrawKnob then
  begin
    RedrawKnob := False;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Tick Offset }
    TickOffset := PI * 4 / 8;

    { Set Work Rect }
    WorkRect := Rect(
      ClientRect.Left,
      ClientRect.Top,
      ClientRect.Right -1,
      ClientRect.Bottom - 1
    );

    { Set Radius }
    Radius      := Round(WorkRect.Width / 2);
    OuterRadius := Radius;
    InnerRadius := OuterRadius - TickLength;

    { Draw }
    DrawBackground;
    DrawBorder(FGraphics);
    DrawTicks(FGraphics);
    DrawFace(FGraphics);
    if Focused and DrawFocusRect then FBuffer.Canvas.DrawFocusRect(ClientRect);
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

procedure TERDRotaryStepKnob.Resize;
begin
  if Width < 50 then Width := 50;
  if Height < 50 then Height := 50;
  RedrawKnob := True;
  inherited;
end;

procedure TERDRotaryStepKnob.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDRotaryStepKnob.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        RedrawKnob := True;
        Invalidate;
      end;

    { Focus is lost }
    WM_KILLFOCUS:
      begin
        {  }
        if DrawFocusRect then RedrawKnob := True;
        Invalidate;
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        {  }
        if DrawFocusRect then RedrawKnob := True;
        Invalidate;
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        RedrawKnob := True;
        Invalidate;
      end;

  end;
end;

procedure TERDRotaryStepKnob.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if Enabled then
  begin
    if (not Focused) and CanFocus then SetFocus;
    FIsDraggingFace := True;
    RedrawKnob      := True;
    Position := FindClosestTick(X, Y);
    Invalidate;
  end;
  inherited;
end;

procedure TERDRotaryStepKnob.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsDraggingFace := False;
  RedrawKnob      := True;
  Invalidate;
  inherited;
end;

procedure TERDRotaryStepKnob.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
begin
  if FIsDraggingFace then Position := FindClosestTick(X, Y);
  inherited;
end;

function TERDRotaryStepKnob.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  inherited;
  { During designtime there is no need for these events }
  if (csDesigning in ComponentState) then Exit;
  { Ignore when the component is disabled }
  if not Enabled then Exit;
  { Move the knob by the mousewheel }
  if WheelDelta < 0 then
  begin
    if (Position > 1) then
      Position := Position - 1
    else
      Position := MaxTicks;
  end else
  begin
    if (Position < MaxTicks) then
      Position := Position + 1
    else
      Position := 1;
  end;
  Result := True;
end;

procedure TERDRotaryStepKnob.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_LEFT) or (Key = VK_DOWN) then
  begin
    if (Position > 1) then
      Position := Position - 1
    else
      Position := MaxTicks;
  end else
  if (Key = VK_RIGHT) or (Key = VK_UP) then
  begin
    if (Position < MaxTicks) then
      Position := Position + 1
    else
      Position := 1;
  end;
  inherited;
end;

end.
