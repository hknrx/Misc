/********************************/
/*				*/
/*				*/
/*  PUISSANCE 4	 [21 mai 1997]  */
/*				*/
/*				*/
/*  Nicolas ROBERT  ! NRX 97 !  */
/*				*/
/*				*/
/********************************/



////////////////
//            //
// Inclusions //
//            //
////////////////
#include <conio.h> // Pour l'affichage.
#include <dos.h>   // Pour les sons et les delays.

////////////////////////////////
//                            //
// Definitions des constantes //
//                            //
////////////////////////////////
#define RIEN   	0   // 00000000b   // Case libre.
#define JAUNE  	1   // 00000001b   // Pion jaune.
#define ROUGE  	2   // 00000010b   // Pion rouge.
#define BORDURE 4   // 00000100b   // Bordure.
#define ECHANGE 771 // (00000011b) // Echange les joueurs.

#define HUMAIN 0 // Joueur = HUMAIN.
#define NRX    1 // Joueur = NRX.

#define OK      0 // Ok.
#define STOP    1 // Force NRX a jouer.
#define ABANDON 2 // [ESC] pressee.
#define EGALITE 3 // Jeu rempli.
#define GAGNE   4 // Gagne !

#define ESC    01 // Touche [ESC].
#define ESPACE 57 // Touche [ESPACE].
#define HAUT   72 // Touche [fleche haut].
#define BAS    80 // Touche [fleche bas].
#define GAUCHE 75 // Touche [fleche gauche].
#define DROITE 77 // Touche [fleche droite].

///////////////////////////
//                       //
// Definitions des types //
//                       //
///////////////////////////
typedef void	      Vide;
typedef char 	      Octet;
typedef int  	      Entier;
typedef unsigned int  EntierNS;
typedef unsigned long Pointeur;

typedef Octet Jeu[65]; // (7+1)*(6+2)+1 // Pas de bord droit...
typedef Octet Pile[8];

////////////////////////
//                    //
// Variables globales //
//                    //
////////////////////////
Octet touche;

Jeu	 jeu;
Pile	 pile;
EntierNS types_joueurs;
Octet 	 son;
EntierNS niveaux_NRX;
EntierNS joueurs;
Octet    meilleur;
Octet	 coups;

Octet recursion;
Octet stop;

Octet SCR_JOU[7]={0,1,4,20,20,20,20};
Octet SCR_ADV[7]={0,2,16,120,120,120,120};

Octet DIAG[12]={39,47,55,54,53,52,52,51,50,49,41,33};



/****************************************************************************/
/****************************************************************************/
/**                                                                        **/
/**			 	    CLAVIER				   **/
/**                                                                        **/
/****************************************************************************/
/****************************************************************************/

/////////////////////////////
//                    	   //
// Fonction lit_vect_inter //
//                    	   //
/////////////////////////////
Pointeur lit_vect_inter(Vide)
{
  asm mov ax,3509h
  asm int 21h
  asm mov ax,bx
  asm mov dx,es
}

//////////////////////////////
//                    	    //
// Procedure met_vect_inter //
//                    	    //
//////////////////////////////
Vide met_vect_inter(Pointeur vect)
{
  asm push ds
  asm mov ax,2509h
  asm lds dx,vect
  asm int 21h
  asm pop ds
}

///////////////////////////////
//                    	     //
// Procedure touche_detourne //
//                    	     //
///////////////////////////////
Vide interrupt touche_detourne(Vide)
{
  asm in al,60h
  asm mov touche,al
  asm mov al,20h
  asm out 20h,al
}



/****************************************************************************/
/****************************************************************************/
/**                                                                        **/
/**			 	      NRX				   **/
/**                                                                        **/
/****************************************************************************/
/****************************************************************************/

