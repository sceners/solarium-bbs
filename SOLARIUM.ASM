; ///////////////////////////////////////////////////////////////////////////
; ////                                                                   ////
; ////  млллллл млллллм ллл        ллл    ллллллм ллл ллл ллл ллл   ллл  ////
; ////  ллл     ллл ллл ллл       ллллл   ллл ллл ллл ллл ллл лллл лллл  ////
; ////  плллллм ллл ллл ллл      ллл ллл  ллллллп ллл ллл ллл ллл л ллл  ////
; ////      ллл ллл ллл ллл     ллл   ллл лллпллм ллл ллл ллл ллл   ллл  ////
; ////  ллллллп плллллп ллллллл ллл   ллл ллл плл ллл плллллп ллл   ллл  ////
; ////                                                                   ////
; ////               Copyright (C) 1994 Altair/Anarchy-PC                ////
; ////                                                                   ////
; ////                                                                   ////
; ////                                                                   ////
; ////  Coding: Altair                                                   ////
; ////   Music: Modified HSC-Tracker tune                                ////
; ////                                                                   ////
; //// Program requires 386 and VGA for operating. It has been tested    ////
; //// with 486/33Mhz (no localbus) where scroller took half frame with  ////
; //// 70Hz screen update. Player is quite slow, but it has been mainly  ////
; //// optimized for size like everything else but scroller. Three tips: ////
; //// VGA detecting and 'zeros to end' were taken from Future Crews     ////
; //// StarPort II and processor detecting from Tietokone-Magazine, but  ////
; //// everything else is self-studied and self-created. Solarium uses   ////
; //// alot of variables, which are included into the code itself. When  ////
; //// you do something like that in your own programs, remember that    ////
; //// value is not necessarely in the code at the time when the command ////
; //// performs. There is no speedup with computers above 286 and those  ////
; //// don't shrink the code either. I must have a headache, when I made ////
; //// the code using that kind of variables (: In the code might be     ////
; //// some parts which could be optimized in smaller size or done other ////
; //// ways better, but I have changed this code many times and haven't  ////
; //// probably noticed everything. You can use parts of this code in    ////
; //// your own programs if you like, but it would be nice for you to    ////
; //// mention where have you got your source materials.                 ////
; //// I have used TASM and TLINK to create the original SOLARIUM.COM.   ////
; ////                                                                   ////
; //// Program consist of following operations:                          ////
; ////   - allocate memory                                               ////
; ////   - detect processor                                              ////
; ////   - unpack music                                                  ////
; ////   - detect VGA                                                    ////
; ////   - clear scrolling-area                                          ////
; ////   - initialize adlib                                              ////
; ////   - make Cos-wave                                                 ////
; ////   - precalculate the track of the scrollers                       ////
; ////       љ calculate the screen address for each vertical line       ////
; ////       љ calculate the source position for each pixel              ////
; ////       љ calculate the shading for each vertical pixel line        ////
; ////   - set the music routine to the timer interrupt                  ////
; ////   - set the new key interrupt (disable pause etc.)                ////
; ////   - create the characters                                         ////
; ////   - set palette                                                   ////
; ////   - intro-loop                                                    ////
; ////       љ test if ESC pressed                                       ////
; ////       љ write text to scrolling-area                              ////
; ////       љ draw scroll to the screen                                 ////
; ////       љ wait vertical retrace                                     ////
; ////   - return old interrupts                                         ////
; ////   - return to DOS                                                 ////
; ////                                                                   ////
; ///////////////////////////////////////////////////////////////////////////

Code                    Segment
                        Assume   Cs:Code,Ds:Code
                        Org      0100h
  Start:                .186
                        Push     Cs
                        Pop      Ds
                        Mov      Bx,2113h   ; allocate memory for operations
                        Mov      Ah,4Ah     ;  which SOLARIUM.COM uses
                        Int      21h        ;  (pattern etc.)
                        Jc       GoodBye
                        Push     Sp         ; is the processor 80186?
                        Pop      Bx
                        Cmp      Bx,Sp
                        Je       Not80186
    GoodBye:            Call     InitializeAdlib; quiet adlib
                        Mov      Ax,0003h   ; set text-mode
                        Int      10h
                        Push     0B800h
                        Pop      Es
                        Xor      Di,Di
                        Mov      Si,Offset BBSInfoText
                        Mov      Ah,0Dh
    WriteBBSText:       Mov      Al,Cs:[Si]
                        Or       Al,Al
                        Jnz      NoColorChange
                        Inc      Ah
    NoColorChange:      StosW
                        Inc      Si
                        Cmp      Si,Offset BBSInfoTextEnd
                        Jb       WriteBBSText
                        Mov      Ax,4C00h
                        Int      21h        ; return to DOS
    Not80186:           .286
                        Mov      Bx,0F000h  ; is it 80286?
                        Push     Bx
                        PopF
                        PushF
                        Pop      Bx
                        And      Bx,0F000h
                        Je       GoodBye    ; if it's 80286 -> bye
                        .386
                        Add      Ax,1000h
                        Mov      Word Ptr [ScrollDataBegin+0001h],Ax
                        Add      Ax,0C80h
                        Mov      Fs,Ax      ; segment for scroller-info
                        Add      Ax,33h     ; save segment for scrolling-area
                        Mov      Word Ptr [TextSegment+0001h],Ax;  here
                        Mov      Es,Ax
                        Add      Ax,70h
                        Mov      Gs,Ax
