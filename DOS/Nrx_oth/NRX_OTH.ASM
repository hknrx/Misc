; NRX 99
; 09/10/99

; tasm /m /mx NRX_OTH.ASM, NRX_OTH.OBJ
; tlink /x NRX_OTH.OBJ, NRX_OTH.EXE

;;;;;;;;;;;;;;;;;;;;;;;;;;
;      			 ;
; OPTIONS DE COMPILATION ;
;      			 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
.MODEL TINY
.486

OUVERTURE EQU 10
FERMETURE EQU 47
HASARD    EQU 25

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			     ;
; DEFINITIONS DES CONSTANTES ;
;			     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RIEN	EQU 00000000b	      ; Case libre.
BLANC	EQU 10000000b	      ; Pion blanc.
ROUGE	EQU 01000000b	      ; Pion rouge.
DEHORS  EQU 00100000b	      ; Dehors (contour du damier).
LIBRE  	EQU 11100000b	      ; Case libre ?
NOMBRE 	EQU 00011111b	      ; Nombre de prises.
ECHANGE EQU 1100000011000000b ; Echange les joueurs.

HUMAIN EQU 0 ; Joueur = HUMAIN.
NRX    EQU 1 ; Joueur = NRX.

ECHAP  EQU  1 ; Touche [ECHAP].
ESPACE EQU 57 ; Touche [ESPACE].
HAUT   EQU 72 ; Touche [fleche haut].
BAS    EQU 80 ; Touche [fleche bas].
GAUCHE EQU 75 ; Touche [fleche gauche].
DROITE EQU 77 ; Touche [fleche droite].

NOTE_FLEXIBILITE EQU 60 ; Calcul de la flexibilite.

;;;;;;;;;;;;;;;;;;;;;;
;		     ;
; VARIABLES GLOBALES ;
;		     ;
;;;;;;;;;;;;;;;;;;;;;;
.DATA

touche	DB ?
abandon DB ?
curseur DB 7
son     DB ?

ALIGN WORD
nombre_pions DW ?
niveaux_NRX  DW ?
types	     DW ?
couleurs     DW ?
meilleur     DW ?
recursion    DB ?

ALIGN WORD
DIR 	     DW -22,-2,18,20,22,2,-18,-20
CRITERE      DW 94,-2,-12,46,2,-28,-66,-2,28,22,2,12
QUART_DAMIER DW    0,-150,30,10,\
		-150,-250, 0, 0,\
		  30,   0, 1, 2,\
		  10,   0, 2,16,\ ; Coin libre.
		1000, 150,60,40,\
		 150, 150,30,30,\
		  60,  30,20,20,\
		  40,  30,20,20   ; Coin pris.

DIRECTIONS DB -1,-1,0,-1,1,-1,1,0,1,1,0,1,-1,1,-1,0

;;;;;;;;;;;;;;;;;;;;;;;;;
;			;
; CHAINES DE CARACTERES ;
;			;
;;;;;;;;;;;;;;;;;;;;;;;;;
chaine_POINTS		 DB ". . . . . . . .",0;
chaine_ETOILES		 DB "***********",0;
chaine_NIVEAU_ROUGES	 DB "Rouges :",0,"NRX-3 ",0;
chaine_NIVEAU_BLANCS	 DB "Blancs :",0,"HUMAIN",0;
chaine_SON		 DB "Son : NON",0;
chaine_OUI		 DB "OUI",0;
chaine_BLANCS		 DB "B L A N C S",0;
chaine_ROUGES		 DB "R O U G E S",0;
chaine_PASSENT		 DB "P A S S E N T !",0;
chaine_VIDE		 DB "               ",0;
chaine_ABANDON		 DB "  ABANDON  ",0;
chaine_EGALITE 		 DB "  EGALITE  ",0;
chaine_ROUGES_VAINQUEURS DB "ROUGES VAINQUEURS",0;
chaine_BLANCS_VAINQUEURS DB "BLANCS VAINQUEURS",0;

