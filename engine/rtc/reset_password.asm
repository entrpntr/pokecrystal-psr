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
	ld b, a
	ld hl, $4000
	and $3
	swap a
	add h
	ld h, a
	ld a, b
	srl a
	srl a
	add $78 ; first bank with save data
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

.Name
	ld a, [wMenuSelection]
	cp -1
	ret z
	push de
	ld hl, .Strings
	ld bc, $11
	call AddNTimes
	ld d, h
	ld e, l
	pop hl
	jp PlaceString

; update .Numbers and .Strings using custom tool along with .sav files
.Numbers
	db 0
	db -1
	db 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
	db -1

.Strings
	ds 16 * $11