; Unpack all patterns
                        Mov      Word Ptr [PatternsSegment+0001h],Ax
                        Mov      Bx,Channels*64*4*Patterns-1
                        Mov      Di,Channels
    ResetInstruments:   Mov      [Di+InstrumentInfo-0001h],Bl
                        Dec      Di
                        Jnz      ResetInstruments
    ClearPatterns:      Mov      Byte Ptr Gs:[Bx],0FFh
                        Dec      Bx
                        Jns      ClearPatterns
                        Mov      Byte Ptr [TrackCounter+0001h],00h
                        Mov      Si,Offset Pattern00
    MakeTrack:          Mov      Dx,[Si]
                        Inc      Si
                        Cmp      Dl,0FFh
                        Je       NoNotes
                        Inc      Si
                        Mov      Bl,Dh
                        And      Bl,0Fh
                        Shl      Bl,02h
    TrackCounter:       Mov      Bh,77h
                        Mov      Ah,Dh
                        And      Ah,70h
                        Shr      Ah,02h
                        Add      Dh,Dh
                        Jc       CopyTrack
                        Mov      Cx,[Di+ChannelInfo]
    NextGroup:          Mov      Dh,Dl
                        And      Dl,1Fh
                        Mov      Bp,Dx
    LoopStoring:        Push     Si
    ReadCommand:        Mov      Al,[Si]
                        Inc      Si
                        Mov      Dh,Al
                        Shr      Al,04h
                        And      Dh,0Fh
                        Cmp      Al,0Eh
                        Je       SetOctaveOrSpace
                        Ja       SetInstrument
                        Push     Cx
                        Cmp      Al,07h
                        Jb       DontIncOctave
                        Inc      Cl
                        Sub      Al,07h
    DontIncOctave:      Shl      Cl,02h
                        Add      Al,Al
                        Mov      Gs:[Bx],Ax
                        Mov      Gs:[Bx+02h],Cx
                        Pop      Cx
                        Inc      Dh
                        Shl      Dh,02h
                        Add      Bl,Dh
                        Jc       TrackFull
    ExtraCommandReturn: Dec      Dl
                        Jns      ReadCommand
                        Mov      Dx,Bp
                        Pop      Si
                        Sub      Bp,2000h
                        Jnc      LoopStoring
                        And      Bp,001Fh
                        Add      Si,Bp
                        Inc      Si
                        Mov      Dl,[Si]
                        Inc      Si
                        Jmp      NextGroup
    SetOctave:          Mov      Cl,Dh
                        Dec      Cl
                        Jmp      ExtraCommandReturn
    SetInstrument:      Mov      Ch,Dh
                        Jmp      ExtraCommandReturn
    CopyTrack:          Push     Si
                        Shl      Dx,08h
                        Mov      Si,Dx
      CopyingLoop:      Mov      Al,Gs:[Si]
                        Mov      Cx,Gs:[Si+02h]
                        Mov      Gs:[Bx],Ax
                        Mov      Gs:[Bx+02h],Cx
                        Add      Si,04h
                        Add      Bl,04h
                        Jnc      CopyingLoop
                        Pop      Si
                        Jmp      NoNotes
    SetOctaveOrSpace:   Test     Dh,08h
                        Jz       SetOctave
                        Shl      Dh,06h
                        Add      Bl,Dh
                        Jnc      ExtraCommandReturn
    TrackFull:          Pop      Si
                        And      Bp,001Fh
                        Add      Si,Bp
                        Inc      Si
                        Mov      [Di+ChannelInfo],Cx
    NoNotes:            Inc      Byte Ptr [TrackCounter+0001h]
                        Sub      Di,02h
                        Jnc      DontZeroChl
                        Mov      Di,0010h
    DontZeroChl:        Cmp      Si,Offset SongDataEnd
                        Jb       MakeTrack
; Detect VGA
                        Mov      Ax,1A00h
                        Int      10h        ; is the display VGA?
                        Cmp      Al,1Ah
                        Jne      GoodBye    ; if not VGA -> bye
; Clear the scrolling-area
                        Mov      Di,06FFh   ; the length of scrolling-area -2
    ClearAreaLoop:      Mov      Byte Ptr Es:[Di],00h
                        Dec      Di
                        Jns      ClearAreaLoop
                        Call     InitializeAdlib

