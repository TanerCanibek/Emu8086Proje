     name "kernel"
; this is a very basic example
; of a tiny operating system.
;
; this is kernel module!
;
; it is assumed that this machine
; code is loaded by 'micro-os_loader.asm'
; from floppy drive from:
;   cylinder: 0
;   sector: 2
;   head: 0


;=================================================
; how to test micro-operating system:
;   1. compile micro-os_loader.asm
;   2. compile micro-os_kernel.asm
;   3. compile writebin.asm
;   4. insert empty floppy disk to drive a:
;   5. from command prompt type:
;        writebin loader.bin
;        writebin kernel.bin /k
;=================================================

; directive to create bin file:
#make_bin#

; where to load? (for emulator. all these values are saved into .binf file)
#load_segment=0800#
#load_offset=0000#

; these values are set to registers on load, actually only ds, es, cs, ip, ss, sp are
; important. these values are used for the emulator to emulate real microprocessor state 
; after micro-os_loader transfers control to this kernel (as expected).
#al=0b#
#ah=00#
#bh=00#
#bl=00#
#ch=00#
#cl=02#
#dh=00#
#dl=00#
#ds=0800#
#es=0800#
#si=7c02#
#di=0000#
#bp=0000#
#cs=0800#
#ip=0000#
#ss=07c0#
#sp=03fe#



; this macro prints a char in al and advances
; the current cursor position:
putc    macro   char
        push    ax
        mov     al, char
        mov     ah, 0eh
        int     10h     
        pop     ax
endm


; sets current cursor position:
gotoxy  macro   col, row
        push    ax
        push    bx
        push    dx
        mov     ah, 02h
        mov     dh, row
        mov     dl, col
        mov     bh, 0
        int     10h
        pop     dx
        pop     bx
        pop     ax
endm


print macro x, y, attrib, sdat
LOCAL   s_dcl, skip_dcl, s_dcl_end
    pusha
    mov dx, cs
    mov es, dx
    mov ah, 13h
    mov al, 1
    mov bh, 0
    mov bl, attrib
    mov cx, offset s_dcl_end - offset s_dcl
    mov dl, x
    mov dh, y
    mov bp, offset s_dcl
    int 10h
    popa
    jmp skip_dcl
    s_dcl DB sdat
    s_dcl_end DB 0
    skip_dcl:    
endm



; kernel is loaded at 0800:0000 by micro-os_loader
org 0000h

; skip the data and function delaration section:
jmp start 
; The first byte of this jump instruction is 0E9h
; It is used by to determine if we had a sucessful launch or not.
; The loader prints out an error message if kernel not found.
; The kernel prints out "F" if it is written to sector 1 instead of sector 2.
           



;==== data section =====================

; welcome message:
msg  db "Micro-os'a ho",159,"geldiniz!", 0 

cmd_size        equ 10    ; size of command_buffer
command_buffer  db cmd_size dup("b")
clean_str       db cmd_size dup(" "), 0
prompt          db ">", 0

; commands:
chelp    db "help", 0
chelp_tail:
ccls     db "cls", 0
ccls_tail:
cquit    db "quit", 0
cquit_tail:
cexit    db "exit", 0
cexit_tail:
creboot  db "reboot", 0
creboot_tail:
cklavye  db "klavye", 0
cklavye_tail:
cfare  db "fare", 0
cfare_tail:
crestart  db "restart", 0
crestart_tail:
csekil  db "sekil", 0
csekil_tail:

