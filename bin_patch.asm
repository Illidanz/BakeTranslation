.psp
.open "BakeData/repack/PSP_GAME/SYSDIR/BOOT.BIN",0x8803F40

;Freed space until 0x0896863c
.org 0x08968278
  .area 0x3c3
  SCE_SAVE:
  li a2,0x1
  sw a2,0x4(a1)
  sw a2,0x8(a1)
  j SCE_SAVE_RET
  li a2,0x13

  VERTICAL_TEXT:
  lw a0,0x30(s1)
  nop
  sra a0,a0,0x6
  j VERTICAL_TEXT_RET
  move a1,a0

  CONVERT_VERTICAL:
  move s1,a1
  ;Check if we're drawing vertical text
  lw a1,0x24(a2)
  nop
  bne a1,0x1,@@ret
  andi a0,a0,0xffff
  ;Return an hardcoded value for some characters
  beql a0,0x20,@@ret
  li a0,0x3005
  beql a0,0x2015,@@ret  ; ―
  li a0,0x30af
  beql a0,0x2018,@@ret  ; ‘
  li a0,0x30b0
  beql a0,0x2019,@@ret  ; ’
  li a0,0x30b1
  beql a0,0x201c,@@ret  ; “
  li a0,0x30b2
  beql a0,0x201d,@@ret  ; ”
  li a0,0x30b3
  beql a0,0x2026,@@ret  ; …
  li a0,0x30ae
  ;Return if the character is > 0x7e
  bgt a0,0x7e,@@ret
  nop
  ;Add 0x3020 to the character code and tweak it for charcode gaps
  blt a0,0x70,@@done
  addiu a1,a0,0x3020
  blt a0,0x72,@@done
  addiu a1,a1,2
  addiu a1,a1,13
  @@done:
  move a0,a1
  @@ret:
  move s6,a0
  j CONVERT_VERTICAL_RET
  move a1,s1

  ;A copy of the function at 0x088ae390 to return a short character name
  GET_SHORT_CHAR_NAME3:
  addiu sp,sp,-0x10
  sw ra,0x0(sp)
  lw a0,0x50b8(a0)
  nop
  jal GET_SHORT_CHAR_NAME2
  nop
  lw a0,0x0897f380
  jal 0x088b58d8
  move a1,v0
  lw ra,0x0(sp)
  nop
  jr ra
  addiu sp,sp,0x10

  ;A copy of the function at 0x08833bf8 to return a short character name
  GET_SHORT_CHAR_NAME2:
  addiu sp,sp,-0x10
  lui a1,0x898
  sw s0,0x0(sp)
  sw ra,0x4(sp)
  jal GET_SHORT_CHAR_NAME
  lw s0,-0x70a0(a1)
  nop
  move a0,s0
  li a1,0
  jal 0x0880a504
  move a2,v0
  lw ra,0x4(sp)
  lw s0,0x0(sp)
  jr ra
  addiu sp,sp,0x10

  ;Return short character name ID
  GET_SHORT_CHAR_NAME:
  sltiu a1,a0,0xc
  beq a1,zero,GET_SHORT_CHAR_NAME_RET
  nop
  addiu v0,a0,0x5b
  GET_SHORT_CHAR_NAME_RET:
  jr ra
  nop

  GET_CHAR_LEN:
  addiu sp,sp,-0x70
  sw ra,0x0(sp)
  sw a0,0x4(sp)
  sw a1,0x8(sp)
  sw a2,0xc(sp)
  sw a3,0x10(sp)
  sw t0,0x14(sp)
  ;Get the font handle
  li a0,0x08a03e80
  lw a0,0x0(a0)
  ;Call sceFontGetCharInfo(SceFontHandle fontHandle, unsigned int charCode, SceFontCharInfo *charInfo[0x3c])
  move a1,a3
  jal 0x0894fbd8
  addiu a2,sp,0x20
  lw t0,0x14(sp)
  ;advancex is in charInfo[0x30]
  addiu a0,sp,0x20
  lw v0,0x34(a0)
  beq t0,zero,@@advancepos
  nop
  lw v0,0x30(a0)
  @@advancepos:
  li.s f13,64.0
  mtc1 v0,f12
  nop
  cvt.s.w f12,f12
  div.s f12,f12,f13
  lw ra,0x0(sp)
  lw a0,0x4(sp)
  lw a1,0x8(sp)
  lw a2,0xc(sp)
  lw a3,0x10(sp)
  jr ra
  addiu sp,sp,0x70

  ;Center wordwrapped lines
  ;a1 = string ptr
  CENTER_WORDWRAP:
  ;Setup stack
  addiu sp,sp,-0x180
  sw a0,0x0(sp)
  sw a1,0x4(sp)
  sw a2,0x8(sp)
  sw a3,0xc(sp)
  sw s0,0x10(sp)
  sw s1,0x14(sp)
  sw s2,0x18(sp)
  swc1 f10,0x1c(sp)
  swc1 f11,0x20(sp)
  swc1 f12,0x24(sp)
  swc1 f13,0x28(sp)
  ;Calculate the length for all the lines
  ;a0 = current str ptr
  ;a3 = current character
  ;s0 = line length ptr
  ;f10 = current length
  ;f11 = max length
  move a0,a1
  move a2,zero
  li t0,0x1
  mtc1 a2,f10
  nop
  mov.s f11,f10
  addiu s0,sp,0x30
  ;Load one character, check for line breaks and 0
  @@loop:
  lhu a3,0x0(a0)
  nop
  beq a3,0xa,@@linebreak
  addiu a0,a0,0x2
  beq a3,0x0,@@center
  nop
  jal GET_CHAR_LEN
  nop
  j @@loop
  add.s f10,f10,f12
  ;Set f11 if the length is more than the max, store it in s0 and move on
  @@linebreak:
  c.lt.s f10,f11
  nop
  bc1t @@linebreaksmall
  nop
  mov.s f11,f10
  @@linebreaksmall:
  swc1 f10,0x0(s0)
  move a2,zero
  mtc1 a2,f10
  j @@loop
  addiu s0,s0,0x4
  ;Finished calculating all the lengths, check the last length with max
  @@center:
  c.lt.s f10,f11
  nop
  bc1t @@centersmall
  nop
  mov.s f11,f10
  @@centersmall:
  swc1 f10,0x0(s0)
  addiu s0,sp,0x30
  addiu a0,sp,0x40
  lwc1 f10,0x0(s0)
  nop
  ;Registers setup
  ;a0 = new str
  ;a1 = original str
  ;s0 = line length ptr
  ;f10 = current length
  ;f11 = max length
  ;s2 = number of padding characters added
  c.seq.s f10,f11
  nop
  bc1t @@copyloop
  move s2,zero
  @@padline:
  ;Pad the line, length is in a2
  ;Length to pad = (f11 - f10) / 2
  sub.s f10,f11,f10
  li.s f12,2.0
  nop
  div.s f10,f10,f12
  li.s f12,4.84375
  nop
  div.s f10,f10,f12
  cvt.w.s f10,f10
  mfc1 a2,f10
  li a3,0x7b
  @@padloop:
  ble a2,0x0,@@copyloop
  addiu s2,s2,0x1
  sh a3,0x0(a0)
  addiu a0,a0,0x2
  j @@padloop
  addi a2,a2,-0x1
  @@copyloop:
  lhu a3,0x0(a1)
  addiu a1,a1,0x2
  sh a3,0x0(a0)
  beq a3,0x0,@@copyover
  addiu a0,a0,0x2
  beq a3,0xa,@@copybreak
  nop
  j @@copyloop
  nop
  ;On line break, check the next string length
  @@copybreak:
  addiu s0,s0,0x4
  lwc1 f10,0x0(s0)
  nop
  c.seq.s f10,f11
  nop
  bc1t @@copyloop
  nop
  j @@padline
  nop
  @@copyover:
  addiu a1,sp,0x40
  @@return:
  ;Original instructions
  lw a0,0x0(sp)
  lw a2,0x8(sp)
  lw a3,0xc(sp)
  lw s0,0x10(sp)
  lw s1,0x14(sp)
  addu a2,a2,s2
  lw s2,0x18(sp)
  lwc1 f10,0x1c(sp)
  lwc1 f11,0x20(sp)
  lwc1 f12,0x24(sp)
  lwc1 f13,0x28(sp)
  addiu a2,a2,0x1
  jal 0x088269d8
  move t0,s2
  ;Restore stack and return
  lw a1,0x4(sp)
  j CENTER_WORDWRAP_RETURN
  addiu sp,sp,0x180

  LINES_POS_TWEAK:
  mov.s f20,f4
  mov.s f21,f14
  ;Move lines text (0x43d2)
  lui a1,0x43c6
  mtc1 a1,f14
  ;Move lines number (0x43be)
  lui a1,0x43b2
  mtc1 a1,f4
  j LINES_POS_TWEAK_RETURN
  addiu a1,a2,0x400
  .endarea