; There is a packed cosine-wave in the end of this program and below program
; unpacks it to the SCROLLERSTRACK.

                        Push     Cs
                        Pop      Es
                        Mov      Si,Offset PackedTrack
                        Mov      Di,Offset ScrollersTrack
                        Mov      Cx,0029h
    UnpackTrackLoop1:   LodsB
    UnpackTrackLoop2:   Mov      Ah,Al
                        And      Ah,0Fh
                        Jz       UnpackTrackLoop1
    UnpackTrackLoop3:   Mov      Ds:[Di],Ch
                        Inc      Di
                        Dec      Ah
                        Jnz      UnpackTrackLoop3
                        Inc      Ch
                        Shr      Al,04h
                        Dec      Cl
                        Jnz      UnpackTrackLoop2
                        Mov      Cl,0A0h
                        Mov      Si,Offset ScrollersTrack+009Fh
    MakeEndOfTheTrack:  MovsB               ; copy table in reverse order
                        Dec      Si
                        Dec      Si
                        Dec      Cl         ; repeat 160 times
                        Jnz      MakeEndOfTheTrack

; Calculate the precalculation tables for scroller. First calculate the
; shadow of the scroller by deriving. This is possible, because scrollers
; track follows the function of cosine. Derived value means the steedness
; of the function in some place of it, so the value is in range -1 and +1
; and the angle of lightsource is naturaly 45 degrees to right and front
; from the the scroller. After this, store also the height of every 4th
; vertical line in the scroller (4 next vertical lines has always a same
; heigh, because this make writing to screen memory alot of faster).
; Then precalculate the screen address of all those 80 vertical line groups.
; Begin address of those line group information tables is 000Ah. Information
; tables don't begin at zero, because this makes scroller-routine little
; faster. Maybe it has no meaning, but it won't make the code longer (:

                        Mov      Di,000Ah   ; Di=pointter in table
                        Xor      Cx,Cx      ; Cx=x coordinate of vertical line
    DeriveDWordLoop:    Mov      Bx,Cx      ; Dcosx=-sinx, so take the
                        Sub      Bx,50h     ;  right value from the table,
                        Cmp      Cx,4Fh     ;  where is a half of the
                        Ja       IsInRange  ;  cosine wave. Move to Bx
                        Mov      Bx,004Fh   ;  value, where in the table
                        Sub      Bx,Cx      ;  the derived value can be find.
                                            ;  In this case x=Cx*(360/320)
                                            ;  what means that value in the
                                            ;  position 0=0 degrees, 1=1.125,
                                            ;  2=2.25 etc.
    IsInRange:          Xor      Ax,Ax
                        Mov      Al,ScrollersTrack[Bx] ; Ax=Dcos*20+20
                        Shl      Ax,04h     ; make derived value to fit in
                        Sub      Ax,0140h   ;  the range 1-31. If there
                        Mov      Bl,15h     ;  is more colors, shading don't
                        Idiv     Bl         ;  look good.
                        Add      Al,10h
                        Mov      Dl,Al
                        Ror      Edx,08h
                        Inc      Cx
                        Test     Cl,03h     ; make shadow for 4 lines
                        Jnz      DeriveDWordLoop;  at the time (DoubleWord)
                        Mov      Fs:[Di],Edx; store 4 shadows to the table
                        Mov      Bx,Cx      ; Bx=Cx-4
                        Sub      Bx,04h
                        Xor      Ax,Ax      ; set to Ax the cosine value,
                        Mov      Al,ScrollersTrack[Bx]; which equals the Cx and
                        Shr      Al,01h     ;  divide it by 2
                        Mov      Bx,Ax      ; calculate to Bx the heigh of
                        Add      Bx,Bx      ;  the scroller at the screen at
                        Add      Bx,28h     ;  Cx and then store it (4 lines)
                        Mov      Fs:[Di+04h],Bx
                        Neg      Ax         ; calculate the begin address of
                        Add      Ax,0087h   ;  the line group (line group
                        Mov      Bp,0140h   ;  consists 4 vertical lines)
                        Mul      Bp
                        Add      Ax,Cx
                        Sub      Ax,04h
                        Mov      Fs:[Di+06h],Ax
                        Mov      Ax,Cx      ; to the end of this line group
                        Shr      Ax,01h     ;  information store the segment,
                        Dec      Ax         ;  where are the addresses where
                        Dec      Ax         ;  pixels will be taken. The
                        Mul      Bp         ;  addresses will be calculated
                        Shr      Ax,04h     ;  when this table is ready
    ScrollDataBegin:    Add      Ax,7777h   ; add to the segment the base
                        Mov      Fs:[Di+08h],Ax;  segment and store it
                        Add      Di,0Ah     ; calculate next line group
                        Cmp      Cx,Bp      ;  information, if any group left
                        Jb       DeriveDWordLoop

