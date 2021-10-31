INCLUDE "constants.asm"

MAX_SAVS EQU 68
SAV_NAME_LENGTH EQU 17


SECTION "Xfer Save", ROM0

XferSave:
	di
	ld [MBC3RomBank], a
	ld a, 4
	ldh [rSVBK], a
	ld de, WRAM1_Begin
	ld bc, (sBox - sOptions) + (wCrystalDataEnd - wCrystalData) + (sLuckyIDNumber + 2 - sMysteryGiftItem)
	call CopyBytes
	ld a, BANK(SaveLoaderMenu)
	ld [MBC3RomBank], a
	ret


SECTION "Save Loader", ROMX

SaveLoaderMenu::
	farcall BlankScreen
	ld b, SCGB_DIPLOMA
	call GetSGBLayout
	call LoadStandardFont
	call LoadFontsExtra
	ld de, MUSIC_MAIN_MENU
	call PlayMusic
	hlcoord 1, 1
	ld de, .MenuTitle
	call PlaceString
	ld hl, .MenuHeader
	call CopyMenuHeader
	call InitScrollingMenu
.joypadLoop
	call ScrollingMenu
	ld b, a
	cp B_BUTTON
	ret z
	cp D_RIGHT
	jr nz, .checkLeft

; handle right pressed
	ld a, [wScrollingMenuListSize]
	cp 6
	jr nc, .multiplePages
	inc a
	ld [wMenuCursorPosition], a
	jr .joypadLoop
.multiplePages
	sub 5
	ld b, a
	ld a, [wMenuScrollPosition]
	ld c, a
	ld a, [wMenuCursorY]
	ld d, a
	add c
	sub b
	jr nc, .pastEnd
	ld a, c
	add 6
	ld e, a
	sub b
	jr nc, .lastPage
	ld a, d
	ld [wMenuCursorPosition], a
	ld a, e
	ld [wMenuScrollPosition], a
	jr .joypadLoop
.pastEnd
	ld a, b
	ld [wMenuScrollPosition], a
	ld a, 6
	ld [wMenuCursorPosition], a
	jr .joypadLoop
.lastPage
	ld a, d
	add e
	sub b
	ld [wMenuCursorPosition], a
	ld a, b
	ld [wMenuScrollPosition], a
	jr .joypadLoop
; end handle right pressed

.checkLeft
	cp D_LEFT
	jr nz, .handleSelection

; handle left pressed
	ld a, [wMenuScrollPosition]
	ld b, a
	ld a, [wMenuCursorY]
	ld c, a
	add b
	ld d, a
	cp 7
	jr c, .beforeStart
	ld a, b
	cp 6
	jr c, .firstPage
	sub 6
	ld [wMenuScrollPosition], a
	ld a, c
	ld [wMenuCursorPosition], a
	jr .joypadLoop
.beforeStart
	xor a
	ld [wMenuScrollPosition], a
	inc a
	ld [wMenuCursorPosition], a
	jr .joypadLoop
.firstPage
	ld a, d
	sub 6
	ld [wMenuCursorPosition], a
	xor a
	ld [wMenuScrollPosition], a
	jp .joypadLoop
; end handle left pressed

; handle A or select pressed on a save file
.handleSelection
	ld a, [wMenuSelection]
	dec a
	push bc
	ld b, 0
	ld c, a
	ld hl, .FreeSpace
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, $00
	call XferSave
	pop bc
	ld a, b
	cp SELECT
	ld a, SRAM_ENABLE
	ld [MBC3SRamEnable], a
	ld a, BANK("Save")
	ld [MBC3SRamBank], a
	jr z, .diff
	ld hl, WRAM1_Begin
	ld de, sOptions
	ld bc, sBox - sOptions
	call CopyBytes
	ld de, sCrystalData
	ld bc, wCrystalDataEnd - wCrystalData
	call CopyBytes
IF !DEF(IGT_AS_RTC)
; copy IGT hours/minutes/seconds from sav into RTC
	ld hl, hRTCDayHi
	xor a
	ld [hli], a
	ld [hli], a
	ld de, hRTCHours
	ld hl, sPlayerData + (wGameTimeHours + 1 - wPlayerData)
	ld bc, wGameTimeSeconds - wGameTimeHours
	call CopyBytes
	call SetClock
ENDC
	xor a
	ld [MBC3SRamBank], a
	ld de, sMysteryGiftItem
	ld bc, sLuckyIDNumber + 2 - sMysteryGiftItem
	call CopyBytes
	xor a
	ld [MBC3SRamEnable], a
	ret

.diff
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	ld a, " "
	call ByteFill
	hlcoord 0, 0
	ld de, WRAM1_Begin
	ld bc, sBox - sOptions
	inc b
	inc c
	jr .diffLoop
