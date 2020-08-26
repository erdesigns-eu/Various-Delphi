{
  untERDVolumeTrackBar v1.0.0 - a audio Volume Trackbar in the style of FL-Studio
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDVolumeTrackBar;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDVolumeTrackbarChangeEvent = procedure(Sender: TObject; Position: Integer) of object;
  TERDVolumeTrackbarSliderShape = (ssRoundRect, ssRectangle);

  TERDVolumeTrackbarSlider = class(TPersistent)
  private
    { Private declarations }
    FActiveColor : TColor;
    FColor       : TColor;
    FBorderColor : TColor;
    FWidth       : Integer;
    FLength      : Integer;
    FShape       : TERDVolumeTrackbarSliderShape;
    FCornerSize  : Integer;

    FOnChange : TNotifyEvent;

    procedure SetActiveColor(const C: TColor);
    procedure SetColor(const C: TColor);
    procedure SetBorderColor(const C: TColor);
    procedure SetWidth(const I: Integer);
    procedure SetLength(const I: Integer);
    procedure SetShape(const S: TERDVolumeTrackbarSliderShape);
    procedure SetCornerSize(const I: Integer);
  public
    { Public declarations }
    constructor Create; virtual;
    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Color: TColor read FColor write SetColor default $00A89E9A;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $004A443C;
    property ActiveColor: TColor read FActiveColor write SetActiveColor default $004ED49D;
    property Width: Integer read FWidth write SetWidth default 24;
    property Length: Integer read FLength write SetLength default 40;
    property Shape: TERDVolumeTrackbarSliderShape read FShape write SetShape default ssRoundRect;
    property CornerSize: Integer read FCornerSize write SetCornerSize default 6;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDVolumeTrackBarRange = class(TPersistent)
  private
    { Private declarations }
    FActiveColor : TColor;
    FColor       : TColor;
    FBorderColor : TColor;
    FWidth       : Integer;

    FOnChange : TNotifyEvent;

    procedure SetActiveColor(const C: TColor);
    procedure SetColor(const C: TColor);
    procedure SetBorderColor(const C: TColor);
    procedure SetWidth(const I: Integer);
  public
    { Public declarations }
    constructor Create; virtual;
    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Color: TColor read FColor write SetColor default $00A89E9A;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00454036;
    property ActiveColor: TColor read FActiveColor write SetActiveColor default $004ED49D;
    property Width: Integer read FWidth write SetWidth default 4;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDVolumeTrackBarTicks = class(TPersistent)
  private
    { Private declarations }
    FColor       : TColor;
    FShadowColor : TColor;
    FShadowAlpha : Integer;
    FLineWidth   : Integer;
    FTickCount   : Integer;

    FOnChange : TNotifyEvent;

    procedure SetColor(const C: TColor);
    procedure SetShadowColor(const C: TColor);
    procedure SetShadowAlpha(const I: Integer);
    procedure SetLineWidth(const I: Integer);
    procedure SetTickCount(const I: Integer);
  public
    { Public declarations }
    constructor Create; virtual;
    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Color: TColor read FColor write SetColor default $004A443C;
    property ShadowColor: TColor read FShadowColor write SetShadowColor default $00454036;
    property ShadowAlpha: Integer read FShadowAlpha write SetShadowAlpha default 40;
    property LineWidth: Integer read FLineWidth write SetLineWidth default 2;
    property TickCount: Integer read FTickCount write SetTickCount default 5;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDVolumeTrackBar = class(TCustomControl)
  private
    { Private declarations }
    FSlider : TERDVolumeTrackbarSlider;
    FRange  : TERDVolumeTrackBarRange;
    FTicks  : TERDVolumeTrackBarTicks;

    { Position, Min and Max }
    FMin        : Integer;
    FMax        : Integer;
    FPosition   : Integer;
    FStep       : Integer;
    FVolumeIcon : Boolean;

    { Buffer - Avoid flickering }
    FBuffer         : TBitmap;
    FUpdateRect     : TRect;
    FRedrawTrackbar : Boolean;
    FRangeRect      : TRect;
    FSliderRect     : TRect;
    FDragging       : Boolean;
    FDrawFocusRect  : Boolean;

    FOnChange : TERDVolumeTrackbarChangeEvent;

    procedure SetSlider(S: TERDVolumeTrackbarSlider);
    procedure SetRange(R: TERDVolumeTrackBarRange);
    procedure SetTicks(T: TERDVolumeTrackBarTicks);

    procedure SetMin(const I: Integer);
    procedure SetMax(const I: Integer);
    procedure SetPosition(const I: Integer);
    procedure SetStep(const I: Integer);
    procedure SetVolumeIcon(const B: Boolean);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure SettingsChanged(Sender: TObject);
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function PositionAtCoords(const X, Y: Integer) : Integer;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property RedrawTrackbar: Boolean read FRedrawTrackbar write FRedrawTrackbar;
    property RangeRect: TRect read FRangeRect write FRangeRect;
    property SliderRect: TRect read FSliderRect write FSliderRect;
  published
    { Published declarations }
    property Slider: TERDVolumeTrackbarSlider read FSlider write SetSlider;
    property Range: TERDVolumeTrackBarRange read FRange write SetRange;
    property Ticks: TERDVolumeTrackBarTicks read FTicks write SetTicks;

    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 100;
    property Step: Integer read FStep write SetStep default 1;
    property ShowVolumeIcon: Boolean read FVolumeIcon write SetVolumeIcon default True;
    property DrawFocusRect: Boolean read FDrawFocusRect write FDrawFocusRect default True;

    property OnChange: TERDVolumeTrackbarChangeEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
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
(*  ERD Volume Trackbar Slider (TERDVolumeTrackbarSlider)
(*
(******************************************************************************)
constructor TERDVolumeTrackbarSlider.Create;
begin
  inherited Create;
  FColor       := $00A89E9A;
  FBorderColor := $004A443C;
  FActiveColor := $004ED49D;
  FWidth       := 24;
  FLength      := 40;
  FShape       := ssRoundRect;
  FCornerSize  := 6;
end;

procedure TERDVolumeTrackbarSlider.Assign(Source: TPersistent);
begin
  if Source is TERDVolumeTrackbarSlider then
  begin
    FActiveColor := TERDVolumeTrackbarSlider(Source).ActiveColor;
    FColor       := TERDVolumeTrackbarSlider(Source).Color;
    FBorderColor := TERDVolumeTrackbarSlider(Source).BorderColor;
    FWidth       := TERDVolumeTrackbarSlider(Source).Width;
    FLength      := TERDVolumeTrackbarSlider(Source).Length;
    FShape       := TERDVolumeTrackbarSlider(Source).Shape;
    FCornerSize  := TERDVolumeTrackbarSlider(Source).CornerSize;
  end else
    inherited;
end;

procedure TERDVolumeTrackbarSlider.SetActiveColor(const C: TColor);
begin
  if ActiveColor <> C then
  begin
    FActiveColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackbarSlider.SetColor(const C: TColor);
begin
  if Color <> C then
  begin
    FColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackbarSlider.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackbarSlider.SetWidth(const I: Integer);
begin
  if Width <> I then
  begin
    FWidth := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackbarSlider.SetLength(const I: Integer);
begin
  if Length <> I then
  begin
    FLength := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackbarSlider.SetShape(const S: TERDVolumeTrackbarSliderShape);
begin
  if Shape <> S then
  begin
    FShape := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackbarSlider.SetCornerSize(const I: Integer);
begin
  if CornerSize <> I then
  begin
    FCornerSize := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

(******************************************************************************)
(*
(*  ERD Volume Trackbar Range (TERDVolumeTrackBarRange)
(*
(******************************************************************************)
constructor TERDVolumeTrackBarRange.Create;
begin
  inherited Create;
  FColor       := $00A89E9A;
  FBorderColor := $00454036;
  FActiveColor := $004ED49D;
  FWidth       := 4;
end;

procedure TERDVolumeTrackBarRange.Assign(Source: TPersistent);
begin
  if Source is TERDVolumeTrackBarRange then
  begin
    FActiveColor := TERDVolumeTrackBarRange(Source).ActiveColor;
    FColor       := TERDVolumeTrackBarRange(Source).Color;
    FBorderColor := TERDVolumeTrackBarRange(Source).BorderColor;
    FWidth       := TERDVolumeTrackBarRange(Source).Width;
  end else
    inherited;
end;

procedure TERDVolumeTrackBarRange.SetActiveColor(const C: TColor);
begin
  if ActiveColor <> C then
  begin
    FActiveColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarRange.SetColor(const C: TColor);
begin
  if Color <> C then
  begin
    FColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarRange.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarRange.SetWidth(const I: Integer);
begin
  if Width <> I then
  begin
    FWidth := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

(******************************************************************************)
(*
(*  ERD Volume Trackbar Ticks (TVolumeTrackBarTicks)
(*
(******************************************************************************)
constructor TERDVolumeTrackBarTicks.Create;
begin
  inherited Create;
  FColor       := $004A443C;
  FShadowColor := $00A89E9A;
  FShadowAlpha := 40;
  FLineWidth   := 2;
  FTickCount   := 5;
end;

procedure TERDVolumeTrackBarTicks.Assign(Source: TPersistent);
begin
  if Source is TERDVolumeTrackBarTicks then
  begin
    FShadowColor := TERDVolumeTrackBarTicks(Source).ShadowColor;
    FColor       := TERDVolumeTrackBarTicks(Source).Color;
    FShadowAlpha := TERDVolumeTrackBarTicks(Source).ShadowAlpha;
    FLineWidth   := TERDVolumeTrackBarTicks(Source).LineWidth;
    FTickCount   := TERDVolumeTrackBarTicks(Source).TickCount;
  end else
    inherited;
end;

procedure TERDVolumeTrackBarTicks.SetShadowColor(const C: TColor);
begin
  if ShadowColor <> C then
  begin
    FShadowColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarTicks.SetColor(const C: TColor);
begin
  if Color <> C then
  begin
    FColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarTicks.SetShadowAlpha(const I: Integer);
begin
  if ShadowAlpha <> I then
  begin
    FShadowAlpha := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarTicks.SetLineWidth(const I: Integer);
begin
  if LineWidth <> I then
  begin
    if LineWidth > 0 then
      FLineWidth := I
    else
      FLineWidth := 1;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDVolumeTrackBarTicks.SetTickCount(const I: Integer);
begin
  if TickCount <> I then
  begin
    if I >= 0 then
      FTickCount := I
    else
      FTickCount := 0;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

(******************************************************************************)
(*
(*  ERD Volume Trackbar (TERDVolumeTrackBar)
(*
(******************************************************************************)
constructor TERDVolumeTrackBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We dont want the control to accept controls - because this is
    a trackbar / slider. }
  ControlStyle := ControlStyle + [csOpaque{, csAcceptsControls},
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We do want to be able to get focus, this is a slider - and we want to be
    able to focus to this control }
  TabStop := True;

  { Create Settings }
  FSlider := TERDVolumeTrackbarSlider.Create;
  FSlider.OnChange := SettingsChanged;
  FRange := TERDVolumeTrackBarRange.Create;
  FRange.OnChange := SettingsChanged;
  FTicks := TERDVolumeTrackBarTicks.Create;
  FTicks.OnChange := SettingsChanged;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Width / Height }
  Width  := 65;
  Height := 185;

  { Defaults }
  FMin        := 0;
  FMax        := 100;
  FPosition   := 100;
  FStep       := 1;
  FVolumeIcon := True;
  FDrawFocusRect := True;
end;

destructor TERDVolumeTrackBar.Destroy;
begin
  { Free Settings }
  FSlider.Free;
  FRange.Free;
  FTicks.Free;

  { Free Buffer }
  FBuffer.Free;

  inherited Destroy;
end;

procedure TERDVolumeTrackBar.SetSlider(S: TERDVolumeTrackbarSlider);
begin
  if Slider <> S then
  begin
    FSlider.Assign(S);
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetRange(R: TERDVolumeTrackBarRange);
begin
  if Range <> R then
  begin
    FRange.Assign(R);
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetTicks(T: TERDVolumeTrackBarTicks);
begin
  if Ticks <> T then
  begin
    FTicks.Assign(T);
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetMin(const I: Integer);
begin
  if Min <> I then
  begin
    if I > Max then
      FMin := Max
    else
    if I >= 0 then
      FMin := I
    else
      FMin := 0;
    if Position < Min then
      FPosition := Min;
    RedrawTrackbar := True;
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetMax(const I: Integer);
begin
  if Max <> I then
  begin
    if I < Min then
      FMax := Min
    else
    if I >= 0 then
      FMax := I
    else
      FMax := 0;
    if Position > Max then
      FPosition := Max;
    RedrawTrackbar := True;
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetPosition(const I: Integer);
begin
  if Position <> I then
  begin
    if I > Max then
      FPosition := Max
    else
    if I < Min then
      FPosition := Min
    else
      FPosition := I;
    if Assigned(FOnChange) then FOnChange(Self, I);
    RedrawTrackbar := True;
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetStep(const I: Integer);
begin
  if Step <> I then
  begin
    if I < 1 then
      FStep := 1
    else
      Fstep := I;
    RedrawTrackbar := True;
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.SetVolumeIcon(const B: Boolean);
begin
  if ShowVolumeIcon <> B then
  begin
    FVolumeIcon := B;
    RedrawTrackbar := True;
    Invalidate;
  end;
end;

procedure TERDVolumeTrackBar.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDVolumeTrackBar.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDVolumeTrackBar.SettingsChanged(Sender: TObject);
begin
  RedrawTrackBar := True;
  Invalidate;
end;

procedure TERDVolumeTrackBar.Paint;
var
  WorkRect   : TRect;
  RangeTop   : Integer;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(WorkRect);
    end;
  end;

  procedure CalculateRangeTop;
  begin
    RangeRect := Rect(
      WorkRect.Left + ((WorkRect.Width div 2) - (Range.Width div 2)),
      WorkRect.Top + (Slider.Length div 2),
      WorkRect.Left + ((WorkRect.Width div 2) + (Range.Width div 2)),
      (WorkRect.Bottom - 4) - (Slider.Length div 2)
    );
    RangeTop := RangeRect.Bottom - Round((RangeRect.Height / (Max - Min)) * Position);
  end;

  function VolumePath(const Rect: TRect) : IGPGraphicsPath;
  var
    W, H : Integer;
    Path : IGPGraphicsPath;
  begin
    Path := TGPGraphicsPath.Create;
    W    := Round(Rect.Width  / 3);
    H    := Round(Rect.Height / 3);
    Path.AddRectangle(TGPRect.Create(Rect.Left, Rect.Top + H, W, H));
    Path.AddPolygon([
      TGPPoint.Create(Rect.Left + W, Rect.Top + H),
      TGPPoint.Create(Rect.Right, Rect.Top),
      TGPPoint.Create(Rect.Right, Rect.Bottom),
      TGPPoint.Create(Rect.Left + W, Rect.Top + (H * 2))
    ]);
    Path.CloseFigure;
    Result := Path;
  end;

  procedure DrawRange(var FGraphics: IGPGraphics);
  var
    FBorderBrush  : IGPSolidBrush;
    FBrush        : IGPSolidBrush;
    FActiveBrush  : IGPSolidBrush;
    FVolumePath   : IGPGraphicsPath;
    FVolumeInPath : IGPGraphicsPath;
    FVolBrush     : IGPSolidBrush;
  var
    ActiveRect : TRect;
  begin
    { Create Brushes }
    FBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Range.BorderColor));
    FBrush       := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Range.Color));
    FActiveBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Range.ActiveColor));
    if Focused then
      FVolBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(Range.ActiveColor, 50)))
    else
      FVolBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(Range.Color, 50)));
    { Draw Border }
    FGraphics.FillRectangle(FBorderBrush, TGPRect.Create(RangeRect));
    InflateRect(FRangeRect, -1, -1);
    { Draw Inside }
    FGraphics.FillRectangle(FBrush, TGPRect.Create(RangeRect));
    { Draw Active Inside }
    ActiveRect := RangeRect;
    ActiveRect.Top := RangeTop;
    FGraphics.FillRectangle(FActiveBrush, TGPRect.Create(ActiveRect));
    { Draw volume speaker }
    if ShowVolumeIcon then
    begin
      ActiveRect  := Rect(
        RangeRect.Left - 4,
        (ClientRect.Bottom - 2) - (RangeRect.Width + 14),
        RangeRect.Right + 4,
        ClientRect.Bottom - 2
      );
      { Outline / border }
      FVolumePath := VolumePath(ActiveRect);
      FGraphics.FillPath(FVolBrush, FVolumePath);
      { Inside }
      InflateRect(ActiveRect, -1, -1);
      FVolumeInPath := VolumePath(ActiveRect);
      if Focused then
        FGraphics.FillPath(FActiveBrush, FVolumeInPath)
      else
        FGraphics.FillPath(FBrush, FVolumeInPath);
    end;
  end;

  procedure DrawTicks(var FGraphics: IGPGraphics);
  var
    FShadowColor : TGPColor;
    FShadowBrush : IGPSolidBrush;
    FTickPen     : IGPPen;
  var
    ShadowLeft, ShadowRight : TRect;
    I, TickHeight           : Integer;
  begin
    { Create Brushes }
    FShadowColor := TGPColor.CreateFromColorRef(Ticks.ShadowColor);
    FShadowColor.Alpha := Ticks.ShadowAlpha;
    FShadowBrush := TGPSolidBrush.Create(FShadowColor);
    InflateRect(FRangeRect, 1, 1);
    { Draw Shadow Left }
    ShadowLeft := Rect(
      WorkRect.Left + 2,
      RangeRect.Top,
      RangeRect.Left - 4,
      RangeRect.Bottom
    );
    FGraphics.FillRectangle(FShadowBrush, TGPRect.Create(ShadowLeft));
    { Draw Shadow Right}
    ShadowRight := Rect(
      RangeRect.Right + 4,
      RangeRect.Top,
      WorkRect.Right - 2,
      RangeRect.Bottom
    );
    FGraphics.FillRectangle(FShadowBrush, TGPRect.Create(ShadowRight));
    { Draw Lines }
    FTickPen := TGPPen.Create(TGPColor.CreateFromColorRef(Ticks.Color), Ticks.LineWidth);
    { Draw Lines on Top and Bottom of the range }
    FGraphics.DrawLine(FTickPen, ShadowLeft.Left -2, ShadowLeft.Top, ShadowLeft.Right, ShadowLeft.Top);
    FGraphics.DrawLine(FTickPen, ShadowRight.Left, ShadowRight.Top, ShadowRight.Right +2, ShadowRight.Top);
    FGraphics.DrawLine(FTickPen, ShadowLeft.Left -2, ShadowLeft.Bottom, ShadowLeft.Right, ShadowLeft.Bottom);
    FGraphics.DrawLine(FTickPen, ShadowRight.Left, ShadowRight.Bottom, ShadowRight.Right +2, ShadowRight.Bottom);
    { Draw Ticks in between the top and bottom }
    TickHeight := Round(ShadowLeft.Height / (Ticks.TickCount + 1));
    for I := 1 to Ticks.TickCount do
    begin
      FGraphics.DrawLine(FTickPen, ShadowLeft.Left, ShadowLeft.Top + (TickHeight * I), ShadowLeft.Right, ShadowLeft.Top + (TickHeight * I));
      FGraphics.DrawLine(FTickPen, ShadowRight.Left, ShadowRight.Top + (TickHeight * I), ShadowRight.Right, ShadowRight.Top + (TickHeight * I));
    end;
  end;

  function RoundRectPath(Rect: TRect; Corner: Integer) : IGPGraphicsPath;
  var
    RoundRectPath : IGPGraphicsPath;
  begin
    RoundRectPath := TGPGraphicsPath.Create;
    RoundRectPath.AddArc(Rect.Left, Rect.Top, Corner, Corner, 180, 90);
    RoundRectPath.AddArc(Rect.Right - Corner, Rect.Top, Corner, Corner, 270, 90);
    RoundRectPath.AddArc(Rect.Right - Corner, Rect.Bottom - Corner, Corner, Corner, 0, 90);
    RoundRectPath.AddArc(Rect.Left, Rect.Bottom - Corner, Corner, Corner, 90, 90);
    RoundRectPath.CloseFigure;
    Result := RoundRectPath;
  end;

  procedure DrawSlider(var FGraphics: IGPGraphics; const SliderColor: TColor);
  var
    FBorderBrush : IGPSolidBrush;
    FShadowBrush : IGPSolidBrush;
    FShadowColor : TGPColor;
    FGrad1Brush  : IGPLinearGradientBrush;
    FGrad2Brush  : IGPLinearGradientBrush;
    FGrad3Brush  : IGPLinearGradientBrush;
    FGrad4Brush  : IGPLinearGradientBrush;
    FGrad5Brush  : IGPLinearGradientBrush;
    FGrad4Path   : IGPGraphicsPath;
    FGrad5Path   : IGPGraphicsPath;
  var
    ShadowRect, GradRect3 : TRect;
  var
    PartsHeight : Integer;
  begin
    { Calculate the rect for the slider - **edit here for position** }
    SliderRect := Rect(
      (ClientRect.Left + (ClientWidth div 2)) - (Slider.Width div 2),
      RangeTop - Ceil(Slider.Length / 2),
      (ClientRect.Left + (ClientWidth div 2)) + (Slider.Width div 2),
      RangeTop + Ceil(Slider.Length / 2)
    );
    PartsHeight := SliderRect.Height div 3;
    ShadowRect  := SliderRect;
    InflateRect(ShadowRect, 1, 0);
    ShadowRect.Bottom := ShadowRect.Bottom + 4;
    { Create Brushes }
    FBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Slider.BorderColor));
    FShadowColor := TGPColor.CreateFromColorRef(Darken(Slider.BorderColor, 80));
    FShadowColor.Alpha := 60;
    FShadowBrush := TGPSolidBrush.Create(FShadowColor);
    { Draw the border and the shadow }
    case Slider.Shape of
      ssRoundRect :
      begin
        FGraphics.FillPath(FBorderBrush, RoundRectPath(SliderRect, Slider.CornerSize));
        FGraphics.FillPath(FShadowBrush, RoundRectPath(ShadowRect, Slider.CornerSize + 4));
      end;

      ssRectangle :
      begin
        FGraphics.FillRectangle(FBorderBrush, TGPRect.Create(SliderRect));
        FGraphics.FillRectangle(FShadowBrush, TGPRect.Create(ShadowRect));
      end;
    end;
    InflateRect(FSliderRect, -1, -1);
    { First Gradient Layer }
    FGrad1Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(WorkRect),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 10)),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 20)),
      90);
    FGraphics.FillPath(FGrad1Brush, RoundRectPath(SliderRect, Slider.CornerSize));
    InflateRect(FSliderRect, -1, -1);
    { Second Gradient Layer }
    FGrad2Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(SliderRect),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 80)),
      TGPColor.CreateFromColorRef(SliderColor),
      90);
    FGraphics.FillRectangle(FGrad2Brush, TGPRect.Create(SliderRect));
    { Third Gradient Layer (Center of the Slider) }
    GradRect3 := Rect(
      SliderRect.Left,
      SliderRect.Top + ((SliderRect.Height div 2) - PartsHeight),
      SliderRect.Right,
      SliderRect.Top + (SliderRect.Height div 2) + PartsHeight
    );
    FGrad3Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(GradRect3),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 25)),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 50)),
      90);
    FGraphics.FillRectangle(FGrad3Brush, TGPRect.Create(GradRect3));
    InflateRect(FSliderRect, 0, -1);
    { Fourth Gradient Layer (Top to center) }
    FGrad4Path := TGPGraphicsPath.Create;
    FGrad4Path.AddLines([
      TGPPoint.Create(SliderRect.Left, SliderRect.Top),
      TGPPoint.Create(SliderRect.Right, SliderRect.Top),
      TGPPoint.Create(SliderRect.Right - 2, SliderRect.Top + PartsHeight),
      TGPPoint.Create(SliderRect.Left + 2, SliderRect.Top + PartsHeight)
    ]);
    FGrad4Path.CloseFigure;
    FGrad4Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(SliderRect.Left, SliderRect.Top -2, SliderRect.Right, PartsHeight +2),
      TGPColor.CreateFromColorRef(Darken(SliderColor, 10)),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 90)),
      90);
    FGraphics.FillPath(FGrad4Brush, FGrad4Path);
    { Fifth Gradient Layer (Bottom to center) }
    FGrad5Path := TGPGraphicsPath.Create;
    FGrad5Path.AddLines([
      TGPPoint.Create(SliderRect.Left +2, (SliderRect.Top + (PartsHeight *2)) -4),
      TGPPoint.Create(SliderRect.Right -2, (SliderRect.Top + (PartsHeight * 2)) -4),
      TGPPoint.Create(SliderRect.Right, SliderRect.Bottom),
      TGPPoint.Create(SliderRect.Left, SliderRect.Bottom)
    ]);
    FGrad5Path.CloseFigure;
    FGrad5Brush := TGPLinearGradientBrush.Create(
      TGPRect.Create(SliderRect.Left, SliderRect.Top + ((PartsHeight * 2) - 2), SliderRect.Width, PartsHeight + 2),
      TGPColor.CreateFromColorRef(Darken(SliderColor, 30)),
      TGPColor.CreateFromColorRef(Brighten(SliderColor, 40)),
      90);
    FGraphics.FillPath(FGrad5Brush, FGrad5Path);
    { Draw Line in center }
    FGraphics.FillRectangle(FBorderBrush, TGPRect.Create(SliderRect.Left + 1, SliderRect.Top + ((Slider.Length div 2) - 3), SliderRect.Width - 2, 1));
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  { Draw the trackbar to the buffer }
  if RedrawTrackBar then
  begin
    RedrawTrackBar := False;
    WorkRect := ClientRect;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Draw to buffer }
    CalculateRangeTop;
    DrawBackground;
    DrawRange(FGraphics);
    DrawTicks(FGraphics);
    if Focused then
      DrawSlider(FGraphics, Slider.ActiveColor)
    else
      DrawSlider(FGraphics, Slider.Color);

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

