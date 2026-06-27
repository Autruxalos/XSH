; =============================================================================
; XSH - THE NATIVE XOS SHELL [XSPEC-0006]
; Dual mode syntax: 16-bit XKERNEL / 64-bit Void Linux Syscalls
; =============================================================================

%ifdef VOID_LINUX
    bits 64
    global _start
    section .text
_start:
    call xsh_init
    mov rax, 60                 ; Linux: sys_exit
    xor rdi, rdi                
    syscall
%else
    bits 16
    org 0x0000                  
    global xsh_main
xsh_main:
    call xsh_init
    ret
%endif

; =============================================================================
; LOGICA DE LA SHELL NATIVA
; =============================================================================
xsh_init:
    mov si, msg_welcome
    call xsh_print

xsh_loop:
    mov si, msg_prompt
    call xsh_print

    call xsh_read_line          ; Guarda la entrada de texto en buffer_input

    mov si, buffer_input
    call xsh_parse_command

    jmp xsh_loop
    ret

; =============================================================================
; PARSER DE COMANDOS COMPATIBLE
; =============================================================================
xsh_parse_command:
    push si
    
    mov al, [si]
    cmp al, 0
    je .done

    ; Comando: ver
    mov di, cmd_ver
    call xsh_strcmp
    jc .execute_ver

    ; Comando: dir
    mov di, cmd_dir
    call xsh_strcmp
    jc .execute_dir

    ; Comando: limpiar
    mov di, cmd_clear
    call xsh_strcmp
    jc .execute_clear

    ; Comando desconocido
    mov si, msg_err_cmd
    call xsh_print

.done:
    pop si
    ret

.execute_ver:
    mov si, msg_ver_out
    call xsh_print
    jmp .done

.execute_dir:
    mov si, msg_dir_out         
    call xsh_print
    jmp .done

.execute_clear:
    %ifdef VOID_LINUX
        mov si, ansi_clear
        call xsh_print
    %else
        mov ax, 0x0003
        int 0x10
    %endif
    jmp .done

; =============================================================================
; CAPA DE ENTRADA / SALIDA (HAL)
; =============================================================================
xsh_print:
%ifdef VOID_LINUX
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    
    mov rdi, rsi
    xor rcx, rcx
.len_loop:
    cmp byte [rdi], 0
    je .len_done
    inc rdi
    inc rcx
    jmp .len_loop
.len_done:
    mov rdx, rcx                
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    syscall

    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
%else
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0x00
.bios_loop:
    lodsb
    cmp al, 0
    je .bios_done
    int 0x10
    jmp .bios_loop
.bios_done:
    pop bx
    pop ax
    ret
%endif

xsh_read_line:
%ifdef VOID_LINUX
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, buffer_input       
    mov rdx, 63                 
    syscall
    
    xor rcx, rcx
.nl_loop:
    cmp byte [rsi + rcx], 10    ; Encontrar salto de linea (LF)
    je .nl_found
    cmp rcx, rdx
    je .nl_found
    inc rcx
    jmp .nl_loop
.nl_found:
    mov byte [rsi + rcx], 0     ; Reemplazar por 0 ASCII
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
%else
    push ax
    push bx
    xor cx, cx                  
.bios_key:
    mov ah, 0x00                
    int 0x16
    cmp al, 13                  ; Enter
    je .bios_key_done
    
    mov ah, 0x0E                ; Eco en pantalla
    int 0x10
    
    mov bx, buffer_input
    add bx, cx
    mov [bx], al
    inc cx
    cmp cx, 63
    jne .bios_key
.bios_key_done:
    mov bx, buffer_input
    add bx, cx
    mov byte [bx], 0            
    pop bx
    pop ax
    ret
%endif

xsh_strcmp:
    push si
    push di
    push ax
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.not_equal:
    clc                         
    jmp .exit
.equal:
    stc                         
.exit:
    pop ax
    pop di
    pop si
    ret

; SECCIÓN DE DATOS
msg_welcome  db '--- Ecosistema de Comandos XSH v0.1 ---', 10, 13, 0
msg_prompt   db 10, 13, '| ', 0
msg_err_cmd  db 10, 13, 'Error: Comando o XEXE no reconocido.', 0
cmd_ver      db 'ver', 0
msg_ver_out  db 10, 13, 'XOS Shell nativa sin dependencias UNIX.', 0
cmd_dir      db 'dir', 0
msg_dir_out  db 10, 13, 'Estructura lineal EXFS: [|system|] [|apps|] [|games|]', 0
cmd_clear    db 'limpiar', 0
ansi_clear   db 27, '[2J', 27, '[H', 0 

section .bss
buffer_input resb 64
