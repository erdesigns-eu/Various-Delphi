{
  untERDTabSet v1.0.0
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Midi Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

  Bugfixes / Updates:
  - Initial Release 1.0.0

  If you use this unit, please give credits to the original author;
  Ernst Reidinga.

}

unit untERDTabSet;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Graphics,
  Winapi.Messages, System.Types, GDIPlus;

type
  TERDTabSetChangeEvent = procedure(Sender: TObject; TabIndex: Integer) of object;

  TERDTabSetItem = class(TCollectionItem)
  private
    { Private declarations }
    FGlyph   : TPicture;
    FCaption : TCaption;
    FRect    : TRect;

    procedure SetGlyph(const P: TPicture);
    procedure SetCaption(const C: TCaption);
  protected
    { Protected declarations }
    function GetDisplayName: string; override;
  public
    { Public declarations }
    constructor Create(AOWner: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    property ItemRect: TRect read FRect write FRect;
  published
    { Published declarations }
    property Glyph: TPicture read FGlyph write SetGlyph;
    property Caption: TCaption read FCaption write SetCaption;
  end;

  TERDTabSetItems = class(TOwnedCollection)
  private
    { Private declarations }
    FOnChange : TNotifyEvent;

    function GetItem(Index: Integer): TERDTabSetItem;
    procedure SetItem(Index: Integer; const Value: TERDTabSetItem);
  protected
    { Protected declarations }
    procedure Update(Item: TCollectionItem); override;
  public
    { Public declarations }
    constructor Create(AOwner: TPersistent);
    function Add: TERDTabSetItem;
    procedure Assign(Source: TPersistent); override;

    property Items[Index: Integer]: TERDTabSetItem read GetItem write SetItem;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TERDTabSet = class(TCustomControl)
  private
    { Private declarations }
    FItems          : TERDTabSetItems;
    FFixedItemWidth : Boolean;
    FItemWidth      : Integer;
    FTabIndex       : Integer;
    FShowFocusRect  : Boolean;
    FOnChange       : TERDTabSetChangeEvent;

    { Buffer - Avoid flickering }
    FBuffer        : TBitmap;
    FUpdateRect    : TRect;
    FRedraw        : Boolean;
    FMouseOverItem : Integer;

    procedure SetFixedItemWidth(const B: Boolean);
    procedure SetItemWidth(const I: Integer);
    procedure SetTabIndex(const I: Integer);

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
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Redraw: Boolean read FRedraw write FRedraw;
    property UpdateRect: TRect read FUpdateRect write FUpdateRect;
  published
    { Published declarations }
    property Items: TERDTabSetItems read FItems write FItems;
    property FixedItemWidth: Boolean read FFixedItemWidth write SetFixedItemWidth default True;
    property ItemWidth: Integer read FItemWidth write SetItemWidth default 150;
    property TabIndex: Integer read FTabIndex write SetTabIndex default -1;
    property ShowFocusRect: Boolean read FShowFocusRect write FShowFocusRect default False;
    property OnChange: TERDTabSetChangeEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Color default $00444444;
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

uses System.Math, untERDMidiCommon;

const
  { Spacing }
  OffSet       = 4;
  Spacing      = 12;
  ImageSpacing = 6;

(******************************************************************************)
(*
(*  ERD Tab Set Item (TERDTabSetItem)
(*
(******************************************************************************)
constructor TERDTabSetItem.Create(AOWner: TCollection);
begin
  inherited Create(AOwner);
  FCaption := '';
  FGlyph   := TPicture.Create;
end;

destructor TERDTabSetItem.Destroy;
begin
  FGlyph.Free;
  inherited;
end;

procedure TERDTabSetItem.SetGlyph(const P: TPicture);
begin
  FGlyph.Assign(P);
  Changed(False);
end;

procedure TERDTabSetItem.SetCaption(const C: TCaption);
begin
  if Caption <> C then
  begin
    FCaption := C;
    Changed(False);
  end;
end;

function TERDTabSetItem.GetDisplayName : string;
begin
  if (Caption <> '') then
    Result := Caption
  else
    Result := Format('Tab %d', [Index]);
end;

procedure TERDTabSetItem.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TERDTabSetItem then
  begin
    FCaption := TERDTabSetItem(Source).Caption;
    FGlyph.Assign(TERDTabSetItem(Source).Glyph);
    Changed(False);
  end else Inherited;
end;

(******************************************************************************)
(*
(*  ERD Tab Set Item Collection (TERDTabSetItems)
(*
(******************************************************************************)
constructor TERDTabSetItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TERDTabSetItem);
end;

procedure TERDTabSetItems.SetItem(Index: Integer; const Value: TERDTabSetItem);
begin
  inherited SetItem(Index, Value);
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TERDTabSetItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChange) then FOnChange(Self);
end;

function TERDTabSetItems.GetItem(Index: Integer) : TERDTabSetItem;
begin
  Result := inherited GetItem(Index) as TERDTabSetItem;
end;

function TERDTabSetItems.Add : TERDTabSetItem;
begin
  Result := TERDTabSetItem(inherited Add);
end;

procedure TERDTabSetItems.Assign(Source: TPersistent);
var
  LI   : TERDTabSetItems;
  Loop : Integer;
begin
  if (Source is TERDTabSetItem)  then
  begin
    LI := TERDTabSetItems(Source);
    Clear;
    for Loop := 0 to LI.Count - 1 do
        Add.Assign(LI.Items[Loop]);
  end else inherited;
end;

(******************************************************************************)
(*
(*  ERD Tab Set (TERDTabSet)
(*
(******************************************************************************)
constructor TERDTabSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { If the ControlStyle property includes csOpaque, the control paints itself
    directly. We do want the control to accept controls - because we might
    want to place some controls on the right }
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls,
    csCaptureMouse, csClickEvents, csDoubleClicks];

  { We want to be able to get focus }
  TabStop := True;

  { Create Buffers }
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;

  { Items }
  FItems := TERDTabSetItems.Create(Self);
  FItems.OnChange := SettingsChanged;

  { Width / Height }
  Width  := 401;
  Height := 41;

  { Defaults }
  Color      := $00444444;
  Font.Name  := 'Segoe UI';
  Font.Color := $00E5E5D5;
  Font.Style := [];

  FItemWidth      :=150;
  FFixedItemWidth := True;
  FMouseOverItem  := -1;
  FShowFocusRect  := False;

  { Initial Draw }
  Redraw := True;
end;

destructor TERDTabSet.Destroy;
begin
  { Free Buffer }
  FBuffer.Free;

  { Free Items }
  FItems.Free;

  inherited Destroy;
end;

procedure TERDTabSet.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TERDTabSet.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  { Draw Buffer to the Control }
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TERDTabSet.SetFixedItemWidth(const B: Boolean);
begin
  if FixedItemWidth <> B then
  begin
    FFixedItemWidth := B;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDTabSet.SetItemWidth(const I: Integer);
begin
  if ItemWidth <> I then
  begin
    if I < 50 then
      FItemWidth := 50
    else
      FItemWidth := I;
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDTabSet.SetTabIndex(const I: Integer);
begin
  if TabIndex <> I then
  begin
    if (I > Items.Count -1) then
      FTabIndex := Items.Count -1
    else
    if (I < -1) then
      FTabIndex := -1
    else
      FTabIndex := I;
    if Assigned(FOnChange) then FOnChange(Self, FTabIndex);
    Redraw := True;
    Invalidate;
  end;
end;

procedure TERDTabSet.SettingsChanged(Sender: TObject);
begin
  Redraw := True;
  Invalidate;
end;

procedure TERDTabSet.Paint;
var
  WorkRect : TRect;

  procedure DrawBackground;
  begin
    with FBuffer.Canvas do
    begin
      Brush.Color := Color;
      FillRect(WorkRect);
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

  procedure CalculateItemRects;

    function GetItemWidth(const I: Integer) : Integer;
    begin
      if FixedItemWidth then
        Result := ItemWidth
      else
      with FBuffer.Canvas do
      begin
        Font.Assign(Self.Font);
        Result := TextWidth(Items.Items[I].Caption) + (Spacing * 2);
        if Items.Items[I].Glyph.Width > 0 then
          Result := Result + Items.Items[I].Glyph.Width + Spacing;
      end;
    end;

  var
    I : Integer;
  begin
    for I := 0 to Items.Count -1 do
    begin
      if I > 0 then
      begin
        Items.Items[I].ItemRect := Rect(
          Items.Items[I -1].ItemRect.Right + Spacing,
          WorkRect.Top + OffSet,
          (Items.Items[I -1].ItemRect.Right + Spacing) + GetItemWidth(I),
          WorkRect.Bottom - Offset
        );
      end else
      begin
        Items.Items[I].ItemRect := Rect(
          WorkRect.Left + OffSet,
          WorkRect.Top + OffSet,
          (WorkRect.Left + OffSet) + GetItemWidth(I),
          WorkRect.Bottom - OffSet
        );
      end;
    end;
  end;

  procedure DrawTab(var FGraphics : IGPGraphics; const I: Integer);
  var
    Rect        : TRect;
    TabBrush    : IGPLinearGradientBrush;
    HoverBrush  : IGPSolidBrush;
    HoverColor  : TGPColor;
    DividerPen1 : IGPPen;
    DividerPen2 : IGPPen;
    TabRect     : TRect;
    FFont       : TGPFont;
    FFontBrush  : IGPSolidBrush;
    FFontRect   : TGPRectF;
    TW, TL      : Integer;
  begin
    Rect := Items.Items[I].ItemRect;
    TabBrush := TGPLinearGradientBrush.Create(
      TGPRect.Create(Rect),
      TGPColor.CreateFromColorRef(Brighten(Color, 10)),
      TGPColor.CreateFromColorRef(Darken(Color, 5)),
      90);
    DividerPen1 := TGPPen.Create(TGPColor.CreateFromColorRef(Brighten(Color, 25)));
    DividerPen2 := TGPPen.Create(TGPColor.CreateFromColorRef(Darken(Color, 25)));
    { Draw Button face }
    if (I = FMouseOverItem) and (I <> TabIndex) then
    begin
      HoverColor := TGPColor.CreateFromColorRef(Darken(Color, 50));
      HoverColor.Alpha := 100;
      HoverBrush := TGPSolidBrush.Create(HoverColor);
      FGraphics.FillRectangle(HoverBrush, TGPRect.Create(Rect));
    end else
    if (I = TabIndex) then
    with FBuffer.Canvas do
    begin
      Brush.Style := bsSolid;
      Brush.Color := Darken(Color, 50);
      FillRect(Rect);
      TabRect := Rect;
      InflateRect(Tabrect, -1, -1);
      TabRect.Right  := TabRect.Right -1;
      TabRect.Bottom := TabRect.Bottom -1;
      FGraphics.FillRectangle(TabBrush, TGPRect.Create(TabRect));
      Brush.Style := bsClear;
      Pen.Width := 1;
      Pen.Color := Brighten(Color, 10);
      Rectangle(TabRect);
    end;
    { Draw Divider }
    FGraphics.DrawLine(DividerPen2, TGPPoint.Create(Rect.Right + ((Spacing div 2) - 2), WorkRect.Top + Offset), TGPPoint.Create(Rect.Right + ((Spacing div 2) - 2), WorkRect.Bottom - Offset));
    FGraphics.DrawLine(DividerPen1, TGPPoint.Create(Rect.Right + (Spacing div 2), WorkRect.Top + Offset), TGPPoint.Create(Rect.Right + (Spacing div 2), WorkRect.Bottom - Offset));
    { Draw Text }
    if fsBold in Font.Style then
      FFont := TGPFont.Create(Font.Name, Font.Size, [FontStyleBold])
    else
      FFont := TGPFont.Create(Font.Name, Font.Size, []);
    FFontBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Font.Color));
    FFontRect  := FGraphics.MeasureString(Items.Items[I].Caption, FFont, TGPPointF.Create(0, 0));
    { Draw Glyph ? }
    if (Items.Items[I].Glyph.Width > 0) then
    begin
      TW := Items.Items[I].Glyph.Width + ImageSpacing + Ceil(FFontRect.Width);
      TL := Rect.Left + (Rect.Width div 2);
      FBuffer.Canvas.Draw(TL - (TW div 2), Rect.Top + ((Rect.Height div 2) - (Items.Items[I].Glyph.Height div 2)), Items.Items[I].Glyph.Graphic);
      FGraphics.DrawString(Items.Items[I].Caption, FFont, TGPPointF.Create((TL - (TW div 2)) + ImageSpacing + Items.Items[I].Glyph.Width, (WorkRect.Top + WorkRect.Height / 2) - (FFontRect.Height / 2)), FFontBrush);
    end else
      FGraphics.DrawString(Items.Items[I].Caption, FFont, TGPPointF.Create(Rect.Left + (Rect.Width / 2) - (FFontRect.Width / 2), (WorkRect.Top + WorkRect.Height / 2) - (FFontRect.Height / 2)), FFontBrush);
    { Draw Focus Rect }
    InflateRect(Tabrect, -2, -2);
    if Focused and ShowFocusRect then FBuffer.Canvas.DrawFocusRect(Tabrect);
  end;

var
  FGraphics : IGPGraphics;
var
  X, Y, W, H, I : Integer;
begin
  { Draw the panel to the buffer }
  if Redraw then
  begin
    Redraw := False;
    WorkRect := ClientRect;

    { Set Buffer size }
    FBuffer.SetSize(ClientWidth, ClientHeight);

    { Create GDI+ Graphic }
    FGraphics := TGPGraphics.Create(FBuffer.Canvas.Handle);
    FGraphics.SmoothingMode := SmoothingModeAntiAlias;
    FGraphics.InterpolationMode := InterpolationModeHighQualityBicubic;

    { Draw to buffer }
    DrawBackground;
    CalculateItemRects;
    for I := 0 to Items.Count -1 do
    DrawTab(FGraphics, I);
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

procedure TERDTabSet.Resize;
begin
  Redraw := True;
  inherited;
end;

procedure TERDTabSet.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TERDTabSet.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    // Capture Keystrokes
    WM_GETDLGCODE:
      Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTALLKEYS;

    { Enabled/Disabled - Redraw }
    CM_ENABLEDCHANGED:
      begin
        Redraw := True;
        Invalidate;
      end;

    { The color changed }
    CM_COLORCHANGED:
      begin
        Redraw := True;
        Invalidate;
      end;

    { Font Changed }
    CM_FONTCHANGED:
      begin
        Redraw := True;
        Invalidate;
      end;

    { Mouse leave }
    CM_MOUSELEAVE:
      if not (csDesigning in ComponentState) then
      begin
        FMouseOverItem := -1;
        Redraw := True;
        Invalidate;
      end;

    { Focus is lost }
    WM_KILLFOCUS:
      begin
        Redraw := True;
        Invalidate;
      end;

    { Focus is set }
    WM_SETFOCUS:
      begin
        Redraw := True;
        Invalidate;
      end;
  end;
end;

procedure TERDTabSet.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
function IsMouseOverItem(var Item: Integer) : Boolean;
  var
    I : Integer;
  begin
    Result := False;
    for I := 0 to Items.Count -1 do
    if PtInRect(Items.Items[I].ItemRect, Point(X, Y)) then
    begin
      Result := True;
      Item := I;
      Break;
    end;
  end;

var
  I : Integer;
begin
  if CanFocus and (not Focused) then SetFocus;
  if IsMouseOverItem(I) then
  begin
    TabIndex := I;
  end;
  inherited;
end;

procedure TERDTabSet.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);

  function IsMouseOverItem(var Item: Integer) : Boolean;
  var
    I : Integer;
  begin
    Result := False;
    for I := 0 to Items.Count -1 do
    if PtInRect(Items.Items[I].ItemRect, Point(X, Y)) then
    begin
      Result := True;
      Item := I;
      Break;
    end;
  end;

var
  I : Integer;
begin
  if IsMouseOverItem(I) then
  begin
    if FMouseOverItem <> I then
    begin
      FMouseOverItem := I;
      Redraw := True;
      Invalidate;
    end;
  end else
  begin
    if FMouseOverItem <> -1 then
    begin
      FMouseOverItem := -1;
      Redraw := True;
      Invalidate;
    end;
  end;
  inherited;
end;

procedure TERDTabSet.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_LEFT) then
  begin
    TabIndex := TabIndex -1;
  end else
  if (Key = VK_RIGHT) then
  begin
    TabIndex := TabIndex +1;
  end;
  inherited;
end;

end.
