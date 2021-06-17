; NRX 98
; 20/12/98

;;;;;;;;;;;;;;;;;;;;;;;;;;
;      			 ;
; OPTIONS DE COMPILATION ;
;      			 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
.MODEL COMPACT,C
.486P

;;;;;;;;;;;;;;
;            ;
; CONSTANTES ;
;            ;
;;;;;;;;;;;;;;
; Camera :
xm     EQU 320
ym     EQU 200
xo     EQU 160
yo     EQU 100
coefx  EQU 307
coefy  EQU 256
coefy_ EQU 8

; Tableaux :
NB_SQRT_FX EQU 32768  ; 0.5
NB_INV_FX  EQU 196608 ; 3.0

; Textures :
OBJ_TEXTURES_L EQU 256 ; modification -> revoir "cre_OBJ_TEXTURES",
OBJ_TEXTURES_H EQU 256 ; "cre_vox", et "ombrage_vox" :
VOX_TEXTURES_L EQU 256 ; - modifier la condition de fin des boucles !
VOX_TEXTURES_H EQU 256 ; - choisir le code normal de "ombrage_vox" !

; Boules :
BOULE_DEF_ EQU 2

; Polygones :
VISIBLE_MIN EQU 22000 ; >65536*65536/NB_INV_FX
PRECISION_  EQU 6     ; pas trop grand ?
D_MIN	    EQU 1000  ; >(1<<PRECISION_)
POLY_DEF_   EQU 2

; Voxel spacing :
VOX_PAS_    EQU 2   ; modifier directement "aff_vox" !
PREMIER_VOX EQU 10
DERNIER_VOX EQU 300
VOX_DEF_    EQU 7
COUL_CIEL   EQU 200

; Tunnel :
RAYON EQU 16

; Bump2D :
FREQ_VAGUES   EQU 16
T_GRAVURE     EQU 8
HAUTEUR_SPOT  EQU 64
HAUTEUR_SPOT_ EQU 6

;;;;;;;;;;;;;;
;            ;
; STRUCTURES ;
;            ;
;;;;;;;;;;;;;;
; Point :
_xe    EQU 0
_ye    EQU 2
_x3D_O EQU 4
_y3D_O EQU 8
_z3D_O EQU 12
_x3D_C EQU 16
_y3D_C EQU 20
_z3D_C EQU 24

; Matrice :
_Mxx EQU 0
_Myx EQU 4
_Mzx EQU 8
_Mxy EQU 12
_Myy EQU 16
_Mzy EQU 20
_Mxz EQU 24
_Myz EQU 28
_Mzz EQU 32

; Boule :
_pt        EQU 0
_r         EQU 28
_deforme_x EQU 32
_deforme_y EQU 36
_deforme_z EQU 40
_texture_B EQU 44

; Poly :
_nb_pts    EQU 0
_num_pt    EQU 1
_norm_V    EQU 5
_norm_W    EQU 9
_texture_P EQU 13

; Objet :
_mat EQU 0
_x   EQU 36
_y   EQU 40
_z   EQU 44

;;;;;;;;;;;;;;;;;;;;;;
;       	     ;
; VARIABLES GLOBALES ;
;       	     ;
;;;;;;;;;;;;;;;;;;;;;;
.DATA
; Gestion de la memoire etendue :
EXTRN XMS_driver: dword
EXTRN XMS_handle: word

; Generateur de nombres aleatoires :
EXTRN aleatoire: byte

; Clavier :
EXTRN TOUCHES: 	  byte
EXTRN nb_touches: byte

; Buffers :
EXTRN SIN_FX:   dword
EXTRN IMAGE:    dword
EXTRN BLOC_64K:	dword
EXTRN PALETTES: dword
EXTRN TEXTURES: dword

; Soleil :
EXTRN sol_x: 	dword
EXTRN sol_y: 	dword
EXTRN sol_z: 	dword

;;;;;;;;;;;;;;;;;
;               ;
; DEBUT DU CODE ; [0]
;      		;
;;;;;;;;;;;;;;;;;
.CODE

;****************************************************************************;
;*                                                                          *;
;* MEMOIRE						                    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Fonction dispo_DOS ; [55]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC dispo_DOS
dispo_DOS PROC NEAR

  ; Programme :

  mov ah,48h
  mov bx,0ffffh
  int 21h
  cmp bh,0fh
  jbe SUITE@55
    mov ax,0ffffh
    ret
  SUITE@55:
  mov ax,bx
  shl ax,4

  ret

dispo_DOS ENDP

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Fonction alloc_DOS ; [1]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC alloc_DOS
alloc_DOS PROC NEAR

  ; Variable d'entree :
  taille EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov bx,taille
  mov al,bl
  shr bx,4
  test al,1111b
  jz SUITE@1
    inc bx
  SUITE@1:
  mov ah,48h
  int 21h
  jnc OK@1
    xor ax,ax
  OK@1:
  mov dx,ax
  xor ax,ax

  pop bp
  ret

alloc_DOS ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure liber_DOS ; [2]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC liber_DOS
liber_DOS PROC NEAR

  ; Variable d'entree :
  pointeur EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov ah,49h
  mov es,[pointeur+2]
  int 21h

  pop bp
  ret

liber_DOS ENDP

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Fonction alloc_XMS ; [3]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC alloc_XMS
alloc_XMS PROC NEAR

  ; Constantes :
  T_SQRT_FX      EQU NB_SQRT_FX*4
  T_INV_FX       EQU NB_INV_FX*4
  T_BOULE 	 EQU (xm+ym*5)*4
  T_Z_BUFFER     EQU xm*ym*4
  T_OBJ_TEXTURES EQU OBJ_TEXTURES_L*OBJ_TEXTURES_H
  T_VOX_TEXTURES EQU VOX_TEXTURES_L*VOX_TEXTURES_H
  T_HAUTEURS     EQU VOX_TEXTURES_L*VOX_TEXTURES_H*2
  T_EMB 	 EQU T_SQRT_FX+T_INV_FX+T_BOULE+T_Z_BUFFER+T_OBJ_TEXTURES+T_VOX_TEXTURES+T_HAUTEURS

  ; Variables locales :
  gdt 	  EQU [bp-16]
  gdt_ptr EQU [bp-22]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,22

  ; Processeur en mode protege ? :
  mov eax,cr0
  and al,1
  jz OK1@3
    mov al,1
    leave
    ret
  OK1@3:

  ; Gestionnaire XMS installe ? :
  mov ax,4300h
  int 2fh
  cmp al,80h
  je OK2@3
    mov al,2
    leave
    ret
  OK2@3:

  ; Adresse du gestionnaire XMS ? :
  mov ax,4310h
  int 2fh
  mov word ptr[XMS_driver+2],es
  mov word ptr[XMS_driver],bx

  ; Version >= 2.0 ? :
  xor ah,ah
  call XMS_driver
  cmp ax,0200h
  jnb OK3@3
    mov al,3
    leave
    ret
  OK3@3:

  ; Allocation de l'EMB :
  mov edx,T_EMB
  mov ax,dx
  shr edx,10
  and ax,1023
  jz OK4@3
    inc dx
  OK4@3:
  mov ah,09h
  call XMS_driver
  or ax,ax
  jnz OK5@3
    mov al,4
    leave
    ret
  OK5@3:
  mov XMS_handle,dx

  ; Protege l'EMB contre le deplacement et recupere son adresse :
  mov ah,0ch
  call XMS_driver
  or ax,ax
  jnz OK6@3
    mov ah,0ah
    mov dx,XMS_handle
    call XMS_driver
    mov al,5
    leave
    ret
  OK6@3:
  shl edx,16
  mov dx,bx

  ; Mise en place des pointeurs :
  mov cs:dword ptr[SQRT_FX@35+6],edx
  mov cs:dword ptr[SQRT_FX@42+6],edx
inc edx
mov cs:dword ptr[SQRT_FX@76+5],edx
dec edx
  add edx,T_SQRT_FX
  mov cs:dword ptr[INV_FX@36+6],edx
  mov cs:dword ptr[INV_FX_a@42+6],edx
  mov cs:dword ptr[INV_FX_b@42+6],edx
  mov cs:dword ptr[INV_FX_a@43+6],edx
  mov cs:dword ptr[INV_FX_b@43+6],edx
  mov cs:dword ptr[INV_FX_c@43+6],edx
  mov cs:dword ptr[INV_FX_d@43+6],edx
  mov cs:dword ptr[INV_FX@53+6],edx
  mov cs:dword ptr[INV_FX@72+6],edx
  add edx,T_INV_FX
  mov cs:dword ptr[BOULE_TAB1@41+6],edx
  mov cs:dword ptr[BOULE_TAB1@42+6],edx
  mov cs:dword ptr[BOULE_TAB1@53+6],edx
  add edx,xm*4
  mov cs:dword ptr[BOULE_TAB2@41+6],edx
  mov cs:dword ptr[BOULE_TAB2@42+6],edx
  add edx,ym*4
  mov cs:dword ptr[BOULE_TAB3_a@42+6],edx
  mov cs:dword ptr[BOULE_TAB3_b@42+6],edx
  add edx,ym*4
  mov cs:dword ptr[BOULE_TAB4_a@42+6],edx
  mov cs:dword ptr[BOULE_TAB4_b@42+6],edx
  add edx,ym*4
  mov cs:dword ptr[BOULE_TAB5_a@42+6],edx
  mov cs:dword ptr[BOULE_TAB5_b@42+6],edx
  add edx,ym*4
  mov cs:dword ptr[BOULE_TAB6_a@42+6],edx
  mov cs:dword ptr[BOULE_TAB6_b@42+6],edx
  add edx,ym*4
  mov cs:dword ptr[Z_BUFFER@40+6],edx
  mov cs:dword ptr[Z_BUFFER_a@42+6],edx
  mov cs:dword ptr[Z_BUFFER_b@42+6],edx
  mov cs:dword ptr[Z_BUFFER_a@43+6],edx
  mov cs:dword ptr[Z_BUFFER_b@43+6],edx
  mov cs:dword ptr[Z_BUFFER_a@53+6],edx
  mov cs:dword ptr[Z_BUFFER_b@53+6],edx
  add edx,T_Z_BUFFER
  mov TEXTURES,edx
  mov cs:dword ptr[OBJ_TEXTURES_a@42+2],edx
  mov cs:dword ptr[OBJ_TEXTURES_a@43+2],edx
  mov cs:dword ptr[OBJ_TEXTURES@66+4],edx
  mov cs:dword ptr[SPR_TEXTURES@48+4],edx
  mov cs:dword ptr[TUN_TEXTURES_a@71+4],edx
  mov cs:dword ptr[TUN_TEXTURES_b@71+4],edx
  mov cs:dword ptr[TUN_TEXTURES_c@71+4],edx
  mov cs:dword ptr[TUN_TEXTURES_d@71+4],edx
  add edx,T_OBJ_TEXTURES
  mov cs:dword ptr[VOX_TEXTURES@53+4],edx
  mov cs:dword ptr[VOX_TEXTURES@62+4],edx
  mov cs:dword ptr[VOX_TEXTURES@65+4],edx
  add edx,T_VOX_TEXTURES
  mov cs:dword ptr[HAUTEURS@53+7],edx
  mov cs:dword ptr[HAUTEURS@60+5],edx
  mov cs:dword ptr[HAUTEURS@61+7],edx
  mov cs:dword ptr[HAUTEURS@65+5],edx

; "ombrage_vox" avec modulo :
  mov cs:dword ptr[HAUTEURS_a@62+5],edx
  mov cs:dword ptr[HAUTEURS_b@62+5],edx
  mov cs:dword ptr[HAUTEURS_c@62+5],edx
  mov cs:dword ptr[HAUTEURS_d@62+5],edx

; "ombrage_vox" normal :
; add edx,2
; mov cs:dword ptr[HAUTEURS_a@62+5],edx
; sub edx,4
; mov cs:dword ptr[HAUTEURS_b@62+5],edx
; add edx,2+2*VOX_TEXTURES_L
; mov cs:dword ptr[HAUTEURS_c@62+5],edx
; sub edx,4*VOX_TEXTURES_L
; mov cs:dword ptr[HAUTEURS_d@62+5],edx

  ; Active A20 globalement :
  mov ah,03h
  call XMS_driver

  ; Modele "flat" :
  mov dword ptr[gdt],0
  mov dword ptr[gdt+4],0
  mov dword ptr[gdt+8],0ffffh
  mov dword ptr[gdt+12],0ffcf9200h
  mov word ptr[gdt_ptr],16
  xor eax,eax
  mov ax,ss
  shl eax,4
  xor ebx,ebx
  lea bx,gdt
  add eax,ebx
  mov dword ptr[gdt_ptr+2],eax
  lgdt gdt_ptr
  cli
  mov eax,cr0
  or al,1
  mov cr0,eax
  jmp SAUT1@3
  SAUT1@3:
  mov bx,8
  mov gs,bx
  and al,254
  mov cr0,eax
  jmp SAUT2@3
  SAUT2@3:
  sti

  ; Pas d'erreur :
  xor al,al
  leave
  ret

alloc_XMS ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure liber_XMS ; [4]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC liber_XMS
liber_XMS PROC NEAR

  ; Programme :

  ; Ferme A20 globalement :
  mov ah,04h
  call XMS_driver

  ; Deverouille l'EMB :
  mov ah,0dh
  mov dx,XMS_handle
  call XMS_driver

  ; Libere l'EMB :
  mov ah,0ah
  mov dx,XMS_handle
  call XMS_driver

  ret

liber_XMS ENDP

;****************************************************************************;
;*                                                                          *;
;* FICHIER							            *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Fonction cre_fichier ; [54]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC cre_fichier
cre_fichier PROC NEAR

  ; Variable d'entree :
  nom EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  push ds
  mov ah,3ch
  xor cx,cx
  lds dx,nom
  int 21h
  jnc OK@54
    xor ax,ax
  OK@54:
  pop ds

  pop bp
  ret

cre_fichier ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                	 ;
; Fonction ouvre_fichier ; [5]
;                	 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC ouvre_fichier
ouvre_fichier PROC NEAR

  ; Variables d'entree :
  nom  EQU dword ptr[bp+4]
  code EQU byte ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp

  push ds
  mov ah,3dh
  mov al,code
  lds dx,nom
  int 21h
  jnc OK@5
    xor ax,ax
  OK@5:
  pop ds

  pop bp
  ret

ouvre_fichier ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 	 ;
; Procedure dplc_fichier ; [9]
;                 	 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC dplc_fichier
dplc_fichier PROC NEAR

  ; Variables d'entree :
  fichier  EQU word ptr[bp+4]
  position EQU byte ptr[bp+6]
  dplcmt   EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp

  mov ah,42h
  mov al,position
  mov bx,fichier
  mov cx,word ptr[dplcmt+2]
  mov dx,word ptr[dplcmt]
  int 21h

  pop bp
  ret