;;;;;;;;;;;;;;;;;
;               ;
; DEBUT DU CODE ; [0]
;      		;
;;;;;;;;;;;;;;;;;
.CODE

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Programme principal ; [1]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;

  ; Variables locales :
  damier	 EQU word ptr[bp-200]
  touche_normale EQU dword ptr[bp-204]
  encore	 EQU byte ptr[bp-205]

  ; Programme :
  mov ax,cs
  mov ds,ax
  push bp
  mov bp,sp
  sub sp,208

  ; Efface l'ecran :
  mov ax,3
  int 10h

  ; Nouveau gestionnaire de clavier :
  mov ax,3509h
  int 21h
  mov word ptr[touche_normale],bx
  mov word ptr[touche_normale+2],es

  mov ax,2509h
  mov dx,offset detourne_clavier
  int 21h

  ; Initialisations :
  mov abandon,0
  lea si,damier
  push si
  call initialisation
  pop si
  cmp abandon,0
  jne ABANDON@1

  ; Boucle principale :
  mov encore,2
  BOUCLE@1:

    ; Affiche a qui de jouer :
    cmp byte ptr[couleurs],BLANC
    jne ROUGES@1
      mov curseur,15
      push offset chaine_BLANCS
      jmp AFF_JOUEUR@1
    ROUGES@1:
      mov curseur,12
      push offset chaine_ROUGES
    AFF_JOUEUR@1:
    push 34+17*256
    call aff_chaine
    add sp,4

    ; Reflexion (NRX ou HUMAIN) :
    cmp byte ptr[types],NRX
    jne HUMAIN@1
      call cherche_meilleur_coup
      jmp FIN_REFLEXION@1
    HUMAIN@1:
      call saisie_coup
    FIN_REFLEXION@1:

    ; Abandon ? :
    cmp abandon,0
    jne ABANDON@1

    ; Agit :
    or al,al
    jz PASSENT@1
      push si
      call joue_affiche_coup
      pop si
      mov encore,2
      jmp FIN_AGIT@1
    PASSENT@1:
      push offset chaine_PASSENT
      push 32+19*256
      call aff_chaine
      push 220
      call start_beep
      push 100
      call tempo
      call stop_beep
      push 900
      call tempo
      push offset chaine_VIDE
      push 32+19*256
      call aff_chaine
      add sp,14
      dec encore
    FIN_AGIT@1:

    ; Echange les joueurs :
    xor couleurs,ECHANGE
    mov ax,nombre_pions
    rol ax,8
    mov nombre_pions,ax
    mov ax,niveaux_NRX
    rol ax,8
    mov niveaux_NRX,ax
    mov ax,types
    rol ax,8
    mov types,ax

    ; Continue :
    cmp encore,0
    jnz BOUCLE@1

  ; Fin :
  mov ax,nombre_pions
  sub al,ah
  jnz PAS_EGALITE@1
    mov curseur,9
    push offset chaine_EGALITE
    push 34+17*256
    call aff_chaine
    jmp FIN@1
  PAS_EGALITE@1:
    cmp byte ptr[couleurs],BLANC
    jne SUITE_VAINQUEURS@1
      neg al
    SUITE_VAINQUEURS@1:
    or al,al
    jl BLANCS_VAINQUEURS@1
      mov curseur,12
      push offset chaine_ROUGES_VAINQUEURS
      jmp AFF_VAINQUEURS@1
    BLANCS_VAINQUEURS@1:
      mov curseur,15
      push offset chaine_BLANCS_VAINQUEURS
    AFF_VAINQUEURS@1:
    push 31+17*256
    call aff_chaine
    jmp FIN@1

  ABANDON@1:
  mov curseur,9
  push offset chaine_ABANDON
  push 34+17*256
  call aff_chaine
  RELACHE_ECHAP@1:
    cmp touche,ECHAP
    je RELACHE_ECHAP@1

  FIN@1:
  push 0+19*256
  call pose_curseur
  add sp,6

  ; Ancien gestionnaire de clavier :
  mov ax,2509h
  lds dx,touche_normale
  int 21h

  ; Retour au DOS :
  leave
  mov ax,4C00h
  int 21h

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Fonction saisie_coup ; [2]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
saisie_coup PROC NEAR

  ; Variables locales :
  touche_ EQU byte ptr[bp-1]
  pion    EQU byte ptr[bp-2]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,2

  push si
  call cherche_coups_valides
  pop si
  or al,al
  jz FINI@2

  BOUCLE1@2:
    BOUCLE2@2:
      cmp abandon,0
      je PAS_ABANDON@2
	mov al,0
	jmp FINI@2

      PAS_ABANDON@2:
      mov cx,meilleur
      mov al,touche
      mov touche_,al

      cmp al,HAUT
      jne PAS_HAUT@2
	cmp ch,1
	jbe PAS_DROITE@2
	  dec byte ptr[meilleur+1]
	  jmp PAS_DROITE@2
      PAS_HAUT@2:

      cmp al,BAS
      jne PAS_BAS@2
	cmp ch,8
	jae PAS_DROITE@2
	  inc byte ptr[meilleur+1]
	  jmp PAS_DROITE@2
      PAS_BAS@2:

      cmp al,GAUCHE
      jne PAS_GAUCHE@2
	cmp cl,1
	jbe PAS_DROITE@2
	  dec byte ptr[meilleur]
	  jmp PAS_DROITE@2
      PAS_GAUCHE@2:

      cmp al,droite
      jne PAS_DROITE@2
	cmp cl,8
	jae PAS_DROITE@2
	  inc byte ptr[meilleur]
      PAS_DROITE@2:

      movzx bx,cl
      imul bx,10
      add bl,ch
      add bx,bx
      mov al,[si+bx]
      and al,LIBRE

      cmp al,RIEN
      jne PAS_RIEN1@2
	mov curseur,2
	mov pion,'.'
	jmp PAS_ROUGE1@2
      PAS_RIEN1@2:

      cmp al,BLANC
      jne PAS_BLANC1@2
	mov curseur,15
	mov pion,'O'
	jmp PAS_ROUGE1@2
      PAS_BLANC1@2:

      cmp al,ROUGE
      jne PAS_ROUGE1@2
	mov curseur,12
	mov pion,'X'
      PAS_ROUGE1@2:

      push word ptr[pion]
      push cx
      call aff_pion
      add sp,4

      mov cx,meilleur
      movzx bx,cl
      imul bx,10
      add bl,ch
      add bx,bx
      mov ax,[si+bx]
      and al,LIBRE

      cmp al,RIEN
      jne PAS_RIEN2@2
	or ah,ah
	jz PAS_ALLUME@2
	  mov curseur,14
	  jmp SUITE_RIEN2@2
	PAS_ALLUME@2:
	  mov curseur,2
	SUITE_RIEN2@2:
	mov pion,'.'
	jmp PAS_ROUGE2@2
      PAS_RIEN2@2:

      cmp al,BLANC
      jne PAS_BLANC2@2
	mov curseur,7
	mov pion,'O'
	jmp PAS_ROUGE2@2
      PAS_BLANC2@2:

      cmp al,ROUGE
      jne PAS_ROUGE2@2
	mov curseur,4
	mov pion,'X'
      PAS_ROUGE2@2:

      push word ptr[pion]
      push cx
      call aff_pion
      add ch,7
      add cl,cl
      add cl,30
      push cx
      call pose_curseur
      add sp,6

      mov al,touche_
      RELACHE@2:
	cmp al,touche
	je RELACHE@2

      cmp al,ESPACE
      jnz BOUCLE2@2

    mov cx,meilleur
    movzx bx,cl
    imul bx,10
    add bl,ch
    add bx,bx
    cmp byte ptr[si+bx+1],0
    je BOUCLE1@2

  mov al,1

  FINI@2:
  leave
  ret

