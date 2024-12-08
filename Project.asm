; Micro processors and Assembly Language 83255 - 01
; Final Project - Bulls and cows GAME DUE 21.09.2024 23:59
; Students : Daniel Negbi ID 326709144 , Shimon Ben Ami ID 215489949

.model small
.stack 100h
.data
    key_pressed db 0 ; detect if a key was pressed
    welcome_msg db 'Welcome to the Bulls & Cows Game', 0
    credits_msg db 'Developed by Daniel Negbi & Shimon Ben Ami', 0
    play_option db 'play', 0
    difficulty_option db 'difficulty', 0
    exit_option db 'exit', 0
    generated_code_msg db 'Generated Code: ', 0
    back_option db 'back to main menu', 0
    cursor_pos dw 0 ; position of the cursor on the screen (crucial and printing)
    current_selection db 0 ; 0 = play, 1 = difficulty, 2 = exit
    current_menu db 0 ; 0 = main menu, 1 = play menu, 2= difficulty menu
	; variables to capture starting and current time
	start_hours db 0
    start_minutes db 0
    start_seconds db 0
    current_hours db 0
    current_minutes db 0
    current_seconds db 0
	elapsed_hours   db 0
    elapsed_minutes db 0
    elapsed_seconds db 0
	time_str db '00:00:00$'
	win_time_str db '00:00:00$' ; will hold the time until winning in the current session
	clock_msg db 'clock time:', 0
	timer_msg db 'timer time:', 0
    seed dw ? ; the seed to generate the code based on the current time
    generated_code db 4 dup(0), 0 ; 4 digits
	generated_code_cover db 4 dup('*'), 0 ; 4 '*'
    number_options db '0123456789', 0 ; will be displayed in the game
    play_selection db 0 ; 0-9 for numbers, 10 for back option, 11 for submit
    user_guess db 'Your guess: ', 0
    guess_length db 0
    user_guess_digits db 4 dup('_') ; store the guessed digits
    submit_option db 'submit', 0
    incomplete_msg db 'Incomplete guess. Please enter 4 digits.', 0
    duplicate_msg db 'All digits must be unique. Try again.', 0
    result_msg db 'Bulls: 0, Cows: 0', 0
    bulls db 0
    cows db 0
    win_message db 'You Win!', 0
    win_animation db '|/-\', 0
    win_animation_index db 0
    win_back_option db 'Back to Main Menu', 0
	save_result db 'save your win by name', 0
	thanks_msg db 'Thank you for playing Bulls & Cows Game', 0
	exit_prog_msg db 'to exit the program, press ESC key', 0
	save_name_enter db 'to save your name, press ENTER after you wrote your nickname', 0
	win_selection db 0 ; 1 - back to main menu 2- save score by difficulty, time & name
    difficulty_menu_title db 'Select Difficulty', 0
    difficulty_levels db 'very easy', 0, 'easy', 0, 'medium', 0, 'difficult', 0, 'very hard', 0
    difficulty_attempts db 0FFh, 20, 15, 10, 5 ; 0FFh represents infinite attempts
    current_difficulty db 0 ; 0 = very easy, 1 = easy, 2 = medium, 3 = difficult, 4 = very hard
    attempts_left db 0
    attempts_msg db 'Attempts left: ', 0
    game_over_msg db 'Game Over! The code was: ', 0
    infinity_symbol db 236 ; infinity is at code 236 (0xEC)
    mouse_x dw 0 ; mouse placement on X - axys
    mouse_y dw 0 ; mouse placement on Y - axys
	saved_mouse_x dw 0 ; saved position of the mouse between menus
    saved_mouse_y dw 0
    mouse_buttons db 0
    mouse_click_processed db 0 ; flag to indicate if a mouse click happened
	last_click_time dw 0
	player_name db 20 dup('_'), 0  ; space for player name (20 characters max)
	Reset_player_name db 20 dup('_'), 0  ; reset player name to underscores
    name_length db 0               ; length of the entered name
    save_message db 80 dup(' '), 0  ; base save message
	is_hex_input db 0 ; 0 = not hex input, 1 = hex input
    scancode_to_ascii_map db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0
    db 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\'
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' ' ; symbols for the name savings
	newline db 0Dh, 0Ah
    FILENAME DB 'WIN_RECO.txt', 0
    BUFFER DB 160 DUP(' ')
    HANDLE DW ?
    LINE_COUNT DW 0
	top_players_title db 'Most recent 5 Saved Wins:', 0
	LINE_COUNTER DW 0
    TEMP_CHAR db 0

.code
start:
    call initialize
    call main_loop
    call exit_program
    
initialize:
     ;disable interrupts before IVT changes
    cli
    in al, 21h ; keyboard input interrupt
    or al, 02h 
    out 21h, al
     ;enable interrupts after IVT changes
    sti   
    ; initialize data segment
    mov ax, @data
    mov ds, ax
    ; setting an extra segment to screen mem.
    mov ax, 0b800h
    mov es, ax
    call clear_screen
    call draw_main_menu
    call init_mouse	
    ret

start_timer proc
    ; get the initial time
    mov ah, 2Ch
    int 21h
    mov start_hours, ch
    mov start_minutes, cl
    mov start_seconds, dh	
    ret
start_timer endp

update_timer:
    ; get system time
    mov ah, 02Ch                 ; get system time function
    int 21h                      ; call DOS interrupt
    mov current_hours, ch
    mov current_minutes, cl
    mov current_seconds, dh
    ; calculate the elapsed time (current time - start time)
    ; handle seconds
    mov al, current_seconds
    sub al, start_seconds
    jnc no_second_borrow
    add al, 60    ; borrow from minutes
    dec current_minutes
	
no_second_borrow:
    ; handle minutes
    mov elapsed_seconds, al
    mov al, current_minutes
    sub al, start_minutes
    jnc no_minute_borrow
    add al, 60    ; borrow from hours
    dec current_hours
	
no_minute_borrow:
    ; handle hours
    mov elapsed_minutes, al  
    mov al, current_hours
    sub al, start_hours
    mov elapsed_hours, al	
    ; display the elapsed time
    call update_time_str   ; update the string for displaying elapsed time
    call display_time      ; actually display the updated time
    ret


update_time_str proc ; procedure that updates the time into time_str
    push ax
    push bx
    push cx
    mov bx, offset time_str
    mov al, elapsed_hours
    call convert_to_ascii
    mov [bx], ax
    mov byte ptr [bx+2], ':'
    mov al, elapsed_minutes
    call convert_to_ascii
    mov [bx+3], ax
    mov byte ptr [bx+5], ':'
    mov al, elapsed_seconds
    call convert_to_ascii
    mov [bx+6], ax
    pop cx
    pop bx
    pop ax
    ret
update_time_str endp

convert_to_ascii proc ; convert the time input to ASCII
    mov ah, 0
    mov cl, 10
    div cl
    add ax, 3030h
    ret
convert_to_ascii endp

reset_timer proc ; reset timer
    mov start_hours, 0
    mov start_minutes, 0
    mov start_seconds, 0
    ret
reset_timer endp

display_time proc ; function that displays the clock/timer in the correct placement
    push ax
    push bx
    push cx
    push dx
    push es
	
	mov bx, offset clock_msg
	cmp current_menu, 1
	jnz write_time_msg
    mov bx, offset timer_msg
	
write_time_msg:
    mov di, 116  
    mov si, bx
    mov cx, 11  ; length of time string
    mov ah, 07h  ; clock properties, white on black
	display_loop2:
    mov al, [si]              ; load character from si to al
    mov ah, 07h
    mov es:[di], ax    ; store character + properties to video mem
    inc si                    ; move to the next character
    add di, 2                 ; move to the next video memory position (1 byte)
    loop display_loop2        
skip_write_clock:
    mov ax, 0B800h
    mov es, ax
    mov di, 140  ; top right corner
    mov si, offset time_str
    mov cx, 8  ; length of time_str
    mov ah, 07h

display_loop: ; loop that will iterate by the length of time_str
    mov al, [si]
    mov ah, 07h
    mov es:[di], ax    ; store character + attribute to video memory
    inc si
    add di, 2
    loop display_loop

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
display_time endp

