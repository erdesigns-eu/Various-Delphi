{
  untERDMatrix v1.0.0 - a Matrix Display (Like LCD)
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

  Working: Cells is a multidimensional array of Boolean, so a cell (Pixel)
           is on or off. You can load a mask - a 1 bit monochrome bitmap
           that will be read pixel by pixel, and is set in the Cells Array.

           Adding text will draw a bitmap with the selected font and text,
           and will be loaded as a mask.

           You can also load graphics, but they will need to be converted to
           a monochrome 1 bit bitmap before you load it, otherwise it will
           not be displayed as expected.

}

unit untERDMatrix;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, Vcl.ExtCtrls, GDIPlus;

type
  TERDMatrixDisplay = class;

  TERDMatrixDisplayCellShape = (csSquare, csRound);

  TERDMatrixDisplayCell  = array of Boolean;
  TERDmatrixDisplayCells = array of TERDMatrixDisplayCell;

  TERDMatrixDisplayScrollDirection = (sdLeft, sdRight);

  TERDMatrixDisplayScroll = class(TPersistent)
  private
    FOwner     : TERDMatrixDisplay;
    FDirection : TERDMatrixDisplayScrollDirection;

    procedure SetDirection(const D: TERDMatrixDisplayScrollDirection);
    procedure SetActive(const B: Boolean);
    procedure SetInterval(const I: Integer);

    function GetActive : Boolean;
    function GetInterval : Integer;
  public
    constructor Create(AOwner: TERDMatrixDisplay); virtual;
  published
    property Direction: TERDMatrixDisplayScrollDirection read FDirection write SetDirection default sdLeft;
    property Active: Boolean read GetActive write SetActive default False;
    property Interval: Integer read GetInterval write SetInterval default 50;
  end;

  TERDMatrixDisplay = class(TCustomControl)
  private
    { Private declarations }
    FCellSize   : Integer;
    FCellSpace  : Integer;
    FCellShape  : TERDMatrixDisplayCellShape;
    FColorOff   : TColor;
    FColorOn    : TColor;
    FBorder     : TColor;
    FBorderSize : Integer;

    { Buffer - Avoid flickering }
    FBuffer         : TBitmap;
    FUpdateRect     : TRect;
    FRedrawBuffer   : Boolean;
    FRedrawEmpty    : Boolean;

    { Cells }
    FCols    : Integer;
    FRows    : Integer;
    FCells   : TERDmatrixDisplayCells;
    FMinCols : Integer;
    FMinRows : Integer;

    { Scroll }
    FScrollTimer : TTimer;
    FScroll      : TERDMatrixDisplayScroll;

    procedure SetCellSize(const I: Integer);
    procedure SetCellSpace(const I: Integer);
    procedure SetCellShape(const S: TERDMatrixDisplayCellShape);
    procedure SetColorOff(const C: TColor);
    procedure SetColorOn(const C: TColor);
    procedure SetBorder(const C: TColor);
    procedure SetBorderSize(const I: Integer);

    function GetCells(Row, Col: Integer): Boolean;
    procedure SetCells(Row, Col: Integer; const Value: Boolean);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure SettingsChanged(Sender: TObject);
    procedure OnScrollTimer(Sender: TObject);
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure LoadMask(const B: TBitmap; const OffsetX: Integer = 0;
      const OffsetY: Integer = 0; const Inversed: Boolean = false);
    procedure ClearDisplay(const Redraw: Boolean = false; const Inversed: Boolean = false); overload;
    procedure ClearDisplay(const FromRow, ToRow : Integer; const Redraw: Boolean = True); overload;
    procedure LoadText(const T: string; const OffsetX: Integer = 0;
      const OffsetY: Integer = 0; const Inversed: Boolean = false);
    procedure MoveCellsLeft(const Loop: Boolean = true; const FromRow: Integer = -1;
      const ToRow: Integer = -1);
    procedure MoveCellsRight(const Loop: Boolean = true; const FromRow: Integer = -1;
      const ToRow: Integer = -1);
    procedure InverseCells;

    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
    property Cols: Integer read FCols;
    property Rows: Integer read FRows;
    property RedrawBuffer: Boolean read FRedrawBuffer write FRedrawBuffer;
    property Cells [Row, Col: Integer]: Boolean read GetCells write SetCells;

    property ScrollTimer: TTimer read FScrollTimer write FScrollTimer;
  published
    { Published declarations }
    property CellSize: Integer read FCellSize write SetCellSize default 3;
    property CellSpace: Integer read FCellSpace write SetCellSpace default 1;
    property CellShape: TERDMatrixDisplayCellShape read FCellShape write SetCellShape default csSquare;
    property ColorOff: TColor read FColorOff write SetColorOff default $0049433A;
    property ColorOn: TColor read FColorOn write SetColorOn default $00E5E5D5;
    property BorderColor: TColor read FBorder write SetBorder default $00494238;
    property BorderWidth: Integer read FBorderSize write SetBorderSize default 1;
    property Scroll: TERDMatrixDisplayScroll read FScroll write FScroll;
    property RedrawEmptyCells: Boolean read FRedrawEmpty write FRedrawEmpty default True;

    property Align;
    property Anchors;
    property Color default $00585349;
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