;This function has a list of harcoded characters that are offset
;when rendering them vertically, we just don't care about this
;Use the space after to inject some more code
.org 0x088266bc
  .area 0x318
  jr ra
  li v0,0x0

  SWAP_CIRCLE_CROSS:
  move t0,a1
  lbu a1,0x5(t0)
  nop
  srl a2,a1,5
  srl a3,a1,6
  xor a2,a2,a3
  andi a2,a2,0x1
  sll a3,a2,5
  sll a2,a2,6
  or a2,a2,a3
  xor a2,a1,a2
  sb a2,0x5(t0)
  move a1,t0
  ;Original code
  lw s1,0x4(a1)
  lw a2,0x0(a0)
  j SWAP_CIRCLE_CROSS_RET
  nop

  ;Wrap the sprintf function by repeating the parameter
  SPRINTF_REPEAT:
  addiu sp,sp,-0x10
  sw ra,0x0(sp)
  jal 0x088cf7f8
  move a3,a2
  lw ra,0x0(sp)
  nop
  jr ra
  addiu sp,sp,0x10

  ;Cut text off taking VWF into account
  ;Originally text is cut off at 0x17 (horizontal) or 0xe (vertical) length
  ;s1 = str ptr (actually a copy, but this is what will be used and cut off)
  ;a1 = max amount of characters
  ;s2 = 1 for shorter text (vertical)
  CUTOFF_TEXT:
  addiu sp,sp,-0x20
  swc1 f10,0x0(sp)
  swc1 f11,0x4(sp)
  swc1 f12,0x8(sp)
  swc1 f13,0xc(sp)
  sw s1,0x10(sp)
  sw a2,0x14(sp)
  sw a3,0x18(sp)
  sw t0,0x1c(sp)
  li a2,0x0
  li t0,0x1
  li.s f10,0.0
  li.s f11,490.0
  ;Don't use the delay slot here since li.s assembles to 2 instructions
  beq s2,zero,@@loop
  nop
  li.s f11,308.0
  @@loop:
  lhu a3,0x0(s1)
  nop
  beq a3,0xa,@@linebreak
  addiu s1,s1,0x2
  beql a3,0x0,@@return
  move a2,a1
  @@check:
  beql a3,0x20,@@getlen
  move a2,a1
  @@getlen:
  jal GET_CHAR_LEN
  addiu a1,a1,0x1
  add.s f10,f10,f12
  c.lt.s f10,f11
  nop
  bc1t @@loop
  nop
  j @@return
  subiu a1,a1,0x1
  @@linebreak:
  ;Replace with space, or invisible character if it's the first one
  li a3,0x20
  beql a2,zero,@@notfirst
  li a3,0x7c
  @@notfirst:
  sh a3,-0x2(s1)
  j @@check
  nop
  @@return:
  move a1,a2
  lwc1 f10,0x0(sp)
  lwc1 f11,0x4(sp)
  lwc1 f12,0x8(sp)
  lwc1 f13,0xc(sp)
  lw s1,0x10(sp)
  lw a2,0x14(sp)
  lw a3,0x18(sp)
  lw t0,0x1c(sp)
  sw a0,0x354(s0)
  j CUTOFF_TEXT_RETURN
  addiu sp,sp,0x20

  LB_TO_SPACE:
  li s1,REPLACE_LB
  lw t2,0x0(s1)
  nop
  beq t2,zero,@@return
  @@loop:
  li t3,0x20
  lhu t2,0x0(s1)
  addiu s1,s1,0x2
  beq t2,zero,@@return
  nop
  bne t2,0xa,@@loop
  nop
  ;Check if it's the first character of the string
  lw t2,0x350(s0)
  nop
  addiu t2,t2,0x2
  ;In that case, set the character to an invisible space
  beql t2,s1,@@notfirst
  li t3,0x7c
  @@notfirst:
  j @@loop
  sh t3,-0x2(s1)
  @@return:
  lw s1,0x350(s0)
  li t2,0x0
  j LB_TO_SPACE_RETURN
  li t3,0

  REPLACE_LB:
  .dw 0

  SET_REPLACE_LB:
  li a1,0x1
  li a3,REPLACE_LB
  sw a1,0x0(a3)
  li a1,0x0
  j SET_REPLACE_LB_RETURN
  li a3,0x0

  ;If REPLACE_LB is set, copy a2 bytes from a1 to a0
  ;s4 = result from wcslen
  LB_TO_SPACE_LONG:
  sw v0,0x24(s0)
  li a1,REPLACE_LB
  lw a0,0x0(a1)
  nop
  beq a0,zero,@@retnormal
  nop
  sw zero,0x0(a1)
  addiu sp,sp,-0x10
  move a0,v0
  move a1,s3
  sw a0,0x0(sp)
  sw a1,0x4(sp)
  sw a2,0x8(sp)
  sw a3,0xc(sp)
  li t8,-1
  @@loop:
  addi t8,t8,0x1
  lhu a3,0x0(a1)
  addiu a2,a2,-0x1
  sh a3,0x0(a0)
  beq a3,0x0,@@return
  addiu a1,a1,0x2
  beq a2,0x0,@@return
  addiu a0,a0,0x2
  bne a3,0xa,@@loop
  li a3,0x20
  beql t8,zero,@@notfirst
  li a3,0x7c
  @@notfirst:
  sh a3,0x0(a0)
  addiu s4,s4,0x2
  sw s4,0x28(s0)
  j @@loop
  addiu a0,a0,0x2
  @@return:
  lw a0,0x0(sp)
  lw a1,0x4(sp)
  lw a2,0x8(sp)
  lw a3,0xc(sp)
  j LB_TO_SPACE_LONG_RETURN
  addiu sp,sp,0x10
  @@retnormal:
  j LB_TO_SPACE_LONG_RETURN_NORMAL
  move a0,v0
  .endarea