check_keyboard_input:
    in al, 64h ; keyboard input interrupt
    test al, 01
    jz no_input
    in al, 60h           ; read scan code
    mov key_pressed, al  ; store scan code in key_pressed
	
no_input:
    ret
	
reset_key:
    mov key_pressed, 0
    ret

main_loop: ; The main loop of the actual game.
GAME:
    call update_timer
    call check_keyboard_input
    call check_mouse_input
    call redraw_menu ; constantly redraw to update hover effects
    
    ; add a small delay to reduce mouse flickering
    mov cx, 3000 ; the delay amount
delay_loop1:
    loop delay_loop1
    

    cmp key_pressed, 0
    jne handle_input
    cmp mouse_buttons, 0
    jne handle_input	
    jmp GAME
	
handle_input: 
    call handle_main_menu_input
    mov key_pressed, 0
    mov mouse_buttons, 0	
    jmp GAME
	
handle_play_menu_input:  ; play menu input handling
    cmp current_menu, 0
    je handle_main_menu_input

    cmp key_pressed, 91h ; W pressed
    je PLAY_UP
    cmp key_pressed, 9Fh ; S pressed
    je PLAY_DOWN
    cmp key_pressed, 9Eh ; A pressed
    je PLAY_LEFT
    cmp key_pressed, 0A0h ; D pressed
    je PLAY_RIGHT
    cmp key_pressed, 1Ch ; enter key
    je PLAY_SELECT
    cmp key_pressed, 0Eh ; backspace key (Delete last digit)
    je PLAY_DELETE
    cmp key_pressed, 01h ; Esc key
    je handle_esc
    cmp mouse_buttons, 1 ; left mouse button clicked
    je check_play_mouse_click
    ret

check_play_mouse_click: ; check the validity of the mouse click
    call get_mouse_play_menu_selection
    cmp al, 0FFh ; invalid selection
    je redraw_menu
    mov play_selection, al
    call PLAY_SELECT
    mov mouse_buttons, 0
    ret

get_mouse_play_menu_selection: ; check if the mouse is hovering over the numbers
    cmp mouse_y, 4 ; row for the numbers
    jne check_play_back
    cmp mouse_x, 32 ; boundary of 0
    je get_num_0
    cmp mouse_x, 34 ; boundary of 1
    je get_num_1
	cmp mouse_x, 36 ; boundary of 2
    je get_num_2
    cmp mouse_x, 38 ; boundary of 3
    je get_num_3
    cmp mouse_x, 40 ; boundary of 4
    je get_num_4
    cmp mouse_x, 42 ; boundary of 5
    je get_num_5
    cmp mouse_x, 44 ; boundary of 6
    je get_num_6
    cmp mouse_x, 46 ; boundary of 7
    je get_num_7
    cmp mouse_x, 48 ; boundary of 8
    je get_num_8
    cmp mouse_x, 50 ; boundary of 9
    je get_num_9
    jmp got_invalid_selection
get_num_0:
    mov al, 0 ; 0 selected
	jmp got_num
get_num_1:
    mov al, 1 ; 1 selected
	jmp got_num
get_num_2:
    mov al, 2 ; 2 selected
	jmp got_num
get_num_3:
    mov al, 3 ; 3 selected
	jmp got_num
get_num_4:
    mov al, 4 ; 4 selected
	jmp got_num
get_num_5:
    mov al, 5 ; 5 selected
	jmp got_num
get_num_6:
    mov al, 6 ; 6 selected
	jmp got_num
get_num_7:
    mov al, 7 ; 7 selected
	jmp got_num
get_num_8:
    mov al, 8 ; 8 selected
	jmp got_num
get_num_9:
    mov al, 9 ; 9 selected
	jmp got_num
	
got_invalid_selection:
    jmp invalid_selection

got_num:
    mov play_selection, al
    ret
	
check_play_back:
    cmp mouse_y, 7 ; row for "back to main menu"
    jne check_play_submit
    cmp mouse_x, 31 ; left boundary of "back to main menu"
    jl invalid_selection
    cmp mouse_x, 47 ; right boundary of "back to main menu"
    jg invalid_selection
    mov al, 0Ah ; "back to main menu" selected
	jmp got_num
	ret

check_play_submit: ; same for the "submit" button
    cmp mouse_y, 9 
    jne invalid_selection
    cmp mouse_x, 37 
    jl invalid_selection
    cmp mouse_x, 42 
    jg invalid_selection
    mov al, 0Bh
    jmp got_num
	ret
	
handle_main_menu_input:
    cmp current_menu, 1
    je handle_play_menu_input
    cmp current_menu, 2
    je handle_difficulty_menu_input
    cmp key_pressed, 91h ; W pressed
    je UP
    cmp key_pressed, 9Fh ; S pressed
    je DOWN
    cmp key_pressed, 1Ch ; Enter key
    je ENTER_PRESS_MAIN_MENU
    cmp key_pressed, 01h ; Esc key
    je handle_esc
    cmp mouse_buttons, 1 ; left mouse button clicked
    je check_main_mouse_click
    ret

check_main_mouse_click:
    call get_mouse_main_menu_selection
    cmp al, 0FFh
    je redraw_menu
    mov current_selection, al
    jmp ENTER_PRESS_MAIN_MENU

get_mouse_main_menu_selection:
    ; check if mouse is on "play" option
    cmp mouse_y, 6 
    jne check_main_difficulty
    cmp mouse_x, 38 
    jl invalid_selection
    cmp mouse_x, 41 
    jg invalid_selection
    mov al, 0 ; play selected
    ret
	
check_main_difficulty:
; same for difficulty option
    cmp mouse_y, 8
    jne check_main_exit
    cmp mouse_x, 35 
    jl invalid_selection
    cmp mouse_x, 44 
    jg invalid_selection
    mov al, 1 ; difficulty selected
    ret
	
check_main_exit:
 ; same for exit option
    cmp mouse_y, 10 
    jne invalid_selection
    cmp mouse_x, 38 
    jl invalid_selection
    cmp mouse_x, 41 
    jg invalid_selection
    mov al, 2 ; exit selected
    ret

invalid_selection:
    mov al, 0FFh
    ret
	
handle_esc: ; function to handle ESC press, either quits the game or takes you back to main menu
    call reset_timer
    cmp current_menu, 0
    je exit_program
    mov current_menu, 0
    call clear_screen
    call draw_main_menu
    ret
	
clear_screen: ; function to clear the screen (just paint black)
    call move_mouse_to_left
    mov ah, 0ch
    mov al, 00h
    xor bx, bx
    mov cx, 0FA0h
BLACK:
    mov es:[bx], ax
    add bx, 2h
    loop BLACK
	call move_mouse_to_saved_place ; call the mouse to its saved place in the last menu after painting the screen, to tackle a bug we had
    ret

draw_main_menu: ; draw the main menu
    call check_mouse_on_main_menu
    mov cursor_pos, 160 ; start at second row
    mov si, offset welcome_msg
    mov cx, 32 ; length of welcome message
    mov ah, 0Fh ; White on black
    call draw_centered_string
    mov cursor_pos, 320 ; go down to the third row
    mov si, offset credits_msg
    mov cx, 42 ; length of credits message
    mov ah, 0Fh
    call draw_centered_string
    add cursor_pos, 640 ; skip four rows
    mov si, offset play_option
    mov cx, 4 ; length of "play"
    mov ah, 07h ; light gray on black
    cmp current_selection, 0
    je highlight_play
    jmp draw_play
	
highlight_play:
    mov ah, 0Eh
draw_play: 
    call draw_centered_string
	
    add cursor_pos, 320 ; skip two rows
    mov si, offset difficulty_option
    mov cx, 10 ; length of "difficulty"
    mov ah, 07h
    cmp current_selection, 1
    je highlight_difficulty
    jmp draw_difficulty
	
highlight_difficulty: ; highlight difficulty button
    mov ah, 0Eh
	
draw_difficulty: ; draw the difficulty button
    call draw_centered_string
    add cursor_pos, 320
    mov si, offset exit_option
    mov cx, 4 
    mov ah, 07h
    cmp current_selection, 2
    je highlight_exit
    jmp draw_exit
	