help_msg db "Micro-os'u se",135,"ti",167,"iniz i",135,"in te",159,"ekk",154,"r ederiz!", 0Dh,0Ah
         db "Desteklenen komutlar",141,"n k",141,"sa listesi:", 0Dh,0Ah
         db "help   - bu listeyi yazd",141,"r.", 0Dh,0Ah
         db "cls    - ekran",141," temizle.", 0Dh,0Ah
         db "reboot - makineyi yeniden ba",159,"lat.", 0Dh,0Ah
         db "klavye - Klavye sayac",141,".", 0Dh,0Ah
         db "fare - Fare ile piksel ",135,"iz.", 0Dh,0Ah
         db "restart - Yeniden ba",159,"lat.", 0Dh,0Ah
         db "sekil   - G",154,"len y",154,"z.", 0Dh,0Ah
         db "quit   - reboot ile ayn",141,".", 0Dh,0Ah 
         db "exit   - quit ile ayn",141,".", 0Dh,0Ah
         db "Daha fazlas",141," yolda!", 0Dh,0Ah, 0

unknown  db "bilinmeyen komut: " , 0    

;======================================

start:

; set data segment:
push    cs
pop     ds

; set default video mode 80x25:
mov     ah, 00h
mov     al, 03h
int     10h

; blinking disabled for compatibility with dos/bios,
; emulator and windows prompt never blink.
mov     ax, 1003h
mov     bx, 0      ; disable blinking.
int     10h


; *** the integrity check  ***
cmp [0000], 0E9h
jz integrity_check_ok
integrity_failed:  
mov     al, 'F'
mov     ah, 0eh
int     10h  
; wait for any key...
mov     ax, 0
int     16h
; reboot...
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h
jmp	0ffffh:0000h	 
integrity_check_ok:
nop
; *** ok ***
              


; clear screen:
call    clear_screen
                     
                       
; print out the message:
lea     si, msg
call    print_string


eternal_loop:
call    get_command

call    process_cmd

; make eternal loop:
jmp eternal_loop


;===========================================
get_command proc near

; set cursor position to bottom
; of the screen:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]

gotoxy  0, al

; clear command line:
lea     si, clean_str
call    print_string

gotoxy  0, al

; show prompt:
lea     si, prompt 
call    print_string


; wait for a command:
mov     dx, cmd_size    ; buffer size.
lea     di, command_buffer
call    get_string


ret
get_command endp
;===========================================

process_cmd proc    near

;//// check commands here ///
; set es to ds
push    ds
pop     es

cld     ; forward compare.

; compare command buffer with 'help'
lea     si, command_buffer
mov     cx, chelp_tail - offset chelp   ; size of ['help',0] string.
lea     di, chelp
repe    cmpsb
je      help_command

; compare command buffer with 'cls'
lea     si, command_buffer
mov     cx, ccls_tail - offset ccls  ; size of ['cls',0] string.
lea     di, ccls
repe    cmpsb
jne     not_cls
jmp     cls_command
not_cls:

; compare command buffer with 'quit'
lea     si, command_buffer
mov     cx, cquit_tail - offset cquit ; size of ['quit',0] string.
lea     di, cquit
repe    cmpsb
je      reboot_command

; compare command buffer with 'exit'
lea     si, command_buffer
mov     cx, cexit_tail - offset cexit ; size of ['exit',0] string.
lea     di, cexit
repe    cmpsb
je      reboot_command

; compare command buffer with 'reboot'
lea     si, command_buffer
mov     cx, creboot_tail - offset creboot  ; size of ['reboot',0] string.
lea     di, creboot
repe    cmpsb
je      reboot_command  

; compare command buffer with 'klavye'
lea     si, command_buffer
mov     cx, cklavye_tail - offset cklavye  ; size of ['klavye',0] string.
lea     di, cklavye
repe    cmpsb
je      klavye_command

; compare command buffer with 'fare'
lea     si, command_buffer
mov     cx, cfare_tail - offset cfare  ; size of ['fare',0] string.
lea     di, cfare
repe    cmpsb
je      fare_command

; compare command buffer with 'restart'
lea     si, command_buffer
mov     cx, crestart_tail - offset crestart  ; size of ['restart',0] string.
lea     di, crestart
repe    cmpsb
je      restart_command

