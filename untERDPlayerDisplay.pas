{
  untERDPlayerDisplay v1.0.0 - a couple of Player Displays for Radio Automation
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDPlayerDisplay;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus, untERD7SegmentLabel, untERDLed,
  untERDProgressBar, untERDPlayerButton;

type
  TERDPlayerDisplayIndicatorShape = (isRectangle, isRoundRect);

  TERDPlayerDisplayIndicator = class(TPersistent)
  private
    { Private declarations }
    FShape   : TERDPlayerDisplayIndicatorShape;
    FCaption : TCaption;
    FColor   : TColor;
    FFont    : TFont;

    FOnChange : TNotifyEvent;

    procedure SetShape(const S: TERDPlayerDisplayIndicatorShape);
    procedure SetCaption(const S: TCaption);
    procedure SetColor(const C: TColor);
    procedure SetFont(const F: TFont);
  protected
    { Protected declarations }
    procedure OnSettingsChanged(Sender: TObject);
  public
    { Public declarations }
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Shape: TERDPlayerDisplayIndicatorShape read FShape write SetShape default isRoundRect;
    property Caption: TCaption read FCaption write SetCaption;
    property Color: TColor read FColor write SetColor default $00EAA900;
    property Font: TFont read FFont write SetFont;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDPlayerDisplayCaptions = class(TPersistent)
  private
    { Private declarations }
    FRuntime : TCaption;
    FIntro   : TCaption;
    FPGM     : TCaption;
    FPFL     : TCaption;
    FOnAir   : TCaption;
    FArtist  : TCaption;
    FTitle   : TCaption;

    FOnChange : TNotifyEvent;

    procedure SetRuntime(const S: TCaption);
    procedure SetIntro(const S: TCaption);
    procedure SetPGM(const S: TCaption);
    procedure SetPFL(const S: TCaption);
    procedure SetOnAir(const S: TCaption);
    procedure SetArtist(const S: TCaption);
    procedure SetTitle(const S: TCaption);
  protected
    { Protected declarations }
    procedure OnSettingsChanged(Sender: TObject);
  public
    { Public declarations }
    constructor Create; virtual;

    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Runtime: TCaption read FRuntime write SetRuntime;
    property Intro: TCaption read FIntro write SetIntro;
    property PGM: TCaption read FPGM write SetPGM;
    property PFL: TCaption read FPFL write SetPFL;
    property OnAir: TCaption read FOnAir write SetOnAir;
    property Artist: TCaption read FArtist write SetArtist;
    property Title: TCaption read FTitle write SetTitle;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDPlayerDisplay = class(TCustomControl)
  private
    { Private declarations }
    FIndicator : TERDPlayerDisplayIndicator;
    FCaptions  : TERDPlayerDisplayCaptions;

    { Buffer - Avoid flickering }
    FBuffer        : TBitmap;
    FUpdateRect    : TRect;
    FRedraw        : Boolean;

    { Audio display rows }
    FAudioInfoRows : Integer;

    { Child Components }
    FRuntimeLabel  : TERD7SegmentLabel;
    FIntroLabel    : TERD7SegmentLabel;
    FPGMLed        : TERDLed;
    FPFLLed        : TERDLed;
    FOnAirLed      : TERDLed;
    FProgressBar   : TERDProgressBar;
    FStopButton    : TERDPlayerButton;
    FPlayButton    : TERDPlayerButton;
    FPauseButton   : TERDPlayerButton;
    FNextButton    : TERDPlayerButton;

    { Artitst and Song title }
    FArtist   : TCaption;
    FTitle    : TCaption;
    FAutoSize : Boolean;

    procedure SetIndicator(const I: TERDPlayerDisplayIndicator);
    procedure SetCaptions(const C: TERDPlayerDisplayCaptions);

    function GetPGMLedOn : Boolean;
    function GetPFLLedOn : Boolean;
    function GetOnAirLedOn : Boolean;
    procedure SetPGMLedOn(const B: Boolean);
    procedure SetPFLLedOn(const B: Boolean);
    procedure SetOnAirLedOn(const B: Boolean);
    function GetRuntimeText : TCaption;
    function GetIntroText : TCaption;
    procedure SetRuntimeText(const S: TCaption);
    procedure SetIntroText(const S: TCaption);

    procedure SetArtist(const S: TCaption);
    procedure SetTitle(const S: TCaption);
    procedure SetAutoSize(const B: Boolean);

    function GetPosition : Integer;
    procedure SetPosition(const I: Integer);

    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    { Protected declarations }
    procedure SettingsChanged(Sender: TObject);

    procedure Paint; override;
    procedure Resize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Redraw: Boolean read FRedraw write FRedraw;
    property UpdateRect: TRect read FUpdateRect write FUpdateRect;

    property AudioInfoRows: Integer read FAudioInfoRows write FAudioInfoRows;
  published
    { Published declarations }
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;

    property Indicator: TERDPlayerDisplayIndicator read FIndicator write SetIndicator;
    property Captions: TERDPlayerDisplayCaptions read FCaptions write SetCaptions;

    property PGM: Boolean read GetPGMLedOn write SetPGMLedOn default False;
    property PFL: Boolean read GetPFLLedOn write SetPFLLedOn default False;
    property OnAir: Boolean read GetOnAirLedOn write SetOnAirLedOn default False;

    property Runtime: TCaption read GetRuntimeText write SetRuntimeText;
    property Intro: TCaption read GetIntroText write SetIntroText;

    property Artist: TCaption read FArtist write SetArtist;
    property Title: TCaption read FTitle write SetTitle;

    property Position: Integer read GetPosition write SetPosition default 0;

    property RuntimeLabel: TERD7SegmentLabel read FRuntimeLabel write FRuntimeLabel;
    property IntroLabel: TERD7SegmentLabel read FIntroLabel write FIntroLabel;

    property StopButton: TERDPlayerButton read FStopButton write FStopButton;
    property PlayButton: TERDPlayerButton read FPlayButton write FPlayButton;
    property PauseButton: TERDPlayerButton read FPauseButton write FPauseButton;
    property NextButton: TERDPlayerButton read FNextButton write FNextButton;

    property Align;
    property Anchors;
    property Color default $00444444;
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
  IndicatorLeft  = 8;
  IndicatorTop   = 8;
  IndicatorSpace = 8;

(******************************************************************************)
(*
(*  ERD Player Display Indicator (TERDPlayerDisplayIndicator)
(*
(******************************************************************************)
constructor TERDPlayerDisplayIndicator.Create;
begin
  inherited Create;
  FShape    := isRoundRect;
  FCaption  := 'A';
  FColor    := $00EAA900;
  FFont     := TFont.Create;
  FFont.OnChange := OnSettingsChanged;
  FFont.Name  := 'Segoe UI';
  FFont.Size  := 24;
  FFont.Color := clHighlightText;
end;

destructor TERDPlayerDisplayIndicator.Destroy;
begin
  FFont.Free;
  inherited Destroy;
end;

procedure TERDPlayerDisplayIndicator.OnSettingsChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TERDPlayerDisplayIndicator.Assign(Source: TPersistent);
begin
  if Source is TERDPlayerDisplayIndicator then
  begin
    FShape    := TERDPlayerDisplayIndicator(Source).Shape;
    FCaption  := TERDPlayerDisplayIndicator(Source).Caption;
    FColor    := TERDPlayerDisplayIndicator(Source).Color;
    FFont.Assign(TERDPlayerDisplayIndicator(Source).Font);
  end else
    inherited;
end;

procedure TERDPlayerDisplayIndicator.SetShape(const S: TERDPlayerDisplayIndicatorShape);
begin
  if Shape <> S then
  begin
    FShape := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayIndicator.SetCaption(const S: TCaption);
begin
  if Caption <> S then
  begin
    FCaption := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayIndicator.SetColor(const C: TColor);
begin
  if Color <> C then
  begin
    FColor := C;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayIndicator.SetFont(const F: TFont);
begin
  if Font <> F then
  begin
    FFont.Assign(F);
    OnSettingsChanged(Self);
  end;
end;

(******************************************************************************)
(*
(*  ERD Player Display Captions (TERDPlayerDisplayCaptions)
(*
(******************************************************************************)
constructor TERDPlayerDisplayCaptions.Create;
begin
  inherited Create;
  FRuntime := 'RUNTIME';
  FIntro   := 'INTRO';
  FPFL     := 'PRE FADE LISTEN';
  FPGM     := 'PROGRAM';
  FOnAir   := 'ON AIR';
  FArtist  := 'ARTIST:';
  FTitle   := 'TITLE:';
end;

procedure TERDPlayerDisplayCaptions.OnSettingsChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TERDPlayerDisplayCaptions.Assign(Source: TPersistent);
begin
  if Source is TERDPlayerDisplayCaptions then
  begin
    FRuntime := TERDPlayerDisplayCaptions(Source).Runtime;
    FIntro   := TERDPlayerDisplayCaptions(Source).Intro;
    FPGM     := TERDPlayerDisplayCaptions(Source).PGM;
    FPFL     := TERDPlayerDisplayCaptions(Source).PFL;
    FOnAir   := TERDPlayerDisplayCaptions(Source).OnAir;
    FArtist  := TERDPlayerDisplayCaptions(Source).Artist;
    FTitle   := TERDPlayerDisplayCaptions(Source).Title;
  end else
    inherited;
end;

procedure TERDPlayerDisplayCaptions.SetRuntime(const S: TCaption);
begin
  if Runtime <> S then
  begin
    FRuntime := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayCaptions.SetIntro(const S: TCaption);
begin
  if Intro <> S then
  begin
    FIntro := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayCaptions.SetPGM(const S: TCaption);
begin
  if PGM <> S then
  begin
    FPGM := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayCaptions.SetPFL(const S: TCaption);
begin
  if PFL <> S then
  begin
    FPFL := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayCaptions.SetOnAir(const S: TCaption);
begin
  if OnAir <> S then
  begin
    FOnAir := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayCaptions.SetArtist(const S: TCaption);
begin
  if Artist <> S then
  begin
    FArtist := S;
    OnSettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplayCaptions.SetTitle(const S: TCaption);
begin
  if Title <> S then
  begin
    FTitle := S;
    OnSettingsChanged(Self);
  end;
end;

(******************************************************************************)
(*
(*  ERD Player Display (TERDPlayerDisplay)
(*
(******************************************************************************)
constructor TERDPlayerDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We do want the control to accept controls, this is a player display
    which will hold components. Offcourse we like to get click, double click
    and mouse events. }
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls,
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We do want to be able to get focus }
  TabStop := True;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Settings }
  FIndicator := TERDPlayerDisplayIndicator.Create;
  FIndicator.OnChange := SettingsChanged;
  FCaptions := TERDPlayerDisplayCaptions.Create;
  FCaptions.OnChange := SettingsChanged;

  { Width / Height }
  Width  := 370;
  Height := 258;

  { AutoSize }
  FAutoSize := True;

  { Defaults }
  Color := $00444444;
  Font.Name  := 'Segoe UI';
  Font.Color := $00E5E5D5;
  Font.Style := [fsBold];

  { Child Components }
  FRuntimeLabel := TERD7SegmentLabel.Create(Self);
  FRuntimeLabel.Parent := Self;
  FRuntimeLabel.Width  := 169;
  FRuntimeLabel.Height := 30;
  FRuntimeLabel.Left   := 66;
  FRuntimeLabel.Top    := 28;
  FRuntimeLabel.DigitCount := 8;
  FRuntimeLabel.Text := '00:00:00';
  FRuntimeLabel.SetSubComponent(True);
  FIntroLabel    := TERD7SegmentLabel.Create(Self);
  FIntroLabel.Parent := Self;
  FIntroLabel.Width  := 108;
  FIntroLabel.Height := 30;
  FIntroLabel.Left   := 274;
  FIntroLabel.Top    := 28;
  FIntroLabel.DigitCount := 5;
  FIntroLabel.Text := '00:00';
  FIntroLabel.SetSubComponent(True);

  FPGMLed   := TERDLed.Create(Self);
  FPGMLed.Parent := Self;
  FPGMLed.LedOnColor := Indicator.Color;
  FPGMLed.BorderWidth := 0;
  FPFLLed   := TERDLed.Create(Self);
  FPFLLed.Parent := Self;
  FPFLLed.LedOnColor := Indicator.Color;
  FPFLLed.BorderWidth := 0;
  FOnAirLed := TERDLed.Create(Self);
  FOnAirLed.Parent := Self;
  FOnAirLed.LedOnColor := Indicator.Color;
  FOnAirLed.BorderWidth := 0;

  FProgressBar := TERDProgressBar.Create(Self);
  FProgressBar.Parent := Self;

  FStopButton := TERDPlayerButton.Create(Self);
  FStopButton.Parent := Self;
  FStopButton.Indicator.Shape := bisStop;
  FStopButton.Height := 65;
  FStopButton.SetSubComponent(True);
  FPlayButton := TERDPlayerButton.Create(Self);
  FPlayButton.Parent := Self;
  FPlayButton.Indicator.Shape := bisPlay;
  FPlayButton.Height := 65;
  FPlayButton.SetSubComponent(True);
  FPauseButton := TERDPlayerButton.Create(Self);
  FPauseButton.Parent := Self;
  FPauseButton.Indicator.Shape := bisPause;
  FPauseButton.Height := 65;
  FPauseButton.SetSubComponent(True);
  FNextButton := TERDPlayerButton.Create(Self);
  FNextButton.Parent := Self;
  FNextButton.Indicator.Shape := bisNext;
  FNextButton.Height := 65;
  FNextButton.LastButton := True;
  FNextButton.SetSubComponent(True);

  { Initial Draw }
 SettingsChanged(Self);
end;

destructor TERDPlayerDisplay.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  { Free Settings }
  FIndicator.Free;
  FCaptions.Free;

  inherited Destroy;
end;

procedure TERDPlayerDisplay.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDPlayerDisplay.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDPlayerDisplay.SetIndicator(const I: TERDPlayerDisplayIndicator);
begin
  if Indicator <> I then
  begin
    FIndicator.Assign(I);
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplay.SetCaptions(const C: TERDPlayerDisplayCaptions);
begin
  if Captions <> C then
  begin
    FCaptions.Assign(C);
    SettingsChanged(Self);
  end;
end;

function TERDPlayerDisplay.GetPGMLedOn : Boolean;
begin
  Result := FPGMLed.State = lsOn;
end;

function TERDPlayerDisplay.GetPFLLedOn : Boolean;
begin
  Result := FPFLLed.State = lsOn;
end;

function TERDPlayerDisplay.GetOnAirLedOn : Boolean;
begin
  Result := FOnAirLed.State = lsOn;
end;

procedure TERDPlayerDisplay.SetPGMLedOn(const B: Boolean);
begin
  if PGM <> B then
  begin
    case B of
      False : FPGMLed.State := lsOff;
      True  : FPGMLed.State := lsOn;
    end;
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplay.SetPFLLedOn(const B: Boolean);
begin
  if PFL <> B then
  begin
    case B of
      False : FPFLLed.State := lsOff;
      True  : FPFLLed.State := lsOn;
    end;
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplay.SetOnAirLedOn(const B: Boolean);
begin
  if OnAir <> B then
  begin
   case B of
      False : FOnAirLed.State := lsOff;
      True  : FOnAirLed.State := lsOn;
    end;
    SettingsChanged(Self);
  end;
end;

function TERDPlayerDisplay.GetRuntimeText : TCaption;
begin
  Result := FRuntimeLabel.Text;
end;

function TERDPlayerDisplay.GetIntroText : TCaption;
begin
  Result := FIntroLabel.Text;
end;

procedure TERDPlayerDisplay.SetRuntimeText(const S: TCaption);
begin
  if FRuntimeLabel.Text <> S then
  FRuntimeLabel.Text := S;
end;

procedure TERDPlayerDisplay.SetIntroText(const S: TCaption);
begin
  if FIntroLabel.Text <> S then
  FIntroLabel.Text := S;
end;

procedure TERDPlayerDisplay.SetArtist(const S: TCaption);
begin
  if Artist <> S then
  begin
    FArtist := S;
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplay.SetTitle(const S: TCaption);
begin
  if Title <> S then
  begin
    FTitle := S;
    SettingsChanged(Self);
  end;
end;

procedure TERDPlayerDisplay.SetAutoSize(const B: Boolean);
begin
  if AutoSize <> B then
  begin
    FAutoSize := B;
    SettingsChanged(Self);
  end;
end;

function TERDPlayerDisplay.GetPosition : Integer;
begin
  Result := FProgressBar.Position;
end;

procedure TERDPlayerDisplay.SetPosition(const I: Integer);
begin
  FProgressBar.Position := I;
end;

procedure TERDPlayerDisplay.SettingsChanged(Sender: TObject);
begin
  if Assigned(FRuntimeLabel) then
  FRuntimeLabel.ColorOff := Brighten(Color, 5);
  if Assigned(FIntroLabel) then
  FIntroLabel.ColorOff   := Brighten(Color, 5);
  if Assigned(FPGMLed) then
  FPGMLed.LedOnColor     := Indicator.Color;
  if Assigned(FPGMLed) then
  FPGMLed.LedOffColor    := Brighten(Color, 5);
  if Assigned(FPFLLed) then
  FPFLLed.LedOnColor     := Indicator.Color;
  if Assigned(FPFLLed) then
  FPFLLed.LedOffColor    := Brighten(Color, 5);
  if Assigned(FOnAirLed) then
  FOnAirLed.LedOnColor   := Indicator.Color;
  if Assigned(FOnAirLed) then
  FOnAirLed.LedOffColor  := Brighten(Color, 5);
  if Assigned(FProgressBar) then
  begin
    FProgressBar.Color := Color;
    FProgressBar.ProgressColor := Indicator.Color;
  end;
  if Assigned(FStopButton) then
  begin
    FStopButton.Indicator.OnColor  := Indicator.Color;
    FStopButton.Indicator.OffColor := Font.Color;
  end;
  if Assigned(FPlayButton) then
  begin
    FPlayButton.Indicator.OnColor  := Indicator.Color;
    FPlayButton.Indicator.OffColor := Font.Color;
  end;
  if Assigned(FPauseButton) then
  begin
    FPauseButton.Indicator.OnColor  := Indicator.Color;
    FPauseButton.Indicator.OffColor := Font.Color;
  end;
  if Assigned(FNextButton) then
  begin
    FNextButton.Indicator.OnColor  := Indicator.Color;
    FNextButton.Indicator.OffColor := Font.Color;
  end;
  Redraw := True;
  Invalidate;
end;

procedure TERDPlayerDisplay.Paint;
var
  WorkRect : TRect;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(ClientRect);
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

  procedure DrawIndicator(var FGraphics : IGPGraphics);
  var
    IndicatorBrush : IGPSolidBrush;
    FFontBrush     : IGPSolidBrush;
    FPen           : IGPPen;
    FFont          : TGPFont;
    FMeasureRect   : TGPRectF;
    Path           : IGPGraphicsPath;
    IndicatorRect  : TRect;
  begin
    { Create Brushes }
    IndicatorBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Indicator.Color));
    FFontBrush     := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Indicator.Font.Color));
    FPen           := TGPPen.Create(TGPColor.CreateFromColorRef(Darken(Indicator.Color, 50)));
    { Create Font }
    if fsBold in Indicator.Font.Style then
      FFont := TGPFont.Create(Indicator.Font.Name, Indicator.Font.Size, [FontStyleBold])
    else
      FFont := TGPFont.Create(Indicator.Font.Name, Indicator.Font.Size, []);
    { Measure the size of the indicator }
    FMeasureRect  := FGraphics.MeasureString(Indicator.Caption, FFont, TGPPointF.Create(0, 0));
    IndicatorRect := Rect(
      WorkRect.Left + IndicatorLeft,
      WorkRect.Top  + IndicatorTop,
      WorkRect.Left + IndicatorLeft + Ceil(FMeasureRect.Width) + (IndicatorSpace * 2),
      WorkRect.Top  + IndicatorTop + Ceil(FMeasureRect.Height) + IndicatorSpace
    );
    { Create Path }
    case Indicator.Shape of
      isRectangle : Path := RectPath(IndicatorRect);
      isRoundRect : Path := RoundRectPath(IndicatorRect, 10);
    end;
    { Draw Indicator }
    FGraphics.FillPath(IndicatorBrush, Path);
    FGraphics.DrawPath(FPen, Path);
    FGraphics.DrawString(Indicator.Caption, FFont, TGPPointF.Create(IndicatorRect.Left + IndicatorSpace, IndicatorRect.Top + (IndicatorSpace / 2)), FFontBrush);
    { Update Workrect }
    WorkRect.Left := IndicatorRect.Right + IndicatorLeft;
  end;

  procedure DrawRuntimeIntro(var FGraphics : IGPGraphics);
  var
    FInActiveColor : TGPColor;
    FInActiveBrush : IGPSolidBrush;
    FFontBrush     : IGPSolidBrush;
    FFont          : TGPFont;
    FMeasureRect   : TGPRectF;
  begin
    { Create Font }
    FInActiveColor := TGPColor.CreateFromColorRef(Font.Color);
    FInActiveColor.Alpha := 100;
    FInActiveBrush := TGPSolidBrush.Create(FInActiveColor);
    FFontBrush     := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Font.Color));
    if fsBold in Font.Style then
      FFont := TGPFont.Create(Font.Name, Font.Size, [FontStyleBold])
    else
      FFont := TGPFont.Create(Font.Name, Font.Size, []);
    { Draw Runtime and Intro }
    FMeasureRect  := FGraphics.MeasureString(Captions.Runtime + Captions.Intro, FFont, TGPPointF.Create(0, 0));
    FGraphics.DrawString(Captions.Runtime, FFont, TGPPointF.Create(WorkRect.Left, WorkRect.Top  + IndicatorTop), FFontBrush);
    FRuntimeLabel.Left := WorkRect.Left;
    FRuntimeLabel.Top  := WorkRect.Top  + IndicatorTop + Ceil(FMeasureRect.Height) + (IndicatorTop div 2);
    FIntroLabel.Left   := FRuntimeLabel.Left + FRuntimeLabel.Width + (IndicatorLeft * 3);
    FIntroLabel.Top    := FRuntimeLabel.Top;
    FGraphics.DrawString(Captions.Intro, FFont, TGPPointF.Create(FIntroLabel.Left, WorkRect.Top  + IndicatorTop), FFontBrush);
    { Draw PFL, PGM and On Air }
    FMeasureRect   := FGraphics.MeasureString(Captions.PGM, FFont, TGPPointF.Create(0, 0));
    WorkRect.Top   := FRuntimeLabel.Top + FRuntimeLabel.Height + (IndicatorTop * 2);
    { PGM - Program }
    FPGMLed.Left   := ClientRect.Left + IndicatorLeft + 2;
    FPGMLed.Top    := WorkRect.Top;
    FPGMLed.Height := Ceil(FMeasureRect.Height);
    if PGM then
      FGraphics.DrawString(Captions.PGM, FFont, TGPPointF.Create(FPGMLed.Left + FPGMLed.Width + 2, WorkRect.Top + 1), FFontBrush)
    else
      FGraphics.DrawString(Captions.PGM, FFont, TGPPointF.Create(FPGMLed.Left + FPGMLed.Width + 2, WorkRect.Top + 1), FInActiveBrush);
    { PFL (Pre Fade Listen) - Cue }
    FPFLLed.Top    := WorkRect.Top;
    FPFLLed.Left   := FPGMLed.Left + FPGMLed.Width + Ceil(FMeasureRect.Width) + 16;
    FMeasureRect   := FGraphics.MeasureString(Captions.PFL, FFont, TGPPointF.Create(0, 0));
    FPFLLed.Height := FPGMLed.Height;
    if PFL then
      FGraphics.DrawString(Captions.PFL, FFont, TGPPointF.Create(FPFLLed.Left + FPFLLed.Width + 2, WorkRect.Top + 1), FFontBrush)
    else
      FGraphics.DrawString(Captions.PFL, FFont, TGPPointF.Create(FPFLLed.Left + FPFLLed.Width + 2, WorkRect.Top + 1), FInActiveBrush);
    { On Air }
    FMeasureRect   := FGraphics.MeasureString(Captions.OnAir, FFont, TGPPointF.Create(0, 0));
    FOnAirLed.Height := FPGMLed.Height;
    FOnAirLed.Top  := WorkRect.Top;
    FOnAirLed.Left := (FIntroLabel.Left + FIntroLabel.Width) - (FOnAirLed.Width +4);
    if OnAir then
      FGraphics.DrawString(Captions.OnAir, FFont, TGPPointF.Create((FOnAirLed.Left - 4) - Ceil(FMeasureRect.Width), WorkRect.Top + 1), FFontBrush)
    else
      FGraphics.DrawString(Captions.OnAir, FFont, TGPPointF.Create((FOnAirLed.Left - 4) - Ceil(FMeasureRect.Width), WorkRect.Top + 1), FInActiveBrush);
    WorkRect.Top   := FOnAirLed.Top + FOnAirLed.Height + (IndicatorTop * 2);
    { Artist }
    FMeasureRect := FGraphics.MeasureString(Format('%s %s', [Captions.Artist, Artist]), FFont, TGPPointF.Create(0, 0));
    if Trim(Artist) <> '' then
      FGraphics.DrawString(Format('%s %s', [Captions.Artist, Artist]), FFont, TGPRectF.Create(FPGMLed.Left, WorkRect.Top, WorkRect.Right - WorkRect.Left, FMeasureRect.Height), nil, FFontBrush)
    else
      FGraphics.DrawString(Captions.Artist, FFont, TGPPointF.Create(FPGMLed.Left, WorkRect.Top), FInActiveBrush);
    { Title }
    WorkRect.Top := WorkRect.Top + Ceil(FMeasureRect.Height) + IndicatorTop;
    FMeasureRect := FGraphics.MeasureString(Format('%s %s', [Captions.Title, title]), FFont, TGPPointF.Create(0, 0));
    if Trim(Title) <> '' then
      FGraphics.DrawString(Format('%s %s', [Captions.Title, Title]), FFont, TGPRectF.Create(FPGMLed.Left, WorkRect.Top, WorkRect.Right - WorkRect.Left, FMeasureRect.Height), nil, FFontBrush)
    else
      FGraphics.DrawString(Captions.Title, FFont, TGPPointF.Create(FPGMLed.Left, WorkRect.Top), FInActiveBrush);
    { Progress }
    WorkRect.Top  := WorkRect.Top + Ceil(FMeasureRect.Height) + IndicatorTop;
    WorkRect.Left := FPGMLed.Left;
    FProgressBar.Left  := WorkRect.Left;
    FProgressBar.Width := (FOnAirLed.Left + FOnAirLed.Width) - WorkRect.Left;
    FProgressBar.Top   := WorkRect.Top;
    { Buttons }
    WorkRect.Top   := FProgressBar.Top + FProgressBar.Height + IndicatorTop;
    WorkRect.Right := FProgressBar.Left + FProgressBar.Width;
    { Stop Button }
    FStopButton.Top   := WorkRect.Top;
    FStopButton.Left  := WorkRect.Left;
    FStopButton.Width := Ceil(WorkRect.Width / 4);
    { Play Button }
    FPlayButton.Top   := WorkRect.Top;
    FPlayButton.Left  := FStopButton.Left + FStopButton.Width;
    FPlayButton.Width := FStopButton.Width;
    { Pause Button }
    FPauseButton.Top   := WorkRect.Top;
    FPauseButton.Left  := FPlayButton.Left + FPlayButton.Width;
    FPauseButton.Width := FStopButton.Width;
    { Next Button }
    FNextButton.Top   := WorkRect.Top;
    FNextButton.Left  := FPauseButton.Left + FPauseButton.Width;
    FNextButton.Width := WorkRect.Right - FNextButton.Left;
    { Component Width / Height }
    if AutoSize then
    begin
      Width  := WorkRect.Right + IndicatorLeft;
      Height := FNextButton.Top + FNextButton.Height + IndicatorTop;
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
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Background }
    DrawBackground;
    DrawIndicator(FGraphics);
    DrawRuntimeIntro(FGraphics);
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

procedure TERDPlayerDisplay.Resize;
begin
  SettingsChanged(Self);
  inherited;
end;

procedure TERDPlayerDisplay.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDPlayerDisplay.WndProc(var Message: TMessage);
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

    { The color changed }
    CM_COLORCHANGED:
      begin
        {  }
        SettingsChanged(Self);
      end;

    { Font changed }
    CM_FONTCHANGED:
      begin
        {  }
        SettingsChanged(Self);
      end;

  end;
end;

end.