procedure TERDVolumeTrackBar.Resize;
begin
  RedrawTrackbar := True;
  inherited;
end;

procedure TERDVolumeTrackBar.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDVolumeTrackBar.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        RedrawTrackbar := True;
        Invalidate;
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        RedrawTrackbar := True;
        Invalidate;
      end;

    { Focus is lost }
    WM_KILLFOCUS:
      begin
        {  }
        RedrawTrackbar := True;
        Invalidate;
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        {  }
        RedrawTrackbar := True;
        Invalidate;
      end;
  end;
end;

procedure TERDVolumeTrackBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Enabled then
  begin
    if (not Focused) and CanFocus then SetFocus;
    if PtInRect(SliderRect, Point(X, Y)) then FDragging := True;
    Position := (PositionAtCoords(X, Y) * Step);
    Invalidate;
  end;
  inherited;
end;

procedure TERDVolumeTrackBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  FDragging := False;
  inherited;
end;

procedure TERDVolumeTrackBar.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
begin
  if FDragging then Position := (PositionAtCoords(X, Y) * Step);
  inherited;
end;

function TERDVolumeTrackBar.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint) : Boolean;
begin
  inherited;
  { During designtime there is no need for these events }
  if (csDesigning in ComponentState) then Exit;
  { Ignore when the component is disabled }
  if not Enabled then Exit;
  { Move the knob by the mousewheel }
  if WheelDelta < 0 then
  begin
    if (Position > 0) then Position := Position - Step;
  end else
  begin
    if (Position < Max) then Position := Position + Step;
  end;
  Result := True;
end;

procedure TERDVolumeTrackBar.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_DOWN) then
  begin
    if (Position > 1) then Position := Position - 1;
  end else
  if (Key = VK_UP) then
  begin
    if (Position < Max) then Position := Position + 1;
  end;
  inherited;
end;

function TERDVolumeTrackBar.PositionAtCoords(const X, Y: Integer) : Integer;
var
  RY : Integer;
begin
  RY := (RangeRect.Bottom - Ceil(Slider.Length / 2)) - (Y - RangeRect.Top);
  Result := Round(RY / (RangeRect.Height / (Max - Min)));
end;

end.