highlight_exit:
    mov ah, 0Eh
	
draw_exit:
    call draw_centered_string
    call line_num_count
    call display_win_reco_content
    ret

VictorySound: ; will be played when you guess the code correctly
    push ax
    push cx
    ; enable the PC speaker
    in al, 61h
    or al, 03h
    out 61h, al
    ; play note C5 (523 Hz)
    mov ax, 2280   ; Frequency divider for C5 (1193180 / 523)
    call PlayNote
    ; play note E5 (659 Hz)
    mov ax, 1810   ; frequency divider for E5
    call PlayNote
    ; play note G5 (784 Hz)
    mov ax, 1521   ; frequency divider for G5
    call PlayNote
    ; disable the PC speaker
    in al, 61h
    and al, 0FCh
    out 61h, al
    pop cx
    pop ax
    ret

DefeatSound: ; will be played when you are out of attempts
    push ax
    push cx    
    in al, 61h
    or al, 03h
    out 61h, al
    ; play note G5 (784 Hz)
    mov ax, 2021   
    call PlayNote
	; play note E5 (659 Hz)
    mov ax, 2810   
    call PlayNote
	; play note C5 (523 Hz)
    mov ax, 3280   
    call PlayNote    
    in al, 61h
    and al, 0FCh
    out 61h, al
    pop cx
    pop ax
    ret

PlayNote: ; function that plays the desired note
    push ax
    mov al, 0B6h  ; command byte: channel 2, binary mode, rate generator, load LSB then MSB
    out 43h, al   ; send the command byte to the PIT
    pop ax
    out 42h, al   ; send the frequency low byte
    mov al, ah
    out 42h, al   ; send the frequency high byte
    ; delay amount determines the length of the notes playtime
    mov cx, 0FFFFh
    call Delay
	call Delay
	call Delay
	call Delay
	call Delay
	call Delay
	call Delay
	call Delay
	call Delay
	call Delay
    ret

Delay:
    push cx ; here we can control the length, or just call it the amount of times we want
DelayLoop:
    loop DelayLoop
    pop cx
    ret

line_num_count: ; procedure that counts the number of rows in the file, to later use it to display the last 5 rows
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    ; open file
    mov ah, 3Dh
    mov al, 0 ; read mode
    mov dx, offset FILENAME
    int 21h
    jc CLOSE_FILE1 ; jump if Carry flag set (error occurred)
    mov HANDLE, ax  ; save file handle
    mov LINE_COUNT, 0

READ_LOOP1:
    ; read a single character
    mov ah, 3Fh
    mov bx, HANDLE
    mov cx, 1
    mov dx, OFFSET TEMP_CHAR
    int 21h
    jc CLOSE_FILE1 ; if error, close file
    cmp ax, 0
    je CLOSE_FILE1  ; if end of file, close file
    cmp BYTE PTR [TEMP_CHAR], 0Ah ; check if end of line (LF)
    jne READ_LOOP1 
    inc LINE_COUNT ; increment line count
    jmp READ_LOOP1

CLOSE_FILE1: ; close the file
    mov ah, 3Eh    
    mov bx, HANDLE
    int 21h   
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
    ; clear buffer
    push cx
    mov cx, 160 ; number of bytes to clear
    mov di, offset BUFFER ; load mem location of BUFFER
    xor al, al ; clear al
   CLEAR_LOOPS:
    mov BYTE PTR [di], 0  ; set byte to 0
    inc di  ; move to next byte
    loop CLEAR_LOOPS
    pop cx
	
display_win_reco_content: ; procedure that is responsible to read and display the last 5 saved wins in the main menu
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    ; display title
    mov cursor_pos, 1920
    mov si, offset top_players_title
    mov cx, 25
    mov ah, 0Fh
    call draw_centered_string 
    mov LINE_COUNTER, 0
    mov ah, 3Dh
    mov al, 0
    mov dx, offset FILENAME
    int 21h
    jc CLOSE_FILE 
    mov HANDLE, ax
    mov cursor_pos, 2080
	
READ_LOOP:
    ; check if we've read 6 lines (5 players + header)
    cmp LINE_COUNTER, 6
    jae CLOSE_FILE
    ; clear buffer
    mov cx, 160
    mov di, offset BUFFER 
    xor al, al
    mov cx, 160
    mov di, OFFSET BUFFER ; load address of BUFFER
    CLEAR_LOOP_BUFFER:
    mov BYTE PTR [di], 0
    inc di
    loop CLEAR_LOOP_BUFFER
    ; read a line from file
    mov si, OFFSET BUFFER
READ_CHAR:
    ; read a single character
    mov ah, 3Fh
    mov bx, HANDLE
    mov cx, 1
    mov dx, si
    int 21h
    jc PROCESS_LINE ; if error, process what we have read so far
    cmp ax, 0
    je PROCESS_LINE ; if end of file, process the last line
    ; check if end of line (CR or LF)
    mov al, [si]
    cmp al, 0Dh ; carriage return
    je READ_CHAR ; Skip CR
    cmp al, 0Ah ; line feed
    je PROCESS_LINE
    inc si
    jmp READ_CHAR
PROCESS_LINE:
    ; null-terminate the line
    mov BYTE PTR [si], 0
    ; calculate the actual length of the line
    mov cx, si
    sub cx, OFFSET BUFFER
    jz CHECK_EOF  ; if length is zero, check if we're at EOF	
	mov bx, LINE_COUNT
	sub bx, 1
	mov LINE_COUNT, bx 	
	cmp LINE_COUNT, 5
    jae READ_LOOP
    ; print the line
    mov si, offset BUFFER
    mov ah, 0Fh
    call draw_centered_string
    add cursor_pos, 160
    inc LINE_COUNTER
CHECK_EOF:
    cmp ax, 0
    je CLOSE_FILE
    jmp READ_loop
CLOSE_FILE:
    ;close the file
    mov ah, 3Eh
    mov bx, HANDLE
    int 21h
    ;pop registers
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_play_menu: ; draw the main playing screen, with the numbers and other options
    cmp current_menu, 1
    jne continue_draw_play_menu
    call get_mouse_play_menu_selection
    mov cursor_pos, 160
    mov si, offset generated_code_msg
    mov cx, 16
    mov ah, 0Fh
    call draw_centered_string
    
    add cursor_pos, 160
	;הורדת ההערה בשורה הבאה תוביל לכיסוי הקוד
    mov si, offset generated_code;_cover 
    mov cx, 4 ; length of the generated code
    mov ah, 0Eh
    call draw_centered_string
    
    add cursor_pos, 320
    call draw_number_options
    
    add cursor_pos, 480 ; skip three rows
    mov si, offset back_option
    mov cx, 17 
    mov ah, 07h
    cmp play_selection, 10
    je highlight_back
    jmp draw_back
highlight_back:
    mov ah, 0Eh
draw_back: ; draw the back to main menu button
    call draw_centered_string
	
    add cursor_pos, 320
    mov si, offset submit_option
    mov cx, 6
    mov ah, 07h
    cmp play_selection, 11
    je highlight_submit
    jmp draw_submit
	
highlight_submit:
    mov ah, 0Eh
	
draw_submit: ; draw the submit button
    call draw_centered_string	
	
    add cursor_pos, 320
    mov si, offset user_guess
    mov cx, 11
    mov ah, 0Fh
    call draw_centered_string
    add cursor_pos, 16
    mov si, offset user_guess_digits ; display the guess
    mov cx, 4 
    mov ah, 0Fh
    call draw_centered_string   
    add cursor_pos, 304
    mov si, offset attempts_msg
    mov cx, 15
    mov ah, 0Fh
    call draw_centered_string
    mov al, attempts_left
    call draw_number
	
continue_draw_play_menu:
    ret
    