saisie_coup ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          ;
; Procedure initialisation ; [3]
;                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initialisation PROC NEAR

  ; Variable d'entree :
  damier EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  ; Prepare le damier :
  mov ax,ds
  mov es,ax
  mov di,damier
  add di,20
  mov eax,RIEN+RIEN*65536
  mov cx,40
  cld
  repnz stosd

  mov si,di
  mov cl,10
  mov al,DEHORS
  BOUCLE1@3:
    mov [si],al
    mov [si-180],al
    mov [di],al
    mov [di+18],al
    add si,2
    sub di,20
    dec cl
    jnz BOUCLE1@3

  mov curseur,2
  mov cx,32+8*256
  BOUCLE2@3:
    push offset chaine_POINTS
    push cx
    call aff_chaine
    add sp,4
    inc ch
    cmp ch,16
    jne BOUCLE2@3

  mov curseur,12
  push 'X'
  push 4+5*256
  call aff_pion
  add sp,2
  push 5+4*256
  call aff_pion
  add sp,4
  mov byte ptr[di+20+(4+5*10)*2],ROUGE
  mov byte ptr[di+20+(5+4*10)*2],ROUGE

  mov curseur,15
  push 'O'
  push 4+4*256
  call aff_pion
  add sp,2
  push 5+5*256
  call aff_pion
  add sp,4
  mov byte ptr[di+20+(4+4*10)*2],BLANC
  mov byte ptr[di+20+(5+5*10)*2],BLANC

  mov nombre_pions,2+2*256;
  mov couleurs,ROUGE+BLANC*256

  ; Prepare l'affichage du score :
  mov curseur,9
  push offset chaine_ETOILES
  push 0+10*256
  call aff_chaine
  push offset chaine_NIVEAU_ROUGES
  push 0+11*256
  call aff_chaine
  push offset chaine_NIVEAU_BLANCS
  push 0+12*256
  call aff_chaine
  push offset chaine_ETOILES
  push 0+13*256
  call aff_chaine
  add sp,16
  call aff_score

  mov byte ptr[chaine_NIVEAU_ROUGES+8],' '
  mov byte ptr[chaine_NIVEAU_BLANCS+8],' '

  ; Initialisations :
  mov types,NRX+HUMAIN*256
  mov niveaux_NRX,3+0*256
  mov son,0

  mov curseur,1
  push offset chaine_NIVEAU_ROUGES
  push 0+0*256
  call aff_chaine
  push offset chaine_NIVEAU_BLANCS
  push 0+1*256
  call aff_chaine
  push offset chaine_SON
  push 0+3*256
  call aff_chaine
  add sp,12

  ; Initialisations (au cas ou 1er joueur = humain...) :
  mov meilleur,4+4*256

  ; Types et niveaux :
  mov bx,0
  mov di,offset types
  mov si,offset niveaux_NRX
  BOUCLE3@3:
    cmp abandon,0
    jne FIN@3

    mov cl,touche

    cmp cl,GAUCHE
    jne PAS_GAUCHE@3
      cmp byte ptr[si+bx],0
      je HUMAIN@3
	dec byte ptr[si+bx]
	jmp PAS_HAUT_BAS@3
      HUMAIN@3:
	mov byte ptr[di+bx],HUMAIN
	jmp PAS_HAUT_BAS@3
    PAS_GAUCHE@3:

    cmp cl,DROITE
    jne PAS_DROITE@3
      cmp byte ptr[di+bx],HUMAIN
      jne INC_NIVEAU@3
	mov byte ptr[di+bx],NRX
	jmp PAS_HAUT_BAS@3
      INC_NIVEAU@3:
	cmp byte ptr[si+bx],7
	je PAS_HAUT_BAS@3
	inc byte ptr[si+bx]
	jmp PAS_HAUT_BAS@3
    PAS_DROITE@3:

    cmp cl,HAUT
    je HAUT_BAS@3
    cmp cl,BAS
    jne PAS_HAUT_BAS@3
    HAUT_BAS@3:
      xor bx,1
    PAS_HAUT_BAS@3:

    cmp byte ptr[di+bx],NRX
    jne NIVEAU_HUMAIN@3
      mov al,[si+bx]
      add al,'0'
      mov [chaine_NIVEAU_ROUGES+13],al
      push offset chaine_NIVEAU_ROUGES+9
      jmp AFF_NIVEAU@3
    NIVEAU_HUMAIN@3:
      push offset chaine_NIVEAU_BLANCS+9
    AFF_NIVEAU@3:
    mov ah,bl
    mov al,9
    push ax
    call aff_chaine
    pop ax
    mov al,15
    push ax
    call pose_curseur
    pop ax
    add sp,2
    movzx bx,ah

    RELACHE1@3:
      cmp cl,touche
      je RELACHE1@3

    cmp cl,ESPACE
    jne BOUCLE3@3

  ; Son :
  push 9+3*256
  call pose_curseur
  add sp,2

  BOUCLE4@3:
    cmp abandon,0
    jne FIN@3

    mov cl,touche

    cmp cl,GAUCHE
    je GAUCHE_DROITE@3
    cmp cl,DROITE
    jne PAS_GAUCHE_DROITE@3
    GAUCHE_DROITE@3:
      xor son,1
    PAS_GAUCHE_DROITE@3:

    cmp son,0
    je PAS_SON@3
      push offset chaine_OUI
      jmp AFF_SON@3
    PAS_SON@3:
      push offset chaine_SON+6
    AFF_SON@3:
    push 6+3*256
    call aff_chaine
    add sp,4

    RELACHE2@3:
      cmp cl,touche
      je RELACHE2@3

    cmp cl,ESPACE
    jne BOUCLE4@3

  FIN@3:
  pop bp
  ret