////////////////////
//                //
// Fonction gagne //
//                //
////////////////////
Octet gagne(Octet xy)
{
  Octet ij,k;

  for(ij=xy-9,k=0;jeu[ij]&(Octet)joueurs;ij-=9,k++);
  for(ij=xy+9;jeu[ij]&(Octet)joueurs;ij+=9,k++);
  if(k>2)
    return(1);

  for(ij=xy-7,k=0;jeu[ij]&(Octet)joueurs;ij-=7,k++);
  for(ij=xy+7;jeu[ij]&(Octet)joueurs;ij+=7,k++);
  if(k>2)
    return(1);

  for(ij=xy+8,k=0;jeu[ij]&(Octet)joueurs;ij+=8,k++);
  if(k>2)
    return(1);

  for(ij=xy-1,k=0;jeu[ij]&(Octet)joueurs;ij--,k++);
  for(ij=xy+1;jeu[ij]&(Octet)joueurs;ij++,k++);
  if(k>2)
    return(1);

  return(0);
}

/////////////////////////////
//                   	   //
// Fonction calcul_critere //
//             		   //
/////////////////////////////
Entier calcul_critere(Vide)
{
  Octet  n,xy;
  Octet  k,kk,l,ll;
  Entier total;
  Octet  adversaire;

  // Initialisation :
  total=0;
  adversaire=joueurs>>8;

  // HAUT-BAS :
  for(k=7,l=0;k>0;k--)
  {
    n=pile[k];
    if(!n)
      continue;
    if(n>l)
      l=n;

    xy=k+n+8;
    n>>=3;
    if(jeu[xy]&adversaire)
    {
      ll=0;
      do
      {
	ll++;
	xy+=8;
      }
      while(jeu[xy]&adversaire);
      if(ll+n>3)
	total-=SCR_ADV[ll];
    }
    else
      if(jeu[xy]&(Octet)joueurs)
      {
	kk=0;
	do
	{
	  kk++;
	  xy+=8;
	}
	while(jeu[xy]&(Octet)joueurs);
	if(kk+n>3)
	  total+=SCR_JOU[kk];
      }
  }

  // DROITE-GAUCHE :
  for(xy=l+7;xy>8;xy--)
  {
    k=kk=l=ll=0;
    do
    {
      k++;
      l++;
      if(jeu[xy]&(Octet)joueurs)
      {
	kk++;
	if(l>4)
	  total-=SCR_ADV[ll];
	l=ll=0;
      }
      else
	if(jeu[xy]&adversaire)
	{
	  ll++;
	  if(k>4)
	    total+=SCR_JOU[kk];
	  k=kk=0;
	}
      xy--;
    }
    while(!(jeu[xy]&BORDURE));
    if(l>3)
      total-=SCR_ADV[ll];
    if(k>3)
      total+=SCR_JOU[kk];
  }

  // DIAGONALE BG-HD :
  for(n=11;n>5;n--)
  {
    k=kk=l=ll=0;
    xy=DIAG[n];
    do
    {
      k++;
      l++;
      if(jeu[xy]&(Octet)joueurs)
      {
	kk++;
	if(l>4)
	  total-=SCR_ADV[ll];
	l=ll=0;
      }
      else
	if(jeu[xy]&adversaire)
	{
	  ll++;
	  if(k>4)
	    total+=SCR_JOU[kk];
	  k=kk=0;
	}
      xy-=7;
    }
    while(!(jeu[xy]&BORDURE));
    if(l>3)
      total-=SCR_ADV[ll];
    if(k>3)
      total+=SCR_JOU[kk];
  }

  // DIAGONALE BD-HG :
  for(;n>=0;n--)
  {
    k=kk=l=ll=0;
    xy=DIAG[n];
    do
    {
      k++;
      l++;
      if(jeu[xy]&(Octet)joueurs)
      {
	kk++;
	if(l>4)
	  total-=SCR_ADV[ll];
	l=ll=0;
      }
      else
	if(jeu[xy]&adversaire)
	{
	  ll++;
	  if(k>4)
	    total+=SCR_JOU[kk];
	  k=kk=0;
	}
      xy-=9;
    }
    while(!(jeu[xy]&BORDURE));
    if(l>3)
      total-=SCR_ADV[ll];
    if(k>3)
      total+=SCR_JOU[kk];
  }

  // Fin :
  return(total);
}