draw_number: ; procedure that is responsible of correctly displaying a number in the number row
    push ax
    push bx
    push cx
    push dx
    push di

    mov di, cursor_pos
    add di, 96 ; center the output position
    ; check if it's infinite attempts
    cmp al, 0FFh
    je draw_infinity
    ; convert number to ASCII
    xor ah, ah ; clear ah for division
    mov cl, 10
    div cl
    ; convert quotient and remainder to ASCII
    add al, '0'
    add ah, '0'
    ; draw the first digit (tens)
    mov bx, 0
    mov bl, al
    mov cx, 1
    mov es:[di], bl
    mov es:[di+1], byte ptr 0Fh ; white on black
    add di, 2
    ; draw the second digit (singles)
    mov bl, ah
    mov es:[di], bl
    mov es:[di+1], byte ptr 0Fh
    jmp draw_done

draw_infinity:  ; draw infinity symbol
    mov bx, offset infinity_symbol
    mov al, [bx]
    mov es:[di], al
    mov es:[di+1], byte ptr 0Fh
	
draw_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_number_options: ; procedure that displays the row of numbers inside the game
    mov cx, 10 ; 10 numbers
    mov si, offset number_options
    mov bx, 0 ; number index
    push dx
    push ax
    mov dx, cursor_pos
    add dx, 40h
    mov di, dx
	
draw_number_loop:
    push cx
    push bx
    mov dh, 07h ; light gray for unselected numbers
    call get_mouse_play_menu_selection
    cmp al, bl
    je highlight_number
    cmp play_selection, bl ; compare with keyboard selection
    je highlight_number
    jmp draw_number1
	
highlight_number:
    mov dh, 0Eh ; yellow for selected or hovered number
	
draw_number1: ; actual printing of the number
    mov dl, [si]
    mov es:[di], dx
    add di, 4 ; move to next number position
    inc si
    pop bx
    inc bx
    pop cx
    loop draw_number_loop
    pop ax
    pop dx
    ret
	
check_mouse_on_back: ; check if the mouse position is on the back to main menu option
    cmp mouse_y, 7 ; row for "back to main menu"
    jne not_on_back
    cmp mouse_x, 31 ; left boundary
    jl not_on_back
    cmp mouse_x, 47 ; right boundary
    jg not_on_back
    stc ; set carry flag if mouse is on back
    ret
not_on_back:
    clc ; clear carry flag if mouse is not on back
    ret

check_mouse_on_submit:
    cmp mouse_y, 9
    jne not_on_submit
    cmp mouse_x, 37
    jl not_on_submit
    cmp mouse_x, 42
    jg not_on_submit
    stc
    ret
not_on_submit:
    clc ; clear carry flag if mouse is not on submit
    ret

draw_centered_string: ; draws whatever called it on the current curser_pos position
    push cx ; save string length
    mov bx, 80 ; screen width
    sub bx, cx ; bx = (80 - string length)
    shr bx, 1 ; bx = (80 - string length) / 2
    shl bx, 1 ; convert to byte offset
    add bx, cursor_pos
    mov di, bx
    pop cx ; restore string length
	
draw_string:
    mov al, [si] ; load character from si into al
    mov es:[di], al ; store character at ES:di
    mov es:[di+1], ah ; store attribute at ES:di+1
    inc si ; move to next source character
    add di, 2 ; move to next screen position
    loop draw_string
    ret

UP: ; W press in main menu
    cmp current_selection, 0
    je wrap_to_bottom
    dec current_selection
    jmp redraw_menu
wrap_to_bottom:
    mov current_selection, 2
    jmp redraw_menu

DOWN: ; S press in main menu
    cmp current_selection, 2
    je wrap_to_top
    inc current_selection
    jmp redraw_menu
wrap_to_top:
    mov current_selection, 0
    jmp redraw_menu

PLAY_UP: ; W pressed in the play menu
    cmp play_selection, 10
    jl play_wrap_to_submit
    cmp play_selection, 11
    je play_go_to_back
    dec play_selection
    jmp redraw_menu
play_go_to_back:
    mov play_selection, 10 ; 10 is back to main menu
    jmp redraw_menu
    play_wrap_to_submit:
     mov play_selection, 11 ; 11 is submit
     jmp redraw_menu
	 
PLAY_DOWN: ; s pressed in the play menu
    cmp play_selection, 10 
    jl play_go_to_back
    cmp play_selection, 10
    je play_go_to_submit
    cmp play_selection, 11 
    je play_wrap_to_zero
    inc play_selection
    jmp redraw_menu
play_go_to_submit:
    mov play_selection, 11
    jmp redraw_menu
    play_wrap_to_zero:
    mov play_selection, 0
    jmp redraw_menu
    
PLAY_LEFT: ; a pressed in the play menu
    cmp play_selection, 0
    je wrap_to_nine
    cmp play_selection, 10
    je play_wrap_to_submit
    dec play_selection
    jmp redraw_menu
wrap_to_nine: ; cyclic wrap around
    mov play_selection, 9
    jmp redraw_menu

PLAY_RIGHT: ; d pressed in the play menu
    cmp play_selection, 9
    je wrap_to_zero
    cmp play_selection, 11
    je play_go_to_back
    inc play_selection
    jmp redraw_menu
wrap_to_zero:
    mov play_selection, 0
    jmp redraw_menu

PLAY_SELECT:
    cmp play_selection, 10
    je return_to_main_menu
    cmp play_selection, 11
    je handle_submit
    ; add selected number to guess
    mov al, guess_length
    cmp al, 4
    jae redraw_menu ; if already 4 digits, do nothing
    mov bx, offset user_guess_digits
    xor dx, dx
    mov dl, al
    add bx, dx ; move to the correct position for the digit
    mov al, play_selection
    add al, '0'; convert the selected number to ASCII
    mov [bx], al
    ; store the digit in user_guess_digits (without caption)
    mov bx, offset user_guess_digits
    add bx, dx ; move to the correct position for the digit
    mov [bx], al  ; store the digit in user_guess_digits
    inc guess_length
    jmp redraw_menu
    ret

PLAY_DELETE: ; delete the most recent digit from the guess input box
    cmp guess_length, 0
    je redraw_menu ; if no digits have been entered, do nothing

    dec guess_length ; decrease the guess length
    mov bx, offset user_guess_digits
    push dx
    xor dx, dx
    mov dl, guess_length
    add bx, dx   ; point to the last entered digit
    pop dx
    mov byte ptr [bx], '_' ; replace it with an underscore
    jmp redraw_menu
	
redraw_menu: ; decide which menu to draw
    cmp current_menu, 0
    je draw_main_menu
    cmp current_menu, 1
    je draw_play_menu
    cmp current_menu, 2
    je draw_difficulty_menu
	cmp current_menu, 3
	je draw_win_screen
	cmp current_menu, 4
	je save_name_procedure
    cmp current_menu, 5
	je game_over_loop
	mov mouse_click_processed, 0  ; reset the mouse click processed indicator
    ret

ENTER_PRESS_MAIN_MENU: ; enter press in the main menu
    cmp current_selection, 0
    je enter_to_play_menu
    cmp current_selection, 1
    je enter_difficulty_menu
    cmp current_selection, 2
    je exit_program
    ret
	
enter_to_play_menu: ; start the timer after choosing to play
    call start_timer
	
enter_play_menu: ; play menu
    mov current_menu, 1
    mov play_selection, 0
    mov guess_length, 0
    mov cx, 4
    mov di, offset user_guess_digits
    mov al, '_'
    mov cx, 4                       ; number of characters to set
    mov di, offset user_guess_digits
    user_init_loop:
    mov byte ptr [di], '_'; set byte to underscore
    inc di
    loop user_init_loop
    call clear_screen
    call generate_random_code
    ; set attempts_left based on current difficulty
    mov bl, current_difficulty
    mov bh, 0
    mov al, [difficulty_attempts + bx]
    mov attempts_left, al
	mov mouse_buttons, 0
    call draw_play_menu
    ret
    
enter_difficulty_menu:
    mov current_menu, 2 ; set menu to difficulty selection
    mov current_difficulty, 0 ; reset to first difficulty option
	mov mouse_buttons, 0
    call clear_screen
    call draw_difficulty_menu
    ret