initialisation ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			      ;
; Procedure joue_affiche_coup ; [4]
;			      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
joue_affiche_coup PROC NEAR

  ; Variable d'entree :
  damier EQU word ptr[bp+4]

  ; Variables locales :
  dir_prises EQU byte ptr[bp-1]
  pion       EQU byte ptr[bp-2]
  frequence  EQU word ptr[bp-4]
  y	     EQU byte ptr[bp-5]
  x	     EQU byte ptr[bp-6]
  xy	     EQU word ptr[bp-6]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,6

  ; Calcule du nombre de pions :
  mov cx,meilleur
  movzx bx,cl
  imul bx,10
  add bl,ch
  add bx,bx
  add bx,damier
  mov ax,[bx]
  mov dir_prises,ah
  and al,NOMBRE
  sub byte ptr[nombre_pions+1],al
  inc al
  add byte ptr[nombre_pions],al

  ; Joue le coup sur le damier :
  mov al,byte ptr[couleurs]
  mov [bx],al

  cmp al,BLANC
  jne ROUGE@4
    mov curseur,15
    mov pion,'O'
    mov frequence,400
    jmp AFF_PION@4
  ROUGE@4:
    mov curseur,12
    mov pion,'X'
    mov frequence,500
  AFF_PION@4:

  push word ptr[pion]
  push cx
  call aff_pion
  add ch,7
  add cl,cl
  add cl,30
  push cx
  call pose_curseur
  add sp,6

  mov si,offset DIRECTIONS+14
  BOUCLE1@4:

    shr dir_prises,1
    jnc DIR_SUIVANTE@4

      mov ax,meilleur
      mov xy,ax
      BOUCLE2@4:
	mov ax,[si]
	add al,x
	add ah,y
	mov xy,ax

	movzx bx,al
	imul bx,10
	add bl,ah
	add bx,bx
	add bx,damier
	mov ax,[couleurs]
	and ah,[bx]
	jz DIR_SUIVANTE@4
	mov [bx],al

	cmp son,0
	je PAS_SON@4
	  push frequence
	  call start_beep
	  push 40
	  call tempo
	  add sp,4
	  call stop_beep
	PAS_SON@4:

	push '+'
	push xy
	call aff_pion
	push 50
	call tempo
	push word ptr[pion]
	push xy
	call aff_pion
	add sp,10
	jmp BOUCLE2@4

    DIR_SUIVANTE@4:
    sub si,2
    cmp si,offset DIRECTIONS
    jge BOUCLE1@4

  ; Affiche le nombre de pions :
  mov curseur,9
  call aff_score

  leave
  ret