//////////////////////
//                  //
// Fonction cherche //
//                  //
//////////////////////
Entier cherche(Entier alpha,Entier beta)
{
  Octet	 i,j,y;
  Entier note,meilleure_note;

  // Fin ? :
  asm mov al,touche
  asm cmp al,ESC
  asm jne PAS_ESC
    asm mov stop,ABANDON
    asm jmp PAS_ESPACE
  PAS_ESC:
  asm cmp al,ESPACE
  asm jne PAS_ESPACE
    asm mov stop,STOP
  PAS_ESPACE:

  // Echange les joueurs :
  asm xor joueurs,ECHANGE
  asm dec recursion

  // Recursion (alpha-beta) :
  asm mov meilleure_note,-32000
  for(i=7;i>0;i--)
    if((j=pile[i])!=0)
    {
      if(gagne(i+j))
      {
	meilleure_note=30000+recursion;
	break;
      }

      jeu[i+j]=(Octet)joueurs;
      pile[i]=j-8;

      if((!recursion)|stop)
	note=calcul_critere();
      else
	note=-cherche(-beta,-alpha);

      pile[i]=j;
      jeu[i+j]=RIEN;

      if(note>meilleure_note)
	meilleure_note=note;

      if(note>alpha)
	alpha=note;

      if(alpha>=beta)
	break;
    }

  // Echange les joueurs :
  asm inc recursion
  asm xor joueurs,ECHANGE

  // Resultat :
  asm mov ax,meilleure_note
  asm cmp ax,-32000
  asm jne BYE
    asm xor ax,ax
  BYE:
}

/////////////////////////////////////
//                  		   //
// Procedure cherche_meilleur_coup //
//                  		   //
/////////////////////////////////////
Vide cherche_meilleur_coup(Vide)
{
  Octet	 i,j;
  Entier note,meilleure_note;

  // Initialisation :
  asm mov stop,OK
  asm mov al,coups
  asm mov bl,byte ptr[niveaux_NRX]
  asm cmp al,4
  asm jge PLUS
    asm or al,al
    asm jnz PAS_ZERO
      asm mov meilleur,4
      asm pop si
      asm leave
      asm retf
    PAS_ZERO:
    asm cmp bl,3
    asm jge SUITE_INIT
      asm mov recursion,3
      asm jmp FIN_INIT
  PLUS:
  asm cmp al,16
  asm jng SUITE_INIT
    asm inc bl
    asm mov byte ptr[niveaux_NRX],bl
  SUITE_INIT:
  asm mov recursion,bl
  FIN_INIT:

  // Recursion (alpha-beta) :
  asm mov meilleure_note,-32000
  for(i=7;i>0;i--)
    if((j=pile[i])!=0)
    {
      if(gagne(i+j))
      {
	meilleur=i;
	return;
      }

      jeu[i+j]=(Octet)joueurs;
      pile[i]=j-8;

      if(!recursion)
	note=calcul_critere();
      else
	note=-cherche(-32000,-meilleure_note);

      pile[i]=j;
      jeu[i+j]=RIEN;

      if(note>meilleure_note)
      {
	meilleure_note=note;
	meilleur=i;
      }
    }
}



/****************************************************************************/
/****************************************************************************/
/**                                                                        **/
/**			 	    HUMAIN				   **/
/**                                                                        **/
/****************************************************************************/
/****************************************************************************/

