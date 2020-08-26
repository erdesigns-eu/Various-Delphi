{
  untERDLedSign v1.0.0 - a simple led sign - Like a ON-AIR sign
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDLedSign;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDLedSignShape = (lssRoundRect, lssRect);
  TERDLedSignState = (lssOff, lssOn);

  TERDLedSign = class(TGraphicControl)
  private
    { Private declarations }
    FShape       : TERDLedSignShape;
    FState       : TERDLedSignState;
    FBorderWidth : Integer;
    FBorderColor : TColor;
    FLedOnColor  : TColor;
    FLedOffColor : TColor;

    { Buffer - Avoid flickering }
    FBuffer : TBitmap;
    FRedraw : Boolean;

    procedure SetShape(const S: TERDLedSignShape);
    procedure SetState(const S: TERDLedSignState);
    procedure SetBorderWidth(const I: Integer);
    procedure SetBorderColor(const C: TColor);
    procedure SetOnColor(const C: TColor);
    procedure SetOffColor(const C: TColor);
  protected
    { Protected declarations }
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
    property Shape: TERDLedSignShape read FShape write SetShape default lssRoundRect;
    property State: TERDLedSignState read FState write SetState default lssOff;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $008F8A87;
    property LedOnColor: TColor read FLedOnColor write SetOnColor default $004347DD;
    property LedOffColor: TColor read FLedOffColor write SetOffColor default $008F8A87;

    property Align;
    property Anchors;
    property Caption;
    property Color default clWhite;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property ParentFont;
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
(*  ERD LED Sign (TERDLedSign)
(*
(******************************************************************************)
constructor TERDLedSign.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Transparent background }
  ControlStyle := ControlStyle + [csOpaque];

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Defaults }
  FState       := lssOff;
  FShape       := lssRoundRect;
  FBorderWidth := 1;
  FBorderColor := $008F8A87;
  FLedOnColor  := $004347DD;
  FLedOffColor := $008F8A87;

  { Set default width and height }
  Width  := 209;
  Height := 97;

  Font.Name  := 'Segoe UI';
  Font.Color := clWhite;
  Font.Style := [fsBold];
  Font.Size  := 24;
  Caption    := 'ON AIR';

  { Draw for the first time }
  Redraw := True;
end;

destructor TERDLedSign.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  inherited Destroy;
end;

procedure TERDLedSign.SetShape(const S: TERDLedSignShape);
begin
  if Shape <> S then
  begin
    FShape := S;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDLedSign.SetState(const S: TERDLedSignState);
begin
  if State <> S then
  begin
    FState := S;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDLedSign.SetBorderWidth(const I: Integer);
begin
  if BorderWidth <> I then
  begin
    if I < 0 then
      FBorderWidth := 0
    else
      FBorderWidth := I;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDLedSign.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDLedSign.SetOnColor(const C: TColor);
begin
  if LedOnColor <> C then
  begin
    FLedOnColor := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDLedSign.SetOffColor(const C: TColor);
begin
  if LedOffColor <> C then
  begin
    FLedOffColor := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDLedSign.Paint;
var
  WorkRect: TRect;
  LedColor: TColor;

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
    FBorderBrush : IGPSolidBrush;
  begin
    { Create Solid Border Brush }
    FBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FBorderColor));
    { Draw background and border }
    case Shape of
      lssRoundRect : FGraphics.FillPath(FBorderBrush, RoundRectPath(WorkRect, 10));
      lssRect      : FGraphics.FillPath(FBorderBrush, RectPath(WorkRect));
    end;
  end;

  procedure DrawLedBorder(var FGraphics: IGPGraphics);
  var
    FLedBorderBrush: IGPSolidBrush;
  begin
    InflateRect(WorkRect, -BorderWidth, -BorderWidth);
    { Create Solid Border Brush }
    FLedBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(LedColor, 50)));
    { Draw background and border }
    case Shape of
      lssRoundRect : FGraphics.FillPath(FLedBorderBrush, RoundRectPath(WorkRect, 10));
      lssRect      : FGraphics.FillPath(FLedBorderBrush, RectPath(WorkRect));
    end;
    InflateRect(WorkRect, -1, -1);
    { Create Solid Border Brush }
    FLedBorderBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Darken(LedColor, 20)));
    { Draw background and border }
    case Shape of
      lssRoundRect : FGraphics.FillPath(FLedBorderBrush, RoundRectPath(WorkRect, 10));
      lssRect      : FGraphics.FillPath(FLedBorderBrush, RectPath(WorkRect));
    end;
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
    FFont         : TGPFont;
    FFontBrush    : IGPSolidBrush;
    FFontRect     : TGPRectF;
    FPen          : IGPPen;
    FontColor     : TGPColor;
  begin
    { Create colors for gradient led face }
    FFromColor := TGPColor.CreateFromColorRef(LedColor);
    FToColor   := TGPColor.CreateFromColorRef(Brighten(LedColor, 80));
    FLedBrush  := TGPLinearGradientBrush.Create(TGPRect.Create(WorkRect), FFromColor, FToColor, 90);
    case Shape of
      lssRoundRect : FGraphics.FillPath(FLedBrush, RoundRectPath(WorkRect, 10));
      lssRect      : FGraphics.FillPath(FLedBrush, RectPath(WorkRect));
    end;
    { Create light overlay on the top of the led face }
    FLightColor    := TGPColor.CreateFromColorRef(Brighten(LedColor, 20));
    FLightColor.Alpha := 125;
    FLightToColor  := TGPColor.CreateFromColorRef(Brighten(LedColor, 65));
    FlightColor.Alpha := 15;
    FLightRect := WorkRect;
    { Draw Text }
    if fsBold in Font.Style then
      FFont := TGPFont.Create(Font.Name, Font.Size, [FontStyleBold])
    else
      FFont := TGPFont.Create(Font.Name, Font.Size, []);
    FFontRect  := FGraphics.MeasureString(Caption, FFont, TGPPointF.Create(0, 0));
    FontColor  := TGPColor.CreateFromColorRef(Font.Color);
    FontColor.Alpha := 125;
    FFontBrush := TGPSolidBrush.Create(FontColor);
    FGraphics.DrawString(Caption, FFont, TGPPointF.Create(ClientRect.Left + Round((ClientWidth / 2) - (FFontRect.Width / 2)), ClientRect.Top + Round((ClientHeight / 2) - (FFontRect.Height / 2))), FFontBrush);
    FLedLight  := TGPLinearGradientBrush.Create(TGPRect.Create(FLightRect), FLightColor, FLightToColor, 135);
    FGraphics.FillPath(FLedLight, RoundRectPath(FLightRect, 5));
    if State = lssOn then
    begin
      FFontBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Font.color));
      FGraphics.DrawString(Caption, FFont, TGPPointF.Create(ClientRect.Left + Round((ClientWidth / 2) - (FFontRect.Width / 2)), ClientRect.Top + Round((ClientHeight / 2) - (FFontRect.Height / 2))), FFontBrush);
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

    case State of
      lssOff : LedColor := LedOffColor;
      lssOn  : LedColor := LedOnColor;
    end;
    WorkRect := Rect(
      ClientRect.Left,
      ClientRect.Top,
      ClientRect.Right -1,
      ClientRect.Bottom - 1
    );

    DrawBackground;
    DrawBorder(FGraphics);
    DrawLedBorder(FGraphics);
    DrawLed(FGraphics);
  end;

  { Draw the whole buffer to the surface }
  BitBlt(Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0,  0, SRCCOPY);

  inherited;
end;

procedure TERDLedSign.Resize;
begin
  Redraw := True;
  inherited;
end;

procedure TERDLedSign.WndProc(var Message: TMessage);
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

    { The font changed }
    CM_FONTCHANGED:
      begin
        Redraw := True;
        Invalidate
      end;

    { The caption changed }
    CM_TEXTCHANGED:
      begin
        Redraw := True;
        Invalidate
      end;
  end;
end;

end.