joue_affiche_coup ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			     ;
; Procedure detourne_clavier ; [5]
;			     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
detourne_clavier PROC NEAR

  ; Programme :
  push ax

  in al,60h
  mov cs:touche,al

  cmp al,ECHAP
  jne SUITE@5
    mov cs:abandon,al
  SUITE@5:

  mov al,20h
  out 20h,al

  pop ax
  iret

detourne_clavier ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;		      ;
; Fonction lit_chrono ; [6]
;		      ;
;;;;;;;;;;;;;;;;;;;;;;;
lit_chrono PROC NEAR

  ; Programme :

  cli
  mov al,0
  out 43h,al
  in al,40h
  mov bl,al
  in al,40h
  mov bh,al
  not bx
  sti

  ret

lit_chrono ENDP

;;;;;;;;;;;;;;;;;;;
;                 ;
; Procedure tempo ; [7]
;                 ;
;;;;;;;;;;;;;;;;;;;
tempo PROC NEAR

  ; Variable d'entree :
  duree EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  xor ebx,ebx
  call lit_chrono

  movzx ecx,duree
  imul ecx,952h
  add ecx,ebx

  BOUCLE@7:
    mov dx,bx
    call lit_chrono
    cmp ebx,ecx
    jae FIN@7
    cmp dx,bx
    jb BOUCLE@7
    add ebx,10000h
    jmp BOUCLE@7
  FIN@7:

  pop bp
  ret

tempo ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure start_beep ; [8]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
start_beep PROC NEAR

  ; Variable d'entree :
  frequence EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  cli
  mov bx,frequence
  mov dx,12h
  cmp bx,dx
  jna FIN@8
    mov al,0b6h
    out 43h,al
    mov ax,34ddh
    div bx
    out 42h,al
    mov al,ah
    out 42h,al

    in al,61h
    or al,00000011b
    out 61h,al
  FIN@8:
  sti

  pop bp
  ret

start_beep ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure stop_beep ; [9]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
stop_beep PROC NEAR

  ; Programme :

  in al,61h
  and al,11111100b
  out 61h,al

  ret

