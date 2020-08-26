{
  untRegister - Register ERDesigns Audio Toolkit Components
  for Delphi 2010 - 10.4 by Ernst Reidinga
  https://erdesigns.eu

  This unit is part of the ERDesigns Audio Toolkit Components Pack.

  (c) Copyright 2020 Ernst Reidinga <ernst@erdesigns.eu>

}

unit untRegister;

interface

uses
  System.Classes, untERD7SegmentLabel, untERDVUMeter, untERDVolumeTrackBar,
  untERDToggleSwitch, untERDRotaryStepKnob, untERDMatrix, untERDLed,
  untERDCaptionPanel, untERDPlayerDisplay, untERDProgressBar,
  untERDPlayerButton, untERDLedSign, untERDEllipseLedClock, untERDTabSet;

procedure Register;

implementation

(******************************************************************************)
(*
(*  Register ERDesigns Audio Toolkit Components
(*
(******************************************************************************)

procedure Register;
begin
  RegisterComponents('ERDesigns Audio Toolkit', [
    TERD7SegmentLabel,
    TERDVUMeter,
    TERDVolumeTrackBar,
    TERDToggleSwitch,
    TERDRotaryStepKnob,
    TERDMatrixDisplay,
    TERDLed,
    TERDCaptionPanel,
    TERDPlayerDisplay,
    TERDProgressBar,
    TERDPlayerButton,
    TERDLedSign,
    TERDEllipseLedClock,
    TERDTabSet
  ]);
end;


end.