dplc_fichier ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 	  ;
; Procedure ferme_fichier ; [6]
;                 	  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC ferme_fichier
ferme_fichier PROC NEAR

  ; Variable d'entree :
  fichier EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov ah,3eh
  mov bx,fichier
  int 21h

  pop bp
  ret

ferme_fichier ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;               	    ;
; Procedure lit_fichier_DOS ; [7]
;               	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC lit_fichier_DOS
lit_fichier_DOS PROC NEAR

  ; Variables d'entree :
  fichier EQU word ptr[bp+4]
  nb      EQU word ptr[bp+6]
  buffer  EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp

  push ds
  mov ah,3fh
  mov bx,fichier
  mov cx,nb
  lds dx,buffer
  int 21h
  pop ds

  pop bp
  ret

lit_fichier_DOS ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 	      ;
; Procedure ecrit_fichier_DOS ; [8]
;                 	      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC ecrit_fichier_DOS
ecrit_fichier_DOS PROC NEAR

  ; Variables d'entree :
  fichier EQU word ptr[bp+4]
  nb	  EQU word ptr[bp+6]
  buffer  EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp

  push ds
  mov ah,40h
  mov bx,fichier
  mov cx,nb
  lds dx,buffer
  int 21h
  pop ds

  pop bp
  ret

ecrit_fichier_DOS ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;               	    ;
; Procedure lit_fichier_XMS ; [56]
;               	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC lit_fichier_XMS
lit_fichier_XMS PROC NEAR

  ; Variables d'entree :
  fichier EQU word ptr[bp+4]
  nb      EQU dword ptr[bp+6]
  buffer  EQU dword ptr[bp+10]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si
  push ds
  cld

  ; Pointeur sur le buffer XMS :
  xor ax,ax
  mov gs,ax
  mov edi,buffer

  ; Memoire conventionnelle disponible ? :
  mov ah,48h
  mov bx,0ffffh
  int 21h
  or bx,bx
  jz FINI@56
  cmp bh,0fh
  jbe SUITE1@56
  mov bx,0fffh
  SUITE1@56:
  movzx ecx,bx
  shl cx,4

  ; Allocation de memoire conventionnelle :
  mov ah,48h
  int 21h
  mov ds,ax
  xor dx,dx

  ; Boucle principale :
  BOUCLE@56:
    cmp ecx,nb
    jbe SUITE2@56
    mov cx,word ptr[nb]
    SUITE2@56:

    ; Lecture du fichier :
    mov ah,3fh
    mov bx,fichier
    int 21h

    ; Copie en memoire XMS :
    xor si,si
    mov bx,cx
    shr bx,2
    COPIE_XMS_a@56:
      lodsd
      mov gs:[edi],eax
      add edi,4
      dec bx
      jnz COPIE_XMS_a@56
    sub nb,ecx
    jnz BOUCLE@56

  ; Copie les derniers octets :
  and cx,3
  jz FINI@56
  COPIE_XMS_b@56:
    lodsb
    mov gs:[edi],al
    inc edi
    dec cx
    jnz COPIE_XMS_b@56

  FINI@56:
  pop ds
  pop si
  pop di
  pop bp
  ret

lit_fichier_XMS ENDP

;****************************************************************************;
;*                                                                          *;
;* CLAVIER							            *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Fonction lit_clavier ; [10]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC lit_clavier
lit_clavier PROC NEAR

  ; Programme :

  mov ax,3509h
  int 21h
  mov ax,bx
  mov dx,es

  ret

lit_clavier ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                    	   ;
; Procedure change_clavier ; [11]
;                    	   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC change_clavier
change_clavier PROC NEAR

  ; Variable d'entree :
  vect EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  push ds
  mov ax,2509h
  lds dx,vect
  int 21h
  pop ds

  pop bp
  ret

change_clavier ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                    	 ;
; Procedure init_touches ; [12]
;                   	 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC init_touches
init_touches PROC NEAR

  ; Programme :
  push di
  cld

  mov ax,ds
  mov es,ax
  mov di,offset TOUCHES
  xor eax,eax
  mov cx,128/4
  rep stosd
  mov nb_touches,al

  pop di
  ret

init_touches ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                    	    ;
; Procedure touche_detourne ; [13]
;                    	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC touche_detourne
touche_detourne PROC NEAR

  ; Programme :
  push ax
  push bx
  push ds

  mov ax,seg TOUCHES
  mov ds,ax
  in al,60h
  mov bl,al
  shr al,7
  xor al,1
  and bl,01111111b
  xor bh,bh
  add bx,offset TOUCHES
  cmp [bx],al
  je SUITE@13
    mov [bx],al
    add al,al
    dec al
    add nb_touches,al
  SUITE@13:
  in al,61h
  or al,82h
  out 61h,al
  and al,7fh
  out 61h,al
  mov al,20h
  out 20h,al

  pop ds
  pop bx
  pop ax
  iret

touche_detourne ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                    	   ;
; Procedure relache_touche ; [67]
;                   	   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC relache_touche
relache_touche PROC NEAR

  ; Variable d'entree :
  touche EQU byte ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  cli
  movzx bx,touche
  cmp [bx+offset TOUCHES],bh
  je OK@67
    mov [bx+offset TOUCHES],bh
    dec nb_touches
  OK@67:
  sti

  pop bp
  ret

relache_touche ENDP

;****************************************************************************;
;*                                                                          *;
;* GRAPHISMES							            *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure lit_palette ; [14]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC lit_palette
lit_palette PROC NEAR

  ; Variable d'entree :
  palette EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov es,word ptr[PALETTES+2]
  mov ax,1017h
  xor bx,bx
  mov cx,256
  mov dx,palette
  int 10h

  pop bp
  ret

lit_palette ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          ;
; Procedure change_palette ; [15]
;                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC change_palette
change_palette PROC NEAR

  ; Variable d'entree :
  palette EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov es,word ptr[PALETTES+2]
  mov ax,1012h
  xor bx,bx
  mov cx,256
  mov dx,palette
  int 10h

  pop bp
  ret

change_palette ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          ;
; Procedure palette_jaunie ; [64]
;                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC palette_jaunie
palette_jaunie PROC NEAR

  ; Variables d'entree :
  pal_source EQU word ptr[bp+4]
  pal_dest   EQU word ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si
  push ds
  cld

  mov ds,word ptr[PALETTES+2]
  mov di,pal_dest
  mov si,pal_source
  xor ah,ah
  xor dl,dl
  BOUCLE@64:
    lodsb
    imul bx,ax,(30*256)/100
    lodsb
    imul cx,ax,(59*256)/100
    add bx,cx
    lodsb
    imul cx,ax,(11*256)/100
    add bx,cx
    mov bl,bh
    mov ds:[di],bx
    mov ds:[di+2],ah
    add di,3
    inc dl
    jnz BOUCLE@64

  pop ds
  pop si
  pop di
  pop bp
  ret

palette_jaunie ENDP

;;;;;;;;;;;;;;;;;;
;                ;
; Procedure fade ; [16]
;                ;
;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC fade
fade PROC NEAR

  ; Variables d'entree :
  pal_mod EQU word ptr[bp+4]
  pal_but EQU word ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si

  ; Plus d'interruption :
  cli

  ; Pointeurs vers les palettes :
  mov es,word ptr[PALETTES+2]
  mov di,pal_mod
  mov si,pal_but

  ; Boucle principale :
  BOUCLE_FADE@16:

    ; Retour balayage :
    mov dx,3dah
    BOUCLE1@16:
      in al,dx
      test al,8
      jnz BOUCLE1@16
    BOUCLE2@16:
      in al,dx
      test al,8
      jz BOUCLE2@16

    ; Change la palette :
    mov ax,1012h
    xor bx,bx
    mov cx,256
    mov dx,di
    int 10h

    ; Modifie la palette :
    xor al,al
    mov bx,256*3
    BOUCLE_PALETTE@16:
      dec bx
      jl FINI_PALETTE@16
      mov ah,es:[bx+di]
      cmp ah,es:[bx+si]
      je BOUCLE_PALETTE@16
      mov al,1
      ja GRAND@16
      inc ah
      mov es:[bx+di],ah
      jmp BOUCLE_PALETTE@16
      GRAND@16:
      dec ah
      mov es:[bx+di],ah
      jmp BOUCLE_PALETTE@16
    FINI_PALETTE@16:

    ; On continue ? :
    or al,al
    jnz BOUCLE_FADE@16

  ; Interruptions autorisees :
  sti

  pop si
  pop di
  pop bp
  ret

fade ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   	     ;
; Procedure cre_palette_unie ; [17]
;                   	     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC cre_palette_unie
cre_palette_unie PROC NEAR

  ; Variables d'entree :
  palette EQU word ptr[bp+4]
  R 	  EQU byte ptr[bp+6]
  V       EQU byte ptr[bp+8]
  B	  EQU byte ptr[bp+10]

  ; Programme :
  push bp
  mov bp,sp
  push di
  cld

  mov es,word ptr[PALETTES+2]
  mov al,R
  mov ah,V
  mov bl,B
  mov cx,256
  mov di,palette
  BOUCLE@17:
    stosw
    mov es:[di],bl
    inc di
    dec cx
    jnz BOUCLE@17

  pop di
  pop bp
  ret

cre_palette_unie ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          ;
; Procedure change_bordure ; [18]
;                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC change_bordure
change_bordure PROC NEAR

  ; Variable d'entree :
  bordure EQU byte ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov ax,1001h
  mov bh,bordure
  int 10h

  pop bp
  ret

change_bordure ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        ;
; Procedure efface_image ; [19]
;                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC efface_image
efface_image PROC NEAR

  ; Variable d'entree :
  coul EQU byte ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp
  push di
  cld

  mov bl,coul
  mov bh,bl
  mov ax,bx
  shl eax,16
  mov ax,bx
  mov es,word ptr[IMAGE+2]
  xor di,di
  mov cx,xm*ym/4
  rep stosd

  pop di
  pop bp
  ret

efface_image ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure aff_image ; [20]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC aff_image
aff_image PROC NEAR

  ; Programme :
  push di
  push si
  cld

  ; Plus d'interruption :
  cli

  ; Retour balayage :
  mov dx,3dah
  BOUCLE1@20:
    in al,dx
    test al,8
    jnz BOUCLE1@20
  BOUCLE2@20:
    in al,dx
    test al,8
    jz BOUCLE2@20

  ; Copie l'image :
  mov ax,word ptr[IMAGE+2]
  push ds
  mov ds,ax
  mov ax,0a000h
  mov es,ax
  xor si,si
  xor di,di
  mov cx,xm*ym/4
  rep movsd
  pop ds

  ; Interruptions autorisees :
  sti

  pop si
  pop di
  ret

aff_image ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			    ;
; Procedure retour_balayage ; [59]
;			    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC retour_balayage
retour_balayage PROC NEAR

  ; Programme :

  mov dx,3dah
  BOUCLE1@59:
    in al,dx
    test al,8
    jnz BOUCLE1@59
  BOUCLE2@59:
    in al,dx
    test al,8
    jz BOUCLE2@59

  ret

retour_balayage ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        ;
; Procedure aff_image_ZR ; [63]
;                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC aff_image_ZR
aff_image_ZR PROC NEAR

  ; Variables d'entree :
  zoom	   EQU dword ptr[bp+4]
  rotation EQU byte ptr[bp+8]
  coul	   EQU byte ptr[bp+10]

  ; Variables locales :
  alphaC EQU dword ptr[bp-4]
  betaC  EQU dword ptr[bp-8]
  ligne  EQU byte ptr[bp-9]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,9
  push di
  push si
  cld

  ; Preparation :
  mov es,word ptr[SIN_FX+2]
  movzx bx,rotation
  mov di,bx
  shl di,2
  mov edi,es:[di]
  add bl,64
  shl bx,2
  mov esi,zoom

  mov eax,es:[bx]
  imul esi
  shrd eax,edx,16+coefy_
  mov cs:dword ptr[alphaA@63+3],eax
  mov cs:dword ptr[betaB@63+4],eax
  imul ebx,eax,-xo
  imul ecx,eax,-yo

  mov eax,esi
  imul eax,-coefx
  sar eax,2*coefy_
  imul edi
  shrd eax,edx,16
  mov cs:dword ptr[alphaB@63+4],eax
  imul eax,-yo
  add eax,ebx
  add eax,xo*256
  mov alphaC,eax

  mov eax,esi
  mov ebx,coefx
  cdq
  idiv ebx
  imul edi
  shrd eax,edx,16
  mov cs:dword ptr[betaA@63+3],eax
  imul eax,-xo
  add eax,ecx
  add eax,yo*256
  mov betaC,eax

  mov ax,0a000h
  mov es,ax
  mov fs,word ptr[IMAGE+2]
  xor di,di

  ; Plus d'interruption :
  cli

  ; Retour balayage :
  mov dx,3dah
  BOUCLE1@63:
    in al,dx
    test al,8
    jnz BOUCLE1@63
  BOUCLE2@63:
    in al,dx
    test al,8
    jz BOUCLE2@63

  ; Affichage :
  mov ligne,ym
  BOUCLE_ye@63:
    mov edx,alphaC
    mov ecx,betaC
    mov bx,xm
    BOUCLE_xe@63:
      mov esi,edx
      sar esi,8
      cmp si,xm
      jb OK_x@63
	mov al,coul
	jmp AFFICHAGE@63
      OK_x@63:
      mov eax,ecx
      sar eax,8
      cmp ax,ym
      jb OK_y@63
	mov al,coul
	jmp AFFICHAGE@63
      OK_y@63:
      shl ax,6
      add si,ax
      shl ax,2
      add si,ax
      mov al,fs:[si]
      AFFICHAGE@63:
      stosb
      alphaA@63:add edx,1234
      betaA@63:add ecx,1234
      dec bx
      jnz BOUCLE_xe@63
    alphaB@63:add alphaC,1234
    betaB@63:add betaC,1234
    dec ligne
    jnz BOUCLE_ye@63

  ; Interruptions autorisees :
  sti

  pop si
  pop di
  leave
  ret

aff_image_ZR ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure etire_ecran ; [21]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC etire_ecran
etire_ecran PROC NEAR

  ; Variable d'entree :
  etire EQU byte ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov dx,3d4h
  mov al,9
  out dx,al
  inc dx
  in al,dx
  and al,11100000b
  or al,etire
  out dx,al

  pop bp
  ret

etire_ecran ENDP