draw_difficulty_menu:
    call check_difficulty_mouse_mouse
    cmp current_menu, 2
    jne not_in_difficulty_menu
    mov cursor_pos, 160 ; start at second row
    mov si, offset difficulty_menu_title
    mov cx, 17 ; length of "Select Difficulty"
    mov ah, 0Fh
    call draw_centered_string

    mov cx, 5 ; 5 difficulty levels
    mov bx, 0 ; difficulty index
    mov si, offset difficulty_levels
draw_difficulty_loop:
    push cx
    push bx
    add cursor_pos, 320 ;Skip two rows
    mov ah, 07h ; light gray for unselected levels
    cmp bl, current_difficulty
    je highlight_difficulty1
    jmp draw_difficulty_option1
highlight_difficulty1:
    mov ah, 0Eh ; yellow for selected or hovered level
draw_difficulty_option1:
    push si
    call get_string_length
    pop si
    call draw_centered_string
    add si, cx ; move to next difficulty level string
    inc si ; skip null terminator
    pop bx
    inc bx
    pop cx
    loop draw_difficulty_loop
not_in_difficulty_menu:
    ret
	
check_mouse_on_difficulty_option:
    push ax
    push bx
	call get_mouse_difficulty_menu_selection
	cmp bl, al
    jne not_on_difficulty_option
    pop bx
    pop ax
    stc ; set carry flag if mouse is on this difficulty option
    ret
not_on_difficulty_option:
    pop bx
    pop ax
    clc ; clear carry flag if mouse is not on this difficulty option
    ret

get_string_length:
    push si
    xor cx, cx
get_length_loop:
    mov al, [si]  ; load byte from memory pointed to by si into al
    inc si        ; icrement si to point to the next byte
    cmp al, 0
    jz end_length
    inc cx
    jmp get_length_loop
end_length:
    pop si
    ret

handle_difficulty_menu_input:
    cmp key_pressed, 91h ; W pressed
    je difficulty_up
    cmp key_pressed, 9Fh ; S pressed
    je difficulty_down
    cmp key_pressed, 1Ch ; Enter key
    je select_difficulty
    cmp key_pressed, 01h ; Esc key
    je handle_esc
    cmp mouse_buttons, 1 ; left mouse button clicked
    je check_difficulty_mouse_click
    ret

check_difficulty_mouse_mouse: ; check on which selected difficulty the mouse is hovering over
    call get_mouse_difficulty_menu_selection
    cmp al, 0FFh ; invalid selection
    je dont_choose_difficulty
    mov current_difficulty, al
	
dont_choose_difficulty:
	ret

check_difficulty_mouse_click:
    call get_mouse_difficulty_menu_selection
    cmp al, 0FFh
    je redraw_menu
    mov current_difficulty, al
    jmp select_difficulty

get_mouse_difficulty_menu_selection:
    ; check if mouse is on "very easy" option
    cmp mouse_y, 3 ; Row for "very easy"
    jne check_difficulty_easy
    cmp mouse_x, 35 ; Left boundary of "very easy"
    jl invalid_selection
    cmp mouse_x, 43 ; Right boundary of "very easy"
    jg invalid_selection
    mov al, 0 ; "very easy" selected
    ret
	
check_difficulty_easy:
;same for "easy" button
    cmp mouse_y, 5
    jne check_difficulty_medium
    cmp mouse_x, 38
    jl invalid_selection
    cmp mouse_x, 41
    jg invalid_selection
    mov al, 1
    ret

check_difficulty_medium:
; medium button
    cmp mouse_y, 7
    jne check_difficulty_difficult
    cmp mouse_x, 37
    jl invalid_selection
    cmp mouse_x, 42
    jg invalid_selection
    mov al, 2
    ret
	
check_difficulty_difficult:
;difficult button
    cmp mouse_y, 9
    jne check_difficulty_very_hard
    cmp mouse_x, 35
    jl invalid_selection
    cmp mouse_x, 43
    jg invalid_selection
    mov al, 3
    ret
	
check_difficulty_very_hard:
;very hard
    cmp mouse_y, 11
    jne invalid_selection
    cmp mouse_x, 35
    jl invalid_selection
    cmp mouse_x, 43
    jg invalid_selection
    mov al, 4
    ret
	
check_mouse_on_play:
;"play" button
    cmp mouse_y, 6
    jne not_on_play
    cmp mouse_x, 38
    jl not_on_play
    cmp mouse_x, 41
    jg not_on_play
	mov current_selection, 0
    stc ; Set carry flag if mouse is on play
    ret
	
not_on_play:
    clc
    ret

check_mouse_on_difficulty:
;"difficulty" button
    cmp mouse_y, 8
    jne not_on_difficulty
    cmp mouse_x, 35
    jl not_on_difficulty
    cmp mouse_x, 44
    jg not_on_difficulty
	mov current_selection, 1
    stc
    ret
	
not_on_difficulty:
    clc
    ret

check_mouse_on_exit:
;"exit" button
    cmp mouse_y, 10
    jne not_on_exit
    cmp mouse_x, 38
    jl not_on_exit
    cmp mouse_x, 41
    jg not_on_exit
	mov current_selection, 2
    stc
    ret
	
not_on_exit:
    clc
    ret

check_mouse_on_main_menu: ; check mouse position relative to the buttons in the main menu
    call check_mouse_on_play
    call check_mouse_on_difficulty
    call check_mouse_on_exit
    ret

difficulty_up: ; W press in the difficulty selection menu
    cmp current_difficulty, 0
    je wrap_to_bottom_difficulty
    dec current_difficulty
    jmp redraw_menu
wrap_to_bottom_difficulty:
    mov current_difficulty, 4
    jmp redraw_menu

difficulty_down: ; S press in the difficulty selection menu
    cmp current_difficulty, 4
    je wrap_to_top_difficulty
    inc current_difficulty
    jmp redraw_menu
wrap_to_top_difficulty:
    mov current_difficulty, 0
    jmp redraw_menu

select_difficulty:
    mov al, current_difficulty
    mov bx, offset difficulty_attempts
    mov bl, al           ; save the index (current_difficulty) in BL
    xor bh, bh           ; clear BH to ensure bx only contains the index
    add bx, offset difficulty_attempts  ; add the base address to bx
    mov al, [bx]         ; load the value from the table into al
    mov attempts_left, al
    call return_to_main_menu
    ret

return_to_main_menu: ; main function to return to the main menu
   call reset_timer ; reset timer
   call PLAY_DELETE ; make sure that the guess box will be blank if playing again
   call PLAY_DELETE
   call PLAY_DELETE
   call PLAY_DELETE
   mov current_menu, 0
   mov current_selection, 0
   call clear_screen
   call draw_main_menu
   ret
    
handle_submit: ; function that handles the "submit" button
    ; check if guess is complete (4 digits)
    cmp guess_length, 4
    jne incomplete_guess
    ; check if all digits are unique
    call check_unique_digits
    cmp al, 0
    je duplicate_digits    
    ; compare guess with generated code
    call compare_guess
    cmp bulls, 4 ; workaround we did to handle a problem - if you won itll display in the winning scrfeen the message of "4 bulls, 0 cows" so we made sure that itll not be displayed
    je dont_display
    call display_result
	jmp dont_reset_timer
	
dont_display:
    call reset_timer
	
dont_reset_timer:
    ; decrement attempts (if not infinite)
    cmp attempts_left, 0FFh
    je skip_decrement
    dec attempts_left
skip_decrement: ; check if out of attempts   
    cmp attempts_left, 0
    je game_over
	
redelete: ; procedure that deletes the current digits in the attempt box if you submit incomplete guess or with dupes
    call PLAY_DELETE
    call PLAY_DELETE
    call PLAY_DELETE
    call PLAY_DELETE
    jmp redraw_menu

incomplete_guess:
    mov cursor_pos, 3200 ; position for error message
    mov si, offset incomplete_msg
    mov cx, 40
    mov ah, 0Ch ; light red on black
    call draw_centered_string
    jmp redelete

duplicate_digits:
    mov cursor_pos, 3200
    mov si, offset duplicate_msg
    mov cx, 36
    mov ah, 0Ch
    call draw_centered_string
    jmp redelete

check_unique_digits:
    mov si, offset user_guess_digits
    mov cx, 3 ; check first 3 digits against the rest
    mov al, 1 ; assume unique unless found otherwise
	