///////////////////////////
//                       //
// Procedure saisie_coup //
//                       //
///////////////////////////
Vide saisie_coup(Vide)
{
  Octet touche_;

  do
  {
    do
    {
      touche_=touche;
      switch(touche_)
      {
	case GAUCHE :
	  if(meilleur>1)
	    meilleur--;
	  break;

	case DROITE :
	  if(meilleur<7)
	    meilleur++;
	  break;

	case ESC :
	  stop=ABANDON;
	  return;
      }

      gotoxy(meilleur+meilleur+29,6);
      if(joueurs&JAUNE)
      {
	textcolor(YELLOW);
	cputs("  O  ");
      }
      else
      {
	textcolor(LIGHTRED);
	cputs("  X  ");
      }

      while(touche==touche_);
    }
    while(touche_!=ESPACE);
  }
  while(!pile[meilleur]);

  stop=OK;
}



/****************************************************************************/
/****************************************************************************/
/**                                                                        **/
/**			     PROGRAMME PRINCIPAL			   **/
/**                                                                        **/
/****************************************************************************/
/****************************************************************************/

//////////////////////////////
//                          //
// Procedure initialise_jeu //
//                          //
//////////////////////////////
Vide initialise_jeu(Vide)
{
  Entier xy;

  // Initialise le jeu :
  for(xy=55;xy>8;xy--)
    jeu[xy]=RIEN;

  for(xy=7;xy>=0;xy--)
  {
    jeu[xy]=BORDURE;
    jeu[xy+56]=BORDURE;
    jeu[xy<<3]=BORDURE;
  }
  jeu[64]=BORDURE;

  for(xy=7;xy>0;xy--)
    pile[xy]=48;

  coups=0;

  // Dessin :
  clrscr();
  textcolor(LIGHTBLUE);
  for(xy=6;xy>0;xy--)
  {
    gotoxy(32,xy+7);
    cputs("Û ³ ³ ³ ³ ³ ³ Û");
  }
  gotoxy(32,14);
  cputs("ßßßßßßßßßßßßßßß");
}

////////////////////
//	          //
// Procedure joue //
//                //
////////////////////
Vide joue(Vide)
{
  Octet  j;
  Entier m;

  // Affiche a qui de jouer :
  gotoxy(34,15);
  if(joueurs&JAUNE)
  {
    textcolor(YELLOW);
    cputs("J A U N E S");
  }
  else
  {
    textcolor(LIGHTRED);
    cputs("R O U G E S");
  }

  // Reflexion (NRX ou humain) :
  if((Octet)types_joueurs==NRX)
    cherche_meilleur_coup();
  else
    saisie_coup();

  // Stop ? :
  if(stop==ABANDON)
  {
    while(touche==ESC);
    return;
  }

  // Affichage :
  if(joueurs&JAUNE)
  {
    textcolor(YELLOW);
    m=400;
  }
  else
  {
    textcolor(LIGHTRED);
    m=500;
  }

  gotoxy(meilleur+meilleur+31,6);
  for(j=pile[meilleur];j>=0;j-=8)
  {
    if(joueurs&JAUNE)
      cputs(" \b\nO\b");

    else
      cputs(" \b\nX\b");
    if(son)
    {
       sound(m);
       delay(10);
       nosound();
    }
    delay(10);
  }
  while(touche==ESPACE);

  // Gagne ? :
  j=pile[meilleur];
  if(gagne(meilleur+j))
  {
    stop=GAGNE;
    return;
  }

  // Fin ? :
  coups++;
  if(coups==42)
  {
    stop=EGALITE;
    return;
  }

  jeu[meilleur+j]=(Octet)joueurs;
  pile[meilleur]=j-8;
  stop=OK;
}