;;;;;;;;;;;;;;;;;;;;;
;                   ;
; Fonction lit_mode ; [22]
;		    ;
;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC lit_mode
lit_mode PROC NEAR

  ; Programme :

  mov ax,40h
  mov es,ax
  mov al,es:[49h]

  ret

lit_mode ENDP

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Procedure met_mode ; [23]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC met_mode
met_mode PROC NEAR

  ; Variable d'entree :
  mode EQU byte ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  xor ah,ah
  mov al,mode
  int 10h

  pop bp
  ret

met_mode ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Fonction detect_VGA ; [24]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC detect_VGA
detect_VGA PROC NEAR

  ; Programme :

  mov ax,1a00h
  int 10h
  mov ah,bl
  cmp ax,081ah
  setz al

  ret

detect_VGA ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure aff_texte ; [25]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC aff_texte
aff_texte PROC NEAR

  ; Variable d'entree :
  texte EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  push ds
  mov ah,9
  lds dx,texte
  int 21h
  pop ds

  pop bp
  ret

aff_texte ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure aff_nombre ; [57]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC aff_nombre
aff_nombre PROC NEAR

  ; Variable d'entree :
  nombre EQU dword ptr[bp+4]

  ; Variable locale :
  buffer EQU byte ptr[bp-12]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,12
  push ds
  mov ax,ss
  mov ds,ax

  mov bx,bp
  dec bx
  mov byte ptr[bx],'$'

  mov eax,nombre
  or eax,eax
  jge SUITE1@57
  neg eax
  SUITE1@57:

  mov ecx,10
  BOUCLE@57:
    xor edx,edx
    div ecx
    add dl,'0'
    dec bx
    mov [bx],dl
    or eax,eax
    jnz BOUCLE@57

  mov eax,nombre
  or eax,eax
  jge SUITE2@57
  dec bx
  mov byte ptr[bx],'-'
  SUITE2@57:

  mov ah,9
  mov dx,bx
  int 21h

  pop ds
  leave
  ret

aff_nombre ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        ;
; Procedure pose_curseur ; [58]
;                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC pose_curseur
pose_curseur PROC NEAR

  ; Variables d'entrees :
  x EQU byte ptr[bp+4]
  y EQU byte ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp

  mov ah,2
  mov bh,0
  mov dl,x
  mov dh,y
  int 10h

  pop bp
  ret

pose_curseur ENDP

;****************************************************************************;
;*                                                                          *;
;* MATH								      	    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;
;                 	;
; Procedure init_hasard ; [26]
;                 	;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC init_hasard
init_hasard PROC NEAR

  ; Programme :

  push ax
  push cx
  push dx

  mov ah,2ch
  int 21h
  mov aleatoire,dl

  pop dx
  pop cx
  pop ax
  ret

init_hasard ENDP

;;;;;;;;;;;;;;;;;;;
;                 ;
; Fonction hasard ; [27]
;                 ;
;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC hasard
hasard PROC NEAR

  ; Programme :

  mov al,aleatoire
  xor al,5
  add al,al
  adc al,125
  mov aleatoire,al

  ret

hasard ENDP

;;;;;;;;;;;;;;;;;;;
;                 ;
; Fonction abs_fx ; [28]
;                 ;
;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC abs_fx
abs_fx PROC NEAR

  ; Variable d'entree :
  x EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov eax,x
  and eax,eax
  jge SUITE@28
    neg eax
  SUITE@28:
  shld edx,eax,16

  pop bp
  ret

abs_fx ENDP

;;;;;;;;;;;;;;;
;             ;
; Fonction fx ; [29]
;             ;
;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC fx
fx PROC NEAR

  ; Variable d'entree :
  x EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov dx,word ptr[x]
  xor ax,ax

  pop bp
  ret

fx ENDP

;;;;;;;;;;;;;;;;;;;
;                 ;
; Fonction entier ; [30]
;                 ;
;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC entier
entier PROC NEAR

  ; Variable d'entree :
  x EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov ax,word ptr[x+2]

  pop bp
  ret

entier ENDP

;;;;;;;;;;;;;;;;;;;;
;                  ;
; Fonction sqrt_fx ; [31]
;                  ;
;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC sqrt_fx
sqrt_fx PROC NEAR

  ; Variable d'entree :
  x EQU dword ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp

  mov ecx,x
  mov eax,1
  ENCORE@31:
    mov ebx,eax
    mov eax,ecx
    xor edx,edx
    div ebx
    add eax,ebx
    shr eax,1
    sub ebx,eax
    cmp ebx,1
    ja ENCORE@31
  shl eax,8
  shld edx,eax,16

  pop bp
  ret

sqrt_fx ENDP

;;;;;;;;;;;;;;;;;;;
;                 ;
; Fonction mul_fx ; [32]
;                 ;
;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC mul_fx
mul_fx PROC NEAR

  ; Variables d'entree :
  a EQU dword ptr[bp+4]
  b EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp

  mov eax,a
  imul b
  sar eax,16

  pop bp
  ret

mul_fx ENDP

;;;;;;;;;;;;;;;;;;;
;                 ;
; Fonction div_fx ; [33]
;                 ;
;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC div_fx
div_fx PROC NEAR

  ; Variables d'entree :
  a EQU dword ptr[bp+4]
  b EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp
  push di

  movsx edx,word ptr[a+2]
  mov ax,word ptr[a]
  mov ebx,b
  mov edi,ebx
  and edi,edi
  jge di_POS@33
    neg edi
  di_POS@33:
  mov ecx,edx
  add ecx,ecx
  jge cx_POS@33
    neg ecx
    or eax,eax
    jz cx_POS@33
      dec ecx
  cx_POS@33:
  cmp ecx,edi
  jge ERREUR@33
    shl eax,16
    idiv ebx
    shld edx,eax,16
  ERREUR@33:

  pop di
  pop bp
  ret

div_fx ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure init_SIN_FX ; [34]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC init_SIN_FX
init_SIN_FX PROC NEAR

  ; Variables locales :
  angle EQU word ptr[bp-2]
  x 	EQU dword ptr[bp-6]
  fact 	EQU dword ptr[bp-22]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,22
  push di
  push si

  ; SIN_FX[x]=(x^1/1!)-(x^3/3!)+(x^5/5!)-(x^7/7!)+(x^9/9!)

  mov es,word ptr[SIN_FX+2]

  mov bx,8
  mov ecx,9
  lea di,fact+12
  BOUCLE_INIT@34:
    imul cx,bx
    mov eax,04000000h
    cdq
    idiv ecx
    mov ss:[di],eax
    sub di,4
    dec bx
    mov cx,bx
    dec bx
    jnz BOUCLE_INIT@34

  mov x,63*1647099
  mov angle,64*4
  BOUCLE_ANGLE@34:
    mov eax,x
    imul eax
    shrd eax,edx,26
    neg eax
    mov ebx,eax
    mov eax,x
    mov ecx,eax
    lea di,fact
    mov si,4
    BOUCLE_SIN@34:
      imul ebx
      shrd eax,edx,26
      imul dword ptr ss:[di]
      shrd eax,edx,26
      add ecx,eax
      add di,4
      dec si
      jnz BOUCLE_SIN@34
    sar ecx,10
    mov bx,angle
    sub bx,4
    mov angle,bx
    mov es:[bx],ecx
    neg ecx
    mov es:[bx+128*4],ecx
    neg bx
    and bx,255*4
    mov es:[bx],ecx
    neg ecx
    mov es:[bx-128*4],ecx
    sub x,1647099
    jnl BOUCLE_ANGLE@34

  mov ecx,00010000h
  mov es:[64*4],ecx
  neg ecx
  mov es:[192*4],ecx

  pop si
  pop di
  leave
  ret

init_SIN_FX ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        ;
; Procedure init_SQRT_FX ; [35]
;                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC init_SQRT_FX
init_SQRT_FX PROC NEAR

  ; Programme :

  xor ax,ax
  mov gs,ax

  mov ecx,NB_SQRT_FX-1
  BOUCLE@35:
    mov eax,1
    ENCORE@35:
      mov ebx,eax
      mov eax,ecx
      xor edx,edx
      div ebx
      add eax,ebx
      shr eax,1
      sub ebx,eax
      cmp ebx,1
      ja ENCORE@35
    shl eax,8
    SQRT_FX@35:mov gs:[ecx*4+1234],eax
    dec ecx
    jnl BOUCLE@35

  ret

init_SQRT_FX ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure init_INV_FX ; [36]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC init_INV_FX
init_INV_FX PROC NEAR

  ; Programme :

  xor ax,ax
  mov gs,ax

  mov ecx,3
  BOUCLE@36:
    mov edx,1
    xor eax,eax
    idiv ecx
    INV_FX@36:mov gs:[ecx*4+1234],eax
    inc ecx
    cmp ecx,NB_INV_FX
    jl BOUCLE@36

  ret

init_INV_FX ENDP

;;;;;;;;;;;;;;;;;;;;;
;                   ;
; Procedure mul_mat ; [38]
;                   ;
;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC mul_mat
mul_mat PROC NEAR

  ; Variables d'entree :
  mat_AB EQU dword ptr[bp+4]
  mat_A  EQU dword ptr[bp+8]
  mat_B  EQU dword ptr[bp+12]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si

  les di,mat_AB
  lfs si,mat_A
  lgs bx,mat_B

  mov eax,fs:[si]
  imul dword ptr gs:[bx+0]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+4]
  imul dword ptr gs:[bx+12]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+8]
  imul dword ptr gs:[bx+24]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di],ecx

  mov eax,fs:[si]
  imul dword ptr gs:[bx+4]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+4]
  imul dword ptr gs:[bx+16]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+8]
  imul dword ptr gs:[bx+28]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+4],ecx

  mov eax,fs:[si]
  imul dword ptr gs:[bx+8]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+4]
  imul dword ptr gs:[bx+20]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+8]
  imul dword ptr gs:[bx+32]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+8],ecx

  mov eax,fs:[si+12]
  imul dword ptr gs:[bx+0]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+16]
  imul dword ptr gs:[bx+12]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+20]
  imul dword ptr gs:[bx+24]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+12],ecx

  mov eax,fs:[si+12]
  imul dword ptr gs:[bx+4]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+16]
  imul dword ptr gs:[bx+16]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+20]
  imul dword ptr gs:[bx+28]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+16],ecx

  mov eax,fs:[si+12]
  imul dword ptr gs:[bx+8]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+16]
  imul dword ptr gs:[bx+20]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+20]
  imul dword ptr gs:[bx+32]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+20],ecx

  mov eax,fs:[si+24]
  imul dword ptr gs:[bx+0]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+28]
  imul dword ptr gs:[bx+12]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+32]
  imul dword ptr gs:[bx+24]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+24],ecx

  mov eax,fs:[si+24]
  imul dword ptr gs:[bx+4]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+28]
  imul dword ptr gs:[bx+16]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+32]
  imul dword ptr gs:[bx+28]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+28],ecx

  mov eax,fs:[si+24]
  imul dword ptr gs:[bx+8]
  shrd eax,edx,16
  mov ecx,eax
  mov eax,fs:[si+28]
  imul dword ptr gs:[bx+20]
  shrd eax,edx,16
  add ecx,eax
  mov eax,fs:[si+32]
  imul dword ptr gs:[bx+32]
  shrd eax,edx,16
  add ecx,eax
  mov es:[di+32],ecx

  pop si
  pop di
  pop bp
  ret

mul_mat ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure tri_rapide ; [46]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
tri_rapide PROC NEAR

  ; Variables d'entree :
  bas  EQU word ptr[bp+4]
  haut EQU word ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp

  movzx edi,bas
  movzx esi,haut

  mov ebx,edi
  add bx,si
  shr bx,1
  mov ecx,es:[ebx*4+ebx]

  dec di
  inc si

  BOUCLE_TRI@46:

    BOUCLE_GAUCHE@46:
    inc di
    cmp es:[edi*4+edi],ecx
    jl BOUCLE_GAUCHE@46

    BOUCLE_DROITE@46:
    dec si
    cmp es:[esi*4+esi],ecx
    jg BOUCLE_DROITE@46

    cmp di,si
    jge FIN_BOUCLE_TRI@46
    mov eax,es:[edi*4+edi]
    mov ebx,es:[esi*4+esi]
    mov es:[edi*4+edi],ebx
    mov es:[esi*4+esi],eax
    mov al,es:[edi*4+edi+4]
    mov bl,es:[esi*4+esi+4]
    mov es:[edi*4+edi+4],bl
    mov es:[esi*4+esi+4],al
    jmp BOUCLE_TRI@46
    FIN_BOUCLE_TRI@46:

  jg SUITE@46
  inc di
  dec si
  SUITE@46:

  cmp si,bas
  jle PAS_BAS@46
  push si
  push bas
  call tri_rapide
  add sp,4
  PAS_BAS@46:

  cmp di,haut
  jge PAS_HAUT@46
  push haut
  push di
  call tri_rapide
  add sp,4
  PAS_HAUT@46:

  pop bp
  ret

tri_rapide ENDP

;;;;;;;;;;;;;;;;;
;               ;
; Procedure tri ; [47]
;               ;
;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC tri
tri PROC NEAR

  ; Variables d'entree :
  a_trier EQU dword ptr[bp+4]
  l   	  EQU word ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si

  mov es,word ptr[a_trier+2]
  mov di,l
  cmp di,12
  ja TRI_RAPIDE@47

    mov ax,di
    shl ax,2
    add di,ax
    BOUCLE_di@47:
      sub di,5
      jz FINI@47
      mov si,di
      BOUCLE_si@47:
	sub si,5
	jl BOUCLE_di@47
	mov eax,es:[di]
	cmp eax,es:[si]
	jge BOUCLE_si@47
	mov ebx,es:[si]
	mov es:[di],ebx
	mov es:[si],eax
	mov al,es:[di+4]
	mov bl,es:[si+4]
	mov es:[di+4],bl
	mov es:[si+4],al
	jmp BOUCLE_si@47

  TRI_RAPIDE@47:
  dec di
  push di
  push 0
  call tri_rapide
  add sp,4

  FINI@47:
  pop si
  pop di
  pop bp
  ret

tri ENDP

;****************************************************************************;
;*                                                                          *;
;* OBJET 								    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   	     ;
; Procedure cre_OBJ_TEXTURES ; [66]
;                   	     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC cre_OBJ_TEXTURES
cre_OBJ_TEXTURES PROC NEAR

  ; Programme :

  mov es,word ptr[SIN_FX+2]
  xor ebx,ebx
  mov gs,bx

  BOUCLE@66:
    mov al,bl
    shl al,2
    movzx edx,al
    mov ecx,es:[edx*4]

    mov al,bh
    shl al,2
    movzx edx,al
    mov eax,es:[edx*4]

    imul ecx
    shrd eax,edx,16+8
    imul ax,31
    and ah,31
    OBJ_TEXTURES@66:mov gs:[ebx+1234],ah

    inc bx
    jnz BOUCLE@66 ; OBJ_TEXTURES_L*OBJ_TEXTURES_H=65536=0 !

  ret

