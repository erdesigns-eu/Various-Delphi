{
  untERDCaptionPanel v1.0.0 - a simple Caption Panel in the style of FL-Studio
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Midi Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDCaptionPanel;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDCaptionPanel = class(TCustomControl)
  private
    { Private declarations }
    FBorderColor    : TColor;
    FBorderWidth    : Integer;
    FCanCollapse    : Boolean;
    FCollapsed      : Boolean;
    FCornerLength   : Integer;
    FCornerColor    : TColor;
    FCollapseWidth  : Integer;
    FCollapseCursor : TCursor;

    { Buffer - Avoid flickering }
    FBuffer       : TBitmap;
    FUpdateRect   : TRect;
    FRedraw       : Boolean;
    FCollapseRect : TRect;

    { "Old" height and width, stored for when collapsed }
    FExpandedHeight : Integer;
    { Height when collapsed - only the caption is visible }
    FCollapseHeight : Integer;

    FOnCollapse : TNotifyEvent;

    procedure SetBorderColor(const C: TColor);
    procedure SetBorderWidth(const I: Integer);
    procedure SetCanCollapse(const B: Boolean);
    procedure SetCollapsed(const B: Boolean);
    procedure SetCornerLength(const I: Integer);
    procedure SetCornerColor(const C: TColor);
    procedure SetCollapseWidth(const I: Integer);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property RedrawPanel: Boolean read FRedraw write FRedraw;
    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property CollapseRect: TRect read FCollapseRect write FCollapseRect;
  published
    { Published declarations }
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00494238;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property CanCollapse: Boolean read FCanCollapse write SetCanCollapse default True;
    property Collapsed: Boolean read FCollapsed write SetCollapsed default False;
    property CornerLength: Integer read FCornerLength write SetCornerLength default 20;
    property CornerColor: TColor read FCornerColor write SetCornerColor default $00554E44;
    property CollapseWidth: Integer read FCollapseWidth write SetCollapseWidth default 2;
    property CollapseCursor: TCursor read FCollapseCursor write FCollapseCursor default crHandPoint;

    property OnCollapse: TNotifyEvent read FOnCollapse write FOnCollapse;

    property Align;
    property Anchors;
    property Caption;
    property Color default $00585349;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Touch;
    property Visible;
    property ParentFont;
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

uses System.Math;

const
  { Spacing for the caption }
  HorzSpacing = 8;
  VertSpacing = 8;

const
  { Collapse size }
  CollapHeight = 6;
  CollapWidth  = 12;
  { Collapse Spacing }
  CollapHorzSpacing = 12;
  CollapVertSpacing = 12;

(******************************************************************************)
(*
(*  ERD Caption Panel (TERDCaptionPanel)
(*
(******************************************************************************)
constructor TERDCaptionPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We do want the control to accept controls - because this is
    a panel afterall :) }
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls,
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We dont want to be able to get focus, this is a panel so its just a parent
    for other components to put on/in }
  TabStop := False;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Width / Height }
  Width  := 321;
  Height := 185;

  { Defaults }
  FBorderColor    := $00494238;
  FBorderWidth    := 1;
  FCanCollapse    := True;
  FCollapsed      := False;
  FCornerLength   := 20;
  FCornerColor    := $00554E44;
  FCollapseWidth  := 2;
  FCollapseCursor := crHandPoint;

  Caption := Name;
  Color := $00585349;
  Font.Name  := 'Segoe UI';
  Font.Color := $00E5E5D5;
  Font.Style := [fsBold];

  { Initial Draw }
  RedrawPanel := True;
end;

destructor TERDCaptionPanel.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  inherited Destroy;
end;

procedure TERDCaptionPanel.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDCaptionPanel.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDCaptionPanel.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    RedrawPanel  := True;
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.SetBorderWidth(const I: Integer);
begin
  if BorderWidth <> I then
  begin
    if I < 1 then
      FBorderWidth := 1
    else
      FBorderWidth := I;
    RedrawPanel  := True;
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.SetCanCollapse(const B: Boolean);
begin
  if CanCollapse <> B then
  begin
    FCanCollapse := B;
    RedrawPanel  := True;
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.SetCollapsed(const B: Boolean);
begin
  if Collapsed <> B then
  begin
    FCollapsed  := B;
    if B then
    begin
      FExpandedHeight := Height;
      Height          := FCollapseHeight;
    end else
    begin
      Height := FExpandedHeight;
    end;
    RedrawPanel := True;
    { Resize to full size or to caption only }
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.SetCornerLength(const I: Integer);
begin
  if CornerLength <> I then
  begin
    FCornerLength := I;
    RedrawPanel   := True;
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.SetCornerColor(const C: TColor);
begin
  if CornerColor <> C then
  begin
    FCornerColor := C;
    RedrawPanel  := True;
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.SetCollapseWidth(const I: Integer);
begin
  if CollapseWidth <> I then
  begin
    FCollapseWidth := I;
    RedrawPanel := True;
    Invalidate;
  end;
end;

