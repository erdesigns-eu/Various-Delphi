{
  untERDProgressBar v1.0.0 - a progressbar used in the ERDPlayerDisplay
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDProgressBar;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, Vcl.ExtCtrls, GDIPlus;

type
  TERDProgressBar = class(TGraphicControl)
  private
    { Private declarations }
    FBuffer : TBitmap;
    FRedraw : Boolean;

    FBorderColor   : TColor;
    FProgressColor : TColor;
    FPosition      : Integer;
    FMax           : Integer;

    procedure SetProgressColor(const C: TColor);
    procedure SetPosition(const I: Integer);
    procedure SetMax(const I: Integer);
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
    property ProgressColor: TColor read FProgressColor write SetProgressColor default $00EAA900;
    property Position: Integer read FPosition write SetPosition default 0;
    property Max: Integer read FMax write SetMax default 100;

    property Align;
    property Anchors;
    property Color;
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

uses System.Math, System.StrUtils, untERDMidiCommon;

(******************************************************************************)
(*
(*  ERD Progress Bar (TERDProgressBar)
(*
(******************************************************************************)
constructor TERDProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Transparent background }
  ControlStyle := ControlStyle + [csOpaque];

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Defaults }
  FProgressColor := $00EAA900;
  FPosition      := 0;
  FMax           := 100;

  { Set default width and height }
  Width  := 184;
  Height := 20;

  { Initial Drawing }
  Redraw := True;
end;

destructor TERDProgressBar.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TERDProgressBar.SetProgressColor(const C: TColor);
begin
  if ProgressColor <> C then
  begin
    FProgressColor := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDProgressBar.SetPosition(const I: Integer);
begin
  if (Position <> I) and (I >= 0) and (I <= 100) then
  begin
    FPosition := I;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDProgressBar.SetMax(const I: Integer);
begin
  if (Max <> I) and (I >= 0) then
  begin
    FMax := I;
    Redraw := True;
    Invalidate;
  end;
end;


procedure TERDProgressBar.Paint;
var
  WorkRect : TRect;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Brighten(Color, 10);
      FillRect(WorkRect);
    end;
  end;

  procedure DrawProgress(var FGraphics : IGPGraphics);
  var
    FInnerBrush : IGPLinearGradientBrush;
    W           : Integer;
  begin
    FInnerBrush  := TGPLinearGradientBrush.Create(
      TGPRect.Create(WorkRect),
      TGPColor.CreateFromColorRef(Brighten(ProgressColor, 25)),
      TGPColor.CreateFromColorRef(Darken(ProgressColor, 20)),
      90);
    W := Round((WorkRect.Width / Max) * Position);
    WorkRect.Right := WorkRect.Left + W;
    FGraphics.FillRectangle(FInnerBrush, TGPRect.Create(WorkRect));
  end;

var
  FGraphics : IGPGraphics;
begin
  if Redraw then
  begin
    Redraw := False;

    { Create Work rect }
    WorkRect := ClientRect;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Draw to buffer }
    DrawBackground;
    DrawProgress(FGraphics);
  end;

  { Draw the whole buffer to the surface }
  BitBlt(Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0,  0, SRCCOPY);

  inherited;
end;

procedure TERDProgressBar.Resize;
begin
  Redraw := True;
  Invalidate;
  inherited;
end;

procedure TERDProgressBar.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    { The color changed }
    CM_COLORCHANGED:
      begin
        Redraw := True;
        Invalidate
      end;

    { Font changed }
    CM_FONTCHANGED:
      begin
        {  }
        Redraw := True;
        Invalidate
      end;
  end;
end;


end.