.diffCheck
	push de
	ld a, [de]
	push af
	ld a, d
	xor $70
	ld d, a
	ld a, [de]
	pop de
	cp d
	pop de
	call nz, .PlaceDiff
	inc de
.diffLoop
	dec c
	jr nz, .diffCheck
	dec b
	jr nz, .diffCheck
	xor a
	ld [MBC3SRamEnable], a
	inc a
	ld [hBGMapMode], a
	ei
.wait
	call DelayFrame
	jr .wait

.MenuTitle:
	db "Savefiles@"

.MenuHeader:
	db MENU_BACKUP_TILES
	menu_coords 1, 4, SCREEN_WIDTH - 2, SCREEN_HEIGHT - 2
	dw .MenuData
	db 1

.MenuData:
	db SCROLLINGMENU_ENABLE_SELECT | SCROLLINGMENU_DISPLAY_ARROWS | SCROLLINGMENU_ENABLE_FUNCTION3 | SCROLLINGMENU_ENABLE_LEFT | SCROLLINGMENU_ENABLE_RIGHT
	db 6, 0
	db SCROLLINGMENU_ITEMS_NORMAL
	dba .Numbers
	dba .PlaceSavName
	dba NULL
	dba .UpdateScrollState

.PlaceDiff:
	push bc
	push af
	ld a, d
	xor $f0
	call .PlaceHex
	ld a, e
	call .PlaceHex
	inc hl
	pop af
	call .PlaceHex
	lb bc, 0, 3
	add hl, bc
	pop bc
	ld a, h
	cp HIGH(wTilemapEnd)
	ret nz
	ld a, l
	cp LOW(wTilemapEnd)
	ret nz
	lb bc, 1, 1
	ret

.PlaceHex:
	ld b, a
	swap a
	and $f
	add "0"
	or "A"
	ld [hli], a
	ld a, b
	and $f
	add "0"
	or "A"
	ld [hli], a
	ret

.PlaceSavName:
	ld a, [wMenuSelection]
	dec a
	push de
	ld hl, .Strings
	ld bc, SAV_NAME_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl
	jp PlaceString

.UpdateScrollState:
	hlcoord 18, 1
	ld a, [wScrollingMenuListSize]
	ld b, a
	call .PlaceNumber
	ld a, "/"
	ld [hld], a
	ld a, [wMenuSelection]
	cp -1
	jr z, .cancel
	ld b, a
	call .PlaceNumber
	jr .done
.cancel
	ld a, "-"
	ld [hld], a
.done
	ld a, " "
	ld [hld], a
	ld [hld], a
	ret

.PlaceNumber:
.nextDigit
	ld a, b
	ld c, 0
.currentDigit
	sub 10
	inc c
	jr nc, .currentDigit
	add 10
	dec c
	add "0"
	ld [hld], a
	ld a, c
	and c
	ret z
	ld b, c
	jr .nextDigit

; update .Numbers and .Strings using custom tool along with .sav files
.Numbers:
	db 0 ; num savs
	db -1
for x, 1, MAX_SAVS
	db x + 1
endr
	db -1 ; end

.Strings:
REPT MAX_SAVS * SAV_NAME_LENGTH
	db "@"
ENDR

.FreeSpace:
; bank, upper byte of address (one of $40/$50/$60/$70)
; currently $1000 bytes allocated per save file (could be reduced to fit more)
	table_width 2, .FreeSpace
	db $0b, $70
	db $11, $50
	db $11, $60
	db $11, $70
	db $12, $70
	db $20, $70
	db $21, $70
	db $28, $60
	db $28, $70
	db $29, $70
	db $2c, $60
	db $2c, $70
	db $2e, $60
	db $2e, $70
	db $2f, $70
	db $35, $70
	db $36, $60
	db $36, $70
	db $3f, $60
	db $3f, $70
	db $41, $70
	db $59, $70
	db $5a, $70
	db $5b, $60
	db $5b, $70
	db $61, $70
	db $6b, $70
	db $6c, $70
	db $6e, $60
	db $6e, $70
	db $6f, $70
	db $70, $60
	db $70, $70
	db $71, $70
	db $72, $70
	db $73, $60
	db $73, $70
	db $74, $60
	db $74, $70
	db $75, $40
	db $75, $50
	db $75, $60
	db $75, $70
	db $76, $40
	db $76, $50
	db $76, $60
	db $76, $70
	db $78, $50
	db $78, $60
	db $78, $70
	db $79, $40
	db $79, $50
	db $79, $60
	db $79, $70
	db $7a, $40
	db $7a, $50
	db $7a, $60
	db $7a, $70
	db $7b, $50
	db $7b, $60
	db $7b, $70
	db $7c, $50
	db $7c, $60
	db $7c, $70
	db $7d, $70
	db $7f, $40
	db $7f, $50
	db $7f, $60
	assert_table_length MAX_SAVS
	db -1, -1 ; end