procedure TERDCaptionPanel.Paint;
var
  WorkRect: TRect;

  procedure DrawBackground;
  var
    I : Integer;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      Pen.Color   := BorderColor;
      FillRect(WorkRect);
      for I := 1 to BorderWidth do
      begin
        Rectangle(WorkRect);
        InflateRect(WorkRect, -1, -1);
      end;
    end;
  end;

  procedure DrawCaption(var FGraphics: IGPGraphics);
  var
    FPen         : IGPPen;
    FFont        : TGPFont;
    FFontBrush   : IGPSolidBrush;
    FSolidBrush  : IGPSolidBrush;
    FFontRect    : TGPRectF;
    FCaptionPath : IGPGraphicsPath;
  begin
    WorkRect.Top  := ClientRect.Top;
    WorkRect.Left := ClientRect.Left;
    if fsBold in Font.Style then
      FFont := TGPFont.Create(Font.Name, Font.Size, [FontStyleBold])
    else
      FFont := TGPFont.Create(Font.Name, Font.Size, []);
    FFontRect  := FGraphics.MeasureString(Caption, FFont, TGPPointF.Create(0, 0));
    FFontBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Font.Color));
    FCaptionPath := TGPGraphicsPath.Create;
    FCaptionPath.AddLines([
      TGPPoint.Create(WorkRect.Left, WorkRect.Top),
      TGPPoint.Create(Ceil(WorkRect.Left + (HorzSpacing * 2) + FFontRect.Width + CornerLength), WorkRect.Top),
      TGPPoint.Create(Ceil(WorkRect.Left + (HorzSpacing * 2) + FFontRect.Width), Ceil(WorkRect.Top + (2 * VertSpacing) + FFontRect.Height)),
      TGPPoint.Create(WorkRect.Left, Ceil(WorkRect.Top + (2 * VertSpacing) + FFontRect.Height))
    ]);
    { Set height when collapsed }
    FCollapseHeight := Ceil(WorkRect.Top + (2 * VertSpacing) + FFontRect.Height);
    Padding.Top     := FCollapseHeight;
    FSolidBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(CornerColor));
    FPen        := TGPPen.Create(TGPColor.CreateFromColorRef(BorderColor));
    FPen.Width  := BorderWidth;
    FGraphics.FillPath(FSolidBrush, FCaptionPath);
    FGraphics.DrawPath(FPen, FCaptionPath);
    FGraphics.DrawString(Caption, FFont, TGPPointF.Create(WorkRect.Left + HorzSpacing, WorkRect.Top + VertSpacing), FFontBrush);
  end;

  procedure DrawCollapse(var FGraphics: IGPGraphics);
  var
    FPen          : IGPPen;
    FCollapsePath : IGPGraphicsPath;
  begin
    FPen       := TGPPen.Create(TGPColor.CreateFromColorRef(Font.Color));
    FPen.Width := CollapseWidth;
    FCollapsePath := TGPGraphicsPath.Create;
    { Set rect for the collapse - so we can react on a click on the collapse }
    FCollapseRect := Rect(
      WorkRect.Right - (CollapHorzSpacing + CollapWidth),
      WorkRect.Top + CollapVertSpacing,
      WorkRect.Right - CollapHorzSpacing,
      WorkRect.Top + CollapVertSpacing + CollapHeight
    );
    InflateRect(FCollapseRect, 4, 4);
    if Collapsed then
    begin
      { Draw Expand Icon }
      FGraphics.DrawLines(FPen, [
        TGPPoint.Create(WorkRect.Right - (CollapHorzSpacing + CollapWidth), WorkRect.Top + CollapVertSpacing),
        TGPPoint.Create(WorkRect.Right - (CollapHorzSpacing + (CollapWidth div 2)), WorkRect.Top + CollapVertSpacing + CollapHeight),
        TGPPoint.Create(WorkRect.Right - CollapHorzSpacing, WorkRect.Top + CollapVertSpacing)
      ]);
    end else
    begin
      { Draw Collapse Icon  }
      FGraphics.DrawLines(FPen, [
        TGPPoint.Create(WorkRect.Right - (CollapHorzSpacing + CollapWidth), WorkRect.Top + CollapVertSpacing + CollapHeight),
        TGPPoint.Create(WorkRect.Right - (CollapHorzSpacing + (CollapWidth div 2)), WorkRect.Top + CollapVertSpacing),
        TGPPoint.Create(WorkRect.Right - CollapHorzSpacing, WorkRect.Top + CollapVertSpacing + CollapHeight)
      ]);
    end;
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H : Integer;
begin
  { Draw the panel to the buffer }
  if RedrawPanel then
  begin
    RedrawPanel := False;
    WorkRect := ClientRect;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Draw to buffer }
    DrawBackground;
    DrawCaption(FGraphics);
    if CanCollapse then
      DrawCollapse(FGraphics);
  end;

  if CanCollapse and Collapsed and (Height < FCollapseHeight) then
    Height := FCollapseHeight;

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

procedure TERDCaptionPanel.Resize;
begin
  RedrawPanel := True;
  inherited;
end;

procedure TERDCaptionPanel.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDCaptionPanel.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        RedrawPanel := True;
        Invalidate;
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        RedrawPanel := True;
        Invalidate;
      end;

    { Caption changed }
    CM_TEXTCHANGED:
      begin
        RedrawPanel := True;
        Invalidate;
      end;

    { Font Changed }
    CM_FONTCHANGED:
      begin
        RedrawPanel := True;
        Invalidate;
      end;
  end;
end;

procedure TERDCaptionPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if Enabled then
  begin
    if PtInRect(FCollapseRect, Point(X, Y)) then Collapsed := not Collapsed;
    if Assigned(FOnCollapse) then FOnCollapse(Self);
    Invalidate;
  end;
  inherited;
end;

procedure TERDCaptionPanel.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
begin
  if PtInRect(FCollapseRect, Point(X, Y)) then
  begin
    if Cursor <> CollapseCursor then Cursor := CollapseCursor;
  end else
  begin
    if Cursor <> crDefault then Cursor := crDefault;
  end;
  inherited;
end;

end.