check_outer:
    mov di, si
    inc di
    push cx
    mov cl, 3
    push dx
    xor dx, dx
    mov dx, si
    sub dx, offset user_guess_digits
    sub cl, dl ; remaining digits to check
    pop dx
	
check_inner:
    mov ah, [si]
    cmp ah, [di]
    je not_unique
    inc di
    loop check_inner
    pop cx
    inc si
    loop check_outer
    ret ; al = 1 if all digits are unique
	
not_unique:
    pop cx
    mov al, 0 ; al = 0 if duplicate found
    ret

compare_guess: ; compare the user's guess with the generated one
    mov bulls, 0
    mov cows, 0
    mov si, offset user_guess_digits
    mov di, offset generated_code
    mov cx, 4

compare_bulls: ; first, check for bull
    mov al, [si]
    cmp al, [di]
    jne not_bull
    inc bulls
    jmp next_digit
	
not_bull:
    push si
    push di
    push cx
    mov bx, offset generated_code
    mov cx, 4
	
compare_cows: ; then, for cow
    cmp al, [bx]
    jne not_cow
    cmp bx, di
    je not_cow
    inc cows
    jmp end_cow_loop
	
not_cow:
    inc bx
    loop compare_cows
	
end_cow_loop:
    pop cx
    pop di
    pop si
	
next_digit: ;move on to the next digit
    inc si
    inc di
    loop compare_bulls
    cmp bulls, 4 ; condition of winning
    je enter_draw_win_screen
    jmp no_win


enter_draw_win_screen:
    push bx
    push cx
    mov cx, 9d
    xor bx, bx

win_time:
    mov al, [time_str+bx]
    mov [win_time_str+bx], al
    inc bx
    loop win_time
    pop cx
    pop bx
    call PLAY_DELETE
    call PLAY_DELETE
    call PLAY_DELETE
    call PLAY_DELETE	
	call VictorySound 
	inc attempts_left ; to tackle a bug -if you guessed correctly with 1 life it would have still trigger the losing procedures, so we just manually added 1 life if you won, it wouldnt change anything because the lives will reset to next play attempt
    mov current_menu, 3
    mov win_selection, 0
    jmp redraw_menu  ; ensure we redraw the menu to show the win screen

draw_win_screen:
    call clear_screen
    cmp current_menu, 3
    jne redraw_menu
    call reset_mouse_state  ; reset mouse state when entering win screen
	
dws:
    ; draw "You Win!" message
    mov cursor_pos, 1120 ; relative center of the screen
    mov si, offset win_message
    mov cx, 8 ; length of "You Win!"
    mov ah, 0Eh
    call draw_centered_string  
    ; draw animation
	
    mov cursor_pos, 1440 ; below the win message
    mov si, offset win_animation
    xor bx, bx 
    mov bl, win_animation_index  ; load win_animation_index into BL
    add si, bx  ; now add bx (containing win_animation_index) to si
    mov cx, 1 ; one character at a time
    mov ah, 0Fh
    call draw_centered_string   
    ; update animation index
    inc win_animation_index
    cmp win_animation_index, 4
    jl animation_index_ok
    mov win_animation_index, 0
	
animation_index_ok:
    call check_mouse_on_win_option
	
    ; draw "Back to Main Menu" option
    mov cursor_pos, 2080 ; near the bottom of the screen
    mov si, offset win_back_option
    mov cx, 17
    mov ah, 07h ; gray on black (default color)
    mov bl, 0 ; option index for "Back to Main Menu"
    cmp win_selection, 0
    jne draw_win_back
    mov ah, 0Eh
	
draw_win_back:
    call draw_centered_string   
    ; Draw "save name" option
    add cursor_pos, 320
    mov si, offset save_result
    mov cx, 21
    mov ah, 07h
    mov bl, 1 ; Option index for "save name"
    cmp win_selection, 1
    jne draw_win_save
    mov ah, 0Eh
	
draw_win_save:
    call draw_centered_string
    
    ; add a delay for animation, but check for keypress and mouse input meanwhile
    mov cx, 0FFFh ; reduced delay to make the screen more responsive
	
delay_loop:
    push cx
    call check_keyboard_input
    call check_mouse_input
    pop cx
    call handle_win_menu_input
    jc exit_win_screen
    loop delay_loop 
    ; if no input, continue animation
    jmp dws
    
exit_win_screen:
    ret
    
handle_win_menu_input:
;just like all other handle menu procedures
    mov al, 0
    cmp key_pressed, 91h
    je win_UP
    cmp key_pressed, 9Fh
    je win_DOWN
    cmp key_pressed, 1Ch
    je win_select
    cmp key_pressed, 01h
    je return_to_main_menu1
    cmp mouse_buttons, 1
    je check_win_mouse_click
    cmp al, 1
    je win_input_done
    clc ; clear carry flag if no action taken
    ret


;functions that processes the win menu inputs
win_UP:
    mov win_selection, 0
    mov al, 1 ; set action taken flag
    ret

win_DOWN:
    mov win_selection, 1
    mov al, 1
    ret

win_select:
    call process_win_selection
    mov al, 1
    jmp win_input_done

check_win_mouse_click: ; check whatever was clicked by the mouse on the winning menu
    call get_win_mouse_selection
    cmp al, 0FFh ; invalid selection
    je no_win_action
    mov win_selection, al
    call process_win_selection
    mov al, 1
    ret

no_win_action:
    mov al, 0 ; no action taken

win_input_done: ; we got the input
    call reset_key
    mov mouse_buttons, 0
    cmp al, 1
    je set_carry_flag
    clc
    ret

set_carry_flag:
    stc
    ret

process_win_selection: ; process the click on the win menu
    cmp win_selection, 0
    je return_to_main_menu1
    cmp win_selection, 1
    je move_to_save_name_procedure
    ret

move_to_save_name_procedure:
    mov current_menu, 4
    mov win_selection, 0 ; reset win selection
    call reset_flags; clear any relevant flags
    call clear_screen
    stc
    ret
	
return_to_main_menu1: ; back to main menu from the winning or losing screen
    mov current_menu, 0 ; set current_menu to main menu
    mov win_selection, 0 ; reset win selection
    call reset_flags ; clear any relevant flags
    call clear_screen
    stc
    ret

get_win_mouse_selection:
    ; check if mouse is on "Back to Main Menu" button
    cmp mouse_y, 13
    jne check_win_mouse_click_save
    cmp mouse_x, 31
    jl invalid_win_selection
    cmp mouse_x, 47
    jg invalid_win_selection
    mov al, 0
    ret

check_win_mouse_click_save:
; check if mouse is on the save button
    cmp mouse_y, 15
    jne invalid_win_selection
    cmp mouse_x, 29
    jl invalid_win_selection
    cmp mouse_x, 49
    jg invalid_win_selection
    mov al, 1
    ret

invalid_win_selection:
    mov al, 0FFh ; invalid selection
    ret

check_mouse_on_win_option:
    push ax
    call get_win_mouse_selection
	cmp al, 0FFh
    je no_mouse_win_select
    mov win_selection, al 
	
no_mouse_win_select:
    pop ax
    ret
	
reset_flags:
    clc ; clear carry flag
    ret
	
no_win:
    ret
	
game_over:  ; main procedure if you lose
    mov current_menu, 5
    call reset_key
    call clear_screen
    call reset_mouse_state ; reset mouse state when entering game over screen
	call DefeatSound
	
game_over_loop:
    ; draw "Game Over!" message
    mov cursor_pos, 1120
    mov si, offset game_over_msg
    mov cx, 25
    mov ah, 0Ch ; light red on black
    call draw_centered_string
    ; draw the generated code
    add cursor_pos, 160
    mov si, offset generated_code
    mov cx, 4
    mov ah, 0Eh
    call draw_centered_string   
    mov cursor_pos, 1600
    mov si, offset win_animation ; reuse the same animation
    xor bx, bx
    mov bl, win_animation_index
    add si, bx
    mov cx, 1
    mov ah, 0Fh
    call draw_centered_string   
    inc win_animation_index
    cmp win_animation_index, 4
    jl animation_index_ok_game_over
    mov win_animation_index, 0
	
