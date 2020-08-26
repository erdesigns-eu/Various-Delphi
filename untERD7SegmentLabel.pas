{
  untERD7SegmentLabel v1.0.0 - a 7 Segment label
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

  Working: The label holds a array of digits, this is a array of Boolean.
           When a segment of the digit is set to true - it will draw this
           segment as a led ON, otherwise it will draw it as led OFF.

           Segment names of a 7 segment digit (actually a 10 segment):

            ----a----
           |          |
           f    h     b
           |          |
            ----g----
           |          |
           e    i     c
           |          |
            ----d----
                j

           h and i are for the ":" character that is used for
           displaying time ( hh:mm:ss )
           j is the dot (in the center of the digit)
           - decimal seperator

  Reference: I took the characters and character shapes from wikiwand.com,
             there can be extended if needed - but i think it covers most
             used characters and should be enough for DPS/Audio software

             URL:
             https://www.wikiwand.com/en/Seven-segment_display

}

unit untERD7SegmentLabel;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, Vcl.ExtCtrls, GDIPlus;

type
  TERD7SegmentLabel = class;

  TERD7SegmentValue = array[0..6] of Boolean;

  TERD7Segments  = array[0..9, 0..5] of TPoint;
  TERD7Digits    = array of TERD7Segments;

  TERD7SegmentShape = (ssRectangle, ssEdge); { Maybe add a double edged variant? }
  TERD7SegmentLabelScrollDirection = (sdLeft, sdRight);

  TERD7SegmentLabelScroll = class(TPersistent)
  private
    FOwner     : TERD7SegmentLabel;
    FDirection : TERD7SegmentLabelScrollDirection;
    FOriginalText : string;

    procedure SetDirection(const D: TERD7SegmentLabelScrollDirection);
    procedure SetActive(const B: Boolean);
    procedure SetInterval(const I: Integer);

    function GetActive : Boolean;
    function GetInterval : Integer;
  public
    constructor Create(AOwner: TERD7SegmentLabel); virtual;
  published
    property Direction: TERD7SegmentLabelScrollDirection read FDirection write SetDirection default sdLeft;
    property Active: Boolean read GetActive write SetActive default False;
    property Interval: Integer read GetInterval write SetInterval default 500;
  end;

  TERD7SegmentLabel = class(TGraphicControl)
  private
    { Private declarations }
    FBuffer      : TBitmap;
    FRedraw      : Boolean;

    FDigits      : Integer;
    FSpace       : Integer;
    FColorOff    : TColor;
    FColorOn     : TColor;
    FShape       : TERD7SegmentShape;
    FText        : TCaption;
    FThickness   : Integer;
    FTransparent : Boolean;
    FAllOff      : Boolean;
    FShowClockD  : Boolean;
    FScrollTimer : TTimer;
    FScroll      : TERD7SegmentLabelScroll;

    FRecalcDigits : Boolean;
    FDigitsPoints : TERD7Digits;

    procedure SetDigits(const I: Integer);
    procedure SetSpace(const I: Integer);
    procedure SetColorOff(const C: TColor);
    procedure SetColorOn(const C: TColor);
    procedure SetShape(const S: TERD7SegmentShape);
    procedure SetText(const S: TCaption);
    procedure SetThickness(const I: Integer);
    procedure SetTransparent(const T: Boolean);
    procedure SetAllOff(const B: Boolean);
    procedure SetShowClockDigits(const B: Boolean);

    function GetDigit(Digit, Segment, APoint: Integer) : TPoint;
    procedure SetDigit(Digit, Segment, APoint: Integer; const Value: TPoint);
  protected
    { Protected declarations }
    procedure Paint; override;
    procedure Resize; override;

    function GetDigitForChar(const C: Char) : TERD7SegmentValue;
    procedure CalculatePoints;
    procedure WndProc(var Message: TMessage); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure OnScrollTimer(Sender: TObject);
    procedure MoveLeft(const Loop: Boolean = True);
    procedure MoveRight(const Loop: Boolean = True);

    property Redraw: Boolean read FRedraw write FRedraw;
    property RecalcDigits: Boolean read FRecalcDigits write FRecalcDigits;
    property Digits [Digit, Segment, APoint: Integer]: TPoint read GetDigit write SetDigit;
    property ScrollTimer: TTimer read FScrollTimer write FScrollTimer;
  published
    { Published declarations }
    property DigitCount: Integer read FDigits write SetDigits default 10;
    property Space: Integer read FSpace write SetSpace default 4;
    property ColorOff: TColor read FColorOff write SetColorOff default $0049433A;
    property ColorOn: TColor read FColorOn write SetColorOn default $00E5E5D5;
    property SegmentShape: TERD7SegmentShape read FShape write SetShape default ssEdge;
    property Text: TCaption read FText write SetText;
    property Thickness: Integer read FThickness write SetThickness default 3;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
    property AllOff: Boolean read FAllOff write SetAllOff default False;
    property ShowClockDigits: Boolean read FShowClockD write SetShowClockDigits default False;
    property Scroll: TERD7SegmentLabelScroll read FScroll write FScroll;

    property Align;
    property Anchors;
    property Color;
    property Enabled;
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
(*  ERD Seven Segment Label Scroll (TERD7SegmentLabelScroll)
(*
(******************************************************************************)
constructor TERD7SegmentLabelScroll.Create(AOwner: TERD7SegmentLabel);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TERD7SegmentLabelScroll.SetDirection(const D: TERD7SegmentLabelScrollDirection);
begin
  if Direction <> D then FDirection := D;
end;

procedure TERD7SegmentLabelScroll.SetActive(const B: Boolean);
begin
  if FOwner.ScrollTimer.Enabled <> B then
  begin
    if B then
    begin
      FOriginalText := FOwner.Text;
      if Length(FOwner.Text) < FOwner.DigitCount then
      FOwner.Text := FOwner.Text + StringOfChar(' ', FOwner.DigitCount - Length(FOwner.Text));
    end else
    begin
      FOwner.Text := FOriginalText;
    end;
    FOwner.ScrollTimer.Enabled := B;
  end;
end;

procedure TERD7SegmentLabelScroll.SetInterval(const I: Integer);
begin
  if FOwner.ScrollTimer.Interval <> I then
    FOwner.ScrollTimer.Interval := I;
end;

function TERD7SegmentLabelScroll.GetActive : Boolean;
begin
  Result := FOwner.ScrollTimer.Enabled;
end;

function TERD7SegmentLabelScroll.GetInterval : Integer;
begin
  Result := FOwner.ScrollTimer.Interval;
end;

(******************************************************************************)
(*
(*  ERD Seven Segment Label (TERD7SegmentLabel)
(*
(******************************************************************************)
constructor TERD7SegmentLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Transparent background }
  ControlStyle := ControlStyle + [csOpaque];

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Defaults }
  FDigits      := 10;
  FSpace       := 4;
  FColorOff    := $0049433A;
  FColorOn     := $00E5E5D5;
  FShape       := ssEdge;
  FText        := '1234567890';
  FThickness   := 3;
  FTRansparent := False;

  { Set default width and height }
  Width  := 297;
  Height := 41;

  { Calculate points for initial drawing }
  RecalcDigits := True;

  { Scroll Timer }
  FScrollTimer := TTimer.Create(Self);
  FScrollTimer.OnTimer  := OnScrollTimer;
  FScrollTimer.Enabled  := False;
  FScrollTimer.Interval := 500;
  FScroll := TERD7SegmentLabelScroll.Create(Self);

  { Draw for the first time }
  Redraw := True;
end;

destructor TERD7SegmentLabel.Destroy;
begin
  FBuffer.Free;
  FScrollTimer.Free;
  FScroll.Free;
  inherited Destroy;
end;

procedure TERD7SegmentLabel.SetDigits(const I: Integer);
begin
  if DigitCount <> I then
  begin
    if I >= 1 then
      FDigits := I
    else
      FDigits := 1;
    RecalcDigits := True;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetSpace(const I: Integer);
begin
  if Space <> I then
  begin
    if I >= 1 then
      FSpace := I
    else
      FSpace := 1;
    RecalcDigits := True;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetColorOff(const C: TColor);
begin
  if ColorOff <> C then
  begin
    FColorOff := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetColorOn(const C: TColor);
begin
  if ColorOn <> C then
  begin
    FColorOn := C;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetShape(const S: TERD7SegmentShape);
begin
  if SegmentShape <> S then
  begin
    FShape := S;
    RecalcDigits := True;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetText(const S: TCaption);
begin
  if Text <> S then
  begin
    FText := S;
    RecalcDigits := True;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetThickness(const I: Integer);
begin
  if Thickness <> I then
  begin
    if I >= 2 then
      FThickness := I
    else
      FThickness := 2;
    RecalcDigits := True;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetTransparent(const T: Boolean);
begin
  if Transparent <> T then
  begin
    FTransparent := T;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetAllOff(const B: Boolean);
begin
  if AllOff <> B then
  begin
    FAllOff := B;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERD7SegmentLabel.SetShowClockDigits(const B: Boolean);
begin
  if ShowClockDigits <> B then
  begin
    FShowClockD := B;
    Redraw := True;
    Invalidate;
  end;
end;

function TERD7SegmentLabel.GetDigit(Digit, Segment, APoint: Integer) : TPoint;
begin
  Result := FDigitsPoints[Digit, Segment, APoint];
end;

procedure TERD7SegmentLabel.SetDigit(Digit, Segment, APoint: Integer; const Value: TPoint);
begin
  if (Digit < DigitCount) and (Digit >= 0) and (Segment <= 9) and (Segment >= 0)
  and (APoint >= 0) and (APoint <= 5) then
  begin
    FDigitsPoints[Digit, Segment, APoint] := Value;
  end;
end;

procedure TERD7SegmentLabel.Paint;

  procedure DrawSegment(const D, S: Integer; const C: TColor);
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := C;
      Polygon(FDigitsPoints[D, S]);
    end;
  end;

  procedure DrawDots(const D, S: Integer; const C: TColor);
  var
    R : TRect;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := C;
      R := Rect(
        FDigitsPoints[D, S][0].X,
        FDigitsPoints[D, S][0].Y,
        FDigitsPoints[D, S][0].X + (Thickness * 2),
        FDigitsPoints[D, S][0].Y + (Thickness * 2)
      );
      case SegmentShape of
        ssRectangle  : Rectangle(R);
        ssEdge       : Ellipse(R);
      end;
    end;
  end;

  procedure DrawSingleDot(const D, S: Integer; const C: TColor);
  var
    R : TRect;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := C;
      R := Rect(
        FDigitsPoints[D, S][0].X,
        FDigitsPoints[D, S][0].Y,
        FDigitsPoints[D, S][0].X + (Thickness * 2),
        FDigitsPoints[D, S][0].Y + (Thickness * 2)
      );
      case SegmentShape of
        ssRectangle  : Rectangle(R);
        ssEdge       : Ellipse(R);
      end;
    end;
  end;

var
  D, S : Integer;
  C    : Char;
begin
  { Need redrawing? }
  if Redraw then
  begin
    Redraw := False;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    with FBuffer.Canvas do
    begin
      Pen.Style   := psClear;
      Brush.Color := Color;
      if not Transparent then FillRect(ClientRect);
    end;

    { Do we need to recalculate the points? }
    if RecalcDigits then
    begin
      RecalcDigits := False;
      CalculatePoints;
    end;

    { Draw the segments }
    for D := 0 to DigitCount -1 do
    begin
      if D < Length(Text) then
        C := Lowercase(Text)[D +1]
      else
        C := ' ';
      { Draw Segments }
      for S := 0 to 6 do
      begin
        if GetDigitForChar(C)[S] then
        begin
          if AllOff then
            DrawSegment(D, S, ColorOff)
          else
            DrawSegment(D, S, ColorOn);
        end else
          DrawSegment(D, S, ColorOff);
      end;
      { Draw Dots }
      for S := 7 to 8 do
      begin
        if C = ':' then
        begin
          if AllOff then
            DrawDots(D, S, ColorOff)
          else
            DrawDots(D, S, ColorOn);
        end else
        if ShowClockDigits then
          DrawDots(D, S, ColorOff);
      end;
      { Draw single dot / decimal seperator }
      if (C = '.') or (C = ',') then
      begin
        if AllOff then
          DrawSingleDot(D, 9, ColorOff)
        else
          DrawSingleDot(D, 9, ColorOn);
      end;
    end;
  end;

  { Draw the whole buffer to the surface }
  BitBlt(Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0,  0, SRCCOPY);

  inherited;
end;

procedure TERD7SegmentLabel.Resize;
begin
  RecalcDigits := True;
  inherited;
end;

function TERD7SegmentLabel.GetDigitForChar(const C: Char) : TERD7SegmentValue;
const
  { 0 -9 }
  DigitValues : array [0..9] of TERD7SegmentValue = (
    (true,  true,  true,  true,  true,  true,  false),
    (false, true,  true,  false, false, false, false),
    (true,  true,  false, true,  true,  false, true ),
    (true,  true,  true,  true,  false, false, true ),
    (false, true,  true,  false, false, true,  true ),
    (true,  false, true,  true,  false, true,  true ),
    (true,  false, true,  true,  true,  true,  true ),
    (true,  true,  true,  false, false, true,  false),
    (true,  true,  true,  true,  true,  true,  true ),
    (true,  true,  true,  true,  false, true,  true )
  );
  { A- J }
  AlphaPart1Values : array ['a'..'j'] of TERD7SegmentValue = (
    (true,  true,  true,  false, true,  true,  true ),
    (false, false, true,  true,  true,  true,  true ),
    (true,  false, false, true,  true,  true,  false),
    (false, true,  true,  true,  true,  false, true ),
    (true,  false, false, true,  true,  true,  true ),
    (true,  false, false, false, true,  true,  true ),
    (true,  false, true,  true,  true,  true,  false),
    (false, true,  true,  false, true,  true,  true ),
    (false, false, false, false, true,  true,  false),
    (false, true,  true,  true,  true,  false, false)
  );
  { L }
  AlphaLValue : TERD7SegmentValue = (false, false, false, true,  true,  true,  false);
  { N - U }
  AlphaParts2Values : array ['n'..'u'] of TERD7SegmentValue = (
    (false, false, true,  false, true,  false, true ),
    (true,  true,  true,  true,  true,  true,  false),
    (true,  true,  false, false, true,  true,  true ),
    (true,  true,  true,  false, false, true,  true ),
    (false, false, false, false, true,  false, true ),
    (true,  false, true,  true,  false, true,  true ),
    (false, false, false, true,  true,  true,  true ),
    (false, true,  true,  true,  true,  true,  false)
  );
  { Y }
  AlphaYValue       : TERD7SegmentValue = (false, true,  true,  true,  false, true,  true );
  { - }
  DashValue         : TERD7SegmentValue = (false, false, false, false, false, false, true );
  { _ }
  UnderscoreValue   : TERD7SegmentValue = (false, false, false, true,  false, false, false);
  { ‾ }
  OverscoreValue    : TERD7SegmentValue = (true,  false, false, false, false, false, false);
  { = }
  EqualsValue       : TERD7SegmentValue = (false, false, false, true,  false, false, true );
  { ≡ }
  TripleBarValue    : TERD7SegmentValue = (true,  false, false, true,  false, false, true );
  { ° }
  DegreeValue       : TERD7SegmentValue = (true,  true,  false, false, false, true,  true );
  { " }
  DoubleQuoteValue  : TERD7SegmentValue = (false, true,  false, false, false, true,  false);
  { ' }
  SingleQuoteValue  : TERD7SegmentValue = (false, false, false, false, false, true,  false);
  { [ }
  BracketRightValue : TERD7SegmentValue = (true,  false, false, true,  true,  true,  false);
  { ] }
  BracketLeftValue  : TERD7SegmentValue = (true,  true,  true,  true,  false, false, false);
  { ? }
  QuestionMarkValue : TERD7SegmentValue = (true,  true,  false, false, true,  false, true );
  { Off - empty }
  OffValue          : TERD7SegmentValue = (false, false, false, false, false, false, false);
begin
  if C in ['0'..'9'] then
  begin
    Result := DigitValues[StrToInt(C)];
  end else
  if C in ['a'..'j'] then
  begin
    Result := AlphaPart1Values[C];
  end else
  if C in ['n'..'u'] then
  begin
    Result := AlphaParts2Values[C];
  end else
  case C of
    'l'  : Result := AlphaLValue;
    'y'  : Result := AlphaYValue;
    '-'  : Result := DashValue;
    '='  : Result := EqualsValue;
    '_'  : Result := UnderscoreValue;
    '‾'  : Result := OverscoreValue;
    '≡'  : Result := TripleBarValue;
    '°'  : Result := DegreeValue;
    '"'  : Result := DoubleQuoteValue;
    '''' : Result := SingleQuoteValue;
    '[',
    '('  : Result := BracketRightValue;
    ']',
    ')'  : Result := BracketLeftValue;
    '?'  : Result := QuestionMarkValue;
    else
      Result := OffValue;
  end;
end;

procedure TERD7SegmentLabel.CalculatePoints;
var
  TN: Integer;
  TH: Integer;

  DHC, DVC : Integer;

  procedure CalculatePointsForDigitRect(const D: Integer; const R: TRect);
  begin
    { A }
    Digits[D, 0, 0] := Point(R.Left + TN, R.Top + (TN div 2));
    Digits[D, 0, 1] := Point(R.Left + TN, R.Top);
    Digits[D, 0, 2] := Point(R.Right - (TN + Space), R.Top);
    Digits[D, 0, 3] := Point(R.Right - (TN + Space), R.Top + (TN div 2));
    Digits[D, 0, 4] := Point(R.Right - (TN + Space), R.Top + TN);
    Digits[D, 0, 5] := Point(R.Left + TN, R.Top + TN);

    { B }
    Digits[D, 1, 0] := Point(R.Right - ((TN div 2) + Space), R.Top + TN);
    Digits[D, 1, 1] := Point(R.Right - Space, R.Top + TN);
    Digits[D, 1, 2] := Point(R.Right - Space, R.Top + TH);
    Digits[D, 1, 3] := Point(R.Right - ((TN div 2) + Space), R.Top + TH);
    Digits[D, 1, 4] := Point(R.Right - (TN + Space), R.Top + TH);
    Digits[D, 1, 5] := Point(R.Right - (TN + Space), R.Top + TN);

    { C }
    Digits[D, 2, 0] := Point(R.Right - ((TN div 2) + Space), R.Top + TH + TN);
    Digits[D, 2, 1] := Point(R.Right - Space, R.Top + TH + TN);
    Digits[D, 2, 2] := Point(R.Right - Space, R.Bottom - TN);
    Digits[D, 2, 3] := Point(R.Right - ((TN div 2) + Space), R.Bottom - TN);
    Digits[D, 2, 4] := Point(R.Right - (TN + Space), R.Bottom - TN);
    Digits[D, 2, 5] := Point(R.Right - (TN + Space), R.Top + TH + TN);

    { D }
    Digits[D, 3, 0] := Point(R.Left + TN, R.Bottom - (TN div 2));
    Digits[D, 3, 1] := Point(R.Left + TN, R.Bottom - TN);
    Digits[D, 3, 2] := Point(R.Right - (TN + Space), R.Bottom - TN);
    Digits[D, 3, 3] := Point(R.Right - (TN + Space), R.Bottom - (TN div 2));
    Digits[D, 3, 4] := Point(R.Right - (TN + Space), R.Bottom);
    Digits[D, 3, 5] := Point(R.Left + TN, R.Bottom);

    { E }
    Digits[D, 4, 0] := Point(R.Left + (TN div 2), R.Top + TH + TN);
    Digits[D, 4, 1] := Point(R.Left + TN, R.Top + TH + TN);
    Digits[D, 4, 2] := Point(R.Left + TN, R.Bottom - TN);
    Digits[D, 4, 3] := Point(R.Left + (TN div 2), R.Bottom - TN);
    Digits[D, 4, 4] := Point(R.Left, R.Bottom - TN);
    Digits[D, 4, 5] := Point(R.left, R.Top + TH + TN);

    { F }
    Digits[D, 5, 0] := Point(R.Left + (TN div 2), R.Top + TN);
    Digits[D, 5, 1] := Point(R.Left + TN, R.Top + TN);
    Digits[D, 5, 2] := Point(R.Left + TN, R.Top + TH);
    Digits[D, 5, 3] := Point(R.Left + (TN div 2), R.Top + TH);
    Digits[D, 5, 4] := Point(R.Left, R.Top + TH);
    Digits[D, 5, 5] := Point(R.left, R.Top + TN);

    { G }
    Digits[D, 6, 0] := Point(R.Left + TN, (R.Top + TH) - (TN div 2));
    Digits[D, 6, 1] := Point(R.Left + TN, R.Top + TH);
    Digits[D, 6, 2] := Point(R.Right - (TN + Space), R.Top + TH);
    Digits[D, 6, 3] := Point(R.Right - (TN + Space), (R.Top + TH) - (TN div 2));
    Digits[D, 6, 4] := Point(R.Right - (TN + Space), R.Top + TH + TN);
    Digits[D, 6, 5] := Point(R.Left + TN, R.Top + TH + TN);

    { Calculate center }
    DHC := (Digits[D, 5, 1].X + ((Digits[D, 1, 5].X - Digits[D, 5, 1].X) div 2)) - TN;

    { H }
    DVC := (Digits[D, 0, 5].Y + ((Digits[D, 6, 1].Y - Digits[D, 0, 5].Y) div 2)) - TN;
    Digits[D, 7, 0] := Point(DHC, DVC);

    { I }
    DVC := (Digits[D, 6, 5].Y + ((Digits[D, 3, 1].Y - Digits[D, 6, 5].Y) div 2)) - TN;
    Digits[D, 8, 0] := Point(DHC, DVC);

    { J }
    Digits[D, 9, 0] := Point((R.Right - Space) - ((R.Width div 2) + TN div 2), R.Bottom - (TN * 2));
  end;

  procedure CalculatePointsForDigitEdge(const D: Integer; const R: TRect);
  begin
    { A }
    Digits[D, 0, 0] := Point((R.Left + 1), R.Top);
    Digits[D, 0, 1] := Point((R.Left + 1), R.Top);
    Digits[D, 0, 2] := Point((R.Right - 1) - Space, R.Top);
    Digits[D, 0, 3] := Point((R.Right - 1) - Space, R.Top);
    Digits[D, 0, 4] := Point((R.Right - 1) - (Space + TN), R.Top + TN);
    Digits[D, 0, 5] := Point((R.Left + 1) + TN, R.Top + TN);

    { B }
    Digits[D, 1, 0] := Point(R.Right - Space, R.Top + 1);
    Digits[D, 1, 1] := Point(R.Right - Space, R.Top + 1);
    Digits[D, 1, 2] := Point(R.Right - Space, (R.Top -2) + TH + (TN div 2));
    Digits[D, 1, 3] := Point(R.Right - Space, (R.Top -2) + TH + (TN div 2));
    Digits[D, 1, 4] := Point(R.Right - (TN + Space), ((R.Top -2) + (TH - (TN div 2))));
    Digits[D, 1, 5] := Point(R.Right - (TN + Space), (R.Top +2) + TN);

    { C }
    Digits[D, 2, 0] := Point(R.Right - Space, (R.Top + 1) + TH + (TN div 2));
    Digits[D, 2, 1] := Point(R.Right - Space, (R.Top + 1) + TH + (TN div 2));
    Digits[D, 2, 2] := Point(R.Right - Space, (R.Bottom - 2));
    Digits[D, 2, 3] := Point(R.Right - Space, (R.Bottom - 2));
    Digits[D, 2, 4] := Point(R.Right - (TN + Space), (R.Bottom - 2) - TN);
    Digits[D, 2, 5] := Point(R.Right - (TN + Space), (R.Top + 2) + TH + TN + (TN div 2));

    { D }
    Digits[D, 3, 0] := Point((R.Left +1) + TN, R.Bottom - TN);
    Digits[D, 3, 1] := Point((R.Left +1) + TN, R.Bottom - TN);
    Digits[D, 3, 2] := Point((R.Right -2) - (TN + Space), (R.Bottom  -1) - TN);
    Digits[D, 3, 3] := Point((R.Right -2) - (TN + Space), (R.Bottom -1) - TN);
    Digits[D, 3, 4] := Point((R.Right -1) - Space, R.Bottom);
    Digits[D, 3, 5] := Point((R.Left +1), R.Bottom);

    { E }
    Digits[D, 4, 0] := Point(R.Left + TN, (R.Top +2) + TH + TN + (TN div 2));
    Digits[D, 4, 1] := Point(R.Left + TN, (R.Top +2) + TH + TN + (TN div 2));
    Digits[D, 4, 2] := Point(R.Left + TN, (R.Bottom -2) - TN);
    Digits[D, 4, 3] := Point(R.Left + TN, (R.Bottom -2) - TN);
    Digits[D, 4, 4] := Point(R.Left, R.Bottom - 2);
    Digits[D, 4, 5] := Point(R.left, (R.Top +2) + TH + (TN div 2));

    { F }
    Digits[D, 5, 0] := Point(R.Left + TN, (R.Top + 2) + TN);
    Digits[D, 5, 1] := Point(R.Left + TN, (R.Top +2) + TN);
    Digits[D, 5, 2] := Point(R.Left + TN, (R.Top - 2) + (TH - (TN div 2)));
    Digits[D, 5, 3] := Point(R.Left + TN, (R.Top - 2) + (TH - (TN div 2)));
    Digits[D, 5, 4] := Point(R.Left, (R.Top - 2) + TH + (TN div 2));
    Digits[D, 5, 5] := Point(R.left, R.Top + 2);

    { G }
    Digits[D, 6, 0] := Point(R.Left + 2, (R.Top + TH) + (TN div 2));
    Digits[D, 6, 1] := Point(R.Left + 2 + (TN div 2), R.Top + TH);
    Digits[D, 6, 2] := Point((R.Right - 2) - ((TN div 2) + Space), R.Top + TH);
    Digits[D, 6, 3] := Point((R.Right - 2) - Space, (R.Top + TH) + (TN div 2));
    Digits[D, 6, 4] := Point((R.Right - 2) - ((TN div 2) + Space), R.Top + TH + TN);
    Digits[D, 6, 5] := Point(R.Left + 2 + (TN div 2), R.Top + TH + TN);

    { Calculate center }
    DHC := (Digits[D, 5, 1].X + ((Digits[D, 1, 5].X - Digits[D, 5, 1].X) div 2)) - TN;

    { H }
    DVC := (Digits[D, 0, 5].Y + ((Digits[D, 6, 1].Y - Digits[D, 0, 5].Y) div 2)) - TN;
    Digits[D, 7, 0] := Point(DHC +1, DVC);

    { I }
    DVC := (Digits[D, 6, 5].Y + ((Digits[D, 3, 1].Y - Digits[D, 6, 5].Y) div 2)) - TN;
    Digits[D, 8, 0] := Point(DHC +1, DVC);

    { J }
    Digits[D, 9, 0] := Point((R.Right - Space) - ((R.Width div 2) + TN div 2), R.Bottom - (TN * 2));
  end;

var
  I, W : Integer;
  WR   : TRect;
begin
  { TN is shorter = cleaner to read }
  TN := Thickness;
  { TH is the length of the segment = workrect div 2 }
  TH := (ClientHeight div 2) - (TN div 2);
  { Set Length of Array with Digits }
  SetLength(FDigitsPoints, DigitCount);
  { Calculate the width of the Segment }
  W := (ClientWidth div DigitCount);
  { Calculate the workrect for each digit }
  for I := 0 to DigitCount -1 do
  begin
    WR.Left   := ClientRect.Left + (W * I);
    WR.Top    := ClientRect.Top;
    WR.Right  := WR.Left + W;
    WR.Bottom := ClientRect.Bottom - 1;
    case SegmentShape of
      ssRectangle  : CalculatePointsForDigitRect(I, WR);
      ssEdge       : CalculatePointsForDigitEdge(I, WR);
    end;
  end;
end;

procedure TERD7SegmentLabel.WndProc(var Message: TMessage);
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
  end;
end;

procedure TERD7SegmentLabel.OnScrollTimer(Sender: TObject);
begin
  case Scroll.Direction of
    sdLeft  : MoveLeft;
    sdRight : MoveRight;
  end;
end;

procedure TERD7SegmentLabel.MoveLeft(const Loop: Boolean = True);
var
  S : string;
begin
  if Loop then
    S := Copy(Text, 2, Length(Text) -1) + Copy(Text, 1, 1)
  else
    S := Copy(Text, 2, Length(Text) -1);
  Text := S;
end;

procedure TERD7SegmentLabel.MoveRight(const Loop: Boolean = True);
var
  S : string;
begin
  if Loop then
    S := Copy(Text, Length(Text), 1) + Copy(Text, 1, Length(Text) -1)
  else
    S := ' ' + Copy(Text, 1, Length(Text) -1);
  Text := S;
end;

end.