; Precalculate now the source addresses for every pixel in the scroller.
; Scroller consist 27408 pixels and one address takes a word. One line group
; will be stored to its own segment, and I don't want to make this code
; any longer so every segment has same size (80*4*2 bytes=640 bytes, because
; at the highest place of the scroller the height is 80 pixels).

                        Xor      Si,Si      ; Si=x coordinate of vertical line
                        Xor      Cx,Cx      ; Cx=x coordinate of source
                        Xor      Bp,Bp      ; Bp=decimal part of Cx
                        Xor      Bx,Bx      ; Bx=(line group number+1)*10
    CalculateDataLoop1: Xor      Di,Di      ; Di=source address store place
                        Add      Bx,000Ah   ; One line group info length
    CalculateDataLoop2: Push     Bx
                        Mov      Gs,Fs:[Bx+08h] ; Get source address segment
                        Mov      Bx,Fs:[Bx+04h] ; Get line group height
                        Xor      Ax,Ax      ; Calculate adding value to Ax
                        Mov      Dx,0007h   ; Height of the font is 7 pixels
                        Div      Bx         ; Ax=carry add value
                        Push     Di
                        Push     Cx
                        Or       Di,Di
                        Jnz      NoSwap1
                        Mov      Di,06h
                        Jmp      FillOneYLine
    NoSwap1:            Cmp      Di,06h
                        Jne      FillOneYLine
                        Xor      Di,Di
    FillOneYLine:       Mov      Gs:[Di],Cx ; Save address to source addresses
                        Add      Dx,Ax      ; Increase y-coordinate with carry
                        Jnc      DontAddY
                        Inc      Ch
    DontAddY:           Add      Di,08h     ; Next address where to save
                        Dec      Bx         ; Save next pixel if any left
                        Jnz      FillOneYLine
                        Pop      Cx
                        Pop      Di

; Calculate adding value which moves the reading pointer in scrolling-area.
; There must notice, that the steedness of position and z position will affect
; to the value. Below program will calculate that value. The adding value
; comes from following equation:
; A:=(1.707106781-(Abs(20-Table[I])*0.035355339))*(16/(Table[I]+40));
; where I is the x-coordinate of vertical line and table points to
; the table SCROLLERSTRACK.

                        Mov      Ax,0014h   ; Take absolute value of this
                        Sub      Al,ScrollersTrack[Si];  subtraction,
                        Jns      DontNeg    ;  if the value in Al will be in
                        Neg      Al         ;  range 0-20
    DontNeg:            Mov      Dx,090Dh   ; Multiply the value by
                        Mul      Dx         ;  Cos45*65536/20=090Dh
                        Neg      Ax         ; Subtract this value from
                        Add      Ax,0B505h  ;  Cos45*65536=B505h
                        Inc      Dx         ; Move to Dx 1 and multibly
                        Shld     Dx,Ax,04h  ;  32 bit value by 16
                        Mov      Bl,ScrollersTrack[Si] ; Then divide the value
                        Add      Bl,28h     ; by the length of vertical line
                        Div      Bx         ; Bh is zero because of above loop
                        Add      Bp,Ax      ; Add to Bp the result and add
                        Adc      Cx,00h     ;  Cx(=source address) with carry
                        Inc      Di
                        Inc      Di
                        Inc      Si
                        Pop      Bx
                        Test     Si,03h     ; calculate 4 vertical lines to
                        Jnz      CalculateDataLoop2;  same segment
                        Cmp      Si,0140h   ; repeat until all 320 lines
                        Jb       CalculateDataLoop1;  are calculated

; set screen mode 320x200x256
                        Mov      Ax,0013h
                        Int      10h
; Start playing
                        Cli
                        Xor      Ax,Ax
                        Mov      Ds:[TempoCounter],Al; zero tempocounter
                        Mov      Byte Ptr Ds:[Row+0001h],Al; and row number
                        Mov      Word Ptr Ds:[SongPosition+0001h],Offset SongOrder
                        Push     Ax
                        Pop      Gs
                        Mov      Eax,Gs:[8*4]
                        Mov      Ds:[OldTimerInt],Eax
                        Mov      Al,34h     ; timer interrupt request 70Hz
                        Out      43h,Al
                        Mov      Al,95h
                        Out      40h,Al
                        Mov      Al,42h
                        Out      40h,Al
                        Push     Cs         ; set player interrupt
                        Pop      Ax
                        Rol      Eax,10h
                        Mov      Ax,Offset Player
                        Mov      Gs:[8*4],Eax
; Set new key interrupt
                        Mov      Edx,Gs:[9*4]
                        Mov      Ds:[OldKeyInt],Edx
                        Mov      Ax,Offset KeyInterrupt
                        Mov      Gs:[9*4],Eax
                        Sti
; Get characters
                        Push     0A000h
                        Pop      Ds
                        Mov      Ax,0220h   ; first character is space
                        Xor      Dx,Dx      ; cursor position is 0,0
                        Mov      Di,Offset Fonts ; offset to store characters
    MoveNewCharacter:   Xor      Si,Si      ; character screen address
                        Mov      Bx,001Fh   ; the color of characters is 31
                        PushA               ; this line is for AMI-BIOS
                        Int      10h
                        PopA                ; this line is for AMI-BIOS
                        PushA               ; this line is for AMI-BIOS
                        Mov      Ah,0Eh     ; write character at cursor
                        Int      10h
                        PopA                ; this line is for AMI-BIOS
                        Mov      Ch,08h     ; copy 8 horizontal lines and
    MoveCharacterLoop2: Mov      Cl,08h     ;  8 vertical lines
    MoveCharacterLoop1: MovsB               ; double the width of a character
                        Dec      Si
                        MovsB
                        Dec      Cl
                        Jnz      MoveCharacterLoop1
                        Add      Si,0138h   ; do next line
                        Dec      Ch
                        Jnz      MoveCharacterLoop2
                        Inc      Al         ; copy characters 32-127
                        Jns      MoveNewCharacter
                        Push     Ds
                        Pop      Es         ; Es=0A000h
                        Push     Cs
                        Pop      Ds         ; Ds=Cs
                        Mov      Ax,0013h   ; clear screen
                        Int      10h