animation_index_ok_game_over:   
    ; draw "Back to Main Menu" option
    mov cursor_pos, 2080
    mov si, offset win_back_option
    mov cx, 17 ; length of string
    mov ah, 0Eh
    call draw_centered_string
	
    ; same as before
    mov cx, 0FFFFh	
delay_lloop:
    push cx
    call check_keyboard_input
    call check_mouse_input
    pop cx
    cmp key_pressed, 1Ch ; check if Enter was pressed
    je exit_l_screen
    cmp mouse_buttons, 1 ; check if left mouse button was clicked
    je check_game_over_mouse_click
    loop delay_lloop  
    ; if no input, continue animation
    jmp game_over_loop

check_game_over_mouse_click:
    ; check if mouse is on "Back to Main Menu" option
    cmp mouse_y, 13
    jne continue_game_over_animation
    cmp mouse_x, 31
    jl continue_game_over_animation
    cmp mouse_x, 47
    jg continue_game_over_animation
    jmp exit_l_screen

continue_game_over_animation:
    mov mouse_buttons, 0 ; reset mouse buttons
    jmp game_over_loop

exit_l_screen:
    ; reset key_pressed to avoid carrying over to next screen
    mov key_pressed, 0
    call return_to_main_menu1
    ret



check_and_remove_v: ; weird bug we had, some symbols were printed with a parasitic "v" after them, we could not manage to outsource the problem (probably the ASCII conversions werent been done correctly but we could not fix it) so we had to manually make sure that itll not get printed.
    push ax
    push bx
    push cx
    cmp name_length, 1  ; check if we have at least one character
    jbe check_v_done    ; if not, nothing to do
    mov bx, offset player_name
    xor cx, cx
    mov cl, name_length
    dec cl              ; point to the last character
    add bx, cx
    cmp byte ptr [bx], 'v'  ; check if the last character is 'v'
    jne check_v_done
    ; if it's 'v', remove it
    mov byte ptr [bx], '_'  ; replace with underscore
    ;dec name_length
check_v_done:
    pop cx
    pop bx
    pop ax
    ret

check_and_return_v:
    push ax
    push bx
    push cx
    cmp name_length, 1  ; check if we have at least one character
    jbe check_return_v_done    ; if not, nothing to do
    mov bx, offset player_name
    xor cx, cx
    mov cl, name_length
check_return_v_loop:
    dec cl ; point to the current character
    add bx, cx
    cmp byte ptr [bx], '_'  ; check if the current character is '_'
    jne check_return_v_next
    mov byte ptr [bx], 'v'  ; replace '_' with 'v'
check_return_v_next:
    sub bx, cx          ; reset bx to the start of the string
    cmp cl, 0           ; check if we have reached the start of the string
    jne check_return_v_loop
check_return_v_done:
    pop cx
    pop bx
    pop ax
    ret

save_name_procedure: ; main procedure to save your name in the file
    call clear_screen
    mov cursor_pos, 1120  ; position to start entering the name
    mov si, offset save_result
    mov cx, 21
    mov ah, 0Fh
    call draw_centered_string
    add cursor_pos, 640 ; start at third row
    mov si, offset save_name_enter
    mov cx, 60 ; length of save_name_enter
    mov ah, 0Fh
    call draw_centered_string
    add cursor_pos, 640
    mov si, offset thanks_msg
    mov cx, 39 ; length of credits message
    mov ah, 0Fh
    call draw_centered_string
    add cursor_pos, 320 ; start at third row
    mov si, offset exit_prog_msg
    mov cx, 34
    mov ah, 0Fh
    call draw_centered_string
    ; initialize name input variables
    mov name_length, 0            ; reset name length
    mov di, offset player_name     ; start position to store the name
    mov cx, 20                    ; limit to 20 characters
	
fill_name_with_underscores:
    mov byte ptr [di], '_'        ; fill with underscores
    inc di
    loop fill_name_with_underscores
    mov byte ptr [di], 0          ; null-terminate the string
    ; display the input prompt
    call display_name_prompt

enter_name_loop: ; loop that runs while entering your name
    call check_keyboard_input ; check for keypresses
    cmp key_pressed, 1Ch  ; check if Enter key was pressed
    je save_name_to_file
    cmp key_pressed, 0Eh ; check if Backspace key was pressed
    je delete_last_char
	cmp key_pressed, 01h ; ESC key
    je handle_esc
    call add_char_to_name
    jmp enter_name_loop
	
add_char_to_name:
    cmp name_length, 20; limit name to 20 characters
    jae skip_char_input
    ; convert the key press to an ASCII character
    mov al, key_pressed
    call convert_scancode_to_ascii
    ; check if its a valid character (letter or number)
    call is_valid_char
    jnc skip_char_input  ; if not valid, skip
    ; store the character
    mov bx, offset player_name
    xor cx, cx
    mov cl, name_length
    add bx, cx
    mov [bx], al  ; store the character in the name array
    inc name_length
    call check_and_remove_v
    call check_and_return_v
	
skip_char_input:
    call reset_key
    jmp redraw_name_input
	
convert_scancode_to_ascii:
    ; convert scan code to ASCII
    push bx
    mov bx, offset scancode_to_ascii_map
    mov bl, al           ; save scancode (index) in BL
    xor bh, bh           ; clear BH to ensure bx only contains the index
    add bx, offset scancode_to_ascii_map  ; add table base address to bx
    mov al, [bx]         ; load ASCII value from table into al
    pop bx
    ret
	
is_valid_char:
    ; check if character is a letter (A-Z or a-z) or number (0-9) based on ASCII values
    cmp al, '0'
    jb not_valid
    cmp al, '9'
    jbe valid
    cmp al, 'A'
    jb not_valid
    cmp al, 'Z'
    jbe valid
    cmp al, 'a'
    jb not_valid
    cmp al, 'z'
    jbe valid
not_valid:
    clc ; clear carry flag for not valid
    ret
valid:
    stc ; set carry flag for valid
    ret

check_for_letters_or_numbers:
    ; if hex mode, ensure input is valid hex digit
    cmp is_hex_input, 1
    jne check_for_numbers
    cmp al, '0'
    jb skip_char_input
    cmp al, '9'
    jbe store_character
    cmp al, 'A'
    jb skip_char_input
    cmp al, 'F'
    jbe store_character
    cmp al, 'a'
    jb skip_char_input
    cmp al, 'f'
    jbe store_character
    jmp skip_char_input

check_for_numbers:
    cmp al, '0'
    jb check_for_letters
    cmp al, '9'
    jbe store_character

check_for_letters:
    ; check for letters A-Z
    cmp al, 'A'
    jb skip_char_input
    cmp al, 'Z'
    jbe store_character
    ; for lowercase letters
    cmp al, 'a'
    jb skip_char_input
    cmp al, 'z'
    jbe store_character
    jmp skip_char_input

store_character:
    mov bx, offset player_name
    xor cx, cx
    mov cl, name_length
    add bx, cx
    mov [bx], al  ; store the character in the name array
    inc name_length

delete_last_char: ; backspace pressed
    cmp name_length, 0
    je redraw_name_input
    dec name_length
    mov bx, offset player_name
	push cx
	xor cx, cx
	mov cl, name_length
    add bx, cx
	pop cx
    mov byte ptr [bx], '_'
    call reset_key
    jmp redraw_name_input

redraw_name_input:
    mov cursor_pos, 1440
    mov si, offset player_name
    mov cx, 20
    mov ah, 0Eh
    call draw_centered_string
    jmp enter_name_loop
	
display_name_prompt:
    mov cursor_pos, 1440  ; position to display the entered name
    mov si, offset player_name
    mov cx, 20
    mov ah, 0Eh
    call draw_centered_string
    ret

save_name_to_file:
    ; try to open the file first
    mov ah, 3Dh
    mov al, 1 ; open for write access
    mov dx, offset FILENAME
    int 21h
    jnc file_opened; CF=0: success
    ; check if file doesnt exist
    cmp ax, 02h
    je create_new_file
    jmp error_save ; any other error
	