; compare command buffer with 'sekil'
lea     si, command_buffer
mov     cx, csekil_tail - offset csekil  ; size of ['sekil',0] string.
lea     di, csekil
repe    cmpsb
je      sekil_command

; ignore empty lines
cmp     command_buffer, 0
jz      processed


;////////////////////////////

; if gets here, then command is
; unknown...

mov     al, 1
call    scroll_t_area

; set cursor position just
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
dec     al
gotoxy  0, al

lea     si, unknown
call    print_string

lea     si, command_buffer
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed

; +++++ 'help' command ++++++
help_command:

; scroll text area 9 lines up:
mov     al, 9
call    scroll_t_area

; set cursor position 9 lines
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
sub     al, 9
gotoxy  0, al

lea     si, help_msg
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed




; +++++ 'cls' command ++++++
cls_command:
call    clear_screen
jmp     processed


; ++++ 'klavye' command ++++
klavye_command:

; Hosgeldin mesajini yazdir

mov bh, 0
lea bp, msj
mov bl, 0ch
mov cx, 66
mov dl, 0
mov dh, 0
mov ah, 13h
mov al, 0
int 10h

xor bx, bx

bekle:  ; bir etiket 

    ; Klavye hizmetini cagirir
    mov ah, 0
    int 16h
    
    cmp al, 27    ; al register'ina ESC tusu degeri atanir                              
    je dur        ; eger ESC tusuna basildiysa 'dur' etiketine atlanir 
    
    call turkce_karakter
     
    ; ekran uzerine karakter yazma hizmetini cagirir
    mov ah, 0eh
    int 10h
    
    inc bx        ; bx register degerini bir arttirir
    
    jmp bekle     ; aksi halde dongu basa doner

turkce_karakter:
    cmp al, 141 
    je tk_buldu

    cmp al, 152
    je tk_buldu

    cmp al, 167
    je tk_buldu

    cmp al, 166
    je tk_buldu

    cmp al, 159
    je tk_buldu

    cmp al, 158
    je tk_buldu

    cmp al, 135
    je tk_buldu

    cmp al, 128
    je tk_buldu

    cmp al, 148
    je tk_buldu

    cmp al, 153
    je tk_buldu

    cmp al, 129
    je tk_buldu

    cmp al, 154
    je tk_buldu

    ret

tk_buldu:
    ; Turkce karakterse ekrana yazdir
    mov ah, 0eh
    int 10h
    inc bx 
    jmp bekle
 

dur:    ; bir etiket
    ; msj2 mesajini yazdir
    lea bp, msj2
    mov cx, 24
    mov dl, 0
    mov dh, 22
    mov ah, 13h
    mov al, 1
    int 10h
    
mov ax, bx
call get_yaz_x

; klavye hizmetini cagirir
mov ah, 0
int 16h

ret

msj db "Klavye sayac",141,"na ho",159,"geldiniz. Sayac",141," durdurmak i",135,"in ESC'ye bas",141,"n.", 0Dh, 0Ah, "$"
msj2 db 0Dh, 0Ah, "Kaydedilen tu",159," say",141,"s",141,": $"

jmp processed ; processed etiketine atla


; +++++ 'fare' command +++++
fare_command:

call get_main ; get_main fonk cagir

jmp processed ; processed etiketine git


; +++ 'restart' command +++
restart_command:

call restart_makine ; restart_makine fonksiyonunu cagir 

jmp processed ; processed etiketine git  

restart_makine:
    call clear_screen ; clear_screen fonk cagir
    
    mov ax, 40h ; 40h adresini al
    mov es, ax  ; es resgister'ina 40h adresini yukle
    mov al, es:[84h] ; al register'ina es:84h adresindeki degeri yukle
    
    ; restart_msj yazdir
    lea si, restart_msj   
    call print_string     
    
    mov ax, 0040h  ; 0040h adresini al
    mov ds, ax     ; ds register'ina 0040h adresini yukle
    
    jmp start      ; start etiketine git
    