cre_OBJ_TEXTURES ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        ;
; Procedure place_soleil ; [39]
;                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC place_soleil
place_soleil PROC NEAR

  ; Variables d'entree :
  Rx EQU byte ptr[bp+4]
  Ry EQU byte ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp
  push di

  mov es,word ptr[SIN_FX+2]
  movzx bx,Rx
  mov di,bx
  shl di,2
  mov ecx,es:[di]
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov sol_y,eax
  movzx bx,Ry
  mov di,bx
  shl di,2
  mov eax,es:[di]
  imul ecx
  shrd eax,edx,16
  mov sol_x,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  imul ecx
  shrd eax,edx,16
  mov sol_z,eax

  pop di
  pop bp
  ret

place_soleil ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure place_objet ; [37]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC place_objet
place_objet PROC NEAR

  ; Variables d'entree :
  objet EQU dword ptr[bp+4]
  x 	EQU dword ptr[bp+8]
  y 	EQU dword ptr[bp+12]
  z	EQU dword ptr[bp+16]
  Rx	EQU byte ptr[bp+20]
  Ry	EQU byte ptr[bp+22]
  Rz	EQU byte ptr[bp+24]

  ; Variables locales :
  SRx 	 EQU dword ptr[bp-4]
  CRx 	 EQU dword ptr[bp-8]

  SRy 	 EQU dword ptr[bp-12]
  CRy	 EQU dword ptr[bp-16]

  SRz	 EQU dword ptr[bp-20]
  CRz	 EQU dword ptr[bp-24]

  SRxSRy EQU dword ptr[bp-28]
  CRxSRy EQU dword ptr[bp-32]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,32
  push di
  push si

  mov es,word ptr[SIN_FX+2]

  movzx bx,Rx
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov SRx,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov CRx,eax

  movzx bx,Ry
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov SRy,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov CRy,eax

  movzx bx,Rz
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov SRz,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov CRz,eax

  mov ebx,SRy
  mov eax,SRx
  imul ebx
  shrd eax,edx,16
  mov SRxSRy,eax
  mov eax,CRx
  imul ebx
  shrd eax,edx,16
  mov CRxSRy,eax

  les di,objet
  mov eax,x
  mov es:[di+_x],eax
  mov eax,y
  mov es:[di+_y],eax
  mov eax,z
  mov es:[di+_z],eax

  mov es:[di+_mat+24],ebx
  mov ebx,CRy
  mov eax,SRz
  imul ebx
  shrd eax,edx,16
  neg eax
  mov es:[di+_mat+12],eax
  mov eax,CRz
  imul ebx
  shrd eax,edx,16
  mov es:[di+_mat+0],eax
  mov eax,SRx
  imul ebx
  shrd eax,edx,16
  neg eax
  mov es:[di+_mat+28],eax
  mov eax,CRx
  imul ebx
  shrd eax,edx,16
  mov es:[di+_mat+32],eax

  mov ebx,SRz
  mov ecx,CRz

  mov eax,CRx
  imul ebx
  shrd eax,edx,16
  mov esi,eax
  mov eax,SRxSRy
  imul ecx
  shrd eax,edx,16
  add esi,eax
  mov es:[di+_mat+4],esi

  mov eax,SRx
  imul ebx
  shrd eax,edx,16
  mov esi,eax
  mov eax,CRxSRy
  imul ecx
  shrd eax,edx,16
  sub esi,eax
  mov es:[di+_mat+8],esi

  mov eax,CRx
  imul ecx
  shrd eax,edx,16
  mov esi,eax
  mov eax,SRxSRy
  imul ebx
  shrd eax,edx,16
  sub esi,eax
  mov es:[di+_mat+16],esi

  mov eax,SRx
  imul ecx
  shrd eax,edx,16
  mov esi,eax
  mov eax,CRxSRy
  imul ebx
  shrd eax,edx,16
  add esi,eax
  mov es:[di+_mat+20],esi

  pop si
  pop di
  leave
  ret

place_objet ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           ;
; Procedure place_objet_XZY ; [45]
;                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC place_objet_XZY
place_objet_XZY PROC NEAR

  ; Variables d'entree :
  objet EQU dword ptr[bp+4]
  x 	EQU dword ptr[bp+8]
  y 	EQU dword ptr[bp+12]
  z	EQU dword ptr[bp+16]
  Rx	EQU byte ptr[bp+20]
  Ry	EQU byte ptr[bp+22]
  Rz	EQU byte ptr[bp+24]

  ; Variables locales :
  SRx 	 EQU dword ptr[bp-4]
  CRx 	 EQU dword ptr[bp-8]

  SRy 	 EQU dword ptr[bp-12]
  CRy	 EQU dword ptr[bp-16]

  SRz	 EQU dword ptr[bp-20]
  CRz	 EQU dword ptr[bp-24]

  SRxSRz EQU dword ptr[bp-28]
  CRxSRz EQU dword ptr[bp-32]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,32
  push di
  push si

  mov es,word ptr[SIN_FX+2]

  movzx bx,Rx
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov SRx,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov CRx,eax

  movzx bx,Ry
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov SRy,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov CRy,eax

  movzx bx,Rz
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov SRz,eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov CRz,eax

  mov ebx,SRz
  mov eax,SRx
  imul ebx
  shrd eax,edx,16
  mov SRxSRz,eax
  mov eax,CRx
  imul ebx
  shrd eax,edx,16
  mov CRxSRz,eax

  les di,objet
  mov eax,x
  mov es:[di+_x],eax
  mov eax,y
  mov es:[di+_y],eax
  mov eax,z
  mov es:[di+_z],eax

  neg ebx
  mov es:[di+_mat+12],ebx
  mov ebx,CRz
  mov eax,SRy
  imul ebx
  shrd eax,edx,16
  mov es:[di+_mat+24],eax
  mov eax,CRy
  imul ebx
  shrd eax,edx,16
  mov es:[di+_mat+0],eax
  mov eax,CRx
  imul ebx
  shrd eax,edx,16
  mov es:[di+_mat+16],eax
  mov eax,SRx
  imul ebx
  shrd eax,edx,16
  mov es:[di+_mat+20],eax

  mov ebx,SRy
  mov ecx,CRy

  mov eax,SRx
  imul ebx
  shrd eax,edx,16
  mov esi,eax
  mov eax,CRxSRz
  imul ecx
  shrd eax,edx,16
  add eax,esi
  mov es:[di+_mat+4],eax

  mov eax,CRx
  imul ebx
  shrd eax,edx,16
  mov esi,eax
  mov eax,SRxSRz
  imul ecx
  shrd eax,edx,16
  sub eax,esi
  mov es:[di+_mat+8],eax

  mov eax,SRx
  imul ecx
  shrd eax,edx,16
  mov esi,eax
  mov eax,CRxSRz
  imul ebx
  shrd eax,edx,16
  sub eax,esi
  mov es:[di+_mat+28],eax

  mov eax,CRx
  imul ecx
  shrd eax,edx,16
  mov esi,eax
  mov eax,SRxSRz
  imul ebx
  shrd eax,edx,16
  add eax,esi
  mov es:[di+_mat+32],eax

  pop si
  pop di
  leave
  ret

place_objet_XZY ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                         ;
; Procedure init_Z_BUFFER ; [40]
;                         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC init_Z_BUFFER
init_Z_BUFFER PROC NEAR

  ; Programme :

  xor eax,eax
  mov gs,ax

  dec eax
  mov ebx,xm*ym
  BOUCLE@40:
    dec bx
    Z_BUFFER@40:mov gs:[ebx*4+1234],eax
    jnz BOUCLE@40

  ret

init_Z_BUFFER ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure init_BOULE ; [41]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC init_BOULE
init_BOULE PROC NEAR

  ; Programme :

  xor ax,ax
  mov gs,ax

  mov ebx,coefx
  mov ecx,xm
  BOUCLE1@41:
    mov eax,ecx
    sub eax,xo+1
    shl eax,16
    cdq
    idiv ebx
    dec cx
    BOULE_TAB1@41:mov gs:[ecx*4+1234],eax
    jnz BOUCLE1@41

  mov ecx,ym
  BOUCLE2@41:
    mov eax,yo+1
    sub eax,ecx
    shl eax,16-coefy_
    dec cx
    BOULE_TAB2@41:mov gs:[ecx*4+1234],eax
    jnz BOUCLE2@41

  ret