create_new_file:
    mov ah, 3Ch ; normal file attribute
    xor cx, cx             
    mov dx, offset FILENAME
    int 21h
    jc error_save
    jmp save_name_to_file ; try opening again

file_opened:
    mov bx, ax  ; save file handle in bx
    ; seek to the end of the file
    mov ah, 42h
    mov al, 2 ; move the pointer to the end of the file
    xor cx, cx
    xor dx, dx
    int 21h
    jc error_save	
    ; write newline to the file
    mov ah, 40h
    mov cx, 2
    mov dx, offset newline
    int 21h
    jc error_save
    ; prepare and write the save message
    call prepare_save_message
    mov ah, 40h
    mov cx, di
    sub cx, offset save_message
    mov dx, offset save_message
    int 21h
    jc error_save
    ; close the file
    mov ah, 3Eh
    int 21h
    jc error_save 
    ;after successful save or error handling:
    call clear_keyboard_buffer
    mov key_pressed, 0
    mov name_length, 0
    mov cx, 21 ; 20 characters + null terminator
    mov si, offset Reset_player_name
    mov di, offset player_name
	
reset_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop reset_loop
    ; set current_menu to main menu
    mov current_menu, 0
    mov current_selection, 0  ; reset selection to first option
    ; clear the screen and redraw main menu
    call clear_screen
    call draw_main_menu
    jmp GAME
	
error_save:
    ret

prepare_save_message:
    ; prepare the save message with current data
    mov di, offset save_message
    mov word ptr [di], 'eL'
    mov word ptr [di+2], 'ev'
    mov word ptr [di+4], ':l' ; for some reason it made us problems trying to write it as 1 string
    add di, 8
    ; get the appropriate difficulty level name
    mov al, current_difficulty
    xor ah, ah
    mov si, offset difficulty_levels
    call find_difficulty_name
    ; copy difficulty name (padding or truncating to 15 characters)
    mov cx, 15
	
copy_difficulty_loop: ; copy the difficulty you have chosen to write in the file
    mov al, [si]
    cmp al, 0
    je pad_difficulty
    mov [di], al
    inc si
    inc di
    loop copy_difficulty_loop
    jmp difficulty_done

pad_difficulty:
    mov byte ptr [di], ' '
    inc di
    loop pad_difficulty

difficulty_done:
    ; add separator
    mov byte ptr [di], '|'
    inc di
    mov word ptr [di], 'iT'
    mov word ptr [di+2], 'em'
    mov word ptr [di+4], ': '
    add di, 6
    ; copy actual time (8 characters)
    mov si, offset win_time_str
    mov cx, 8
	
copy_time_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop copy_time_loop
    ; add separator
    mov byte ptr [di], '|'
    inc di
    ; write "Name: " (fixed 6 characters)
    mov word ptr [di], 'aN'
    mov word ptr [di+2], 'em'
    mov word ptr [di+4], ': '
    add di, 6
    ; copy player name
    mov cx, 20
    mov si, offset player_name
	
copy_name_loop:
    mov al, [si]
    cmp al, '_'
    je pad_name
    mov [di], al
    inc si
    inc di
    loop copy_name_loop
    jmp name_done

pad_name:
    mov byte ptr [di], ' '
    inc di
    loop pad_name

name_done:
    ret

find_difficulty_name:
    cmp ax, 0
    je found_difficulty
    inc si
    cmp byte ptr [si], 0
    jne find_difficulty_name
    inc si
    dec ax
    jmp find_difficulty_name

found_difficulty:
    ret

clear_keyboard_buffer:
    push ax
	
clear_loop:
    mov ah, 1
    int 16h     ; check if a key is available
    jz clear_done  ; if ZF=1, no key available, we're done
    mov ah, 0
    int 16h     ; read the key to remove it from buffer
    jmp clear_loop  ; continue clearing
	
clear_done:
    pop ax
    ret
		
move_mouse_to_left: ; handle the carry pixel bug
    push ax
    push cx
    push dx	
	
	mov ax, 0003h  ; get mouse position and button status
    int 33h
    mov saved_mouse_x, cx
    mov saved_mouse_y, dx	
    mov ax, 0004h  ; set mouse cursor position function
    xor cx, cx ; set X position to 0 (leftmost edge)
    mov dx, mouse_y  ; keep current Y position
    int 33h ; call mouse interrupt
	
    pop dx
    pop cx
    pop ax
    ret

move_mouse_to_saved_place: ; move the mouse back to its original place between menu swaps
    push ax
    push cx
    push dx
	
    mov ax, 0004h ; set mouse cursor position function
    mov cx, saved_mouse_x; use saved X position
    mov dx, saved_mouse_y ; saved Y position
    int 33h; Call mouse interrupt
	
    pop dx
    pop cx
    pop ax
    ret
	
display_result: ; display how many bulls & cows have you got
    push ax
    push bx
    push cx
	
    mov ah, 0ch
    mov al, 00h
    mov bx, 0C80h
    mov cx, 3E8h
BLACK_bottom:
    mov es:[bx], ax
    add bx, 2h
    loop BLACK_bottom   
    pop cx
    pop bx
    pop ax
    mov cursor_pos, 3200 ; position for result message
    mov si, offset result_msg
    mov cx, 18
    mov ah, 0Ah ; light green on black
    ; update bulls in result
    mov al, bulls
    add al, '0'
    mov [si + 7], al
    ; update cows
    mov al, cows
    add al, '0'
    mov [si + 16], al
    call draw_centered_string
    ret

generate_random_code: ; generate the code itself
    ; get system time for seed
    mov ah, 2Ch
    int 21h
    mov seed, dx
    mov cx, 4 ; generate 4 digits
    mov di, offset generated_code
generate_digit:
    mov ax, 25173
    mul seed
    add ax, 13849
    mov seed, ax ; update seed for next iteration
    xor dx, dx
    mov bx, 10
    div bx ; divide by 10, remainder in DL
    add dl, '0' ; convert to ASCII 
    ; check if digit is already in the code (no dupes allowed)
    push cx
    push di
    mov cx, 4
    mov si, offset generated_code
	
check_digit:
    cmp [si], dl
    je regenerate_digit
    inc si
    loop check_digit
    pop di
    pop cx   
    mov [di], dl ; store digit
    inc di
    loop generate_digit
    mov byte ptr [di], 0 ; null-terminate the string
    ret
	
regenerate_digit:
    pop di
    pop cx
    jmp generate_digit
	
reset_mouse_state:
    mov mouse_x, 0
    mov mouse_y, 0
    mov mouse_buttons, 0
    mov mouse_click_processed, 0
    ret
	
init_mouse:
    mov ax, 0000h ; reset mouse
    int 33h
    mov ax, 0001h ; show mouse cursor
    int 33h
    ret

check_mouse_input:
    mov ax, 0003h  ; get mouse position and button status
    int 33h
    mov mouse_x, cx
    mov mouse_y, dx
	mov mouse_buttons, bl
	test bx, 1  ; check if the left mouse button is pressed
    jz no_mouse_press  ; if not pressed, skip
	
 ; button is pressed, wait for release
wait_for_release: ; we went with mouse release register approach , to fix bugs & be consistent
    mov ax, 3  ; check mouse status again
    int 33h
    test bx, 1 ; check if left mouse button is still pressed
    jnz wait_for_release  ; if pressed, keep waiting
	
no_mouse_press:
    ; convert mouse_x from pixel to character cell units
    mov ax, mouse_x
	shr ax, 1
	shr ax, 1
    shr ax, 1 ; divide by 8 to convert from pixels to character cells
    mov mouse_x, ax
 ; same for mouse_y
    mov ax, mouse_y
	shr ax, 1
	shr ax, 1
    shr ax, 1
    mov mouse_y, ax
    ret

exit_program: ; main exit function
    call clear_screen
    mov ah, 02h ; set cursor position function
    mov bh, 0 ; page number
    mov dh, 0 ; row 0 (top row)
    mov dl, 0
    int 10h; call BIOS interrupt to set cursor position
    cli ; reenable IRQ1
    in al, 21h
    and al, 0FDh
    out 21h, al
    sti	   
    mov ax, 4C00h ; exit program  
    int 21h  
end start