restart_msj db "Yeniden ba",159,"lat",141,"l",141,"yor..."   

; + 'sekil' command +
sekil_command:
; Video modu hizmeti
mov ax, 3       
int 10h
             
; Ekran baslangici ve renk ayari
mov dx, 0127h        
mov cx, 2           
mov bh, 0           
mov bl, 1001_1100b

y:  
    ; Imlec belli bir konuma tasinir
    mov ah, 02h         
    int 10h
    
    ; ASCII karakteri ekrana yazdirir              
    mov al, [ASCII_karakter]
    mov ah, 09h         
    int 10h
    
    ; Desen konumu dikey de guncellenir
    add dx, 00FEh       
    add cx, 4           
    cmp cx, 2+(4*11)
    jb y

x:  
    ; Kesme cagrisi
    mov ah, 02h         
    int 10h
    
    ; ASCII karateri ekrana yazdirir
    mov al, [ASCII_karakter]
    mov ah, 09h         
    int 10h
    
    ; Desen konumu yatay da guncellenir
    add dx, 0102h     
    sub cx, 4           
    jnb x

; Klavye hizmeti cagrisi
mov ah, 0
int 16h 

ret

ASCII_karakter db 2    ; ASCII karakterlerini kullanir        

jmp processed


; +++ 'quit', 'exit', 'reboot' +++
reboot_command:
call    clear_screen 
print 5,2,0011_1111b," please eject any floppy disks "
print 5,3,0011_1111b," and press any key to reboot... "
mov ax, 0  ; wait for any key....
int 16h
; store magic value at 0040h:0072h:
;   0000h - cold boot.
;   1234h - warm boot.
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h ; cold boot.
jmp	0ffffh:0000h	 ; reboot!

; ++++++++++++++++++++++++++

processed:
ret
process_cmd endp

;===========================================

; scroll all screen except last row
; up by value specified in al

scroll_t_area   proc    near

mov dx, 40h
mov es, dx  ; for getting screen parameters.
mov ah, 06h ; scroll up function id.
mov bh, 07  ; attribute for new lines.
mov ch, 0   ; upper row.
mov cl, 0   ; upper col.
mov di, 84h ; rows on screen -1,
mov dh, es:[di] ; lower row (byte).
dec dh  ; don't scroll bottom line.
mov di, 4ah ; columns on screen,
mov dl, es:[di]
dec dl  ; lower col.
int 10h

ret
scroll_t_area   endp

;===========================================




; get characters from keyboard and write a null terminated string 
; to buffer at DS:DI, maximum buffer size is in DX.
; 'enter' stops the input.
get_string      proc    near
push    ax
push    cx
push    di
push    dx

mov     cx, 0                   ; char counter.

cmp     dx, 1                   ; buffer too small?
jbe     empty_buffer            ;

dec     dx                      ; reserve space for last zero.


;============================
; eternal loop to get
; and processes key presses:

wait_for_key:

mov     ah, 0                   ; get pressed key.
int     16h

cmp     al, 0Dh                 ; 'return' pressed?
jz      exit


cmp     al, 8                   ; 'backspace' pressed?
jne     add_to_buffer
jcxz    wait_for_key            ; nothing to remove!
dec     cx
dec     di
putc    8                       ; backspace.
putc    ' '                     ; clear position.
putc    8                       ; backspace again.
jmp     wait_for_key

add_to_buffer:

        cmp     cx, dx          ; buffer is full?
        jae     wait_for_key    ; if so wait for 'backspace' or 'return'...

        mov     [di], al
        inc     di
        inc     cx
        
        ; print the key:
        mov     ah, 0eh
        int     10h

jmp     wait_for_key
;============================

exit:

; terminate by null:
mov     [di], 0

empty_buffer:

pop     dx
pop     di
pop     cx
pop     ax
ret
get_string      endp