uses System.Math, System.StrUtils, untERDMidiCommon;

const
  { Border }
  OffsetX = 1;
  OffsetY = 1;

(******************************************************************************)
(*
(*  ERD Matrix Display Scroll (TERDMatrixDisplayScroll)
(*
(******************************************************************************)
constructor TERDMatrixDisplayScroll.Create(AOwner: TERDMatrixDisplay);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TERDMatrixDisplayScroll.SetDirection(const D: TERDMatrixDisplayScrollDirection);
begin
  if Direction <> D then FDirection := D;
end;

procedure TERDMatrixDisplayScroll.SetActive(const B: Boolean);
begin
  if FOwner.ScrollTimer.Enabled <> B then
    FOwner.ScrollTimer.Enabled := B;
end;

procedure TERDMatrixDisplayScroll.SetInterval(const I: Integer);
begin
  if FOwner.ScrollTimer.Interval <> I then
    FOwner.ScrollTimer.Interval := I;
end;

function TERDMatrixDisplayScroll.GetActive : Boolean;
begin
  Result := FOwner.ScrollTimer.Enabled;
end;

function TERDMatrixDisplayScroll.GetInterval : Integer;
begin
  Result := FOwner.ScrollTimer.Interval;
end;

(******************************************************************************)
(*
(*  ERD Matrix Display (TERDMatrixDisplay)
(*
(******************************************************************************)
constructor TERDMatrixDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We dont want the control to accept controls - because this is
    a Matrix Display and not a panel like component. }
  ControlStyle := ControlStyle + [csOpaque{, csAcceptsControls},
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We dont want to be able to get focus, this is a display only - and we wont
    be using direct user input }
  TabStop := True;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Width / Height }
  Width  := 401;
  Height := 81;

  { Defaults }
  Color       := $00585349;
  FColorOn    := $00E5E5D5;
  FColorOff   := $0049433A;
  FCellShape  := csSquare;
  FCellSize   := 3;
  FCellSpace  := 1;
  FBorder     := $00494238;
  FBorderSize := 1;
  FMinCols    := -1;
  FMinRows    := -1;

  { Draw buffer for the first time }
  FRedrawBuffer := True;
  FRedrawEmpty  := True;

  { Scrolling }
  FScrollTimer := TTimer.Create(Self);
  FScrollTimer.OnTimer  := OnScrollTimer;
  FScrollTimer.Enabled  := False;
  FScrollTimer.Interval := 50;
  FScroll := TERDMatrixDisplayScroll.Create(Self);
end;

destructor TERDMatrixDisplay.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  { Free scrolling }
  FScrollTimer.Free;
  FScroll.Free;

  inherited Destroy;
end;

procedure TERDMatrixDisplay.LoadMask(const B: TBitmap; const OffsetX: Integer = 0;
      const OffsetY: Integer = 0; const Inversed: Boolean = false);

  function IsCellOn(const Row, Col: Integer) : Boolean;
  begin
    if Inversed then
      Result := B.Canvas.Pixels[Col, Row] <> clBlack
    else
      Result := B.Canvas.Pixels[Col, Row] = clBlack;
  end;

var
  T, Col, Row : Integer;
begin
  FMinCols := B.Width + OffsetX;
  FMinRows := B.Height + OffsetY;
  { Re-Calculate the Cols }
  T := Ceil((ClientWidth - (OffsetX * 2)) / (CellSize + CellSpace));
  if FMinCols > T then
    FCols := FMinCols
  else
    FCols := T;
  { Re-Calculate Rows }
  T := Ceil((ClientHeight - (OffsetY * 2)) / (CellSize + CellSpace));
  if FMinRows > T then
    FRows := FMinRows
  else
    FRows := T;
  { Set the length of the array (Cells) }
  SetLength(FCells, FRows, FCols);
  { Loop over the pixels and set the Cells on/off }
  for Row := 0 to B.Height do
  for Col := 0 to B.Width do
  begin
    if ((OffsetY + Row) < Rows) and ((OffsetX + Col) < Cols) then
    Cells[OffsetY + Row, OffsetX + Col] := IsCellOn(Row, Col);
  end;
  SettingsChanged(Self);
end;

procedure TERDMatrixDisplay.ClearDisplay(const Redraw: Boolean = False; const Inversed: Boolean = false);
var
  Row, Col: Integer;
begin
  { No minimal cols/rows }
  FMinCols := -1;
  FMinRows := -1;
  { Clean }
  for Row := 0 to Rows -1 do
  for Col := 0 to Cols -1 do
  Cells[Row, Col] := Inversed;
  if Redraw then SettingsChanged(Self);
end;

procedure TERDMatrixDisplay.ClearDisplay(const FromRow, ToRow: Integer; const Redraw: Boolean = True);
var
  Row, Col, T: Integer;
begin
  if ToRow >= Rows then
    T := Rows
  else
    T := ToRow;
  for Row := FromRow to T -1 do
  for Col := 0 to Cols -1 do
  Cells[Row, Col] := False;
end;

procedure TERDMatrixDisplay.LoadText(const T: string; const OffsetX: Integer = 0;
      const OffsetY: Integer = 0; const Inversed: Boolean = false);
var
  W, H : Integer;
  B    : TBitmap;
  S    : string;
begin
  { Create a bitmap for drawing the text }
  B := TBitmap.Create;
  try
    { Set bitmap to 1 bit - black/white }
    B.PixelFormat := pf1bit;
    B.Monochrome  := True;
    with B.Canvas do
    begin
      { Assign Font }
      Font.Assign(Self.Font);
      Font.Color := clBlack;
      { Calculate the width and height }
      S := IfThen(T[Length(T)] <> ' ', T + ' ', T);
      W := TextWidth(S);
      H := TextHeight(S);
      B.SetSize(W, H);
      { Draw the text }
      TextOut(0, 0, S);
    end;
    LoadMask(B, OffsetX, OffsetY, Inversed);
  finally
    B.Free;
  end;
end;

procedure TERDMatrixDisplay.MoveCellsLeft(const Loop: Boolean = true; const FromRow: Integer = -1;
  const ToRow: Integer = -1);
var
  B : Boolean;
  R, C : Integer;
begin
  for R := ifThen(FromRow > -1, FromRow, 0) to ifThen(ToRow > -1, ToRow, Rows -1) do
  begin
    B := Cells[R, 0];
    for C := 0 to Cols -1 do
    begin
      Cells[R, C] := Cells[R, C +1];
    end;
    if Loop then Cells[R, Cols] := B;
  end;
  SettingsChanged(Self);
end;

procedure TERDMatrixDisplay.MoveCellsRight(const Loop: Boolean = true; const FromRow: Integer = -1;
  const ToRow: Integer = -1);
var
  B : Boolean;
  R, C : Integer;
begin
  for R := ifThen(FromRow > -1, FromRow, 0) to ifThen(ToRow > -1, ToRow, Rows -1) do
  begin
    B := Cells[R, Cols -1];
    for C := Cols -1 downto 0 do
    begin
      Cells[R, C] := Cells[R, C -1];
    end;
    if Loop then Cells[R, 0] := B;
  end;
  SettingsChanged(Self);
end;

procedure TERDMatrixDisplay.InverseCells;
var
  R, C: Integer;
begin
  for R := 0 to Rows -1 do
  for C := 0 to Cols -1 do
  Cells[R, C] := not Cells[R, C];
  SettingsChanged(Self);
end;

procedure TERDMatrixDisplay.SetCellSize(const I: Integer);
begin
  if CellSize <> I then
  begin
    if I > 1 then
      FCellSize := I
    else
      FCellSize := 1;
    SettingsChanged(Self);
  end;
end;

procedure TERDMatrixDisplay.SetCellSpace(const I: Integer);
begin
  if CellSpace <> I then
  begin
    if I > 0 then
      FCellSpace := I
    else
      FCellSpace := 0;
    SettingsChanged(Self);
  end;
end;

procedure TERDMatrixDisplay.SetCellShape(const S: TERDMatrixDisplayCellShape);
begin
  if CellShape <> S then
  begin
    FCellShape := S;
    SettingsChanged(Self);
  end;
end;

procedure TERDMatrixDisplay.SetColorOff(const C: TColor);
begin
  if ColorOff <> C then
  begin
    FColorOff := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDMatrixDisplay.SetColorOn(const C: TColor);
begin
  if ColorOn <> C then
  begin
    FColorOn := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDMatrixDisplay.SetBorder(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorder := C;
    SettingsChanged(Self);
  end;
end;

procedure TERDMatrixDisplay.SetBorderSize(const I: Integer);
begin
  if BorderWidth <> I then
  begin
    if I > 0 then
      FBorderSize := I
    else
      FBorderSize := 0;
    SettingsChanged(Self);
  end;
end;

function TERDMatrixDisplay.GetCells(Row, Col: Integer) : Boolean;
begin
  if ((Row >= 0) and (Row < Rows)) and ((Col >= 0) or (Col < Cols)) then
    Result := FCells[Row, Col]
  else
    Result := False;
end;

procedure TERDMatrixDisplay.SetCells(Row, Col: Integer; const Value: Boolean);
begin
  if ((Row >= 0) and (Row < Rows)) and ((Col >= 0) or (Col < Cols)) then
  FCells[Row, Col] := Value;
end;

procedure TERDMatrixDisplay.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDMatrixDisplay.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDMatrixDisplay.SettingsChanged(Sender: TObject);
begin
  RedrawBuffer := True;
  Invalidate;
end;

procedure TERDMatrixDisplay.OnScrollTimer(Sender: TObject);
begin
  case Scroll.Direction of
    sdLeft  : MoveCellsLeft;
    sdRight : MoveCellsRight;
  end;
end;

procedure TERDMatrixDisplay.Paint;
var
  WorkRect: TRect;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(ClientRect);
      Pen.Color := BorderColor;
      Pen.Width := BorderWidth;
      Rectangle(ClientRect);
    end;
  end;

  procedure DrawCell(const Row, Col: Integer; const CellColor: TColor);

    { ** Test to see if modifieing pixels is faster ** }
    procedure FillRectPixels(R: TRect);
    var
      X, Y : Integer;
    begin
      for X := R.Left to R.Right -1 do
      for Y := R.Top  to R.Bottom -1 do
      FBuffer.Canvas.Pixels[X, Y] := CellColor;
    end;

  var
    CellRect : TRect;
  begin
    with FBuffer.Canvas do
    begin
      { Set Cell Rect }
      CellRect.Left   := WorkRect.Left + OffSetX + ((CellSize + CellSpace) * Col);
      CellRect.Top    := WorkRect.Top + OffsetY + ((CellSize + CellSpace) * Row);
      CellRect.Right  := CellRect.Left + CellSize;
      CellRect.Bottom := CellRect.Top + CellSize;
      { Set Cell Color }
      Pen.Color   := CellColor;
      Brush.Color := CellColor;
      { Draw Cell }
      case CellShape of
        csSquare : FillRect(CellRect);
        csRound  : Ellipse(CellRect);
      end;
    end;
  end;

  procedure DrawGrid;
  var
    Row, Col : Integer;
  begin
    for Col := 0 to Cols -1 do
    for Row := 0 to Rows -1 do
    if Cells[Row, Col] then
      DrawCell(Row, Col, ColorOn)
    else
      if RedrawEmptyCells then
      DrawCell(Row, Col, ColorOff);
  end;

var
  T, X, Y, W, H : Integer;
begin

  { Draw to the buffer }
  if RedrawBuffer then
  begin
    FRedrawBuffer := False;
    { Set WorkRect }
    WorkRect := ClientRect;
    InflateRect(WorkRect, -BorderWidth, -BorderWidth);
    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);
    { Calculate Cols }
    T := Ceil((WorkRect.Width - (OffsetX * 2)) / (CellSize + CellSpace));
    if FMinCols > T then
      FCols := FMinCols
    else
      FCols := T;
    { Calculate Rows }
    T := Ceil((WorkRect.Height - (OffsetY * 2)) / (CellSize + CellSpace));
    if FMinRows > T then
      FRows := FMinRows
    else
      FRows := T;
    { Set Length of the array of cells }
    SetLength(FCells, FRows, FCols);
    { Draw to buffer }
    DrawBackground;
    DrawGrid;
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

procedure TERDMatrixDisplay.Resize;
begin
  SettingsChanged(Self);
  inherited;
end;

procedure TERDMatrixDisplay.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDMatrixDisplay.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        {  }
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        SettingsChanged(Self);
      end;

    { Focus is lost }
    WM_KILLFOCUS:
      begin
        {  }
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        {  }
      end;

    { Font Changed }
    CM_FONTCHANGED:
      begin
        SettingsChanged(Self);
      end;
  end;
end;

end.
