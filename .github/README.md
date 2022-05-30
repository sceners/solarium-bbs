# Solarium BBStro

#### Written in 1994 for MS-DOS.

[Original package](https://defacto2.net/f/b028bec)

```
     An Anarchy Production

         ┐  └┐ │ ┌┘  ┌
     ─┐  └┐Assembler┌┘  ┌─
      └Sources Included!┘
   ──┐  └ ▄▄███████▄▄ ┘  ┌──
  ┐  └─ ▄████▀███▀████▄ ─┘  ┌
  └─── ▄████ ▄ █ ▄ ████▄ ───┘
 ───── ████████▀████████ ─────

        S O L A R I U M
             B B S
      ADVERTISEMENT INTRO
    (for Adlib,VGA and 386)
SPiDeR/OTL/ToXiC/TMC & EXoTiC/TRaXX/TMC
```

![image](https://user-images.githubusercontent.com/513842/170977742-1c4cb5ae-aa52-4e02-ab64-1761b02a811e.png)

---

```asm
; ///////////////////////////////////////////////////////////////////////////
; ////                                                                   ////
; ////  ▄██████ ▄█████▄ ███        ███    ██████▄ ███ ███ ███ ███   ███  ////
; ////  ███     ███ ███ ███       █████   ███ ███ ███ ███ ███ ████ ████  ////
; ////  ▀█████▄ ███ ███ ███      ███ ███  ██████▀ ███ ███ ███ ███ █ ███  ////
; ////      ███ ███ ███ ███     ███   ███ ███▀██▄ ███ ███ ███ ███   ███  ////
; ////  ██████▀ ▀█████▀ ███████ ███   ███ ███ ▀██ ███ ▀█████▀ ███   ███  ////
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
; ////       ∙ calculate the screen address for each vertical line       ////
; ////       ∙ calculate the source position for each pixel              ////
; ////       ∙ calculate the shading for each vertical pixel line        ////
; ////   - set the music routine to the timer interrupt                  ////
; ////   - set the new key interrupt (disable pause etc.)                ////
; ////   - create the characters                                         ////
; ////   - set palette                                                   ////
; ////   - intro-loop                                                    ////
; ////       ∙ test if ESC pressed                                       ////
; ////       ∙ write text to scrolling-area                              ////
; ////       ∙ draw scroll to the screen                                 ////
; ////       ∙ wait vertical retrace                                     ////
; ////   - return old interrupts                                         ////
; ////   - return to DOS                                                 ////
; ////                                                                   ////
; ///////////////////////////////////////////////////////////////////////////
```