init_BOULE ENDP

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure aff_boule ; [42]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC aff_boule
aff_boule PROC NEAR

  ; Variables d'entree :
  boule	    EQU dword ptr[bp+4]
  objet_mat EQU dword ptr[bp+8]

  ; Variables locales :
  K        EQU dword ptr[bp-4]

  xe       EQU word ptr[bp-6]
  xe_      EQU word ptr[bp-8]

  ye       EQU word ptr[bp-10]
  ye_      EQU word ptr[bp-12]

  stop_xe  EQU byte ptr[bp-13]
  stop_ye  EQU byte ptr[bp-14]

  ecran    EQU word ptr[bp-16]

  Vx       EQU dword ptr[bp-20]
  Vy       EQU dword ptr[bp-24]
  Vz       EQU dword ptr[bp-28]

  sauve_sp EQU word ptr[bp-30]

  mat      EQU dword ptr[bp-66]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,66

  push di
  les di,boule
  mov eax,es:[di+_deforme_x]
  mov ebx,es:[di+_deforme_y]
  cmp eax,ebx
  jb SUITE1@42
  mov eax,ebx
  SUITE1@42:
  mov ebx,es:[di+_deforme_z]
  cmp eax,ebx
  jb SUITE2@42
  mov eax,ebx
  SUITE2@42:
  imul es:dword ptr[di+_pt+_z3D_C]
  shrd eax,edx,16
  cmp eax,es:[di+_r]
  jg SUITE3@42
  pop di
  leave
  ret
  SUITE3@42:
  mov K,eax

  xor ax,ax
  mov gs,ax
  mov ebx,es:[di+_r]
  INV_FX_a@42:mov ecx,gs:[ebx*4+1234]

  push si
  lfs si,objet_mat
  mov eax,fs:[si+_Mxx]
  imul sol_x
  shrd eax,edx,16
  mov ebx,eax
  mov eax,fs:[si+_Mxy]
  imul sol_y
  shrd eax,edx,16
  add ebx,eax
  mov eax,fs:[si+_Mxz]
  imul sol_z
  shrd eax,edx,16
  add eax,ebx
  imul ecx
  shrd eax,edx,16
  mov cs:dword ptr[Sx@42+2],eax
  mov eax,fs:[si+_Myx]
  imul sol_x
  shrd eax,edx,16
  mov ebx,eax
  mov eax,fs:[si+_Myy]
  imul sol_y
  shrd eax,edx,16
  add ebx,eax
  mov eax,fs:[si+_Myz]
  imul sol_z
  shrd eax,edx,16
  add eax,ebx
  imul ecx
  shrd eax,edx,16
  mov cs:dword ptr[Sy@42+2],eax
  mov eax,fs:[si+_Mzx]
  imul sol_x
  shrd eax,edx,16
  mov ebx,eax
  mov eax,fs:[si+_Mzy]
  imul sol_y
  shrd eax,edx,16
  add ebx,eax
  mov eax,fs:[si+_Mzz]
  imul sol_z
  shrd eax,edx,16
  add eax,ebx
  imul ecx
  shrd eax,edx,16
  mov cs:dword ptr[Sz@42+2],eax

  mov ebx,es:[di+_deforme_x]
  mov eax,fs:[si+_Mxx]
  imul ebx
  shrd eax,edx,16
  mov mat+_Mxx,eax
  mov eax,fs:[si+_Mxy]
  imul ebx
  shrd eax,edx,16
  mov mat+_Mxy,eax
  mov eax,fs:[si+_Mxz]
  imul ebx
  shrd eax,edx,16
  mov mat+_Mxz,eax
  mov ebx,es:[di+_deforme_y]
  mov eax,fs:[si+_Myx]
  imul ebx
  shrd eax,edx,16
  mov mat+_Myx,eax
  mov eax,fs:[si+_Myy]
  imul ebx
  shrd eax,edx,16
  mov mat+_Myy,eax
  mov eax,fs:[si+_Myz]
  imul ebx
  shrd eax,edx,16
  mov mat+_Myz,eax
  mov ebx,es:[di+_deforme_z]
  mov eax,fs:[si+_Mzx]
  imul ebx
  shrd eax,edx,16
  mov mat+_Mzx,eax
  mov eax,fs:[si+_Mzy]
  imul ebx
  shrd eax,edx,16
  mov mat+_Mzy,eax
  mov eax,fs:[si+_Mzz]
  imul ebx
  shrd eax,edx,16
  mov mat+_Mzz,eax

  mov eax,mat+_Mxx
  imul es:dword ptr[di+_pt+_x3D_C]
  shrd eax,edx,16
  mov ebx,eax
  mov eax,mat+_Mxy
  imul es:dword ptr[di+_pt+_y3D_C]
  shrd eax,edx,16
  add ebx,eax
  mov eax,mat+_Mxz
  imul es:dword ptr[di+_pt+_z3D_C]
  shrd eax,edx,16
  add eax,ebx
  mov cs:dword ptr[x_a@42+2],eax
  mov cs:dword ptr[x_b@42+2],eax
  mov cs:dword ptr[x_c@42+2],eax
  imul eax
  shrd eax,edx,16
  mov ecx,eax
  mov eax,mat+_Myx
  imul es:dword ptr[di+_pt+_x3D_C]
  shrd eax,edx,16
  mov ebx,eax
  mov eax,mat+_Myy
  imul es:dword ptr[di+_pt+_y3D_C]
  shrd eax,edx,16
  add ebx,eax
  mov eax,mat+_Myz
  imul es:dword ptr[di+_pt+_z3D_C]
  shrd eax,edx,16
  add eax,ebx
  mov cs:dword ptr[y_a@42+2],eax
  mov cs:dword ptr[y_b@42+2],eax
  mov cs:dword ptr[y_c@42+2],eax
  imul eax
  shrd eax,edx,16
  add ecx,eax
  mov eax,mat+_Mzx
  imul es:dword ptr[di+_pt+_x3D_C]
  shrd eax,edx,16
  mov ebx,eax
  mov eax,mat+_Mzy
  imul es:dword ptr[di+_pt+_y3D_C]
  shrd eax,edx,16
  add ebx,eax
  mov eax,mat+_Mzz
  imul es:dword ptr[di+_pt+_z3D_C]
  shrd eax,edx,16
  add eax,ebx
  mov cs:dword ptr[z_a@42+2],eax
  mov cs:dword ptr[z_b@42+2],eax
  mov cs:dword ptr[z_c@42+2],eax
  imul eax
  shrd eax,edx,16
  add ecx,eax
  mov eax,es:[di+_r]
  imul eax
  shrd eax,edx,16
  sub ecx,eax
  mov cs:dword ptr[K_a@42+2],ecx

  mov eax,es:[di+_texture_B]
  OBJ_TEXTURES_a@42:add eax,1234
  mov cs:dword ptr[OBJ_TEXTURES_b@42+4],eax

  mov bx,es:[di+_pt+_xe]
  or bx,bx
  jge xe_OK1@42
  xor bx,bx
  jmp xe_OK2@42
  xe_OK1@42:
  cmp bx,xm-2
  jle xe_OK2@42
  mov bx,xm-2
  xe_OK2@42:
  mov xe,bx

  mov bx,es:[di+_pt+_ye]
  or bx,bx
  jge ye_OK1@42
  xor bx,bx
  jmp ye_OK2@42
  ye_OK1@42:
  cmp bx,ym-2
  jle ye_OK2@42
  mov bx,ym-2
  ye_OK2@42:
  mov ye,bx

  mov eax,es:[di+_r]
  shl eax,coefy_
  cdq
  idiv K
  add ax,10 ; +10 ?
  mov di,bx
  sub bx,ax
  jge ye_min_OK@42
  xor bx,bx
  ye_min_OK@42:
  add di,ax
  cmp di,ym
  jle ye_max_OK@42
  mov di,ym
  ye_max_OK@42:

  mov es,word ptr[IMAGE+2]

  cli
  mov sauve_sp,sp

  movzx ebx,bx
  BOUCLE_PREPARATION@42:
    BOULE_TAB2@42:mov esi,gs:[ebx*4+1234]

    mov eax,mat+_Mxy
    imul esi
    shrd eax,edx,16
    BOULE_TAB3_a@42:mov gs:[ebx*4+1234],eax
    x_a@42:mov edx,1234
    imul edx
    shrd eax,edx,16
    mov ecx,eax

    mov eax,mat+_Myy
    imul esi
    shrd eax,edx,16
    BOULE_TAB4_a@42:mov gs:[ebx*4+1234],eax
    y_a@42:mov edx,1234
    imul edx
    shrd eax,edx,16
    add ecx,eax

    mov eax,mat+_Mzy
    imul esi
    shrd eax,edx,16
    BOULE_TAB5_a@42:mov gs:[ebx*4+1234],eax
    z_a@42:mov edx,1234
    imul edx
    shrd eax,edx,16
    add ecx,eax

    BOULE_TAB6_a@42:mov gs:[ebx*4+1234],ecx

    inc bx
    cmp bx,di
    jb BOUCLE_PREPARATION@42

  mov stop_xe,2
  mov cs:byte ptr[INC_xe@42],4bh ; dec bx
  movzx ebx,xe

  xor edi,edi
  xor esi,esi
  ENCORE_xe@42:
    mov si,ye

    BOUCLE_xe@42:
    mov xe_,bx
    mov ye_,si

    mov ax,si
    shl ax,6
    mov di,ax
    shl ax,2
    add di,ax
    add di,bx
    mov ecran,di

    BOULE_TAB1@42:mov esp,gs:[ebx*4+1234]

    mov eax,mat+_Mxx
    imul esp
    shrd eax,edx,16
    add eax,mat+_Mxz
    mov cs:dword ptr[Vxo@42+2],eax
    x_b@42:mov edx,1234
    imul edx
    shrd eax,edx,16
    mov ecx,eax

    mov eax,mat+_Myx
    imul esp
    shrd eax,edx,16
    add eax,mat+_Myz
    mov cs:dword ptr[Vyo@42+2],eax
    y_b@42:mov edx,1234
    imul edx
    shrd eax,edx,16
    add ecx,eax

    mov eax,mat+_Mzx
    imul esp
    shrd eax,edx,16
    add eax,mat+_Mzz
    mov cs:dword ptr[Vzo@42+2],eax
    z_b@42:mov edx,1234
    imul edx
    shrd eax,edx,16
    add ecx,eax

    mov cs:dword ptr[K_b@42+2],ecx

    mov stop_ye,2
    mov cs:byte ptr[INC_ye@42],4eh ; dec si
    mov cs:word ptr[INC_ecran_ye@42+2],-xm
    inc si

    BOUCLE_ye@42:
      INC_ye@42:inc si

      BOULE_TAB3_b@42:mov eax,gs:[esi*4+1234]
      Vxo@42:add eax,1234
      mov Vx,eax
      imul eax
      shrd eax,edx,16
      mov ecx,eax

      BOULE_TAB4_b@42:mov eax,gs:[esi*4+1234]
      Vyo@42:add eax,1234
      mov Vy,eax
      imul eax
      shrd eax,edx,16
      add ecx,eax

      BOULE_TAB5_b@42:mov eax,gs:[esi*4+1234]
      Vzo@42:add eax,1234
      mov Vz,eax
      imul eax
      shrd eax,edx,16
      add ecx,eax

      BOULE_TAB6_b@42:mov eax,gs:[esi*4+1234]
      K_b@42:add eax,1234
      mov esp,eax
      imul eax
      shrd eax,edx,16
      mov ebx,eax

      K_a@42:mov eax,1234
      imul ecx
      shrd eax,edx,16
      sub ebx,eax
      jl FIN_ye@42

      SQRT_FX@42:sub esp,gs:[ebx*4+1234]
      INV_FX_b@42:mov eax,gs:[ecx*4+1234]
      imul esp
      shrd eax,edx,16

      Z_BUFFER_a@42:cmp eax,gs:[edi*4+1234]
      jae SUITE_ye@42
      Z_BUFFER_b@42:mov gs:[edi*4+1234],eax

      mov esp,eax
      imul Vx
      shrd eax,edx,16
      x_c@42:sub eax,1234
      mov edx,eax
      sar edx,BOULE_DEF_
      movzx ebx,dh
      Sx@42:mov edx,1234
      imul edx
      shrd eax,edx,16
      mov ecx,eax

      mov eax,Vy
      imul esp
      shrd eax,edx,16
      y_c@42:sub eax,1234
      mov edx,eax
      sar edx,BOULE_DEF_
      mov bh,dh
      Sy@42:mov edx,1234
      imul edx
      shrd eax,edx,16
      add ecx,eax

      mov eax,Vz
      imul esp
      shrd eax,edx,16
      z_c@42:sub eax,1234
;     jnl SUITE4@42
;     add bx,128
;     SUITE4@42:
      Sz@42:mov edx,1234
      imul edx
      shrd eax,edx,16
      add eax,ecx

      OBJ_TEXTURES_b@42:mov cl,gs:[ebx+1234]
      cmp eax,65536
      jb NUANCE_NORMALE@42
	jl FIN_NUANCE@42
	mov ah,11100000b
      NUANCE_NORMALE@42:
      and ah,11100000b
      or cl,ah
      FIN_NUANCE@42:
      mov es:[di],cl

      SUITE_ye@42:
      INC_ecran_ye@42:add di,xm
      cmp di,xm*ym
      jb BOUCLE_ye@42

      FIN_ye@42:
      dec stop_ye
      jz CONTINUE_xe@42
      mov cs:byte ptr[INC_ye@42],46h ; inc si
      mov cs:word ptr[INC_ecran_ye@42+2],xm
      mov bx,si
      mov si,ye_
      mov ye_,bx
      mov di,ecran
      add di,xm
      jmp BOUCLE_ye@42

    CONTINUE_xe@42:
    dec si
    cmp si,ye_
    je FIN_xe@42
    add si,ye_
    shr si,1

    movzx ebx,xe_
    INC_xe@42:inc bx
    cmp bx,xm
    jb BOUCLE_xe@42

    FIN_xe@42:
    dec stop_xe
    jz FINI@42
    mov cs:byte ptr[INC_xe@42],43h ; inc bx
    movzx ebx,xe
    inc bx
    jmp ENCORE_xe@42

  FINI@42:
  mov sp,sauve_sp
  sti
  pop si
  pop di
  leave
  ret