;Center wordwrapped lines
.org 0x08826668
  jal CENTER_WORDWRAP
  .skip 12
  CENTER_WORDWRAP_RETURN:

;Cut off text taking VWF into account
.org 0x08826460
  j CUTOFF_TEXT
  li a1,0x1
  .skip 8
  CUTOFF_TEXT_RETURN:

;Change line breaks to spaces for glossary lines
.org 0x088263fc
  j LB_TO_SPACE
  .skip 4
  LB_TO_SPACE_RETURN:
.org 0x088b41f0
  j SET_REPLACE_LB
  .skip 4
  SET_REPLACE_LB_RETURN:
.org 0x0882651c
  j LB_TO_SPACE_LONG
  .skip 4
  LB_TO_SPACE_LONG_RETURN_NORMAL:
  .skip 8
  LB_TO_SPACE_LONG_RETURN:

;Make some more space for the allocation to replace line breaks with line break+space
.org 0x08826504
  ;addiu a0,s4,0x1
  addiu a0,s4,0x2

;Handle vertical text VWF
.org 0x088e4da8
  j VERTICAL_TEXT
  sw zero,0x2c(s1)
  nop
  nop
  nop
  VERTICAL_TEXT_RET:

;Convert the character code for vertical text
.org 0x088e49ec
  j CONVERT_VERTICAL
  move s0,a1
  CONVERT_VERTICAL_RET:

