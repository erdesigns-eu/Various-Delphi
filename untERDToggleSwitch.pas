{
  untERDToggleSwitch v1.0.0 - a simple customizable toggle Switch
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDToggleSwitch;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDToggleSwitchChangeEvent = procedure(Sender: TObject; Checked: Boolean) of object;

  TERDToggleSwitchShape     = (shRoundRect, shRect);
  TERDToggleSwitchTextAlign = (taInside, taOutside);

  TERDToggleSwitchStateIndicator = class(TPersistent)
  private
    { Private declarations }
    FShape   : TERDToggleSwitchShape;
    FOnText  : TCaption;
    FOffText : TCaption;
    FColor   : TColor;
    FBorder  : TColor;

    FOnChange : TNotifyEvent;

    procedure SetShape(const S: TERDToggleSwitchShape);
    procedure SetOnText(const S: TCaption);
    procedure SetOffText(const S: TCaption);
    procedure SetColor(const C: TColor);
    procedure SetBorder(const C: TColor);
  protected
    { Protected declarations }
    procedure OnSettingsChanged(Sender: TObject);
  public
    { Public declarations }
    constructor Create; virtual;

    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Shape: TERDToggleSwitchShape read FShape write SetShape default shRoundRect;
    property OnText: TCaption read FOnText write SetOnText;
    property OffText: TCaption read FOffText write SetOffText;
    property Color: TColor read FColor write SetColor default $00E5E5D5;
    property Border: TColor read FBorder write SetBorder default 00494238;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDToggleSwitch = class(TCustomControl)
  private
    { Private declarations }
    FAlign           : TERDToggleSwitchTextAlign;
    FStateIndicator  : TERDToggleSwitchStateIndicator;
    FBorder          : TColor;
    FBorderWidth     : Integer;
    FBackground      : TColor;
    FChecked         : Boolean;
    FOnChange        : TERDToggleSwitchChangeEvent;
    FDrawFocusRect   : Boolean;
    FSwitchMouseDown : Boolean;

    { Buffer - Avoid flickering }
    FBuffer      : TBitmap;
    FUpdateRect  : TRect;
    FRedraw      : Boolean;

    { Position of the Indicator }
    FIndicatorRect : TRect;

    procedure SetAlign(const A: TERDToggleSwitchTextAlign);
    procedure SetStateIndicator(const I: TERDToggleSwitchStateIndicator);
    procedure SetBorder(const C: TColor);
    procedure SetBorderWidth(const I: Integer);
    procedure SetBackground(const C: TColor);
    procedure SetChecked(B: Boolean);

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
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property RedrawToggle: Boolean read FRedraw write FRedraw;
    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
  published
    { Published declarations }
    property TextAlign: TERDToggleSwitchTextAlign read FAlign write SetAlign default taInside;
    property StateIndicator: TERDToggleSwitchStateIndicator read FStateIndicator write SetStateIndicator;

    property Border: TColor read FBorder write SetBorder default $00494238;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property Background: TColor read FBackground write SetBackground default $00585349;
    property Checked: Boolean read FChecked write SetChecked default False;
    property DrawFocusRect: Boolean read FDrawFocusRect write FDrawFocusRect default True;

    property OnChange: TERDToggleSwitchChangeEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
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
  { Toggle fixed measurements }
  ToggleHeight = 24;
  ToggleCorner = 6;
  ToggleSpace  = 8;

(******************************************************************************)
(*
(*  ERD Toggle Switch Indicator (TERDToggleSwitchStateIndicator)
(*
(******************************************************************************)
constructor TERDToggleSwitchStateIndicator.Create;
begin
  inherited Create;
  FShape    := shRoundRect;
  FOnText   := 'ON';
  FOffText  := 'OFF';
  FColor    := $00E5E5D5;
  FBorder   := $00494238;
end;

procedure TERDToggleSwitchStateIndicator.Assign(Source: TPersistent);
begin
  if Source is TERDToggleSwitchStateIndicator then
  begin
    FShape    := TERDToggleSwitchStateIndicator(Source).Shape;
    FOnText   := TERDToggleSwitchStateIndicator(Source).OnText;
    FOffText  := TERDToggleSwitchStateIndicator(Source).OffText;
    FColor    := TERDToggleSwitchStateIndicator(Source).Color;
    FBorder   := TERDToggleSwitchStateIndicator(Source).Border;
  end else
    inherited;
end;

procedure TERDToggleSwitchStateIndicator.SetShape(const S: TERDToggleSwitchShape);
begin
  if S <> Shape then
  begin
    FShape := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDToggleSwitchStateIndicator.SetOnText(const S: TCaption);
begin
  if S <> OnText then
  begin
    FOnText := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDToggleSwitchStateIndicator.SetOffText(const S: TCaption);
begin
  if S <> OffText then
  begin
    FOffText := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDToggleSwitchStateIndicator.SetColor(const C: TColor);
begin
  if C <> Color then
  begin
    FColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDToggleSwitchStateIndicator.SetBorder(const C: TColor);
begin
  if C <> Border then
  begin
    FBorder := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TERDToggleSwitchStateIndicator.OnSettingsChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

(******************************************************************************)
(*
(*  ERD Toggle Switch (TERDToggleSwitch)
(*
(******************************************************************************)
constructor TERDToggleSwitch.Create(AOwner: TComponent);
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

  { Width / Height }
  Width  := 121;
  Height := 33;

  { State Indicator }
  FStateIndicator := TERDToggleSwitchStateIndicator.Create;
  FStateIndicator.OnChange := SettingsChanged;

  { Defaults }
  FAlign := taInside;
  FBorderWidth := 1;
  FBorder      := $00494238;
  FBackground  := $00585349;

  Font.Color := $00E5E5D5;
  Font.Name  := 'Segoe UI';

  FDrawFocusRect := True;

  { Initial Draw }
  RedrawToggle := True;
end;

destructor TERDToggleSwitch.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  { Free State Indicator }
  FStateIndicator.Free;

  inherited Destroy;
end;

procedure TERDToggleSwitch.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDToggleSwitch.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDToggleSwitch.SettingsChanged(Sender: TObject);
begin
  RedrawToggle := True;
  Invalidate;
end;

procedure TERDToggleSwitch.SetAlign(const A: TERDToggleSwitchTextAlign);
begin
  if FAlign <> A then
  begin
    FAlign := A;
    SettingsChanged(Self);
  end;
end;

procedure TERDToggleSwitch.SetStateIndicator(const I: TERDToggleSwitchStateIndicator);
begin
  if StateIndicator <> I then
  begin
    FStateIndicator.Assign(I);
    SettingsChanged(Self);
  end;
end;

procedure TERDToggleSwitch.SetBorder(const C: TColor);
begin
  if Border <> C then
  begin
    FBorder := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDToggleSwitch.SetBorderWidth(const I: Integer);
begin
 if BorderWidth <> I then
  begin
    FBorderWidth := I;
    SettingsChanged(Self);
  end;
end;

procedure TERDToggleSwitch.SetBackground(const C: TColor);
begin
  if Background <> C then
  begin
    FBackground := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDToggleSwitch.SetChecked(B: Boolean);
begin
  if Checked <> B then
  begin
    FChecked := B;
    if Assigned(FOnChange) then FOnChange(Self, B);
    SettingsChanged(Self);
  end;
end;

procedure TERDToggleSwitch.Paint;
var
  WorkRect : TRect;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(ClipRect);
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

  function RectPath(Rect: TRect) : IGPGraphicsPath;
  var
    RectPath : IGPGraphicsPath;
  begin
    RectPath := TGPGraphicsPath.Create;
    RectPath.AddRectangle(TGPRect.Create(Rect));
    Result := RectPath;
  end;

  procedure DrawTogglebackground(var FGraphics : IGPGraphics);
  var
    Path          : IGPGraphicsPath;
    FBorder       : TGPColor;
    FInnerBrush   : IGPLinearGradientBrush;
    FBorderBrush  : IGPSolidBrush;
  begin
    { Create Path }
    case StateIndicator.Shape of
      shRoundRect : Path := RoundRectPath(WorkRect, ToggleCorner);
      shRect      : Path := RectPath(WorkRect);
    end;
    { Create brushes and colors }
    FBorder  := TGPColor.CreateFromColorRef(Border);
    FBorderBrush := TGPSolidBrush.Create(FBorder);
    FInnerBrush  := TGPLinearGradientBrush.Create(
      TGPRect.Create(WorkRect),
      TGPColor.CreateFromColorRef(Background),
      TGPColor.CreateFromColorRef(Brighten(Background, 30)),
      90);
    { Draw border }
    FGraphics.FillPath(FBorderBrush, Path);
    { Draw Background }
    InflateRect(WorkRect, -BorderWidth, -BorderWidth);
    case StateIndicator.Shape of
      shRoundRect : Path := RoundRectPath(WorkRect, ToggleCorner);
      shRect      : Path := RectPath(WorkRect);
    end;
    FGraphics.FillPath(FInnerBrush, Path);
  end;

  procedure DrawOnOffText(var FGraphics : IGPGraphics);
  var
    FFontBrush   : IGPSolidBrush;
    FFont        : TGPFont;
    FMeasureRect : TGPRectF;
  begin
    { Create Brush and Font }
    FFontBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Font.Color));
    if fsBold in Font.Style then
      FFont := TGPFont.Create(Font.Name, Font.Size, [FontStyleBold])
    else
      FFont := TGPFont.Create(Font.Name, Font.Size, []);
    { Draw Outside }
    if TextAlign = taOutside then
    begin
      { Measure and draw ON text }
      FMeasureRect := FGraphics.MeasureString(StateIndicator.OnText, FFont, TGPPointF.Create(0, 0));
      FGraphics.DrawString(StateIndicator.OnText, FFont, TGPPointF.Create(0, (ClientHeight div 2 - Round(FMeasureRect.Height / 2)) +1), FFontBrush);
      { Measure and draw OFF text }
      FMeasureRect := FGraphics.MeasureString(StateIndicator.OffText, FFont, TGPPointF.Create(0, 0));
      FGraphics.DrawString(StateIndicator.OffText, FFont, TGPPointF.Create(Round((ClientRect.Right -1) - FMeasureRect.Width), (ClientHeight div 2 - Round(FMeasureRect.Height / 2)) +1), FFontBrush);
    end else
    { Draw Inside }
    begin
      { Measure and draw ON text }
      FMeasureRect := FGraphics.MeasureString(StateIndicator.OnText, FFont, TGPPointF.Create(0, 0));
      FGraphics.DrawString(StateIndicator.OnText, FFont, TGPPointF.Create(WorkRect.Left + ToggleSpace, (Round(ClientHeight div 2) - Round(FMeasureRect.Height / 2)) +1), FFontBrush);
      { Measure and draw OFF text }
      FMeasureRect := FGraphics.MeasureString(StateIndicator.OffText, FFont, TGPPointF.Create(0, 0));
      FGraphics.DrawString(StateIndicator.OffText, FFont, TGPPointF.Create(Round(((ClientRect.Right -1) - ToggleSpace) - FMeasureRect.Width), (ClientHeight div 2 - Round(FMeasureRect.Height / 2)) +1), FFontBrush);
    end;
  end;

  procedure DrawStateIndicator(var FGraphics : IGPGraphics);
  var
    Path          : IGPGraphicsPath;
    FInnerBrush   : IGPLinearGradientBrush;
    FBorderBrush  : IGPSolidBrush;
    FBorderShadow : IGPSolidBrush;
  var
    GripRect : TRect;
  begin
    { Calculate Indicator Rect }
    FIndicatorRect := WorkRect;
    if TextAlign = taInside then
    begin
      case Checked of
        True:
        begin
          FIndicatorRect.Left  := WorkRect.Right - (WorkRect.Width div 2);
          FIndicatorRect.Right := WorkRect.Right;
        end;
        False:
        begin
          FIndicatorRect.Left := WorkRect.Left;
          FIndicatorRect.Right := WorkRect.Left + WorkRect.Width div 2;
        end;
      end;
    end else
    begin
      case Checked of
        True:
        begin
          FIndicatorRect.Left := WorkRect.Left;
          FIndicatorRect.Right := WorkRect.Left + WorkRect.Width div 2;
        end;
        False:
        begin
          FIndicatorRect.Left  := WorkRect.Right - (WorkRect.Width div 2);
          FIndicatorRect.Right := WorkRect.Right;
        end;
      end;
    end;
    { Create Path }
    case StateIndicator.Shape of
      shRoundRect : Path := RoundRectPath(FIndicatorRect, ToggleCorner);
      shRect      : Path := RectPath(FIndicatorRect);
    end;
    { Create brushes and colors }
    FBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(StateIndicator.Border));
    FInnerBrush  := TGPLinearGradientBrush.Create(
      TGPRect.Create(FIndicatorRect),
      TGPColor.CreateFromColorRef(StateIndicator.Color),
      TGPColor.CreateFromColorRef(Darken(StateIndicator.Color, 30)),
      90);
    { Draw border }
    FGraphics.FillPath(FBorderBrush, Path);
    { Draw Background }
    InflateRect(FIndicatorRect, -1, -1);
    case StateIndicator.Shape of
      shRoundRect : Path := RoundRectPath(FIndicatorRect, ToggleCorner);
      shRect      : Path := RectPath(FIndicatorRect);
    end;
    FGraphics.FillPath(FInnerBrush, Path);
    FBorderShadow := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(StateIndicator.Color, 70)));
    { Create the grip rect }
    GripRect.Left   := (FIndicatorRect.Left + (FIndicatorRect.Width div 2)) - 2;
    GripRect.Top    := FIndicatorRect.Top + 3;
    GripRect.Right  := GripRect.Left + 1;
    GripRect.Bottom := FIndicatorRect.Bottom - 3;
    { Draw the grip }
    FGraphics.FillRectangle(FBorderShadow, TGPRect.Create(GripRect));
    GripRect.Left   := GripRect.Left + 4;
    GripRect.Right  := GripRect.Left +1;
    FGraphics.FillRectangle(FBorderShadow, TGPRect.Create(GripRect));
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  if RedrawToggle then
  begin
    RedrawToggle := False;

    {  Create toggle clientrect }
    WorkRect.Left   := ClientRect.Left + 1;
    WorkRect.Right  := ClientRect.Right -2;
    WorkRect.Top    := (ClientRect.Height div 2) - (ToggleHeight div 2);
    WorkRect.Bottom := WorkRect.Top + ToggleHeight;
    if TextAlign = taInside then InflateRect(WorkRect, -2, 0);
    if TextAlign = taOutside then
    with FBuffer.Canvas do
    begin
      Font := Self.Font;
      WorkRect.Left  := WorkRect.Left + (TextWidth(StateIndicator.OnText) + ToggleSpace);
      WorkRect.Right := WorkRect.Right - (TextWidth(StateIndicator.OffText) + ToggleSpace);
    end;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Background }
    DrawBackground;
    DrawTogglebackground(FGraphics);

    { Draw on/off text }
    DrawOnOffText(FGraphics);

    { Draw State Indicator }
    DrawStateIndicator(FGraphics);

    { Focus Rect }
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

procedure TERDToggleSwitch.Resize;
begin
  SettingsChanged(Self);
  inherited;
end;

procedure TERDToggleSwitch.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDToggleSwitch.WndProc(var Message: TMessage);
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
        if DrawFocusRect then
          SettingsChanged(Self)
        else
          Invalidate;
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        {  }
        if DrawFocusRect then
          SettingsChanged(Self)
        else
          Invalidate;
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

procedure TERDToggleSwitch.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if (not Focused) and CanFocus then SetFocus;
  if X < (ClientWidth div 2) then
  begin
    case TextAlign of
      taInside  : Checked := False;
      taOutside : Checked := True;
    end;
  end else
  begin
    case TextAlign of
      taInside  : Checked := True;
      taOutside : Checked := False;
    end;
  end;
  if PtInRect(FIndicatorRect, Point(X, Y)) then FSwitchMouseDown := True;
  inherited;
end;

procedure TERDToggleSwitch.MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if FSwitchMouseDown then FSwitchMouseDown := False;
end;

procedure TERDToggleSwitch.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
begin
  if FSwitchMouseDown then
  begin
    if X < (ClientWidth div 2) then
    begin
      case TextAlign of
        taInside  : Checked := False;
        taOutside : Checked := True;
      end;
    end else
    begin
      case TextAlign of
        taInside  : Checked := True;
        taOutside : Checked := False;
      end;
    end;
  end;
end;

procedure TERDToggleSwitch.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_LEFT) then
  begin
    case TextAlign of
      taInside  : Checked := False;
      taOutside : Checked := True;
    end;
  end else
  if (Key = VK_RIGHT) then
  begin
    case TextAlign of
      taInside  : Checked := True;
      taOutside : Checked := False;
    end;
  end;
  inherited;
end;

end.