stop_beep ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				 ;
; Fonction cherche_coups_valides ; [10]
;				 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cherche_coups_valides PROC NEAR

  ; Programme :
  push bp
  mov bp,sp
  push di

  ; Initialisations :
  add si,22
  mov dx,couleurs

  mov bx,nombre_pions
  add bl,bl
  add bl,bh
  cmp bl,64
  ja CHERCHE_VIDE@10

  ; Cherche a partir des pions du joueur :
  mov eax,LIBRE+LIBRE*65536
  mov bx,152
  BOUCLE_INIT@10:
    and [si+bx],eax
    sub bx,4
    jnl BOUCLE_INIT@10

  mov ch,8
  BOUCLE_PION1@10:
    mov cl,8
    BOUCLE_PION2@10:
      test [si],dl
      jz SUITE_PION@10
	mov bh,1
	mov bp,14
	BOUCLE_PION_DIR1@10:
	  mov bl,-1
	  mov di,si
	  BOUCLE_PION_DIR2@10:
	    inc bl
	    sub di,[bp+offset DIR]
	    test [di],dh
	    jnz BOUCLE_PION_DIR2@10
	  or bl,bl
	  jz FIN_PION_DIR@10
	    test byte ptr[di],LIBRE
	    jnz FIN_PION_DIR@10
	      add [di],bx
	  FIN_PION_DIR@10:
	  add bh,bh
	  sub bp,2
	  jns BOUCLE_PION_DIR1@10
      SUITE_PION@10:
      add si,2
      dec cl
      jnz BOUCLE_PION2@10
    add si,4
    dec ch
    jnz BOUCLE_PION1@10

  sub si,160
  mov ax,NOMBRE*256
  mov bx,154
  BOUCLE_NOMBRE_COUPS@10:
    test [si+bx],ah
    jz SUITE_NOMBRE_COUPS@10
      inc al
    SUITE_NOMBRE_COUPS@10:
    sub bx,2
    jnl BOUCLE_NOMBRE_COUPS@10

  mov [si+177],al
  pop di
  pop bp
  ret

  ; Cherche a partir des cases vides :
  CHERCHE_VIDE@10:
  xor ax,ax
  mov ch,8
  BOUCLE_VIDE1@10:
    mov cl,8
    BOUCLE_VIDE2@10:
      and word ptr[si],LIBRE
      jnz SUITE_VIDE@10
	mov bh,1
	mov bp,14
	BOUCLE_VIDE_DIR1@10:
	  mov bl,-1
	  mov di,si
	  BOUCLE_VIDE_DIR2@10:
	    inc bl
	    add di,[bp+offset DIR]
	    test [di],dh
	    jnz BOUCLE_VIDE_DIR2@10
	  or bl,bl
	  jz FIN_VIDE_DIR@10
	    test [di],dl
	    jz FIN_VIDE_DIR@10
	      add [si],bx
	      mov ah,1
	  FIN_VIDE_DIR@10:
	  add bh,bh
	  sub bp,2
	  jns BOUCLE_VIDE_DIR1@10
	or ah,ah
	jz SUITE_VIDE@10
	  inc al
	  mov ah,0
      SUITE_VIDE@10:
      add si,2
      dec cl
      jnz BOUCLE_VIDE2@10
    add si,4
    dec ch
    jnz BOUCLE_VIDE1@10

  mov [si+17],al
  pop di
  pop bp
  ret

cherche_coups_valides ENDP