;Swap date order for save games
.org 0x088094a0
  lhu a2,0x212(sp) ;MM
  lhu a3,0x214(sp) ;DD
  lhu t0,0x210(sp) ;YYYY

;Swap order for "%sで対%s語録が|使えるようになりました。||対%s戦オススメの語録で|シングルモードでのみ使用可能な語録です。"
.org 0x088cd2d4
  move a2,s1
  move a3,s3
.org 0x088cd33c
  move a2,s1
  move a3,s3
.org 0x088cd3a4
  move a2,s1
  move a3,s3
.org 0x088cd408
  move a2,s1
  move a3,s3

;Add more space for the "Glossary n" lines
.org 0x0881da9c
  addiu s4,s4,0x12

;Use short character names in the menu
;Original:
;4f: 阿良々木暦
;50: 戦場ヶ原ひたぎ
;51: 八九寺真宵
;54: 神原駿河
;52: 千石撫子
;53: 羽川翼
;55: ブラック羽川
;59: 阿良々木火憐
;5A: 阿良々木月火
;56: 忍野メメ
;57: 忍野忍
.macro short_char_names
  .dw 0x5b ;暦
  .dw 0x5c ;ひたぎ
  .dw 0x5d ;真宵
  .dw 0x60 ;駿河
  .dw 0x5e ;撫子
  .dw 0x5f ;翼
  .dw 0x61 ;猫
  .dw 0x65 ;火憐
  .dw 0x66 ;月火
  .dw 0x62 ;メメ
  .dw 0x63 ;忍