; print a null terminated string at current cursor position, 
; string address: ds:si
print_string proc near
push    ax      ; store registers...
push    si      ;

next_char:      
        mov     al, [si]
        cmp     al, 0
        jz      printed
        inc     si
        mov     ah, 0eh ; teletype function.
        int     10h
        jmp     next_char
printed:

pop     si      ; re-store registers...
pop     ax      ;

ret
print_string endp



; clear the screen by scrolling entire screen window,
; and set cursor position on top.
; default attribute is set to white on blue.
clear_screen proc near
        push    ax      ; store registers...
        push    ds      ;
        push    bx      ;
        push    cx      ;
        push    di      ;

        mov     ax, 40h
        mov     ds, ax  ; for getting screen parameters.
        mov     ah, 06h ; scroll up function id.
        mov     al, 0   ; scroll all lines!
        mov     bh, 1001_1111b  ; attribute for new lines.
        mov     ch, 0   ; upper row.
        mov     cl, 0   ; upper col.
        mov     di, 84h ; rows on screen -1,
        mov     dh, [di] ; lower row (byte).
        mov     di, 4ah ; columns on screen,
        mov     dl, [di]
        dec     dl      ; lower col.
        int     10h

        ; set cursor position to top
        ; of the screen:
        mov     bh, 0   ; current page.
        mov     dl, 0   ; col.
        mov     dh, 0   ; row.
        mov     ah, 02
        int     10h

        pop     di      ; re-store registers...
        pop     cx      ;
        pop     bx      ;
        pop     ds      ;
        pop     ax      ;

        ret
clear_screen endp




get_yaz_x proc near
    
    cmp ax, 0  ; ax register'indaki degeri 0 ile karsilastirir
    jne yaz_y  ; eger deger sifir degilse yaz_y etiketine atlar
    
    ; ASCII degeri '0' olan karakterleri ekrana yazdirir
    mov al, '0'
    mov ah, 0eh
    int 10h
    pop ax  ; ax ile onceki ax degerini geri alir
    ret
    
    yaz_y:
        pusha  ; genel amacli register'lar stack'e kaydedilir
        mov dx, 0
        cmp ax, 0  ; 0 ile ax register'indaki deger 0 ile karilastirilir.
        je bitti  ; Eger deger sifir ise bitti etiketine atlar
        mov bx, 10  ; bx register'ina 10 degeri atanir
        div bx      ; bx register'i bolunur
        call yaz_y  
        ; Ekrana 'al' degerini ASCII olarak '0' ekleyerek donusturur
        mov ax, dx
        add al, 30h
        mov ah, 0eh
        int 10h
        jmp bitti ; bitti etiketine atla
    bitti:
        popa  ; onceki registerlar geri alinir
        ret

get_yaz_x endp   



get_main proc near
    
    ; Video modunu ayarlar
    mov ah, 00
    mov al, 13h    
    int 10h
    
    ; mouse hizmetini cagirir
    mov ax, 1      
    int 33h
    
    siradaki:         ; bir etiket
        mov ax, 3     ; mouse pozisyonu almak icin
        int 33h       ; mouse hizmetini cagirir
        
        call get_pixciz  ; mouse kullanarak get_pixciz cagirilir
        
        mov ah, 1        ; klavye hizmeti cagrisi
        int 16h
        
        cmp al, 27       ; al register'ina ESC tusu degeri atanir
        je son           ; eger ESC tusuna basildiysa 'son' etiketine atlanir
        
        jmp siradaki     ; aksi halde dongu basina doner
        
    son:
        mov ah, 0      
        int 16h        ; klavye hizmetini cagirir
        
        ret            ; prosedur sonlandirir
        
        jmp processed  ; processed etiketine atlar
        
get_main endp

get_pixciz proc 
    
    ; rastgele renkte piksel cizdirme
    mov al, dl     
    mov ah, 0ch    
    shr cx, 1      
    int 10h
    
    ret            
get_pixciz endp