aff_boule ENDP

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Procedure aff_poly ; [43]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC aff_poly
aff_poly PROC NEAR

  ; Variables d'entree :
  poly EQU dword ptr[bp+4]
  pt   EQU dword ptr[bp+8]

  ; Variables locales :
  x1 	    EQU dword ptr[bp-4]
  y1 	    EQU dword ptr[bp-8]
  z1	    EQU dword ptr[bp-12]

  Vx	    EQU dword ptr[bp-16]
  Vy	    EQU dword ptr[bp-20]
  Vz	    EQU dword ptr[bp-24]

  Wx	    EQU dword ptr[bp-28]
  Wy	    EQU dword ptr[bp-32]
  Wz	    EQU dword ptr[bp-36]

  Nx	    EQU dword ptr[bp-40]
  Ny	    EQU dword ptr[bp-44]
  Nz	    EQU dword ptr[bp-48]

  L3	    EQU dword ptr[bp-52]
  M3	    EQU dword ptr[bp-56]
  N3	    EQU dword ptr[bp-60]

  gauche    EQU byte ptr[bp-61]
  droite    EQU byte ptr[bp-62]

  xe_gauche EQU dword ptr[bp-66]
  xe_droite EQU dword ptr[bp-70]

  ye	    EQU word ptr[bp-72]
  ye_gauche EQU word ptr[bp-74]
  ye_droite EQU word ptr[bp-76]

  ecran     EQU word ptr[bp-78]

  nb_pts    EQU byte ptr[bp-79]
  num_pt    EQU word ptr[bp-81]

  sauve_sp  EQU word ptr[bp-83]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,83
  push di
  push si

  ; Calcule V et W :
  lgs bx,poly
  mov ecx,gs:[bx+_norm_V]
  les di,gs:[bx+_num_pt]
  lfs si,pt

  movzx bx,es:byte ptr[di+1]
  imul bx,28
  mov eax,fs:[si+bx+_x3D_C]
  mov x1,eax
  mov eax,fs:[si+bx+_y3D_C]
  mov y1,eax
  mov eax,fs:[si+bx+_z3D_C]
  mov z1,eax

  movzx bx,es:byte ptr[di+2]
  imul bx,28
  mov eax,fs:[si+bx+_x3D_C]
  sub eax,x1
  imul ecx
  shrd eax,edx,16
  mov Vx,eax
  mov eax,fs:[si+bx+_y3D_C]
  sub eax,y1
  imul ecx
  shrd eax,edx,16
  mov Vy,eax
  mov eax,fs:[si+bx+_z3D_C]
  sub eax,z1
  imul ecx
  shrd eax,edx,16
  mov Vz,eax

  mov bx,word ptr[poly]
  mov ecx,gs:[bx+_norm_W]

  movzx bx,es:byte ptr[di]
  imul bx,28
  mov eax,fs:[si+bx+_x3D_C]
  sub eax,x1
  imul ecx
  shrd eax,edx,16
  mov Wx,eax
  mov eax,fs:[si+bx+_y3D_C]
  sub eax,y1
  imul ecx
  shrd eax,edx,16
  mov Wy,eax
  mov eax,fs:[si+bx+_z3D_C]
  sub eax,z1
  imul ecx
  shrd eax,edx,16
  mov Wz,eax

  ; Calcule N et D :
  mov eax,Vz
  imul Wy
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Vy
  imul Wz
  shrd eax,edx,16
  sub eax,ebx
  mov Nx,eax
  imul x1
  shrd eax,edx,16
  mov esi,eax
  mov eax,Vx
  imul Wz
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Vz
  imul Wx
  shrd eax,edx,16
  sub eax,ebx
  mov Ny,eax
  imul y1
  shrd eax,edx,16
  add esi,eax
  mov eax,Vy
  imul Wx
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Vx
  imul Wy
  shrd eax,edx,16
  sub eax,ebx
  mov Nz,eax
  imul z1
  shrd eax,edx,16
  add esi,eax
  cmp esi,-D_MIN ; |D| trop petit -> erreurs !
  jge FINI@43

  ; Suite des initialisations :
  mov bx,word ptr[poly]
  mov eax,gs:[bx+_texture_P]
  OBJ_TEXTURES_a@43:add eax,1234
  mov cs:dword ptr[OBJ_TEXTURES_b@43+4],eax
  mov al,gs:byte ptr[bx+_nb_pts]
  mov nb_pts,al
  mov num_pt,di

  ; Modifie W (texture non deformee) :
  mov eax,Ny
  imul Vz
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Nz
  imul Vy
  shrd eax,edx,16
  sub ebx,eax
  mov Wx,ebx
  mov eax,Nz
  imul Vx
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Nx
  imul Vz
  shrd eax,edx,16
  sub ebx,eax
  mov Wy,ebx
  mov eax,Nx
  imul Vy
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Ny
  imul Vx
  shrd eax,edx,16
  sub ebx,eax
  mov Wz,ebx

  ; Calcule les "N" :
  imul edi,esi,coefx

  mov eax,Nx
  cdq
  shld edx,eax,16+PRECISION_
  shl eax,16+PRECISION_
  idiv edi
  mov cs:dword ptr[N1_a@43+3],eax
  mov cs:dword ptr[N1_b@43+3],eax
  imul ebx,eax,xo
  mov eax,Ny
  cdq
  shl eax,16-coefy_+PRECISION_
  idiv esi
  mov cs:dword ptr[N2_a@43+3],eax
  mov cs:dword ptr[N2_b@43+4],eax
  imul eax,yo
  sub ebx,eax
  mov eax,Nz
  cdq
  shld edx,eax,16+PRECISION_
  shl eax,16+PRECISION_
  idiv esi
  sub eax,ebx
  mov N3,eax

  ; Calcule les "L" et "M" :
  xor ax,ax
  mov gs,ax

  mov eax,Nx
  or eax,eax
  jge Nx_POSITIF_a@43
  neg eax
  Nx_POSITIF_a@43:
  mov ebx,Ny
  or ebx,ebx
  jge Ny_POSITIF_a@43
  neg ebx
  Ny_POSITIF_a@43:
  mov ecx,Nz
  or ecx,ecx
  jge Nz_POSITIF_a@43
  neg ecx
  Nz_POSITIF_a@43:

  cmp eax,ecx
  jb PAS_Nx@43
  cmp eax,ebx
  ja CALCUL_Nx@43
  jmp CALCUL_Ny@43
  PAS_Nx@43:
  cmp ebx,ecx
  ja CALCUL_Ny@43

  ; ...calculs avec Nz :
  cmp ecx,Nz
  INV_FX_a@43:mov edi,gs:[ecx*4+1234]
  je Nz_POSITIF_b@43
  neg edi
  Nz_POSITIF_b@43:
  mov eax,edi
  cdq
  mov esi,coefx
  idiv esi
  mov esi,eax

  mov eax,Wy
  imul esi
  shrd eax,edx,16-PRECISION_
  neg eax
  mov cs:dword ptr[L1_a@43+3],eax
  mov cs:dword ptr[L1_b@43+3],eax
  imul ecx,eax,xo
  mov eax,Wx
  imul edi
  shrd eax,edx,16+coefy_-PRECISION_
  neg eax
  mov cs:dword ptr[L2_a@43+3],eax
  mov cs:dword ptr[L2_b@43+4],eax
  imul eax,yo
  add eax,ecx
  mov L3,eax
  mov eax,y1
  imul Wx
  shrd eax,edx,16
  mov ecx,eax
  mov eax,x1
  imul Wy
  shrd eax,edx,16
  sub eax,ecx
  imul edi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[L4@43+2],eax

  mov eax,Vy
  imul esi
  shrd eax,edx,16-PRECISION_
  neg eax
  mov cs:dword ptr[M1_a@43+3],eax
  mov cs:dword ptr[M1_b@43+3],eax
  imul ecx,eax,xo
  mov eax,Vx
  imul edi
  shrd eax,edx,16+coefy_-PRECISION_
  neg eax
  mov cs:dword ptr[M2_a@43+3],eax
  mov cs:dword ptr[M2_b@43+4],eax
  imul eax,yo
  add eax,ecx
  mov M3,eax
  mov eax,y1
  imul Vx
  shrd eax,edx,16
  mov ecx,eax
  mov eax,x1
  imul Vy
  shrd eax,edx,16
  sub eax,ecx
  imul edi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[M4@43+2],eax

  jmp CALCUL_NUANCE@43

  ; ...calculs avec Nx :
  CALCUL_Nx@43:
  cmp eax,Nx
  INV_FX_b@43:mov edi,gs:[eax*4+1234]
  je Nx_POSITIF_b@43
  neg edi
  Nx_POSITIF_b@43:

  xor eax,eax
  mov cs:dword ptr[L1_a@43+3],eax
  mov cs:dword ptr[L1_b@43+3],eax
  mov eax,Wz
  imul edi
  shrd eax,edx,16+coefy_-PRECISION_
  mov cs:dword ptr[L2_a@43+3],eax
  mov cs:dword ptr[L2_b@43+4],eax
  imul ecx,eax,yo
  mov eax,Wy
  imul edi
  shrd eax,edx,16-PRECISION_
  sub ecx,eax
  mov L3,ecx
  mov eax,z1
  imul Wy
  shrd eax,edx,16
  mov ecx,eax
  mov eax,y1
  imul Wz
  shrd eax,edx,16
  sub eax,ecx
  imul edi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[L4@43+2],eax

  xor eax,eax
  mov cs:dword ptr[M1_a@43+3],eax
  mov cs:dword ptr[M1_b@43+3],eax
  mov eax,Vz
  imul edi
  shrd eax,edx,16+coefy_-PRECISION_
  mov cs:dword ptr[M2_a@43+3],eax
  mov cs:dword ptr[M2_b@43+4],eax
  imul ecx,eax,yo
  mov eax,Vy
  imul edi
  shrd eax,edx,16-PRECISION_
  sub ecx,eax
  mov M3,ecx
  mov eax,z1
  imul Vy
  shrd eax,edx,16
  mov ecx,eax
  mov eax,y1
  imul Vz
  shrd eax,edx,16
  sub eax,ecx
  imul edi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[M4@43+2],eax

  jmp CALCUL_NUANCE@43;

  ; ...calculs avec Ny :
  CALCUL_Ny@43:
  cmp ebx,Ny
  INV_FX_c@43:mov edi,gs:[ebx*4+1234]
  je Ny_POSITIF_b@43
  neg edi
  Ny_POSITIF_b@43:
  mov eax,edi
  cdq
  mov esi,coefx
  idiv esi
  mov esi,eax

  mov eax,Wz
  imul esi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[L1_a@43+3],eax
  mov cs:dword ptr[L1_b@43+3],eax
  imul ecx,eax,xo
  xor eax,eax
  mov cs:dword ptr[L2_a@43+3],eax
  mov cs:dword ptr[L2_b@43+4],eax
  mov eax,Wx
  imul edi
  shrd eax,edx,16-PRECISION_
  add ecx,eax
  mov L3,ecx
  mov eax,x1
  imul Wz
  shrd eax,edx,16
  mov ecx,eax
  mov eax,z1
  imul Wx
  shrd eax,edx,16
  sub eax,ecx
  imul edi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[L4@43+2],eax

  mov eax,Vz
  imul esi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[M1_a@43+3],eax
  mov cs:dword ptr[M1_b@43+3],eax
  imul ecx,eax,xo
  xor eax,eax
  mov cs:dword ptr[M2_a@43+3],eax
  mov cs:dword ptr[M2_b@43+4],eax
  mov eax,Vx
  imul edi
  shrd eax,edx,16-PRECISION_
  add ecx,eax
  mov M3,ecx
  mov eax,x1
  imul Vz
  shrd eax,edx,16
  mov ecx,eax
  mov eax,z1
  imul Vx
  shrd eax,edx,16
  sub eax,ecx
  imul edi
  shrd eax,edx,16-PRECISION_
  mov cs:dword ptr[M4@43+2],eax

  ; Calcule la nuance :
  CALCUL_NUANCE@43:
  mov eax,Nx
  imul sol_x
  shrd eax,edx,16
  mov ebx,eax
  mov eax,Ny
  imul sol_y
  shrd eax,edx,16
  add ebx,eax
  mov eax,Nz
  imul sol_z
  shrd eax,edx,16
  add eax,ebx
  cmp eax,65536
  jb NUANCE_NORMALE@43
    jge NUANCE_MAX@43
    mov cs:byte ptr[nuance@43+1],0
    jmp FIN_NUANCE@43
    NUANCE_MAX@43:
    mov ah,11100000b
  NUANCE_NORMALE@43:
  and ah,11100000b
  mov cs:byte ptr[nuance@43+1],ah
  FIN_NUANCE@43:

  ; On va utiliser ds, esp, et epb ! :
  push ds
  mov ds,word ptr[IMAGE+2]
  cli
  mov sauve_sp,sp
  mov cs:word ptr[sauve_bp@43+1],bp

  ; Suite des initialisations :
  mov di,num_pt
  mov si,word ptr[pt]

  mov sp,ym
  movzx dx,nb_pts
  BOUCLE_INIT@43:
    dec dl
    jl FIN_INIT@43
    movzx bx,dl
    mov bl,es:[di+bx]
    imul bx,28
    mov eax,fs:[si+bx+_z3D_C]
    cmp eax,VISIBLE_MIN
    jle FINI_ye@43
    mov ax,fs:[si+bx+_ye]
    cmp ax,sp
    jge BOUCLE_INIT@43
    mov sp,ax
    mov dh,dl
    mov cx,fs:[si+bx+_xe]
    jmp BOUCLE_INIT@43
  FIN_INIT@43:
  shl ecx,16
  mov xe_gauche,ecx
  mov xe_droite,ecx
  mov ye_droite,sp
  mov droite,dh

  movsx edi,sp
  L2_a@43:imul eax,edi,1234
  sub L3,eax
  M2_a@43:imul eax,edi,1234
  sub M3,eax
  N2_a@43:imul eax,edi,1234
  sub N3,eax

  shl di,6
  mov ax,di
  shl di,2
  add di,ax
  mov ecran,di

  ; Boucle principale :
  mov di,word ptr[pt]
  mov si,num_pt
  jmp START@43

  BOUCLE_ye@43:

    cmp sp,ye_gauche
    jne FIN_gauche@43

      mov dh,gauche
      mov di,word ptr[pt]
      mov si,num_pt

      BOUCLE_gauche@43:
      cmp dh,droite
      je FINI_ye@43

      START@43:
      dec dh
      jge OK_gauche@43
	mov dh,nb_pts
	dec dh
      OK_gauche@43:

      movzx bx,dh
      movzx bx,es:byte ptr[bx+si]
      imul bx,28

      mov ax,fs:[bx+di+_xe]
      shl eax,16
      movzx ecx,fs:word ptr[bx+di+_ye]
      mov ye_gauche,cx

      sub cx,sp
      jg SUITE_gauche@43
	mov xe_gauche,eax
	jmp BOUCLE_gauche@43
      SUITE_gauche@43:

      mov gauche,dh
      sub eax,xe_gauche
      cdq
      idiv ecx
      mov cs:dword ptr[d_xe_gauche@43+4],eax

    FIN_gauche@43:

    cmp sp,ym
    jge FINI_ye@43

    cmp sp,ye_droite
    jne FIN_droite@43

      mov dh,droite
      mov di,word ptr[pt]
      mov si,num_pt

      BOUCLE_droite@43:
      inc dh
      cmp dh,nb_pts
      jne OK_droite@43
	xor dh,dh
      OK_droite@43:

      movzx bx,dh
      movzx bx,es:byte ptr[bx+si]
      imul bx,28

      mov ax,fs:[bx+di+_xe]
      shl eax,16
      movzx ecx,fs:word ptr[bx+di+_ye]
      mov ye_droite,cx

      sub cx,sp
      jg SUITE_droite@43
	mov xe_droite,eax
	jmp BOUCLE_droite@43
      SUITE_droite@43:

      mov droite,dh
      sub eax,xe_droite
      or al,255 ; pour les problemes de precision... (255 ?)
      cdq
      idiv ecx
      mov cs:dword ptr[d_xe_droite@43+4],eax

    FIN_droite@43:

    or sp,sp
    jl CONTINUE@43

      mov edi,xe_gauche
      sar edi,16
      jge xe_gauche_OK@43
	xor edi,edi
      xe_gauche_OK@43:

      mov esi,xe_droite
      sar esi,16
      cmp si,xm
      jng xe_droite_OK@43
	mov si,xm
      xe_droite_OK@43:

      sub si,di
      jle CONTINUE@43

      mov ye,sp

      L1_a@43:imul ecx,edi,1234
      sub ecx,L3
      M1_a@43:imul esp,edi,1234
      sub esp,M3
      N1_a@43:imul eax,edi,1234
      add eax,N3

      add di,ecran

      mov ebp,eax
      BOUCLE_xe@43:
	shr eax,PRECISION_
	INV_FX_d@43:mov eax,gs:[eax*4+1234]

	Z_BUFFER_a@43:cmp eax,gs:[edi*4+1234]
	jae SUITE_xe@43
	Z_BUFFER_b@43:mov gs:[edi*4+1234],eax

	mov ebx,eax
	imul ecx
	shrd eax,edx,16
	L4@43:add eax,1234
	sar eax,POLY_DEF_+PRECISION_
	mov dl,ah
	mov eax,ebx
	movzx ebx,dl
	imul esp
	shrd eax,edx,16
	M4@43:add eax,1234
	sar eax,POLY_DEF_+PRECISION_
	mov bh,ah

	OBJ_TEXTURES_b@43:mov al,gs:[ebx+1234]
	nuance@43:or al,12
	mov ds:[di],al

	SUITE_xe@43:
	L1_b@43:add ecx,1234
	M1_b@43:add esp,1234
	N1_b@43:add ebp,1234
	mov eax,ebp
	inc di
	dec si
	jnz BOUCLE_xe@43

      sauve_bp@43:mov bp,1234
      mov sp,ye

    CONTINUE@43:

    d_xe_gauche@43:add xe_gauche,1234
    d_xe_droite@43:add xe_droite,1234

    L2_b@43:sub L3,1234
    M2_b@43:sub M3,1234
    N2_b@43:sub N3,1234

    inc sp
    add ecran,xm

    jmp BOUCLE_ye@43

  FINI_ye@43:
  mov sp,sauve_sp
  sti
  pop ds

  FINI@43:
  pop si
  pop di
  leave
  ret

aff_poly ENDP

;****************************************************************************;
;*                                                                          *;
;* SPRITE							    	    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           ;
; Procedure aff_sprite_fond ; [48]
;                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC aff_sprite_fond
aff_sprite_fond PROC NEAR

  ; Variables d'entree :
  x  EQU dword ptr[bp+4]
  y  EQU dword ptr[bp+8]
  z  EQU dword ptr[bp+12]
  Rz EQU byte ptr[bp+16]

  ; Variables locales :
  z_coefx EQU dword ptr[bp-4]
  alphaC  EQU dword ptr[bp-8]
  betaC   EQU dword ptr[bp-12]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,12
  push di
  push si
  cld

  mov eax,z
  mov ebx,coefx
  cdq
  idiv ebx
  mov z_coefx,eax

  mov es,word ptr[SIN_FX+2]
  movzx bx,Rz
  mov di,bx
  shl di,2
  mov edi,es:[di]
  add bl,64
  shl bx,2
  mov esi,es:[bx]

  mov eax,z_coefx
  imul esi
  shrd eax,edx,16
  mov cs:dword ptr[alphaA@48+3],eax
  imul ebx,eax,xo
  mov eax,z
  imul edi
  shrd eax,edx,16+coefy_
  neg eax
  mov cs:dword ptr[alphaB@48+4],eax
  imul eax,yo
  add ebx,eax
  mov eax,x
  imul esi
  shrd eax,edx,16
  add ebx,eax
  mov eax,y
  imul edi
  shrd eax,edx,16
  sub eax,ebx
  mov alphaC,eax

  mov eax,z_coefx
  imul edi
  shrd eax,edx,16
  mov cs:dword ptr[betaA@48+3],eax
  imul ebx,eax,xo
  mov eax,z
  imul esi
  shrd eax,edx,16+coefy_
  mov cs:dword ptr[betaB@48+4],eax
  imul eax,yo
  add ebx,eax
  mov eax,x
  imul edi
  shrd eax,edx,16
  sub ebx,eax
  mov eax,y
  imul esi
  shrd eax,edx,16
  sub eax,ebx
  mov betaC,eax

  xor eax,eax
  mov gs,ax
  mov es,word ptr[IMAGE+2]
  xor di,di

  mov si,ym
  BOUCLE_ye@48:
    mov edx,alphaC
    mov ecx,betaC
    mov bx,xm
    BOUCLE_xe@48:
      mov al,dh
      mov ah,ch
      SPR_TEXTURES@48:mov al,gs:[eax+1234]
      stosb
      alphaA@48:add edx,1234
      betaA@48:add ecx,1234
      dec bx
      jnz BOUCLE_xe@48
    alphaB@48:add alphaC,1234
    betaB@48:add betaC,1234
    dec si
    jnz BOUCLE_ye@48

  pop si
  pop di
  leave
  ret