.endmacro
.org 0x0897c728
  short_char_names
.org 0x0897dd7c
  short_char_names

;Use short character names in menu headers
.org 0x088af798
  jal GET_SHORT_CHAR_NAME3 - 0x8804000
.org 0x088b2fec
  jal GET_SHORT_CHAR_NAME3 - 0x8804000
.org 0x088b3a64
  jal GET_SHORT_CHAR_NAME3 - 0x8804000
.org 0x088ae02c
  jal GET_SHORT_CHAR_NAME3 - 0x8804000
.org 0x088b1128
  jal GET_SHORT_CHAR_NAME3 - 0x8804000
.org 0x088c4d2c
  jal GET_SHORT_CHAR_NAME2 - 0x8804000

;Repeat sprintf parameter for these two strings:
;"%sの「中敵」語録が開放されました。|フリー対戦モード限定のＣＯＭ専用語録です。|より強力なＣＯＭと会話劇ができます。"
.org 0x088cd1e4
  jal SPRINTF_REPEAT - 0x8804000
;"%sの「強敵」語録が開放されました。|フリー対戦モード限定のＣＯＭ専用語録です。|最強難易度に挑戦してみてください！"
.org 0x088cd214
  jal SPRINTF_REPEAT - 0x8804000

;Align "Achievements" header
.org 0x088bc20c
  ;lui v0,0x41a0
  lui v0,0x4140
;Move Progress text
.org 0x088bc2e4
  ;lui t3,0x43b4
  lui t3,0x43a0
;Move first progress number
.org 0x088bbf64
  ;li a1,0x15c
  li a1,0x16c
;Move second progress number
.org 0x088bbf7c
  ;li a1,0x176
  li a1,0x186
;Don't overwrite the progress position every frame
.org 0x088bbf4c
  ;swc1 f12,0x0(a0)
  nop

;Align "General" header
.org 0x088b8828
  ;lui a0,0x4260
  lui a0,0x4270