//////////////////////////
//                      //
// Procedure parametres //
//                      //
//////////////////////////
Vide parametres(Vide)
{
  Octet touche_;
  Octet joueur;
  Octet *ptr;

  // Initialisation :
  textcolor(BLUE);
  gotoxy(1,1);
  cputs("Rouges : NRX\n\rJaunes : HUMAIN");
  gotoxy(1,4);
  cputs("Son : OUI");
  gotoxy(1,6);
  cputs("Niveau Rouges : 3\n\rNiveau Jaunes : X");

  // Type des joueurs :
  types_joueurs=NRX|(HUMAIN<<8);
  joueur=0;
  ptr=(Octet *)&types_joueurs;
  do
  {
    touche_=touche;
    switch(touche_)
    {
      case GAUCHE :
      case DROITE :
	*(ptr+joueur)^=1;
	break;

      case HAUT :
      case BAS :
	joueur^=1;
    }

    gotoxy(17,6+joueur);
    if(*(ptr+joueur)==NRX)
    {
      cputs("3");
      gotoxy(10,1+joueur);
      cputs("NRX   ");
    }
    else
    {
      cputs("X");
      gotoxy(10,1+joueur);
      cputs("HUMAIN");
    }

    while(touche==touche_);
  }
  while(touche_!=ESPACE);

  // Son :
  son=1;
  do
  {
    touche_=touche;
    if((touche_==GAUCHE)||(touche_==DROITE))
      son^=1;

    gotoxy(7,4);
    if(son)
      cputs("OUI");
    else
      cputs("NON");

    while(touche==touche_);
  }
  while(touche_!=ESPACE);

  // Niveaux :
  niveaux_NRX=3|(3<<8);
  if(types_joueurs)
  {
    if(types_joueurs&NRX)
      joueur=0;
    else
      joueur=1;

    ptr=(Octet *)&niveaux_NRX;
    do
    {
      touche_=touche;
      switch(touche_)
      {
	case GAUCHE :
	  if(*(ptr+joueur)>0)
	    (*(ptr+joueur))--;
	  break;

	case DROITE :
	  if(*(ptr+joueur)<7)
	    (*(ptr+joueur))++;
	  break;

	case HAUT :
	case BAS :
	  if(types_joueurs==(NRX|(NRX<<8)))
	    joueur^=1;
      }

      gotoxy(17,6+joueur);
      cprintf("%d",*(ptr+joueur));

      while(touche==touche_);
    }
    while(touche_!=ESPACE);
  }

  // Initialisation (au cas ou 1er joueur = humain) :
  meilleur=4;
}

/////////////////////////
//                     //
// Programme principal //
//                     //
/////////////////////////
Vide main(Vide)
{
  Pointeur touche_normale;

  // Nouveau gestionnaire de clavier :
  touche_normale=lit_vect_inter();
  met_vect_inter((Pointeur)touche_detourne);

  // Initialisations :
  initialise_jeu();
  parametres();
  _setcursortype(_NOCURSOR);

  // Boucle principale :
  asm mov joueurs,ROUGE+JAUNE*256
  BOUCLE:

    // Joue :
    joue();
    asm cmp stop,0
    asm jne FIN

    // Echange les joueurs :
    asm xor joueurs,ECHANGE
    asm mov ax,niveaux_NRX
    asm xchg ah,al
    asm mov niveaux_NRX,ax
    asm mov ax,types_joueurs
    asm xchg ah,al
    asm mov types_joueurs,ax
    asm jmp BOUCLE
  FIN:

  // Fin :
  sound(220);
  delay(100);
  nosound();

  gotoxy(31,15);
  if(stop!=GAGNE)
  {
    textcolor(LIGHTBLUE);
    if(stop==ABANDON)
      cputs("     ABANDON  ");
    else
      cputs("     EGALITE  ");
  }
  else
    if(joueurs&ROUGE)
    {
      textcolor(LIGHTRED);
      cputs("ROUGES VAINQUEURS");
    }
    else
    {
      textcolor(YELLOW);
      cputs("JAUNES VAINQUEURS");
    }
  gotoxy(1,20);
  _setcursortype(_NORMALCURSOR);

  // Ancien gestionnaire de clavier :
  met_vect_inter(touche_normale);
}