aff_sprite_fond ENDP

;****************************************************************************;
;*                                                                          *;
;* INTERFERENCES							    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;
;                     ;
; Procedure aff_inter ; [49]
;                     ;
;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC aff_inter
aff_inter PROC NEAR

  ; Variables d'entree :
  xo1 EQU word ptr[bp+4]
  yo1 EQU word ptr[bp+6]
  xo2 EQU word ptr[bp+8]
  yo2 EQU word ptr[bp+10]
  d   EQU byte ptr[bp+12]

  ; Variables locales :
  xe  EQU word ptr[bp-2]
  ye  EQU word ptr[bp-4]

  x1  EQU word ptr[bp-6]
  y1  EQU word ptr[bp-8]
  rr1 EQU word ptr[bp-10]

  x2  EQU word ptr[bp-12]
  y2  EQU word ptr[bp-14]
  rr2 EQU word ptr[bp-16]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,16
  push di
  push si
  cld

  mov ax,xo1
  mov bx,ax
  imul ax
  mov cx,ax
  add bx,bx
  dec bx
  mov x1,bx
  mov ax,yo1
  mov bx,ax
  imul ax
  add ah,d
  add cx,ax
  mov rr1,cx
  add bx,bx
  dec bx
  mov y1,bx

  mov ax,xo2
  mov bx,ax
  imul ax
  mov cx,ax
  add bx,bx
  dec bx
  mov x2,bx
  mov ax,yo2
  mov bx,ax
  imul ax
  add ah,d
  add cx,ax
  mov rr2,cx
  add bx,bx
  dec bx
  mov y2,bx

  mov es,word ptr[IMAGE+2]
  xor di,di

  mov ye,ym
  BOUCLE_ye@49:
    mov bx,rr1
    mov cx,x1
    mov dx,rr2
    mov si,x2
    mov xe,xm
    BOUCLE_xe@49:
      mov al,bh
      xor al,dh
      shr al,3
      stosb
      sub bx,cx
      sub cx,2
      sub dx,si
      sub si,2
      dec xe
      jnz BOUCLE_xe@49
    mov ax,y1
    sub rr1,ax
    sub ax,2
    mov y1,ax
    mov ax,y2
    sub rr2,ax
    sub ax,2
    mov y2,ax
    dec ye
    jnz BOUCLE_ye@49

  pop si
  pop di
  leave
  ret

aff_inter ENDP

;****************************************************************************;
;*                                                                          *;
;* FEU									    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   	    ;
; Procedure cre_palette_feu ; [50]
;                   	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC cre_palette_feu
cre_palette_feu PROC NEAR

  ; Variable d'entree :
  palette EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp
  push di
  cld

  mov es,word ptr[PALETTES+2]
  mov di,palette

  xor ax,ax
  mov bh,32
  BOUCLE32@50:
    stosw
    mov bl,bh
    add bl,31
    shr bl,2
    mov es:[di],bl
    inc di
    dec bh
    jnz BOUCLE32@50
  mov bh,63
  BOUCLE96@50:
    stosw
    mov bl,bh
    shr bl,3
    mov es:[di],bl
    inc di
    inc al
    dec bh
    jnl BOUCLE96@50
  mov al,63
  BOUCLE160@50:
    stosw
    mov es:[di],bl
    inc di
    inc ah
    cmp ah,al
    jbe BOUCLE160@50
  mov ah,al
  BOUCLE224@50:
    stosw
    mov es:[di],bl
    inc di
    inc bl
    cmp bl,al
    jbe BOUCLE224@50
  mov bh,32
  BOUCLE256@50:
    stosw
    stosb
    dec bh
    jnz BOUCLE256@50

  pop di
  pop bp
  ret

cre_palette_feu ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   	       ;
; Procedure cre_palette_pastel ; [44]
;                   	       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC cre_palette_pastel
cre_palette_pastel PROC NEAR

  ; Variable d'entree :
  palette EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp
  push di

  call init_hasard

  mov es,word ptr[PALETTES+2]
  mov di,palette

  mov dl,3
  BOUCLE_pastel@44:
    call hasard
    and al,7
    mov cl,24
    add cl,al
    call hasard
    and al,7
    mov ch,63
    sub ch,al
    call hasard
    and al,1
    mov ah,al
    call hasard
    and al,31
    add al,28

    xor dh,dh
    BOUCLE_RVB@44:
      mov es:[di],al
      or ah,ah
      jz DEC_RVB@44

      inc al
      cmp al,ch
      setb ah
      jmp SUITE_RVB@44

      DEC_RVB@44:
      sub al,2
      cmp al,cl
      setbe ah

      SUITE_RVB@44:
      add di,3
      dec dh
      jnz BOUCLE_RVB@44

    sub di,256*3-1
    dec dl
    jnz BOUCLE_pastel@44

  pop di
  pop bp
  ret

cre_palette_pastel ENDP

;;;;;;;;;;;;;;;;;;;;;;
;                    ;
; Procedure init_feu ; [51]
;                    ;
;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC init_feu
init_feu PROC NEAR

  ; Programme :
  push di
  cld

  mov es,word ptr[BLOC_64K+2]
  xor eax,eax
  mov di,ax
  mov cx,xo*(yo+2)/4
  rep stosd

  pop di
  ret

init_feu ENDP

;;;;;;;;;;;;;;;;;;;;;
;                   ;
; Procedure aff_feu ; [52]
;                   ;
;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC aff_feu
aff_feu PROC NEAR

  ; Programme :
  push di
  push si
  cld

  ; Pointeur vers "FEU" :
  mov fs,word ptr[BLOC_64K+2]

  ; On met de la braise :
  call hasard
  or al,00100000b
  mov dl,al
  mov dh,dl
  xor ah,ah
  mov cx,4
  BOUCLE_BRAISE@52:
    call hasard
    cmp al,xo-1
    jb OK_BRAISE@52
      sub al,xo-1
    OK_BRAISE@52:
    mov di,xo*yo
    add di,ax
    mov fs:[di],dx
    mov fs:[di+xo],dx
    dec cx
    jnz BOUCLE_BRAISE@52

  ; Le feu monte :
  xor di,di
  xor dh,dh
  mov dl,fs:[di+xo-2]
  mov bx,dx
  mov dl,fs:[di+xo-1]
  add bx,dx
  mov dl,fs:[di+xo]
  add bx,dx
  mov dl,fs:[di+xo+1]
  add bx,dx
  mov dl,fs:[di+xo+xo-1]
  add bx,dx
  mov dl,fs:[di+xo+xo]
  add bx,dx
  mov cx,xo*yo
  BOUCLE_FEU@52:
    mov dl,fs:[di+xo+2]
    add bx,dx
    mov dl,fs:[di+xo+xo+1]
    add bx,dx
    mov ax,bx
    shr ax,3
    jz SUITE_FEU@52
      dec ax
    SUITE_FEU@52:
    mov fs:[di],al
    mov dl,fs:[di+xo-2]
    sub bx,dx
    mov dl,fs:[di+xo+xo-1]
    sub bx,dx
    inc di
    dec cx
    jnz BOUCLE_FEU@52

  ; Copie dans "image" :
  mov es,word ptr[IMAGE+2]
  xor si,si
  xor di,di
  mov cx,yo
  BOUCLE_COPIE_ye@52:
    mov dx,xo
    BOUCLE_COPIE_xe@52:
      mov al,fs:[si]
      mov ah,al
      mov es:[di+xm],ax
      stosw
      inc si
      dec dx
      jnz BOUCLE_COPIE_xe@52
    add di,xm
    dec cx
    jnz BOUCLE_COPIE_ye@52

  pop si
  pop di
  ret

aff_feu ENDP

;****************************************************************************;
;*                                                                          *;
;* VOXEL							    	    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;
;                   ;
; Procedure cre_vox ; [65]
;                   ;
;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC cre_vox
cre_vox PROC NEAR

  ; Programme :

  xor ebx,ebx
  mov es,word ptr[SIN_FX+2]
  mov gs,bx

  BOUCLE@65:
    mov al,bl
    xor al,bh
    and al,31
    VOX_TEXTURES@65:mov gs:[ebx+1234],al

    movzx eax,bl
    mov ecx,es:[eax*4]

    mov al,bh
    add al,al
    mov eax,es:[eax*4]
    imul ecx
    shrd eax,edx,16
    mov ecx,eax

    mov al,bl
    imul al
    shr ax,6
    movzx eax,al
    add al,bh
    mov eax,es:[eax*4]
    imul ecx
    shrd eax,edx,16
    imul eax,5

    sar eax,8
    HAUTEURS@65:mov gs:[ebx*2+1234],ax
    inc bx
    jnz BOUCLE@65 ; VOX_TEXTURES_L*VOX_TEXTURES_H=65536=0 !

  ret

cre_vox ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure ombrage_vox ; [62]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC ombrage_vox
ombrage_vox PROC NEAR

  ; Programme :
  push bp
  push di
  push si

  xor ebx,ebx
  mov gs,bx

  BOUCLE@62:

; Avec modulo :
    inc bl
    HAUTEURS_a@62:mov di,gs:[ebx*2+1234]
    sub bl,2
    HAUTEURS_b@62:sub di,gs:[ebx*2+1234]
    inc bl
    movsx edi,di
    shl edi,8+7-VOX_DEF_
    mov eax,edi
    imul eax
    shrd eax,edx,16
    mov ecx,eax

    add bx,VOX_TEXTURES_L
    HAUTEURS_c@62:mov si,gs:[ebx*2+1234]
    sub bx,2*VOX_TEXTURES_L
    HAUTEURS_d@62:sub si,gs:[ebx*2+1234]
    add bx,VOX_TEXTURES_L
    movsx esi,si
    shl esi,8+7-VOX_DEF_
    mov eax,esi
    imul eax
    shrd eax,edx,16
    add ecx,eax

; Normal :
;   HAUTEURS_a@62:mov di,gs:[ebx*2+1234]
;   HAUTEURS_b@62:sub di,gs:[ebx*2+1234]
;   movsx edi,di
;   shl edi,8+7-VOX_DEF_
;   mov eax,edi
;   imul eax
;   shrd eax,edx,16
;   mov ecx,eax
;
;   HAUTEURS_c@62:mov si,gs:[ebx*2+1234]
;   HAUTEURS_d@62:sub si,gs:[ebx*2+1234]
;   movsx esi,si
;   shl esi,8+7-VOX_DEF_
;   mov eax,esi
;   imul eax
;   shrd eax,edx,16
;   add ecx,eax

    add ecx,65536
    mov eax,1
    SQRT_FX@62:
      mov ebp,eax
      mov eax,ecx
      xor edx,edx
      div ebp
      add eax,ebp
      shr eax,1
      sub ebp,eax
      cmp ebp,1
      ja SQRT_FX@62
    shl eax,8
    mov ecx,eax

    mov eax,sol_x
    imul edi
    shrd eax,edx,16
    mov edi,eax

    mov eax,sol_z
    imul esi
    shrd eax,edx,16
    add eax,edi

    add eax,sol_y
    cdq
    shld edx,eax,16
    shl eax,16
    idiv ecx

    cmp eax,65536
    jb NUANCE_NORMALE@62
      jl FIN_NUANCE@62
      mov ah,11100000b
    NUANCE_NORMALE@62:
    and ah,11100000b
    VOX_TEXTURES@62:or gs:[ebx+1234],ah
    FIN_NUANCE@62:

    inc bx
    jnz BOUCLE@62 ; VOX_TEXTURES_L*VOX_TEXTURES_H=65536=0 !

  pop si
  pop di
  pop bp
  ret

ombrage_vox ENDP

;;;;;;;;;;;;;;;;;;;;;
;                   ;
; Procedure aff_vox ; [53]
;                   ;
;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC aff_vox
aff_vox PROC NEAR

  ; Variables d'entree :
  x  EQU dword ptr[bp+4]
  y  EQU dword ptr[bp+8]
  z  EQU dword ptr[bp+12]
  Ry EQU byte ptr[bp+16]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si

  mov es,word ptr[SIN_FX+2]
  movzx bx,Ry
  mov di,bx
  shl di,2
  mov eax,es:[di]
  mov cs:dword ptr[SIN@53+2],eax
  add bl,64
  shl bx,2
  mov eax,es:[bx]
  mov cs:dword ptr[COS@53+2],eax

  mov fs,word ptr[IMAGE+2]
  xor ax,ax
  mov gs,ax

  mov eax,x
  mov cs:dword ptr[x@53+3],eax
  mov eax,y
  mov cs:dword ptr[y@53+2],eax
  mov eax,z
  mov cs:dword ptr[z@53+3],eax
  cli
  mov cs:word ptr[sauve_sp@53+1],sp

  xor ebx,ebx
  mov edi,xm-1
  BOUCLE_xe@53:
    BOULE_TAB1@53:mov eax,gs:[edi*4+1234]
    SIN@53:mov esp,1234
    COS@53:mov ebp,1234

    mov ecx,eax
    imul ebp
    shrd eax,edx,16
    add eax,esp
    sar eax,VOX_PAS_
    mov cs:dword ptr[deltaX@53+3],eax
    imul esi,eax,PREMIER_VOX
    x@53:add esi,1234

    mov eax,ecx
    imul esp
    shrd eax,edx,16
    sub eax,ebp
    sar eax,VOX_PAS_
    mov cs:dword ptr[deltaZ@53+3],eax
    imul esp,eax,PREMIER_VOX
    z@53:add esp,1234

    add di,xm*(ym-1)
    mov bp,ym
    mov ecx,PREMIER_VOX*64 ; PREMIER_VOX<<(16-VOX_PAS_-coefy_)
    BOUCLE_k@53:
      mov eax,esi
      sar eax,VOX_DEF_
      mov bl,ah
      mov eax,esp
      sar eax,VOX_DEF_
      mov bh,ah
      HAUTEURS@53:movsx eax,gs:word ptr[ebx*2+1234]
      shl eax,8
      y@53:sub eax,1234
      INV_FX@53:imul gs:dword ptr[ecx*4+1234]
      sub dx,yo
      jle OK_ye@53
	xor dx,dx
      OK_ye@53:
      add bp,dx
      jle FIN_vox@53

	mov eax,ecx
	shl eax,coefy_
	VOX_TEXTURES@53:mov bl,gs:[ebx+1234]
	BOUCLE_vox@53:
	  mov fs:[di],bl
	  Z_BUFFER_a@53:mov gs:[edi*4+1234],eax
	  sub di,xm
	  dec bp
	  jnz BOUCLE_vox@53
	FIN_vox@53:
	sub bp,dx
	jz SUITE_xe@53

      SUITE_k@53:
      deltaX@53:add esi,1234
      deltaZ@53:add esp,1234
      add ecx,64 ; 1<<(16-VOX_PAS_-coefy_)
      cmp ecx,DERNIER_VOX*64 ; DERNIER_VOX<<(16-VOX_PAS_-coefy_)
      jbe BOUCLE_k@53

      mov eax,0ffffffffh
      mov bl,COUL_CIEL
      BOUCLE_fin@53:
	mov fs:[di],bl
	Z_BUFFER_b@53:mov gs:[edi*4+1234],eax
	sub di,xm
	dec bp
	jnz BOUCLE_fin@53

    SUITE_xe@53:
    add di,xm-1
    jnl BOUCLE_xe@53

  sauve_sp@53:mov sp,1234
  sti
  pop si
  pop di
  pop bp
  ret