;;;;;;;;;;;;;;;;;;;;
;		   ;
; Fonction cherche ; [11]
;		   ;
;;;;;;;;;;;;;;;;;;;;
cherche PROC NEAR

  ; Variables d'entree :
  alpha  	EQU word ptr[bp+4]
  beta		EQU word ptr[bp+6]
  damier_before	EQU word ptr[bp+8]  ; = si
  coup		EQU word ptr[bp+10] ; = bx

  ; Variable locale :
  damier EQU word ptr[bp-200]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,200

  ; Copie le damier :
  lea di,damier
  mov cx,50
  repnz movsd
  lea si,damier

  ; Joue le coup :
  or bx,bx
  jz FIN_COUP@11
    add si,bx
    mov al,byte ptr[couleurs+1]
    mov [si],al

    mov ah,[si+1]
    mov bx,offset DIR-2
    BOUCLE_COUP1@11:
      add bx,2
      add ah,ah
      jnc CONTINUE_COUP@11

      mov di,si
      add di,[bx]
      BOUCLE_COUP2@11:
	mov [di],al
	add di,[bx]
	test [di],al
	jz BOUCLE_COUP2@11
      or ah,ah

      CONTINUE_COUP@11:
      jnz BOUCLE_COUP1@11
    sub si,coup
  FIN_COUP@11:

  ; Cherche les coups valides :
  push si
  call cherche_coups_valides
  pop si

  ; La partie est terminee ? :
  or al,al
  jnz TEST_RECURSION@11
  cmp coup,0
  jne TEST_RECURSION@11

    ; Critere = diff. nombre de pions + gros bonus si victoire :
    mov ax,nombre_pions
    sub al,ah
    js NEGATIF@11
      mov ah,127
      leave
      ret
    NEGATIF@11:
    mov ah,129
    leave
    ret

  TEST_RECURSION@11:
  cmp recursion,0
  je FIN_RECURSION@11
  cmp abandon,0
  je PAS_FINI@11

  FIN_RECURSION@11:

    ; Note la flexibilite :
    mov di,damier_before
    movzx bx,byte ptr[di+199]
    mov ah,0
    sub ax,bx
    imul ax,NOTE_FLEXIBILITE

    ; Note la position :
    mov dx,couleurs
    mov bx,18
    BOUCLE_POSITION1@11:
      mov di,offset QUART_DAMIER
      add si,[bx+offset CRITERE]
      test byte ptr[si],LIBRE
      jz FIN_TEST_COIN@11
	add di,32
      FIN_TEST_COIN@11:

      mov ch,4
      BOUCLE_POSITION2@11:
	mov cl,4
	BOUCLE_POSITION3@11:
	  test [si],dl
	  jz SUITE_POSITION@11
	    add ax,[di]
	    jmp FIN_POSITION@11
	  SUITE_POSITION@11:
	    test [si],dh
	    jz FIN_POSITION@11
	      sub ax,[di]
	  FIN_POSITION@11:
	  add di,2
	  add si,[bx+offset CRITERE+2]
	  dec cl
	  jnz BOUCLE_POSITION3@11
	add si,[bx+offset CRITERE+4]
	dec ch
	jnz BOUCLE_POSITION2@11

      sub bx,6
      jge BOUCLE_POSITION1@11

    leave
    ret

  PAS_FINI@11:

  ; Echange les joueurs :
  xor couleurs,ECHANGE
  mov bx,nombre_pions
  rol bx,8
  mov nombre_pions,bx
  dec recursion
  neg alpha
  neg beta

  ; On peut jouer ? :
  or al,al
  jnz RECURSION@11
    xor bx,bx
    push bx
    push si
    push alpha
    push beta
    call cherche
    add sp,8
    jmp INVERSE@11
  RECURSION@11:

  ; Recursion (alpha-beta) :
  mov bx,22
  BOUCLE_PRINCIPALE@11:
    mov al,[bx+si]
    and al,NOMBRE
    jz SUITE_PRINCIPALE@11

      sub byte ptr[nombre_pions],al
      inc al
      add byte ptr[nombre_pions+1],al

      push bx
      push si
      push alpha
      push beta
      call cherche
      add sp,4
      pop si
      pop bx

      mov cl,[bx+si]
      add byte ptr[nombre_pions],cl
      inc cl
      sub byte ptr[nombre_pions+1],cl

      cmp ax,alpha
      jge SUITE_PRINCIPALE@11
	mov alpha,ax
	cmp ax,beta
	jle INVERSE@11

    SUITE_PRINCIPALE@11:
    add bx,2
    cmp bx,176
    jle BOUCLE_PRINCIPALE@11
  mov ax,alpha

  INVERSE@11:
  neg ax

  ; Echange les joueurs :
  inc recursion
  mov bx,nombre_pions
  rol bx,8
  mov nombre_pions,bx
  xor couleurs,ECHANGE

  leave
  ret