; Palette setting routine sets the color of the text purple

                        Mov      Dx,03C8h
                        Mov      Al,01h
                        Out      Dx,Al
                        Inc      Dx
                        Mov      Ah,07h
    SetPaletteLoop:     Mov      Al,Ah
                        Out      Dx,Al
                        Xor      Al,Al
                        Out      Dx,Al
                        Mov      Al,Ah
                        Out      Dx,Al
                        Inc      Ah
                        Cmp      Ah,26h
                        Jb       SetPaletteLoop
                        Xor      Cx,Cx      ; scrollers position
                        Xor      Bx,Bx      ; text counter
                        Mov      Di,0080h   ; position to write font
    IntroLoop:
    KeyValue:           Mov      Al,00h     ; check, if ESC pressed
                        Cmp      Al,01h
                        Jne      NoESC
; Stop playing
                        Cli                 ; set timer interrupt to occur
                        Mov      Al,34h     ;  18.2 times/second
                        Out      43h,Al
                        Xor      Al,Al
                        Out      40h,Al
                        Out      40h,Al
                        Push     00h
                        Pop      Gs         ; Return old timer interrupt and
                        Mov      Eax,Ds:[OldTimerInt]
                        Mov      Gs:[8*4],Eax;  old key interrupt
                        Mov      Eax,Ds:[OldKeyInt]
                        Mov      Gs:[9*4],Eax
                        Sti
                        Jmp      GoodBye
    NoESC:              Mov      Gs,Word Ptr [TextSegment+0001h]
                        Test     Cl,0Fh     ; test, if font must be writen
                        Jnz      DontPutFont
                        Xor      Ax,Ax      ; write font
                        Mov      Al,ScrollText[Bx] ; read font to write
                        Mov      Si,Ax      ; calculate the address of the
                        Sub      Si,20h     ;  font in the code segment
                        Shl      Si,07h
                        Add      Si,Offset Fonts+0060h
                        Mov      Bp,Di      ; set to Bp the position of font
                        Mov      Dh,07h     ; copy 7 lines and
    Loop2:              Mov      Dl,10h     ;  16 columns
    Loop1:              Mov      Al,Ds:[Si]
                        Mov      Gs:[Bp],Al
                        Inc      Si
                        Inc      Bp
                        Dec      Dl
                        Jnz      Loop1
                        Add      Bp,00F0h   ; next line address
                        Sub      Si,20h
                        Dec      Dh
                        Jnz      Loop2
                        Inc      Bx         ; increase text counter
                        Cmp      Bx,ScrollTextEnd-ScrollText
                        Jb       DontPutFont; if all fonts has been writed
                        Xor      Bx,Bx      ;  start text at the beginning
    DontPutFont:        Push     Bx         ; save value of text counter
                        Mov      Ah,07h     ; move one vertical line in
                        Mov      Bx,Di      ;  the scrolling-area to left
    CopyVerticalLine:   Mov      Al,Gs:[Bx] ;  so scroller seems to be
                        Mov      Gs:[Bx-80h],Al;  continuing
                        Inc      Bh
                        Dec      Ah
                        Jnz      CopyVerticalLine
                        Inc      Cx         ; add scroller position and
                        Inc      Di         ;  draw/move position
                        Or       Cl,Cl      ; If Cl>127, zero counters
                        Jns      NoZeroing
                        Xor      Cx,Cx
                        Mov      Di,0080h
    NoZeroing:          Push     Di