aff_vox ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Fonction hauteur_vox ; [60]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC hauteur_vox
hauteur_vox PROC NEAR

  ; Variables d'entree :
  x EQU dword ptr[bp+4]
  z EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp

  xor ax,ax
  mov gs,ax

  mov eax,x
  sar eax,VOX_DEF_
  movzx ebx,ah
  mov eax,z
  sar eax,VOX_DEF_
  mov bh,ah
  HAUTEURS@60:mov ax,gs:[ebx*2+1234]
  movsx dx,ah
  shl ax,8

  pop bp
  ret

hauteur_vox ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           ;
; Fonction moy_hauteurs_vox ; [61]
;                      	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC moy_hauteurs_vox
moy_hauteurs_vox PROC NEAR

  ; Variables d'entree :
  x EQU dword ptr[bp+4]
  z EQU dword ptr[bp+8]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si

  xor eax,eax
  mov gs,ax

  xor ebx,ebx
  mov ecx,x
  sar ecx,VOX_DEF_
  sub ecx,2*64
  mov edx,z
  sar edx,VOX_DEF_
  sub edx,2*64
  mov di,5
  BOUCLE_x@61:
    mov bl,ch
    mov si,5
    BOUCLE_z@61:
      mov bh,dh
      HAUTEURS@61:movsx ebp,gs:word ptr[ebx*2+1234]
      shl ebp,8
      add eax,ebp
      add edx,64
      dec si
      jnz BOUCLE_z@61
    sub edx,5*64
    add ecx,64
    dec di
    jnz BOUCLE_x@61
  mov bx,25
  cdq
  idiv ebx
  shld edx,eax,16

  pop si
  pop di
  pop bp
  ret

moy_hauteurs_vox ENDP

;****************************************************************************;
;*                                                                          *;
;* NEURONES								    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                      	  ;
; Procedure init_neurones ; [69]
;                      	  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC init_neurones
init_neurones PROC NEAR

  ; Programme :

  mov ax,word ptr[BLOC_64K+2]
  mov cs:word ptr[BLOC_64K@75+4],ax
  mov ax,word ptr[IMAGE+2]
  mov cs:word ptr[IMAGE@75+4],ax

  ret

init_neurones ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                      	 ;
; Procedure aff_neurones ; [68]
;                     	 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC aff_neurones
aff_neurones PROC NEAR

  ; Programme :
  push di
  cld

  mov es,word ptr[BLOC_64K+2]
  mov fs,word ptr[IMAGE+2]
  mov word ptr[BLOC_64K+2],fs
  mov word ptr[IMAGE+2],es

  xor di,di
  xor dh,dh
  BOUCLE@68:
    movzx ax,fs:byte ptr[di]
    shl ax,2
    mov dl,fs:[di+1]
    add ax,dx
    mov dl,fs:[di-1]
    add ax,dx
    mov dl,fs:[di+xm]
    add ax,dx
    mov dl,fs:[di-xm]
    add ax,dx
    shr ax,3
    dec al
    stosb
    cmp di,xm*ym
    jnz BOUCLE@68

  pop di
  ret

aff_neurones ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;
;                      	 ;
; Procedure fin_neurones ; [75]
;                      	 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC fin_neurones
fin_neurones PROC NEAR

  ; Programme :

  BLOC_64K@75:mov word ptr[BLOC_64K+2],1234
  IMAGE@75:mov word ptr[IMAGE+2],1234

  ret

fin_neurones ENDP

;****************************************************************************;
;*                                                                          *;
;* TUNNEL								    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;
;                       ;
; Procedure init_tunnel ; [70]
;                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;
db 0dbh ; ANTI DEBUG !
PUBLIC init_tunnel
init_tunnel PROC NEAR

  ; Variables locales :
  var1 EQU word ptr[bp-2]
  var2 EQU word ptr[bp-4]
  var3 EQU word ptr[bp-6]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,6
  push di
  push si
  cld

  mov es,word ptr[BLOC_64K+2]
  xor di,di

  mov si,yo-1
  BOUCLE_dye@70:
    mov var1,si
    mov ax,si
    imul ax
    mov var2,ax
    mov cx,xo-1
    BOUCLE_dxe@70:

      mov var3,cx
      fild var1
      fmul coefx_coefy
      fild var3
      fpatan
      fmul deg
      fistp es:word ptr[di]
      inc di

      mov ax,cx
      imul ax
      mov var3,ax
      fild var3
      fmul coefx_2
      fild var2
;     fmul coefy_2
      fadd
      fsqrt
      fistp var3
      mov bx,var3
      or bx,bx
      jz FINI@70
      mov ax,256*RAYON
      xor dx,dx
      idiv bx
      stosb

      dec cx
      jnl BOUCLE_dxe@70
    dec si
    jmp BOUCLE_dye@70
  FINI@70:

  pop si
  pop di
  leave
  ret

  coefx_2     dd 0.695350  ; 65536/(coefx*coefx)
; coefy_2     dd 1 	   ; 65536/(coefy*coefy)
  coefx_coefy dd 1.199219  ; coefx/coefy
  deg	      dd 40.743665 ; 128/pi

init_tunnel ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure aff_tunnel ; [71]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 8eh ; ANTI DEBUG !
PUBLIC aff_tunnel
aff_tunnel PROC NEAR

  ; Variables d'entree :
  a EQU byte ptr[bp+4]
  z EQU byte ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si
  push ds
  cld

  xor eax,eax
  mov gs,ax
  mov es,word ptr[IMAGE+2]
  mov ds,word ptr[BLOC_64K+2]
  xor di,di
  xor si,si

  BOUCLE_ye@71:
    xor cx,cx
    BOUCLE_xe@71:
      lodsw
      add ah,z
      mov dl,al

      add al,a
      TUN_TEXTURES_a@71:mov dh,gs:[eax+1234]
      mov bx,di
      add bx,cx
      mov es:[bx],dh

      add al,128
      TUN_TEXTURES_b@71:mov dh,gs:[eax+1234]
      neg bx
      add bx,xm*ym-1
      mov es:[bx],dh

      sub al,dl
      sub al,dl
      TUN_TEXTURES_c@71:mov dh,gs:[eax+1234]
      mov bx,di
      sub bx,cx
      add bx,xm-1
      mov es:[bx],dh

      sub al,128
      TUN_TEXTURES_d@71:mov dh,gs:[eax+1234]
      neg bx
      add bx,xm*ym-1
      mov es:[bx],dh

      inc cx
      cmp cx,xo
      jnz BOUCLE_xe@71
    add di,xm
    cmp di,xm*yo
    jnz BOUCLE_ye@71

  pop ds
  pop si
  pop di
  pop bp
  ret

aff_tunnel ENDP

;****************************************************************************;
;*                                                                          *;
;* BUMP2D								    *;
;*                                                                          *;
;****************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			       ;
; Procedure cre_palette_bump2D ; [73]
;			       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0f3h ; ANTI DEBUG !
PUBLIC cre_palette_bump2D
cre_palette_bump2D PROC NEAR

  ; Variable d'entree :
  palette EQU word ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp
  push di
  cld

  mov es,word ptr[PALETTES+2]
  mov di,palette
  xor ax,ax
  BOUCLE@73:
    stosw
    stosb
    add ax,1*256+1
    cmp al,64
    jnz BOUCLE@73

  mov cx,((256-64)*3)/4
  mov eax,3f3f3f3fh
  rep stosd

  pop di
  pop bp
  ret

cre_palette_bump2D ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;	               ;
; Procedure cre_vagues ; [74]
;       	       ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 8ah ; ANTI DEBUG !
PUBLIC cre_vagues
cre_vagues PROC NEAR

  ; Variable d'entree :
  d EQU byte ptr[bp+4]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si
  cld

  mov es,word ptr[BLOC_64K+2]
  mov fs,word ptr[SIN_FX+2]
  xor di,di

  xor eax,eax
  mov bx,((xo*xo+yo*yo)*FREQ_VAGUES) and 65535
  add bh,d
  mov dx,(yo*2-1)*FREQ_VAGUES
  BOUCLE_ye@74:
    mov cx,bx
    mov si,(xo*2-1)*FREQ_VAGUES
    mov bp,xm
    BOUCLE_xe@74:
      movzx ax,ch
      mov ax,fs:[eax*4+1] ; ax=SIN_FX*256
      sub al,ah           ; al=SIN_FX*256-SIN_FX
      sar ah,1            ; pour avoir le bon signe apres le decalage...
      sar ax,1            ; al=SIN_FX*127.5
      stosb               ; [-128...+127]
      sub cx,si
      sub si,2*FREQ_VAGUES
      dec bp
      jnz BOUCLE_xe@74
    sub bx,dx
    sub dx,2*FREQ_VAGUES
    cmp di,xm*ym
    jnz BOUCLE_ye@74

  pop si
  pop di
  pop bp
  ret

cre_vagues ENDP

;;;;;;;;;;;;;;;;;;;;
;                  ;
; Fonction granite ; [77]
;                  ;
;;;;;;;;;;;;;;;;;;;;
db 0dch ; ANTI DEBUG !
PUBLIC granite
granite PROC NEAR

  ; Programme :

  mov es,word ptr[BLOC_64K+2]

  xor ax,ax
  mov ebx,xm*ym-1
  BOUCLE@77:
    mov cl,es:[bx]
    mov ch,ah
    and ch,31
    cmp cl,ch
    je SUITE@77
      mov al,1
      jl PETIT@77
	dec cl
	jmp AFFICHE@77
      PETIT@77:
      inc cl
      AFFICHE@77:
      mov es:[bx],cl
    SUITE@77:
    xor ah,5   ;
    add ah,ah  ; "hasard" inline
    adc ah,125 ;
    dec ebx
    jnl BOUCLE@77

  ret

granite ENDP

;;;;;;;;;;;;;;;;;;;;;
;                   ;
; Procedure gravure ; [76]
;                   ;
;;;;;;;;;;;;;;;;;;;;;
db 0a8h ; ANTI DEBUG !
PUBLIC gravure
gravure PROC NEAR

  ; Variables d'entree :
  x EQU word ptr[bp+4]
  y EQU word ptr[bp+6]

  ; Programme :
  push bp
  mov bp,sp
  push di
  push si

  mov es,word ptr[BLOC_64K+2]
  xor ax,ax
  mov gs,ax

  mov ax,y
  shl ax,6
  mov si,ax
  shl ax,2
  add si,ax
  add si,x

  mov cl,-128+32

  mov ebp,T_GRAVURE*T_GRAVURE
  mov dx,-1
  mov bx,-xm
  BOUCLE_ye@76:
    SQRT_FX@76:mov ax,gs:[ebp*4+1234]
    mov di,si
    sub di,ax
    add ax,ax
    BOUCLE_xe@76:
      mov es:[di],cl
      mov es:[di+bx],cl
      inc di
      dec ax
      jnz BOUCLE_xe@76
    add si,xm
    sub bx,xm*2
    add dx,2
    sub bp,dx
    jg BOUCLE_ye@76

  pop si
  pop di
  pop bp
  ret

gravure ENDP

;;;;;;;;;;;;;;;;;;;;;;;;
;                      ;
; Procedure aff_bump2D ; [72]
;                      ;
;;;;;;;;;;;;;;;;;;;;;;;;
db 00h ; ANTI DEBUG !
PUBLIC aff_bump2D
aff_bump2D PROC NEAR

  ; Variables d'entree :
  x EQU word ptr[bp+4]
  y EQU word ptr[bp+6]

  ; Variables locales :
  xe	   EQU word ptr[bp-2]
  dist	   EQU dword ptr[bp-6]
  ddistx   EQU dword ptr[bp-10]
  ddisty   EQU dword ptr[bp-14]
  sauve_sp EQU word ptr[bp-16]

  ; Programme :
  push bp
  mov bp,sp
  sub sp,16
  push di
  push si
  cld

  mov es,word ptr[IMAGE+2]
  mov fs,word ptr[BLOC_64K+2]
  xor di,di
  mov gs,di

  movsx eax,x
  mov ebx,eax
  add ebx,ebx
  dec ebx
  mov ddistx,ebx
  imul eax

  movsx ecx,y
  mov ebx,ecx
  add ebx,ebx
  dec ebx
  mov ddisty,ebx
  mov esi,ecx
  imul esi,esi

  add eax,HAUTEUR_SPOT*HAUTEUR_SPOT
  add esi,eax

  cli
  mov sauve_sp,sp

  BOUCLE_ye@72:
    mov dist,esi
    movsx ebx,x
    mov esp,ddistx
    mov xe,xm
    BOUCLE_xe@72:
      mov al,fs:[di-1]
      sub al,fs:[di+1]
      movsx eax,al
      imul ebx

      mov dl,fs:[di-xm]
      sub dl,fs:[di+xm]
      movsx edx,dl
      imul edx,ecx

      add eax,edx
      add eax,128*HAUTEUR_SPOT
      INV_FX@72:imul gs:dword ptr[esi*4+1234]
      shrd eax,edx,32-(HAUTEUR_SPOT_-1)

      jge SUITE@72
	xor al,al
      SUITE@72:
      stosb

      sub esi,esp
      sub esp,2
      dec ebx
      dec xe
      jnz BOUCLE_xe@72

    mov esi,dist
    mov esp,ddisty
    sub esi,esp
    sub esp,2
    mov ddisty,esp
    dec ecx
    cmp di,xm*ym
    jnz BOUCLE_ye@72

  mov sp,sauve_sp
  sti
  pop si
  pop di
  leave
  ret

aff_bump2D ENDP

;;;;;;;;;;;;;;;
;             ;
; FIN DU CODE ; [78]
;             ;
;;;;;;;;;;;;;;;
END