;Move the hour number
.org 0x088bbce8
  ;lui a1,0x439a
  lui a1,0x4393
;Move the : and minute number
.org 0x088bbd3c
  ;lui a0,0x4396
  lui a0,0x4391
;Move (Hr:M) text
.org 0x088bbe80
  ;lui a0,0x4100
  lui a0,0x3e99
;NOTE: the stuff below runs at boot
;Move wins/losses text
.org 0x088bccb8
  ;lui a1,0x43b8
  lui a1,0x43a8
;Move wins number
.org 0x088bcccc
  ;lui a1,0x43ab
  lui a1,0x439b
;Move losses number
.org 0x088bccdc
  ;lui a1,0x43c2
  lui a1,0x43b8
;Move lines number/text
.org 0x088bd0d4
  ;addiu a1,a2,0x400
  j LINES_POS_TWEAK
  .skip 4
  LINES_POS_TWEAK_RETURN:
;Fix the last 3 Beat Character values that are set after
.org 0x088bd0f0
  ;swc1 f14,0x438(a2)
  swc1 f21,0x438(a2)
.org 0x088bd100
  ;swc1 f4,0x458(a2)
  swc1 f20,0x458(a2)
.org 0x088bd128
  ;swc1 f14,0x4B8(a2)
  swc1 f21,0x4b8(a2)
.org 0x088bd138
  ;swc1 f4,0x4d8(a2)
  swc1 f20,0x4d8(a2)
.org 0x088bd160
  ;swc1 f14,0x538(a2)
  swc1 f21,0x538(a2)
.org 0x088bd170
  ;swc1 f4,0x558(a2)
  swc1 f20,0x558(a2)


;Don't use installed data, always return 0 from the function that checks for it
.org 0x08807438
  j 0x08807470
  nop
;Do not prompt to install data on new game
.org 0x088232c4
  ;li a1,0xa
  li a1,0xb

;Set the language to 1 (English) and buttonSwap to 1 (X) for syscalls
;sceImposeSetLanguageMode
.org 0x0880706c
  li a1,0x1
  .skip 8
  li a0,0x1
;sceUtilitySavedataInitStart
.org 0x08807174
  j SCE_SAVE
  .skip 4
  SCE_SAVE_RET:

;Swap Circle with Cross
;Call the code after the sceCtrlReadBufferPositive call
.org 0x088ebd28
  j SWAP_CIRCLE_CROSS
  nop
  SWAP_CIRCLE_CROSS_RET:

;Redirect some error codes to free up some space
ERROR_PTR equ 0x08968250 - 0x08804000
.org 0x08925d24
  lui a1,hi(ERROR_PTR)
  addiu a1,a1,lo(ERROR_PTR)
.org 0x08926184
  li a1,ERROR_PTR
.org 0x0892619c
  addiu a1,a1,lo(ERROR_PTR)
.org 0x089261c8
  addiu a1,a1,lo(ERROR_PTR)
.org 0x089261ec
  addiu a1,a1,lo(ERROR_PTR)
.org 0x08926450
  lui a1,hi(ERROR_PTR)
  .skip 4
  addiu a1,a1,lo(ERROR_PTR)
.org 0x089264d8
  lui a1,hi(ERROR_PTR)
  .skip 4
  addiu a1,a1,lo(ERROR_PTR)
.org 0x089264e4
  lui a1,hi(ERROR_PTR)
  .skip 8
  addiu a1,a1,lo(ERROR_PTR)
.org 0x089264f8
  lui a1,hi(ERROR_PTR)
  .skip 4
  addiu a1,a1,lo(ERROR_PTR)
.org 0x08926504
  lui a1,hi(ERROR_PTR)
  .skip 4
  addiu a1,a1,lo(ERROR_PTR)
.org 0x08926698
  lui a1,hi(ERROR_PTR)
  .skip 4
  addiu a1,a1,lo(ERROR_PTR)
.close