; Below routine writes the text to the scroller using those tables, which
; the program created before.

                        Mov      Word Ptr [ScrollLinePointer+0001h],0316h
                        Mov      Si,0320h
    TextSegment:        Push     7777h      ; move to Ds the scrolling-area
                        Pop      Ds         ;  segment
    ScrollLineLoop:     Mov      Edx,Fs:[Si]; read shading to Edx
                        Mov      Bx,Fs:[Si+04h]; line group height to Bp
                        Dec      Bx         ; decrease it and multiply by 8
                        Shl      Bx,03h     ;  so we get the address
                        Mov      Di,Fs:[Si+06h]; get linegroup write address
                        Mov      Gs,Fs:[Si+08h]; get source address segment
    ScrollMainLoop:     Mov      Si,Gs:[Bx+04h]; get two source addresses
                        Add      Si,Cx
                        Mov      Al,Ds:[Si]
                        Mov      Si,Gs:[Bx]
                        Add      Si,Cx
                        Mov      Ah,Ds:[Si]
                        Rol      Eax,10h
                        Mov      Si,Gs:[Bx+06h]
                        Add      Si,Cx
                        Mov      Al,Ds:[Si]
                        Mov      Si,Gs:[Bx+02h]
                        Add      Si,Cx
                        Mov      Ah,Ds:[Si]
                        And      Eax,Edx    ; make shadow for those bytes
                        Mov      Es:[Di],Eax;  and store to screen memory
                        Add      Di,0140h   ; move one line down and get
                        Sub      Bx,08h     ;  next information if any left
                        Jnc      ScrollMainLoop
    ScrollLinePointer:  Mov      Si,7777h
                        Sub      Word Ptr Cs:[ScrollLinePointer+0001h],0Ah
                        Jnc      ScrollLineLoop; loop this 80 times
                        Push     Cs         ; move Cs to Ds
                        Pop      Ds
                        Mov      Dx,03DAh
                        Cli
    WaitVR:             In       Al,Dx
                        And      Al,08h
                        Jz       WaitVR
                        Sti
                        Pop      Di         ; restore write position and
                        Pop      Bx         ;  text counter
                        Jmp      IntroLoop

  InitializeAdlib       Proc     Near
                        Mov      Ax,2001h   ; initialize Adlib
                        Call     AdlibCommand
                        Mov      Ax,0008h   ; set right mode and key split
                        Call     AdlibCommand
                        Mov      Al,0B0h
    QuietChannelLoop:   Call     AdlibCommand
                        Inc      Al
                        Cmp      Al,0BEh
                        Jb       QuietChannelLoop
                        Ret
  InitializeAdlib       EndP

  AdlibCommand          Proc     Near       ; Al=command, Ah=data
                        PushA
                        Mov      Dx,0388h   ; command port
                        Mov      Cl,05h
                        Call     WriteAndWait
                        Inc      Dx         ; data port
                        Mov      Al,Ah
                        Mov      Cl,10h
                        Call     WriteAndWait
                        PopA
                        Ret
    WriteAndWait:       Out      Dx,Al
      WaitAdlibLoop:    In       Al,Dx
                        Dec      Cl
                        Jnz      WaitAdlibLoop
                        Ret
  AdlibCommand          EndP

  Player                Proc     Near
                        PushA
                        Push     Ds
                        Push     Es
                        Push     Cs
                        Pop      Ds
                        Dec      Ds:[TempoCounter]; test if next row
                        Jns      DontChangeRows
                        Mov      Ds:[TempoCounter],07h; tempo is 7
                        Xor      Bp,Bp
    PatternsSegment:    Push     7777h      ; Move to Es the segment of
                        Pop      Es         ;  patterns
    Row:                Mov      Bl,77h     ; Bl=Row number*4
                        Mov      Al,Channels*16
    SongPosition:       Mov      Si,7777h   ; one track takes 256 bytes, so
                        Mul      Byte Ptr Ds:[Si];  set pattern nr*channels
                        Mov      Bh,Ah      ;  to Bh
    SetChannelsLoop:    Mov      Cx,Es:[Bx] ; Cl=note value, Ch=volume
                        Cmp      Cl,0FFh    ; If no note, set next track
                        Je       NoNote
                        Mov      Dx,Es:[Bx+02h]; Dl=octave, Dh=instrument
                        Mov      Ax,Bp
                        Add      Al,0B0h
                        Call     AdlibCommand
                        Mov      Al,Ss:[Bp+AdlibAddress]
                        Add      Al,20h
                        Cmp      Byte Ptr Ss:[Bp+InstrumentInfo],Dh
                        Je       DontChangeInst
                        Mov      Byte Ptr Ss:[Bp+InstrumentInfo],Dh
                        Sub      Al,20h     ; set instrument, if it's not same
                        Movzx    Di,Dh      ;  as before
                        Add      Di,Offset Instrument
    SetInstrumentLoop:  Add      Al,1Dh
                        Mov      Ah,Ds:[Di]
                        Call     AdlibCommand
                        Add      Al,03h
                        Mov      Ah,Ds:[Di+Instruments]
                        Add      Di,Instruments*2
                        Call     AdlibCommand
                        Or       Al,Al
                        Jns      SetInstrumentLoop
                        Add      Al,40h
                        Jnc      SetInstrumentLoop
                        Push     Ax
                        Mov      Ax,Bp
                        Add      Al,0C0h
                        Mov      Ah,Ds:[Di]
                        Call     AdlibCommand
                        Pop      Ax
    DontChangeInst:     Add      Al,20h     ; set volume of the instrument
                        Mov      Ah,Ch
                        Call     AdlibCommand
                        Movzx    Di,Cl      ; set new note to channel
                        Mov      Ax,Bp
                        Add      Al,0A0h
                        Mov      Ah,Byte Ptr Ds:[Di+NoteValue]
                        Call     AdlibCommand
                        Add      Al,10h
                        Mov      Ah,Byte Ptr Ds:[Di+Offset Notevalue+0001h]
                        Or       Ah,Dl
                        Call     AdlibCommand
    NoNote:             Inc      Bh
                        Inc      Bp
                        Cmp      Bp,Channels; do all channels
                        Jb       SetChannelsLoop
                        Add      Bl,04h     ; increase row
                        Adc      Si,00h     ; if last row, increase song pos.
                        Cmp      Si,Offset SongOrder+SongLength
                        Jb       NoRestart
                        Mov      Si,Offset SongOrder+Restart
    NoRestart:          Mov      Word Ptr Ds:[SongPosition+0001h],Si
                        Mov      Byte Ptr Ds:[Row+0001h],Bl
    DontChangeRows:     Pop      Es
                        Pop      Ds
                        Mov      Al,20h     ; send EOI to IRQ-chip
                        Out      20h,Al
                        PopA
                        Iret
  Player                EndP

  KeyInterrupt          Proc     Near
                        Push     Ax
                        Mov      Al,20h     ; EOI
                        Out      20h,Al
                        In       Al,60h
                        Mov      Byte Ptr Cs:[KeyValue+0001h],Al
                        Pop      Ax
                        Iret
  KeyInterrupt          EndP

  ScrollText            Db       '    THE SOLARIUM - ANARCHY SFHQ - THE BBS '
                        Db       'SERVES 24h A DAY AND OFFERS 1GB HARD DISK '
                        Db       'SPACE FOR YOUR USE WITH 16800 ZYXEL!   '
                        Db       'CALL +358-31-3170851 NOW!!!  '
  ScrollTextEnd         Label
  BBSInfoText           Db       'Solarium',00h,00h,'+358-31-3170851'
  BBSInfoTextEnd        Label

  PackedTrack           Db       09Ch,056h,044h,034h,043h,023h,033h,023h
                        Db       033h,032h,023h,023h,033h,023h,033h,033h
                        Db       043h,044h,054h,086h,008h
  AdlibAddress          Db       003h,004h,005h,00Bh,00Ch,00Dh,013h,014h,015h
  NoteValue             Dw       2157h      ; C-x
                        Dw       2181h      ; D-x
                        Dw       21B0h      ; E-x
                        Dw       21CAh      ; F-x
                        Dw       2202h      ; G-x
                        Dw       2241h      ; A-x
                        Dw       2287h      ; B-x
  Instruments           Equ      09h
  Instrument            Db       008h,0C2h,0C8h,0E2h,0EFh,0E0h,0C4h,0E2h,0C0h
                        Db       0E2h,0E2h,0E2h,0E2h,0E0h,0C0h,0E4h,0E2h,0E4h
                        Db       020h,01Ah,020h,010h,000h,000h,017h,00Eh,000h
                        Db       000h,006h,00Ah,008h,000h,000h,000h,000h,000h
                        Db       0F4h,015h,095h,0F4h,070h,0A8h,084h,0AFh,0F0h
                        Db       0F6h,054h,076h,0F6h,077h,0F6h,075h,0F6h,0F7h
                        Db       0F7h,0F9h,0F7h,0F4h,089h,058h,0F7h,0F6h,084h
                        Db       0F7h,0F7h,0F8h,0F7h,0F9h,0F8h,0F7h,0F6h,0F6h
                        Db       002h,000h,002h,000h,000h,000h,000h,001h,000h
                        Db       001h,000h,000h,000h,003h,000h,001h,000h,000h
                        Db       000h,006h,006h,00Ch,00Eh,008h,004h,008h,00Ch

  Channels              Equ      09h
  Patterns              Equ      07h
  SongLength            Equ      0Bh
  ReStart               Equ      05h
  SongOrder             Db       000h,010h,010h,020h,020h,030h,040h,050h,050h
                        Db       060h,060h

  Pattern00             Db       0FFh       ; Track 00
                        Db       0FFh       ; Track 01
                        Db       005h,000h  ; Track 02
                        Db       0E3h,0F1h
                        Db       05Fh,0EAh,047h,057h
                        Db       002h,080h  ; Track 03
                        Db       011h,010h  ; Track 04
                        Db       0E4h,0F2h
                        Db       073h,057h,061h,081h,053h,02Bh,073h,071h,081h
                        Db       091h,071h,081h,061h,063h,043h,027h
                        Db       01Ch,033h  ; Track 05
                        Db       0E4h,0F2h
                        Db       072h,070h,052h,052h,051h,061h,081h,052h,050h
                        Db       022h,022h,022h,022h,072h,070h,071h,081h,091h
                        Db       071h,081h,061h,062h,060h,042h,040h,022h,021h
                        Db       0FFh       ; Track 06
                        Db       015h,060h  ; Track 07
                        Db       0E6h,0F4h
                        Db       071h,075h,073h,073h,071h,075h,072h,070h,073h
                        Db       071h,075h,072h,072h,071h,071h,075h,072h,070h
                        Db       071h,071h
                        Db       0FFh       ; Track 08
  Pattern01             Db       0FFh       ; Track 09
                        Db       0FFh       ; Track 0A
                        Db       002h,080h  ; Track 0B
                        Db       002h,080h  ; Track 0C
                        Db       004h,090h  ; Track 0D
                        Db       005h,0B0h  ; Track 0E
                        Db       062h,000h  ; Track 0F
                        Db       0E2h,0F3h
                        Db       053h
                        Db       0E0h
                        Db       053h
                        Db       003h
                        Db       043h,043h,053h,053h
                        Db       007h,0E0h  ; Track 10
                        Db       0FFh       ; Track 11
  Pattern02             Db       0A5h,000h  ; Track 12
                        Db       0E3h,0F0h
                        Db       051h,091h,0A1h,0C1h
                        Db       007h
                        Db       041h,081h,091h,0B1h,051h,091h,0A1h,0C1h
                        Db       4Ah,000h   ; Track 13
                        Db       0E3h,0F7h
                        Db       051h,051h,0C1h,0C0h,051h,051h,050h,0C1h,0C1h
                        Db       008h
                        Db       051h,051h,0C1h,050h,051h,050h,051h,0C1h,0C1h
                        Db       0A0h,000h  ; Track 14
                        Db       057h
                        Db       001h
                        Db       047h,057h
                        Db       014h,080h  ; Track 15
                        Db       004h,090h  ; Track 16
                        Db       005h,0B0h  ; Track 17
                        Db       00Fh,080h  ; Track 18
                        Db       007h,0E0h  ; Track 19
                        Db       00Bh,000h  ; Track 1A
                        Db       0E2h,0F5h
                        Db       000h,000h,000h,002h,000h,000h,001h,000h,004h
                        Db       0EBh
  Pattern03             Db       0FFh       ; Track 1B
                        Db       013h,080h  ; Track 1C
                        Db       0FFh       ; Track 1D
                        Db       0FFh       ; Track 1E
                        Db       0FFh       ; Track 1F
                        Db       0FFh       ; Track 20
                        Db       067h,00h   ; Track 21
                        Db       0E1h,051h,050h,050h,0B0h,050h,0B0h,0C0h
                        Db       067h
                        Db       0E2h,011h,010h,010h,070h,010h,070h,080h
                        Db       0FFh       ; Track 22
                        Db       0FFh       ; Track 23
  Pattern04             Db       0FFh       ; Track 24
                        Db       013h,080h  ; Track 25
                        Db       0FFh       ; Track 26
                        Db       0FFh       ; Track 27
                        Db       0FFh       ; Track 28
                        Db       0E1h,034h  ; Track 29
                        Db       0E2h
                        Db       007h
                        Db       021h,080h  ; Track 2A
                        Db       0E2h,004h  ; Track 2B
                        Db       0E2h,0F8h
                        Db       007h
                        Db       08Bh,000h  ; Track 2C
                        Db       001h,070h,070h,071h,070h,000h,070h,000h,001h
                        Db       071h,070h,070h
  Pattern05             Db       0FFh       ; Track 2D
                        Db       0FFh       ; Track 2E
                        Db       044h,000h  ; Track 2F
                        Db       0E4h,0F0h
                        Db       090h,080h,070h
                        Db       003h
                        Db       060h,051h,023h,0E9h
                        Db       042h
                        Db       010h,020h,030h
                        Db       003h
                        Db       050h,071h,014h,0E9h
                        Db       02Fh,0A2h  ; Track 30
                        Db       02Fh,0C5h  ; Track 31
                        Db       029h,0B0h  ; Track 32
                        Db       021h,080h  ; Track 33
                        Db       02Bh,080h  ; Track 34
                        Db       02Ch,080h  ; Track 35
  Pattern06             Db       063h,000h  ; Track 36
                        Db       0E2h
                        Db       052h,052h,051h
                        Db       062h
                        Db       012h,012h,011h
                        Db       011h,030h  ; Track 37
                        Db       0F6h
                        Db       023h,021h,051h,083h,093h,023h,021h,011h,027h
                        Db       013h,051h,011h,051h,041h,031h,021h,01Fh
                        Db       02Bh,000h  ; Track 38
                        Db       090h,080h,070h,090h,080h,070h,090h,080h,070h
                        Db       060h,051h,023h
                        Db       042h
                        Db       010h,020h,030h
                        Db       002h
                        Db       050h,071h,013h
                        Db       042h
                        Db       080h,090h,0A0h
                        Db       002h
                        Db       0B0h,0C1h,083h
                        Db       038h,0A2h  ; Track 39
                        Db       038h,0C5h  ; Track 3A
                        Db       029h,0B0h  ; Track 3B
                        Db       021h,080h  ; Track 3C
                        Db       02Bh,080h  ; Track 3D
                        Db       02Ch,080h  ; Track 3E
  SongDataEnd           Label

; --- Cut below bytes off from compiled COM file ---

  ScrollersTrack        Db       0140h Dup(00h)
  TempoCounter          Db       00h
  OldTimerInt           Dd       00000000h
  OldKeyInt             Dd       00000000h
  ChannelInfo           Dw       Channels Dup(0000h)
  InstrumentInfo        Db       Channels Dup(00h)
  Fonts                 Db       3000h Dup(00h)
Code                    EndS
                        End      Start
