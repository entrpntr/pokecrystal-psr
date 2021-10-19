_ResetClock::
	farcall BlankScreen
	ld b, SCGB_DIPLOMA
	call GetSGBLayout
	call LoadStandardFont
	call LoadFontsExtra
	ld de, MUSIC_MAIN_MENU
	call PlayMusic
	hlcoord 1, 1
	ld de, .Title
	call PlaceString
	ld hl, .MenuHeader
	call CopyMenuHeader
	call InitScrollingMenu
	call ScrollingMenu
	ld b, a
	cp B_BUTTON
	ret z
	ld a, [wMenuSelection]
	cp -1
	ret z
	push bc
	ld b, 0
	ld c, a
	ld hl, Savefiles_FreeSpace
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
	ld hl, $d000
	ld de, sOptions
	ld bc, sBox - sOptions
	call CopyBytes
	ld de, sCrystalData
	ld bc, wCrystalDataEnd - wCrystalData
	call CopyBytes
	xor a
	ld [MBC3SRamBank], a
	ld de, sMysteryGiftItem
	ld bc, sLuckyIDNumber + 2 - sMysteryGiftItem
	call CopyBytes
	xor a
	ld [MBC3SRamEnable], a
	ret

.diff:
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	ld a, " "
	call ByteFill
	hlcoord 0, 0
	ld de, $d000
	ld bc, sBox - sOptions
	inc b
	inc c
	jr .diff_loop

.diff_check:
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

.diff_loop:
	dec c
	jr nz, .diff_check
	dec b
	jr nz, .diff_check
	xor a
	ld [MBC3SRamEnable], a
	inc a
	ld [hBGMapMode], a
	ei

.wait:
	call DelayFrame
	jr .wait

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

.Title:
	db "Savefiles@"

.MenuHeader:
	db MENU_BACKUP_TILES
	menu_coords 1, 4, SCREEN_WIDTH - 2, SCREEN_HEIGHT - 2
	dw .MenuData
	db 1

.MenuData:
	db SCROLLINGMENU_ENABLE_SELECT | SCROLLINGMENU_DISPLAY_ARROWS | SCROLLINGMENU_ENABLE_FUNCTION3
	db 6, 0
	db SCROLLINGMENU_ITEMS_NORMAL
	dba .Numbers
	dba .Name
	dba NULL
	dba .ScrollState

.ScrollState:
	hlcoord 18, 1
	ld a, [wScrollingMenuListSize]
	ld b, a
	call .PlaceNumber
	ld a, "/"
	ld [hld], a
	ld a, [wMenuSelection]
	inc a
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
.nextDigit:
	ld a, b
	ld c, 0
.currentDigit:
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

MAX_SAVS EQU 68
SAV_NAME_LENGTH EQU 17

.Name:
	ld a, [wMenuSelection]
	cp -1
	ret z
	push de
	ld hl, Savefiles_Strings
	ld bc, SAV_NAME_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl
	jp PlaceString

; update .Numbers and Savefiles_Strings using custom tool along with .sav files
.Numbers:
	db 0 ; num savs
	db -1
for x, 1, MAX_SAVS
	db x
endr
	db -1 ; end

Savefiles_Strings:
REPT MAX_SAVS * SAV_NAME_LENGTH
	db "@"
ENDR

Savefiles_FreeSpace:
; bank, upper byte of address (one of $40/$50/$60/$70)
; currently $1000 bytes allocated per save file (could be reduced to fit more)
	table_width 2, Savefiles_FreeSpace
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
