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
	ld hl, .FreeSpace
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, 0
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

.diff
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

.diff_check
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

.diff_loop
	dec c
	jr nz, .diff_check
	dec b
	jr nz, .diff_check
	xor a
	ld [MBC3SRamEnable], a
	inc a
	ld [hBGMapMode], a
	ei

.wait
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

.Title
	db "Select a save file@"

.MenuHeader
	db MENU_BACKUP_TILES
	menu_coords 1, 4, SCREEN_WIDTH - 2, SCREEN_HEIGHT - 2
	dw .MenuData
	db 1

.MenuData
	db STATICMENU_CURSOR | STATICMENU_PLACE_TITLE
	db 6, 0
	db SCROLLINGMENU_ITEMS_NORMAL
	dba .Numbers
	dba .Name
	dba NULL
	dba NULL

MAX_SAVS EQU 68
SAV_NAME_LENGTH EQU 17

.Name
	ld a, [wMenuSelection]
	cp -1
	ret z
	push de
	ld hl, .Strings
	ld bc, SAV_NAME_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl
	jp PlaceString

; update .Numbers and .Strings using custom tool along with .sav files
.Numbers
	db  0 ; num savs
.ids
	table_width 1, .ids
	db -1,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
	db 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
	db 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47
	db 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63
	db 64, 65, 66, 67
	assert_table_length MAX_SAVS
	db -1 ; end

.Strings
	table_width SAV_NAME_LENGTH, .Strings
REPT MAX_SAVS
	db "                @"
ENDR
	assert_table_length MAX_SAVS

.FreeSpace
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