cherche ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				 ;
; Fonction cherche_meilleur_coup ; [12]
;				 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cherche_meilleur_coup PROC NEAR

  ; Variables locales :
  j    EQU byte ptr[bp-1]
  i    EQU byte ptr[bp-2]
  ij   EQU word ptr[bp-2]
  note EQU word ptr[bp-4]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,4
  push di

  ; Niveau de NRX :
  ifdef OUVERTURE or FERMETURE
    mov ax,nombre_pions
    add al,ah
  endif

  ifdef OUVERTURE
    cmp al,OUVERTURE
    jg PAS_OUVERTURE@12
      mov ah,3
      jmp PAS_HASARD@12
  endif
  PAS_OUVERTURE@12:

  mov ah,byte ptr[niveaux_NRX]

  ifdef FERMETURE
    sub al,FERMETURE
    jle PAS_FERMETURE@12
      add ah,al
  endif
  PAS_FERMETURE@12:

  ifdef HASARD
    call lit_chrono
    cmp bl,HASARD
    ja PAS_HASARD@12
      inc ah
  endif
  PAS_HASARD@12:

  mov recursion,ah

  ; Cherche les coups valides :
  push si
  call cherche_coups_valides
  pop si

  ; On peut jouer ? :
  or al,al
  jnz PAS_FINI@12
    pop di
    leave
    ret
  PAS_FINI@12:

  ; Echange les joueurs :
  xor couleurs,ECHANGE
  mov bx,nombre_pions
  rol bx,8
  mov nombre_pions,bx

  ; Recursion (alpha-beta) :
  mov ax,ds
  mov es,ax
  cld
  mov note,32767
  mov bx,176
  mov i,8
  BOUCLE_PRINCIPALE1@12:
    mov j,8
    BOUCLE_PRINCIPALE2@12:
      mov al,[bx+si]
      and al,NOMBRE
      jz SUITE_PRINCIPALE@12

	sub byte ptr[nombre_pions],al
	inc al
	add byte ptr[nombre_pions+1],al

	push bx
	push si
	push note
	push -32767
	call cherche
	add sp,4
	pop si
	pop bx

	mov cl,[bx+si]
	add byte ptr[nombre_pions],cl
	inc cl
	sub byte ptr[nombre_pions+1],cl

	cmp ax,note
	jge SUITE_PRINCIPALE@12
	  mov note,ax
	  mov ax,ij
	  mov meilleur,ax

      SUITE_PRINCIPALE@12:
      sub bx,2
      dec j
      jnz BOUCLE_PRINCIPALE2@12
    sub bx,4
    dec i
    jnz BOUCLE_PRINCIPALE1@12
  mov al,1

  ; Echange les joueurs :
  mov bx,nombre_pions
  rol bx,8
  mov nombre_pions,bx
  xor couleurs,ECHANGE

  pop di
  leave
  ret

cherche_meilleur_coup ENDP

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Procedure aff_pion ; [13]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
aff_pion PROC NEAR

  ; Variables d'entree :
  x    EQU byte ptr[bp+4]
  y    EQU byte ptr[bp+5]
  pion EQU byte ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp

  mov ax,0b800h
  mov es,ax

  movzx bx,x
  movzx ax,y
  shl ax,3
  add bx,ax
  shl ax,2
  add bx,ax
  shl bx,2
  add bx,(30+7*80)*2

  mov ah,curseur
  mov al,pion
  mov es:[bx],ax

  pop bp
  ret

aff_pion ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure aff_chaine ; [14]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
aff_chaine PROC NEAR

  ; Variables d'entree :
  x	 EQU byte ptr[bp+4]
  y 	 EQU byte ptr[bp+5]
  chaine EQU word ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp
  push si

  mov ax,0b800h
  mov es,ax

  movzx bx,x
  movzx ax,y
  shl ax,4
  add bx,ax
  shl ax,2
  add bx,ax
  add bx,bx

  cld
  mov ah,curseur
  mov si,chaine
  BOUCLE@14:
    lodsb
    or al,al
    jz FIN@14
    mov es:[bx],ax
    add bx,2
    jmp BOUCLE@14
  FIN@14:

  pop si
  pop bp
  ret

aff_chaine ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure aff_score ; [15]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
aff_score PROC NEAR

  ; Variable locale :
  buffer EQU byte ptr[bp-4]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,4

  mov si,1
  BOUCLE@15:

    mov bx,bp
    dec bx
    mov byte ptr[bx],0

    mov al,byte ptr[nombre_pions+si]
    cmp al,10
    jnb GRAND@15
      add al,'0'
      mov ah,al
      mov al,' '
      jmp SUITE@15
    GRAND@15:
      mov ah,0
      xor dx,dx
      mov cx,10
      div cx
      mov ah,dl
      add ax,'0'+'0'*256
    SUITE@15:
    sub bx,2
    mov [bx],ax

    mov ah,byte ptr[couleurs+si]
    and ah,ROUGE
    setz ah
    add ah,11

    push bx
    mov al,9
    push ax
    call aff_chaine
    add sp,4

    dec si
    jnl BOUCLE@15

  leave
  ret

aff_score ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        ;
; Procedure pose_curseur ; [16]
;                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
pose_curseur PROC NEAR

  ; Variable d'entree :
  xy EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov ah,2
  mov bh,0
  mov dx,xy
  int 10h

  pop bp
  ret

pose_curseur ENDP

;;;;;;;;;;;;;;;
;             ;
; FIN DU CODE ; [17]
;             ;
;;;;;;;;;;;;;;;
END