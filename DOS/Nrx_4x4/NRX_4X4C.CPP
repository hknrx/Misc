// NRX 98
// 20/12/98

// A FAIRE :
//
// ! 0) VERIFIER, MODIFIER, OPTIMISER LE CLIPPING !!!
// ! 1) PLACEMENT DU MONDE DEVANT LA CAMERA.
// ! 2) MODIFIER LA STRUCTURE "Objet" POUR FACILITER LE PLACEMENT...
// ? 3) "DESACTIVER" LE MODELE FLAT (gs) AVANT DE PARTIR (-> WINDOWS...) ?
// ! 4) AJOUTER LES ROUTINES DE "OTHELLO" !
// ? 5) Compression des fichiers ".DAT".

////////////////
//            //
// Constantes //
//            //
////////////////
// Touches :
#define GAUCHE 75 // [fleche GAUCHE].
#define DROITE 77 // [fleche DROITE].
#define HAUT   72 // [fleche HAUT].
#define BAS    80 // [fleche BAS].
#define CTRL   29 // [CTRL].
#define ALT    56 // [ALT], [ALTGR].
#define ESPACE 57 // [ESPACE].
#define INSER  82 // [INSER].
#define SUPPR  83 // [SUPPR].
#define HOME   71 // [HOME].
#define FIN    79 // [FIN].
#define PGUP   73 // [PGUP].
#define PGDN   81 // [PGDN].
#define ECHAP  1  // [ECHAP].
#define F1     59 // [F1].
#define F2     60 // [F2].
#define F3     61 // [F3].
#define F4     62 // [F4].

// Fichiers :
#define RD	  0 // Ouverture d'un fichier en lecture.
#define WR	  1 // Ouverture d'un fichier en ecriture.
#define RD_WR 	  2 // Ouverture d'un fichier en lecture/ecriture.
#define POS_DEBUT 0 // Debut du fichier.
#define POS_COUR  1 // Position courante.
#define POS_FIN   2 // Fin du fichier.

// Palettes :
#define PALETTE_A 0     // Palette A.
#define PALETTE_B 256*3 // Palette B.

// Camera :
#define xm     320 // Largeur de l'ecran.
#define ym     200 // Hauteur de l'ecran.
#define xo     160 // Milieu de l'ecran (X).
#define yo     100 // Milieu de l'ecran (Y).
#define coefx  307 // Ouverture camera en X.
#define coefy  256 // Ouverture camera en Y.
#define coefy_ 8   // Ouverture camera en Y.

// Textures :
#define OBJ_TEXTURES_L 256L // Largeur du buffer "OBJ_TEXTURES".
#define OBJ_TEXTURES_H 256L // Hauteur du buffer "OBJ_TEXTURES".
#define VOX_TEXTURES_L 256L // Largeur du buffer "VOX_TEXTURES".
#define VOX_TEXTURES_H 256L // Hauteur du buffer "VOX_TEXTURES".

// Clipping :
#define XY_CLIPPING 2*65536L  // "Taille" du volume englobant.
#define Z_CLIPPING  40*65536L // Distance maximale.

// Logo :
#define V_GRAVURE_ 1 // Vitesse de gravure.

// Control de la demo :
#define SUITE 0 // Suite !
#define STOP  1 // Sortie immediate...

///////////////////////////
//       		 //
// Definitions des types //
//       		 //
///////////////////////////
typedef void 	      Vide;
typedef char 	      Char;
typedef unsigned char Octet;
typedef Char 	      OctetS;
typedef unsigned int  Entier;
typedef int 	      EntierS;
typedef unsigned long Long;
typedef long 	      LongS;
typedef Entier 	      Fichier;
typedef LongS 	      Flottant;
typedef Octet 	      Angle;
typedef Octet 	      Couleur;
typedef float         Float;

typedef struct
	{
	  Flottant distance;
	  Octet    code;
	}
	A_trier;

typedef struct
	{
	  EntierS  xe;
	  EntierS  ye;

	  Flottant x3D_O;
	  Flottant y3D_O;
	  Flottant z3D_O;

	  Flottant x3D_C;
	  Flottant y3D_C;
	  Flottant z3D_C;
	}
	Point;

typedef struct
	{
	  Flottant Mxx,Myx,Mzx;
	  Flottant Mxy,Myy,Mzy;
	  Flottant Mxz,Myz,Mzz;
	}
	Matrice;

typedef struct
	{
	  Point    pt;

	  Flottant r;
	  Flottant deforme_x;
	  Flottant deforme_y;
	  Flottant deforme_z;

	  Long     texture;
	}
	Boule;

typedef struct
	{
	  Octet      nb_pts;
	  Octet far* num_pt;

	  Flottant   norm_V;
	  Flottant   norm_W;

	  Long       texture;
	}
	Poly;

typedef struct
	Objet_
	{
	  Matrice     mat;
	  Flottant    x;
	  Flottant    y;
	  Flottant    z;

	  Octet       nb_boules;
	  Boule far*  boule;

	  Octet       nb_pts;
	  Point far*  pt;
	  Octet       nb_polys;
	  Poly far*   poly;

	  Octet       nb_sous_objets;
	  Objet_ far* sous_objet;
	}
	Objet;

typedef struct
	{
	  Entier x;
	  Entier y;
	}
	Pt_logo;

typedef struct
	{
	  Pt_logo depart;
	  Pt_logo arrivee;
	}
	Logo;

////////////////////////
//       	      //
// Variables globales //
//       	      //
////////////////////////
// Gestion de la memoire etendue :
Vide far* XMS_driver;
Entier    XMS_handle;

// Generateur de nombres aleatoires :
Octet aleatoire;

// Clavier :
Octet TOUCHES[128];
Octet nb_touches;

// Buffers :
Flottant far* SIN_FX;
Couleur far*  IMAGE;
Vide far*     BLOC_64K;
Couleur far*  PALETTES;
Long	      TEXTURES;

// Soleil :
Flottant sol_x,sol_y,sol_z;

// Logo :
Logo LOGO[]={{{ 20, 50},{ 20,150}},
	     {{ 20, 50},{100,150}},
	     {{100, 50},{100,150}},
	     {{120, 50},{120,150}},
	     {{120, 50},{200, 75}},
	     {{200, 75},{120,100}},
	     {{120,100},{200,150}},
	     {{220, 50},{300,150}},
	     {{300, 50},{220,150}}};

/****************************************************************************/
/*                                                                          */
/* MEMOIRE						                    */
/*                                                                          */
/****************************************************************************/

extern "C" Entier dispo_DOS(Vide);
extern "C" Vide far* alloc_DOS(Entier taille);
extern "C" Vide liber_DOS(Vide far* pointeur);
extern "C" Octet alloc_XMS(Vide);
extern "C" Vide liber_XMS(Vide);

/****************************************************************************/
/*                                                                          */
/* FICHIER							            */
/*                                                                          */
/****************************************************************************/

extern "C" Fichier cre_fichier(Char far* nom);
extern "C" Fichier ouvre_fichier(Char far* nom,Octet type);
extern "C" Vide dplc_fichier(Fichier fichier,Octet position,LongS dplcmt);
extern "C" Vide ferme_fichier(Fichier fichier);
extern "C" Vide lit_fichier_DOS(Fichier fichier,Entier nb,Vide far* buffer);
extern "C" Vide ecrit_fichier_DOS(Fichier fichier,Entier nb,Vide far* buffer);
extern "C" Vide lit_fichier_XMS(Fichier fichier,Long nb,Long buffer);

/****************************************************************************/
/*                                                                          */
/* CLAVIER							            */
/*                                                                          */
/****************************************************************************/

extern "C" Vide far* lit_clavier(Vide);
extern "C" Vide change_clavier(Vide far* vect);
extern "C" Vide init_touches(Vide);
extern "C" Vide interrupt touche_detourne(Vide);
extern "C" Vide relache_touche(Octet touche);

/****************************************************************************/
/*                                                                          */
/* GRAPHISMES							            */
/*                                                                          */
/****************************************************************************/

extern "C" Vide lit_palette(Entier palette);
extern "C" Vide change_palette(Entier palette);
extern "C" Vide palette_jaunie(Entier pal_source,Entier pal_dest);
extern "C" Vide fade(Entier pal_mod,Entier pal_but);
extern "C" Vide cre_palette_unie(Entier palette,Couleur R,Couleur V,Couleur B);
extern "C" Vide change_bordure(Couleur bordure);
extern "C" Vide efface_image(Couleur coul);
extern "C" Vide aff_image(Vide);
extern "C" Vide retour_balayage(Vide);
extern "C" Vide aff_image_ZR(Flottant zoom,Angle rotation,Couleur coul);
extern "C" Vide etire_ecran(Octet etire);
extern "C" Octet lit_mode(Vide);
extern "C" Vide met_mode(Octet mode);
extern "C" Octet detect_VGA(Vide);
extern "C" Vide aff_texte(Char far* texte);
extern "C" Vide aff_nombre(Long nombre);
extern "C" Vide pose_curseur(Octet x,Octet y);

/****************************************************************************/
/*                                                                          */
/* MATH								      	    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide init_hasard(Vide);
extern "C" Octet hasard(Vide);
extern "C" Flottant abs_fx(Flottant x);
extern "C" Flottant fx(Entier x);
extern "C" Entier entier(Flottant x);
extern "C" Flottant sqrt_fx(Flottant x);
extern "C" Flottant mul_fx(Flottant a,Flottant b);
extern "C" Flottant div_fx(Flottant a,Flottant b);
extern "C" Vide init_SIN_FX(Vide);
extern "C" Vide init_SQRT_FX(Vide);
extern "C" Vide init_INV_FX(Vide);
extern "C" Vide mul_mat(Matrice far* mat_AB,Matrice far* mat_A,Matrice far* mat_B);
extern "C" Vide tri(A_trier far* a_trier,Entier l);

/****************************************************************************/
/*                                                                          */
/* OBJET 								    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide cre_OBJ_TEXTURES(Vide);
extern "C" Vide place_soleil(Angle Rx,Angle Ry);
extern "C" Vide place_objet(Objet far* objet,
			    Flottant x,Flottant y,Flottant z,
			    Angle Rx,Angle Ry,Angle Rz);
extern "C" Vide place_objet_XZY(Objet far* objet,
				Flottant x,Flottant y,Flottant z,
				Angle Rx,Angle Ry,Angle Rz);
extern "C" Vide init_Z_BUFFER(Vide);
extern "C" Vide init_BOULE(Vide);
extern "C" Vide aff_boule(Boule far* b,Matrice far* objet_mat);
extern "C" Vide aff_poly(Poly far* poly,Point far* pt);

/////////////////////////
//                     //
// Procedure aff_objet //
//                     //
/////////////////////////
Vide aff_objet(Objet far* objet)
{
  EntierS    n;
  Flottant   x1,y1,z1;
  Flottant   x2,y2,z2;
  Matrice    mat;
  Boule far* boule;
  Point far* pt;
  Objet far* sous_objet;

  // Clipping :
  x1=objet->x;
  y1=objet->y;
  z1=objet->z;

  if(z1<=0)
    return;
  if(z1>Z_CLIPPING)
    return;
  if((x1+XY_CLIPPING)*coefx<-xo*z1)
    return;
  if((x1-XY_CLIPPING)*coefx>xo*z1)
    return;
  if(((y1+XY_CLIPPING)<<coefy_)<-yo*z1)
    return;
  if(((y1-XY_CLIPPING)<<coefy_)>yo*z1)
    return;

  // Placement et affichage des boules :
  for(n=0;n<objet->nb_boules;n++)
  {
    boule=&objet->boule[n];

    x1=boule->pt.x3D_O;
    y1=boule->pt.y3D_O;
    z1=boule->pt.z3D_O;

    z2=objet->z+mul_fx(objet->mat.Mxz,x1)+
		mul_fx(objet->mat.Myz,y1)+
		mul_fx(objet->mat.Mzz,z1);

    if(z2>0)
    {
      x2=objet->x+mul_fx(objet->mat.Mxx,x1)+
		  mul_fx(objet->mat.Myx,y1)+
		  mul_fx(objet->mat.Mzx,z1);
      y2=objet->y+mul_fx(objet->mat.Mxy,x1)+
		  mul_fx(objet->mat.Myy,y1)+
		  mul_fx(objet->mat.Mzy,z1);

      boule->pt.x3D_C=x2;
      boule->pt.y3D_C=y2;
      boule->pt.z3D_C=z2;

      boule->pt.xe=xo+(x2*coefx)/z2;
      boule->pt.ye=yo-(y2<<coefy_)/z2;

      aff_boule(boule,&objet->mat);
    }
  }

  // Placement et affichage des polygones :
  for(n=0;n<objet->nb_pts;n++)
  {
    pt=&objet->pt[n];

    x1=pt->x3D_O;
    y1=pt->y3D_O;
    z1=pt->z3D_O;

    z2=objet->z+mul_fx(objet->mat.Mxz,x1)+
		mul_fx(objet->mat.Myz,y1)+
		mul_fx(objet->mat.Mzz,z1);

    pt->z3D_C=z2;

    if(z2>0)
    {
      x2=objet->x+mul_fx(objet->mat.Mxx,x1)+
		  mul_fx(objet->mat.Myx,y1)+
		  mul_fx(objet->mat.Mzx,z1);
      y2=objet->y+mul_fx(objet->mat.Mxy,x1)+
		  mul_fx(objet->mat.Myy,y1)+
		  mul_fx(objet->mat.Mzy,z1);

      pt->x3D_C=x2;
      pt->y3D_C=y2;

      pt->xe=xo+(x2*coefx)/z2;
      pt->ye=yo-(y2<<coefy_)/z2;
    }
  }
  for(n=0;n<objet->nb_polys;n++)
    aff_poly(&objet->poly[n],objet->pt);

  // Placement et affichage des sous-objets :
  for(n=0;n<objet->nb_sous_objets;n++)
  {
    sous_objet=&objet->sous_objet[n];

// CLIPPING ICI ?! (ENLEVER CELUI DU HAUT ; RAJOUTER DANS LA FONCTION
// QUI PLACE LE MONDE DEVANT LA CAMERA...)

// MODIFIER LA STRUCTURE "Objet" POUR NE PAS AVOIR A PLACER TOUS LES
// SOUS-OBJETS A CHAQUE FOIS !
// x,y,z -> x3D_O,y3D_O,z3D_O ; x3D_C,y3D_C,z3D_C
// mat   -> mat_O             ; mat_C

    x1=sous_objet->x;
    y1=sous_objet->y;
    z1=sous_objet->z;

    sous_objet->x=objet->x+mul_fx(objet->mat.Mxx,x1)+
			   mul_fx(objet->mat.Myx,y1)+
			   mul_fx(objet->mat.Mzx,z1);
    sous_objet->y=objet->y+mul_fx(objet->mat.Mxy,x1)+
			   mul_fx(objet->mat.Myy,y1)+
			   mul_fx(objet->mat.Mzy,z1);
    sous_objet->z=objet->z+mul_fx(objet->mat.Mxz,x1)+
			   mul_fx(objet->mat.Myz,y1)+
			   mul_fx(objet->mat.Mzz,z1);

    mat.Mxx=sous_objet->mat.Mxx;
    mat.Myx=sous_objet->mat.Myx;
    mat.Mzx=sous_objet->mat.Mzx;
    mat.Mxy=sous_objet->mat.Mxy;
    mat.Myy=sous_objet->mat.Myy;
    mat.Mzy=sous_objet->mat.Mzy;
    mat.Mxz=sous_objet->mat.Mxz;
    mat.Myz=sous_objet->mat.Myz;
    mat.Mzz=sous_objet->mat.Mzz;

    mul_mat(&sous_objet->mat,&objet->mat,&mat);

    aff_objet(sous_objet);
  }
}

/////////////////////////
//                     //
// Fonction lit_objets //
//                     //
/////////////////////////
Objet far* lit_objets(Fichier fichier)
{
  Entier     taille;
  Octet      nb_objets,nb_boules,nb_pts,nb_polys,nb_num_pts;
  Objet far* objet;
  Boule far* boule;
  Point far* pt;
  Poly far*  poly;
  Octet far* num_pt;

  Octet      m,n;
  Flottant   x,y,z;
  Flottant   Ux,Uy,Uz;

  // Allocation memoire :
  lit_fichier_DOS(fichier,sizeof(Entier),&taille);
  objet=(Objet far*)alloc_DOS(taille);
  if(!objet)
    return(0);

  // Mise en place des pointeurs :
  lit_fichier_DOS(fichier,5*sizeof(Octet),&nb_num_pts);

  boule=(Boule far*)(objet+nb_objets);
  pt=(Point far*)(boule+nb_boules);
  poly=(Poly far*)(pt+nb_pts);
  num_pt=(Octet far*)(poly+nb_polys);

  // Lecture des objets :
  for(n=0;n<nb_objets;n++)
  {
    lit_fichier_DOS(fichier,sizeof(Octet),&objet[n].nb_boules);
    lit_fichier_DOS(fichier,sizeof(Octet),&m);
    objet[n].boule=&boule[m];

    lit_fichier_DOS(fichier,sizeof(Octet),&objet[n].nb_pts);
    lit_fichier_DOS(fichier,sizeof(Octet),&m);
    objet[n].pt=&pt[m];
    lit_fichier_DOS(fichier,sizeof(Octet),&objet[n].nb_polys);
    lit_fichier_DOS(fichier,sizeof(Octet),&m);
    objet[n].poly=&poly[m];

    lit_fichier_DOS(fichier,sizeof(Octet),&objet[n].nb_sous_objets);
    lit_fichier_DOS(fichier,sizeof(Octet),&m);
    objet[n].sous_objet=&objet[m];
  }

  // Lecture des boules :
  for(n=0;n<nb_boules;n++)
  {
    lit_fichier_DOS(fichier,3*sizeof(Flottant),&boule[n].pt.x3D_O);
    lit_fichier_DOS(fichier,5*sizeof(Flottant),&boule[n].r);
  }

  // Lecture des points :
  for(n=0;n<nb_pts;n++)
    lit_fichier_DOS(fichier,3*sizeof(Flottant),&pt[n].x3D_O);

  // Lecture des polygones :
  for(n=0;n<nb_polys;n++)
  {
    lit_fichier_DOS(fichier,sizeof(Octet),&poly[n].nb_pts);
    lit_fichier_DOS(fichier,sizeof(Octet),&m);
    poly[n].num_pt=&num_pt[m];
    lit_fichier_DOS(fichier,sizeof(Long),&poly[n].texture);
  }

  // Lecture des num_pts :
  lit_fichier_DOS(fichier,nb_num_pts*sizeof(Octet),num_pt);

  // Initialisation des polygones : // METTRE "norm_V" ET "norm_W" DANS LE FICHIER !
  for(m=0;m<nb_objets;m++)
    for(n=0;n<objet[m].nb_polys;n++)
    {
      num_pt=objet[m].poly[n].num_pt;

      x=objet[m].pt[num_pt[1]].x3D_O;
      y=objet[m].pt[num_pt[1]].y3D_O;
      z=objet[m].pt[num_pt[1]].z3D_O;

      Ux=objet[m].pt[num_pt[2]].x3D_O-x;
      Uy=objet[m].pt[num_pt[2]].y3D_O-y;
      Uz=objet[m].pt[num_pt[2]].z3D_O-z;

      objet[m].poly[n].norm_V=
      div_fx(65536L,sqrt_fx(mul_fx(Ux,Ux)+mul_fx(Uy,Uy)+mul_fx(Uz,Uz)));

      Ux=objet[m].pt[num_pt[0]].x3D_O-x;
      Uy=objet[m].pt[num_pt[0]].y3D_O-y;
      Uz=objet[m].pt[num_pt[0]].z3D_O-z;

      objet[m].poly[n].norm_W=
      div_fx(65536L,sqrt_fx(mul_fx(Ux,Ux)+mul_fx(Uy,Uy)+mul_fx(Uz,Uz)));
    }

  // Fin :
  return(objet);
}

/****************************************************************************/
/*                                                                          */
/* SPRITE							    	    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide aff_sprite_fond(Flottant x,Flottant y,Flottant z,Angle Rz);

/****************************************************************************/
/*                                                                          */
/* INTERFERENCES							    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide aff_inter(Entier xo1,Entier yo1,Entier xo2,Entier yo2,Octet d);

/****************************************************************************/
/*                                                                          */
/* FEU									    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide cre_palette_feu(Entier palette);
extern "C" Vide cre_palette_pastel(Entier palette);
extern "C" Vide init_feu(Vide);
extern "C" Vide aff_feu(Vide);

/****************************************************************************/
/*                                                                          */
/* VOXEL								    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide cre_vox(Vide);
extern "C" Vide ombrage_vox(Vide);
extern "C" Vide aff_vox(Flottant x,Flottant y,Flottant z,Angle Ry);
extern "C" Flottant hauteur_vox(Flottant x,Flottant z);
extern "C" Flottant moy_hauteurs_vox(Flottant x,Flottant z);

/****************************************************************************/
/*                                                                          */
/* NEURONES								    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide init_neurones(Vide);
extern "C" Vide aff_neurones(Vide);
extern "C" Vide fin_neurones(Vide);

/****************************************************************************/
/*                                                                          */
/* TUNNEL								    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide init_tunnel(Vide);
extern "C" Vide aff_tunnel(Octet a,Octet z);

/****************************************************************************/
/*                                                                          */
/* BUMP2D								    */
/*                                                                          */
/****************************************************************************/

extern "C" Vide cre_palette_bump2D(Entier palette);
extern "C" Vide cre_vagues(Octet d);
extern "C" Octet granite(Vide);
extern "C" Vide gravure(Entier x,Entier y);
extern "C" Vide aff_bump2D(Entier x,Entier y);

/****************************************************************************/
/*                                                                          */
/* MOTEUR NRX						                    */
/*                                                                          */
/****************************************************************************/

///////////////////////
//                   //
// Fonction init_NRX //
//                   //
///////////////////////
Octet init_NRX(Vide)
{
  Octet erreur;

  // Detection de la carte VGA :
  erreur=7;
  if(detect_VGA())
  {
    // Allocation de memoire conventionnelle :
    erreur=6;
    SIN_FX=(Flottant far*)alloc_DOS(256*sizeof(Flottant));
    if(SIN_FX)
    {
      IMAGE=(Couleur far*)alloc_DOS(xm*ym*sizeof(Couleur));
      if(IMAGE)
      {
	BLOC_64K=(Vide far*)alloc_DOS(-1); // 64K
	if(BLOC_64K)
	{
	  PALETTES=(Couleur far*)alloc_DOS(256*3*2*sizeof(Couleur));
	  if(PALETTES)
	  {
	    // Allocation de memoire etendue :
	    erreur=alloc_XMS();
	    if(!erreur)
	    {
	      // Initialisations :
	      init_SIN_FX();
	      init_SQRT_FX();
	      init_INV_FX();
	      init_BOULE();
	      init_hasard();

	      // OK ! :
	      return(1);
	    }
	    liber_DOS(PALETTES);
	  }
	  liber_DOS(BLOC_64K);
	}
	liber_DOS(IMAGE);
      }
      liber_DOS(SIN_FX);
    }
  }

  // Il y a eu une erreur ! :
  switch(erreur)
  {
    case 1:
      aff_texte("ERREUR : Processeur en mode protege.\r\n$");
      break;
    case 2:
      aff_texte("ERREUR : Gestionnaire XMS non installe.\r\n$");
      break;
    case 3:
      aff_texte("ERREUR : Version du gestionnaire XMS < 2.0.\r\n$");
      break;
    case 4:
      aff_texte("ERREUR : Memoire XMS insuffisante.\r\n$");
      break;
    case 5:
      aff_texte("ERREUR : Protection de l'EMB impossible.\r\n$");
      break;
    case 6:
      aff_texte("ERREUR : Memoire conventionnelle insuffisante.\r\n$");
      break;
    case 7:
      aff_texte("ERREUR : Carte video inadaptee.\r\n$");
  }
  return(0);
}

///////////////////////
//                   //
// Procedure fin_NRX //
//                   //
///////////////////////
Vide fin_NRX(Vide)
{
  liber_XMS();
  liber_DOS(PALETTES);
  liber_DOS(BLOC_64K);
  liber_DOS(IMAGE);
  liber_DOS(SIN_FX);
}

/****************************************************************************/
/*                                                                          */
/* PROGRAMME ET FONCTIONS PRINCIPALES			                    */
/*                                                                          */
/****************************************************************************/

////////////////////////////////
//                   	      //
// Procedure cre_palette_test //
//                   	      //
////////////////////////////////
Vide cre_palette_test(Entier palette,OctetS init)
{
  Entier  l,m,n;
  Float   nuance;
  Couleur RVB,pal[32*3];
  Octet   sens,incr;

  // Re-initialise le generateur de nombres aleatoires ! :
  if(init==-1)
    init_hasard();
  else
    aleatoire=init;

  // Creation des 32 couleurs de base :
  for(l=0;l<3;l++)
  {
    RVB=(hasard()&32)+26;
    sens=hasard()&1;
    incr=(hasard()&3)+1;

    for(m=l;m<32*3;m+=3)
    {
      pal[m]=RVB;
      if(sens)
      {
	RVB+=incr;
	if(RVB>=60)
	  sens=0;
      }
      else
      {
	RVB-=incr;
	if(RVB<=23)
	  sens=1;
      }
    }
  }

  // Creation de toutes les nuances :
  for(l=8,n=palette,nuance=0.4;l>0;l--,nuance+=0.07)
    for(m=0;m<32*3;m++,n++)
      PALETTES[n]=pal[m]*nuance;
}

///////////////////
//               //
// Fonction logo //
//               //
///////////////////
Octet logo(Vide)
{
  Entier   tempo_demo;
  Entier   tempo_manuel;
  Octet    start;

  Flottant x_spot,y_spot;
  Angle	   angle;

  Octet    creation;
  Entier   tempo_vagues;
  Octet    logo;
  Flottant x_gravure,y_gravure;
  Flottant inc_x,inc_y;
  Flottant diff_x,diff_y;
  EntierS  dist;

  // Initialisations :
  change_bordure(0);

  tempo_demo=900;
  tempo_manuel=0;
  start=1;

  x_spot=160*65536L;
  y_spot=100*65536L;

  creation=3;
  tempo_vagues=100;
  logo=0;
  dist=0;

  // Demo :
  do
  {
    // Mouvement du spot :
    if(nb_touches)
    {
      tempo_manuel=100;

      if(TOUCHES[GAUCHE])
	if(x_spot>=3*65536L)
	  x_spot-=3*65536L;
      if(TOUCHES[DROITE])
	if(x_spot<(xm-3)*65536L)
	  x_spot+=3*65536L;
      if(TOUCHES[HAUT])
	if(y_spot>=3*65536L)
	  y_spot-=3*65536L;
      if(TOUCHES[BAS])
	if(y_spot<(ym-3)*65536L)
	  y_spot+=3*65536L;
    }
    else
      if(tempo_manuel)
	tempo_manuel--;
      else
      {
	x_spot+=SIN_FX[(Angle)(angle+64)]*3;
	y_spot+=SIN_FX[angle]*3;
	angle++;
	if((entier(x_spot)>=xm)||(entier(y_spot)>=ym))
	  angle+=4;
      }

    // Creation de la plaque :
    switch(creation)
    {
      case 3:
	cre_vagues(tempo_vagues<<4);
	tempo_vagues--;
	if(!tempo_vagues)
	  creation--;
	break;

      case 2:
	if(!granite())
	  creation--;
	break;

      case 1:
	if(!dist)
	{
	  if(logo==9)
	  {
	    creation--;
	    break;
	  }

	  x_gravure=fx(LOGO[logo].depart.x);
	  y_gravure=fx(LOGO[logo].depart.y);

	  diff_x=fx(LOGO[logo].arrivee.x)-x_gravure;
	  diff_y=fx(LOGO[logo].arrivee.y)-y_gravure;

	  if(abs_fx(diff_x)<diff_y)
	  {
	    dist=entier(diff_y)>>V_GRAVURE_;
	    inc_x=diff_x/dist;
	    inc_y=65536L<<V_GRAVURE_;
	  }
	  else
	  {
	    if(diff_x>0)
	    {
	      dist=entier(diff_x)>>V_GRAVURE_;
	      inc_x=65536L<<V_GRAVURE_;
	    }
	    else
	    {
	      dist=entier(-diff_x)>>V_GRAVURE_;
	      inc_x=-65536L<<V_GRAVURE_;
	    }
	    inc_y=diff_y/dist;
	  }

	  logo++;
	}

	gravure(entier(x_gravure),entier(y_gravure));
	x_gravure+=inc_x;
	y_gravure+=inc_y;
	dist--;
    }

    // Bump2D :
    aff_bump2D(entier(x_spot),entier(y_spot));
    aff_image();

    // Fade :
    if(start)
    {
      start=0;
      cre_palette_bump2D(PALETTE_B);
      fade(PALETTE_A,PALETTE_B);
    }

    // Stop ? :
    if(TOUCHES[ECHAP])
    {
      relache_touche(ECHAP);
      return(STOP);
    }

    // Fin ? :
    tempo_demo--;
  }
  while(tempo_demo);
  return(SUITE);
}

/////////////////////
//                 //
// Procedure photo //
//                 //
/////////////////////
Vide photo(Vide)
{
  Octet  l,m,n;
  Entier o;

  // Une zolie photo jaunie :
  palette_jaunie(PALETTE_A,PALETTE_B);
  fade(PALETTE_A,PALETTE_B);

  // Cherche la couleur la plus sombre :
  n=255;
  l=PALETTES[PALETTE_A+255*3];
  for(m=0,o=PALETTE_A;m<255;m++,o+=3)
    if(PALETTES[o]<l)
    {
      l=PALETTES[o];
      n=m;
    }

  // Zoom et rotation :
  change_bordure(n);
  for(m=0;m<64;m++)
    aff_image_ZR(65536L+(m<<9),m>>1,n);

  // Une petite pause :
  for(m=35;m>0;m--)
    retour_balayage();

  // "efface" l'ecran :
  cre_palette_unie(PALETTE_B,63,32,32);
  fade(PALETTE_A,PALETTE_B);
}

/////////////////////////
//                     //
// Programme principal //
//                     //
/////////////////////////
Vide main(Vide)
{
  Octet      ancien_mode;
  Vide far*  touche_normale;

  Fichier    fichier;
  Objet far* objet;

  Flottant   x,y,z;
  Angle      Rx,Ry,Rz;

  Flottant   x_cam,y_cam,z_cam,dist_cam;
  Angle      R_cam;

  Flottant   xc1,yc1,xc2,yc2;
  Octet      d1,d2,d3,d4,d5,d6,d7;

  // Detourne les touches :
  touche_normale=lit_clavier();
  init_touches();
  change_clavier(touche_detourne);

  // Initialisation du moteur :
  if(init_NRX())
  {
    // Lecture des textures :
    fichier=ouvre_fichier("TEXTURES.DAT",RD);
    if(!fichier)
    {
      cre_OBJ_TEXTURES();
      cre_vox();

      fichier=ouvre_fichier("NRX_4x4.DAT",RD);
      d1=0;
    }
    else
    {
      lit_fichier_XMS(fichier,
		      OBJ_TEXTURES_L*OBJ_TEXTURES_H+VOX_TEXTURES_L*VOX_TEXTURES_H*3,
		      TEXTURES);
      ferme_fichier(fichier);

      fichier=ouvre_fichier("OBJETS.DAT",RD);
      d1=1;
    }

    // Lecture des objets :
    if(!fichier)
    {
      aff_texte("ERREUR : Fichier $");
      if(!d1)
	aff_texte("NRX_4x4$");
      else
	aff_texte("OBJETS$");
      aff_texte(".DAT introuvable.\r\n$");
    }
    else
    {
      objet=lit_objets(fichier);
      ferme_fichier(fichier);

      if(!objet)
	aff_texte("ERREUR : Memoire conventionnelle insuffisante.\r\n$");
      else
      {
	// Initialisation de l'ecran :
	lit_palette(PALETTE_A);
	cre_palette_unie(PALETTE_B,0,0,0);
	fade(PALETTE_A,PALETTE_B);

	ancien_mode=lit_mode();
	met_mode(0x13);
	change_palette(PALETTE_A);

	// Presentation :
	logo();

	// "efface" l'ecran :
	cre_palette_unie(PALETTE_B,0,0,0);
	fade(PALETTE_A,PALETTE_B);

	// Affichage de la tete uniquement :
	change_bordure(0);

	place_soleil(-32,-32);

	xc1=(xo-20)*65536L;
	yc1=yo*65536L;
	xc2=(xo+20)*65536L;
	yc2=yo*65536L;

	d1=10;
	d2=0;
	d3=0;
	d4=0;

	do
	{
	  // Mouvement du fond :
	  if(!(hasard()&127))
	    d4^=1;
	  if(d4)
	    d5++;
	  else
	    d5--;

	  xc1+=SIN_FX[(Angle)(d6+64)]*3;
	  yc1+=SIN_FX[d6]*3;
	  d6++;
	  if((entier(xc1)>=xm)||(entier(yc1)>=ym))
	    d6+=4;

	  xc2+=SIN_FX[(Angle)(d7+64)]*2;
	  yc2+=SIN_FX[d7]*2;
	  d7++;
	  if((entier(xc2)>=xm)||(entier(yc2)>=ym))
	    d7+=4;

	  // Dessine le fond :
	  aff_inter(entier(xc1),entier(yc1),entier(xc2),entier(yc2),d5);

	  // Bouge la tete :
	  if(d3)
	    d2++;
	  else
	    d2--;
	  if(d2>63)
	    d3^=1;

	  // Place la tete :
	  place_objet(&objet[1],0,0,1.4*65536L,d2-40,(d2<<1)+64,0);

	  // Dessine la tete :
	  init_Z_BUFFER();
	  aff_objet(&objet[1]);

	  // Affichage ! :
	  aff_image();

	  // Changement de palette :
	  if(TOUCHES[F2])
	  {
	    relache_touche(F2);
	    d1=-1;
	  }

	  // Fade :
	  if(d1)
	  {
	    cre_palette_test(PALETTE_B,d1);
	    d1=0;
	    fade(PALETTE_A,PALETTE_B);
	  }
	}
	while(!TOUCHES[ECHAP]);
	relache_touche(ECHAP);

	// "efface" l'ecran :
	cre_palette_unie(PALETTE_B,63,32,32);
	fade(PALETTE_A,PALETTE_B);

	// Affichage du pirate :
	change_bordure(0);

	x=0;
	y=-0.6*65536L;
	z=2.5*65536L;
	Rx=0;
	Ry=150;
	Rz=0;

	xc1=0;
	yc1=0;

	d1=16;
	d2=0;
	d3=48;
	d4=0;
	d5=0;

	do
	{
	  // Deplacement :
	  if(TOUCHES[GAUCHE])
	    if(TOUCHES[ESPACE])
	      Rx-=2;
	    else
	      x-=0.1*65536L;
	  if(TOUCHES[DROITE])
	    if(TOUCHES[ESPACE])
	      Rx+=2;
	    else
	      x+=0.1*65536L;
	  if(TOUCHES[HAUT])
	    if(TOUCHES[ESPACE])
	      Ry+=2;
	    else
	      y+=0.1*65536L;
	  if(TOUCHES[BAS])
	    if(TOUCHES[ESPACE])
	      Ry-=2;
	    else
	      y-=0.1*65536L;
	  if(TOUCHES[CTRL])
	    if(TOUCHES[ESPACE])
	      Rz-=2;
	    else
	      z-=0.1*65536L;
	  if(TOUCHES[ALT])
	    if(TOUCHES[ESPACE])
	      Rz+=2;
	    else
	      z+=0.1*65536L;

	  // Mouvement du fond :
	  if(!(hasard()&127))
	    d2^=1;
	  if(d2)
	    d1++;
	  else
	    d1--;
	  xc1+=SIN_FX[(Angle)(d6+64)]<<1;
	  yc1+=SIN_FX[d6]<<1;
	  d6++;

	  // Dessine le fond :
	  aff_sprite_fond(xc1>>9,yc1>>9,0.8*65536L+(SIN_FX[d6]>>1),d1);

	  // Bouge les membres :
	  if(d5)
	    d4++;
	  else
	    d4--;
	  if(d4>63)
	    d5^=1;

	  // Place le bras gauche :
	  place_objet(&objet[5],-0.1*65536L,0.75*65536L,0,d4-32,0,50);
	  // Place le bras droit :
	  place_objet(&objet[4],0.1*65536L,0.75*65536L,0,32-d4,0,-50);
	  // Place la jambe gauche :
	  place_objet(&objet[3],-0.12*65536L,0.45*65536L,0,d4-32,0,0);
	  // Place la jambe droite :
	  place_objet(&objet[2],0.12*65536L,0.45*65536L,0,32-d4,0,0);
	  // Place la tete :
	  place_objet(&objet[1],0,1.05*65536L,0,0,d4-32,0);
	  // Place le pirate :
	  place_objet(&objet[0],x,y,z,Rx,Ry,Rz);

	  // Dessine le pirate :
	  init_Z_BUFFER();
	  aff_objet(&objet[0]);

	  // Affichage ! :
	  aff_image();

	  // Help :
	  if(TOUCHES[F1])
	  {
	    pose_curseur(10,10);
	    aff_texte("[F1]  Help          $");
	    pose_curseur(10,12);
	    aff_texte("[F2]  Change palette$");
	    pose_curseur(10,14);
	    aff_texte("[F3]  Debug         $");
	    while(TOUCHES[F1]);
	  }

	  // Debug :
	  if(TOUCHES[F3])
	  {
	    pose_curseur(1,1);
	    aff_texte("x =$");
	    aff_nombre(x);
	    pose_curseur(1,2);
	    aff_texte("y =$");
	    aff_nombre(y);
	    pose_curseur(1,3);
	    aff_texte("z =$");
	    aff_nombre(z);
	    pose_curseur(1,4);
	    aff_texte("Rx=$");
	    aff_nombre(Rx);
	    pose_curseur(1,5);
	    aff_texte("Ry=$");
	    aff_nombre(Ry);
	    pose_curseur(1,6);
	    aff_texte("Rz=$");
	    aff_nombre(Rz);
	    pose_curseur(1,7);
	    aff_texte("d =$");
	    aff_nombre(d4);
	    pose_curseur(1,8);
	    aff_texte("t =$");
	    aff_nombre(nb_touches);
	    while(TOUCHES[F3]);
	  }

	  // Changement de palette :
	  if(TOUCHES[F2])
	  {
	    relache_touche(F2);
	    d3=-1;
	  }

	  // Fade :
	  if(d3)
	  {
	    cre_palette_test(PALETTE_B,d3);
	    d3=0;
	    fade(PALETTE_A,PALETTE_B);
	  }
	}
	while(!TOUCHES[ECHAP]);
	relache_touche(ECHAP);

	// Neurones :
	change_bordure(32);

	init_neurones();

	d1=1;
	d2=0;

	do
	{
	  // Dessine les "neurones" :
	  aff_neurones();

	  // Affichage ! :
	  aff_image();

	  // Changement de palette :
	  if(TOUCHES[F2])
	  {
	    relache_touche(F2);
	    d1=1;
	    d2^=1;
	  }

	  // Fade :
	  if(d1)
	  {
	    d1=0;
	    if(d2)
	      cre_palette_pastel(PALETTE_B);
	    else
	      cre_palette_feu(PALETTE_B);
	    fade(PALETTE_A,PALETTE_B);
	  }
	}
	while(!TOUCHES[ECHAP]);
	relache_touche(ECHAP);

	fin_neurones();

	// "efface" l'ecran :
	cre_palette_unie(PALETTE_B,63,32,32);
	fade(PALETTE_A,PALETTE_B);

	// Tunnel :
	change_bordure(0);

	place_soleil(-64,0);
	init_tunnel();

	Rx=-16;
	Ry=160;
	Rz=0;

	d1=29;
	d2=0;

	do
	{
	  // Bouge dans le tunnel :
	  d3++;

	  // Dessine le tunnel :
	  aff_tunnel(d3,d3*2);

	  // Deplace la voiture :
	  d4--;

	  if(nb_touches)
	  {
	    d2=200;

	    if(TOUCHES[GAUCHE])
	      Rx-=2;
	    if(TOUCHES[DROITE])
	      Rx+=2;
	    if(TOUCHES[HAUT])
	      Ry+=2;
	    if(TOUCHES[BAS])
	      Ry-=2;
	    if(TOUCHES[CTRL])
	      Rz-=2;
	    if(TOUCHES[ALT])
	      Rz+=2;
	  }
	  else
	    if(d2)
	      d2--;
	    else
	    {
	      Rx++;
	      Ry+=2;
	      Rz++;
	    }

	  // Place la voiture :
	  place_objet(&objet[7],-0.7*65536L,0.36*65536L,1.8*65536L,d4,0,0);
	  place_objet(&objet[8],0.7*65536L,0.36*65536L,1.8*65536L,d4,0,0);
	  place_objet(&objet[9],-0.7*65536L,0.36*65536L,0,d4,0,0);
	  place_objet(&objet[10],0.7*65536L,0.36*65536L,0,d4,0,0);
	  place_objet(&objet[6],0,0,10*65536L,Rx,Ry,Rz);

	  // Dessine la voiture :
	  init_Z_BUFFER();
	  aff_objet(&objet[6]);

	  // Affichage ! :
	  aff_image();

	  // Changement de palette :
	  if(TOUCHES[F2])
	  {
	    relache_touche(F2);
	    d1=-1;
	  }

	  // Fade :
	  if(d1)
	  {
	    cre_palette_test(PALETTE_B,d1);
	    d1=0;
	    fade(PALETTE_A,PALETTE_B);
	  }
	}
	while(!TOUCHES[ECHAP]);
	relache_touche(ECHAP);

	// Photo ! :
	photo();

	// Voxel spacing... :
	change_bordure(0);

	place_soleil(48,0);
	ombrage_vox();

	x=0;
	z=0;
	Ry=64;
	R_cam=96;
	dist_cam=14.0*65536L;

	d1=55;
	d2=0;
	d3=0;
	d7=0;

	do
	{
	  // Accelerateur :
	  if(TOUCHES[HAUT])
	  {
	    if((OctetS)d2<95)
	      d2+=2;
	    else
	      d2=95;
	  }
	  else
	    if(TOUCHES[BAS])
	    {
	      if((OctetS)d2>-48)
		d2-=2;
	    }
	    else
	      if((OctetS)d2<0)
		d2++;
	      else
		if((OctetS)d2>0)
		  d2--;

	  // Volant :
	  if((OctetS)d2>0)
	    d5=12-(d2>>3);
	  else
	    d5=12+((OctetS)d2>>3);

	  if(TOUCHES[GAUCHE])
	  {
	    if((OctetS)d3<(OctetS)d5)
	      d3+=2;
	    else
	      d3=d5;
	  }
	  else
	    if(TOUCHES[DROITE])
	    {
	      if((OctetS)d3>-(OctetS)d5)
		d3-=2;
	      else
		d3=-d5;
	    }
	    else
	      if((OctetS)d3<0)
		d3++;
	      else
		if((OctetS)d3>0)
		  d3--;

	  // Avance :
	  x+=(OctetS)d2*SIN_FX[Ry]>>6;
	  z-=(OctetS)d2*SIN_FX[(Angle)(Ry+64)]>>6;

	  if((OctetS)(d2^d3)>0)
	    Ry-=((OctetS)d2*(OctetS)d3)>>6;
	  else
	    Ry+=(-(OctetS)d2*(OctetS)d3)>>6;

	  d4-=d2;

	  // Pose la voiture sur la piste :
	  y=moy_hauteurs_vox(x,z);

	  Rx=(moy_hauteurs_vox(x+2*SIN_FX[Ry],z-2*SIN_FX[(Angle)(Ry+64)])-y)
	      >>(16-4);

	  Rz=(moy_hauteurs_vox(x-SIN_FX[(Angle)(Ry+64)],z-SIN_FX[Ry])-
	      moy_hauteurs_vox(x+SIN_FX[(Angle)(Ry+64)],z+SIN_FX[Ry]))
	      >>(16-4);

	  if((OctetS)Rx>0)
	    d2-=(OctetS)Rx>>2;
	  else
	    d2+=-(OctetS)Rx>>2;

	  // Place la camera derriere la voiture :
	  if(TOUCHES[ALT])
	    if(dist_cam<30*65536L)
	      dist_cam+=0.2*65536L;
	  if(TOUCHES[CTRL])
	    if(dist_cam>4*65536L)
	      dist_cam-=0.2*65536L;

	  if(nb_touches)
	    d7=100;

	  if(d7)
	  {
	    d7--;

	    if(R_cam!=Ry)
	      if((OctetS)(R_cam-Ry)<0)
		R_cam++;
	      else
		R_cam--;
	  }
	  else
	    R_cam++;

	  x_cam=x-mul_fx(dist_cam,SIN_FX[R_cam]);
	  z_cam=z+mul_fx(dist_cam,SIN_FX[(Angle)(R_cam+64)]);
	  y_cam=moy_hauteurs_vox(x_cam,z_cam)+(dist_cam>>2);

	  // Place la voiture :
	  place_objet(&objet[7],-0.7*65536L,0.36*65536L,1.8*65536L,d4,d3*2,0);
	  place_objet(&objet[8],0.7*65536L,0.36*65536L,1.8*65536L,d4,d3*2,0);
	  place_objet(&objet[9],-0.7*65536L,0.36*65536L,0,d4,0,0);
	  place_objet(&objet[10],0.7*65536L,0.36*65536L,0,d4,0,0);
	  place_objet_XZY(&objet[6],0,y-y_cam,dist_cam,Rx,R_cam-Ry,Rz);

	  // Dessine le decor :
	  aff_vox(x_cam,y_cam,z_cam,R_cam);

	  // Dessine la voiture :
	  place_soleil(48,-R_cam);
	  aff_objet(&objet[6]);

	  // Affichage ! :
	  aff_image();

	  // Changement de palette :
	  if(TOUCHES[F2])
	  {
	    relache_touche(F2);
	    d1=-1;
	  }

	  // Fade :
	  if(d1)
	  {
	    cre_palette_test(PALETTE_B,d1);
	    d1=0;
	    fade(PALETTE_A,PALETTE_B);
	  }
	}
	while(!TOUCHES[ECHAP]);
	relache_touche(ECHAP);

	// Photo ! :
	photo();

	// Un peu de feu :
	change_bordure(32);

	init_feu();

	d2=1;
	d3=0;
	d4=0;

	do
	{
	  // Dessine le feu :
	  aff_feu();

	  // Changement de palette :
	  if(TOUCHES[F2])
	  {
	    relache_touche(F2);
	    d3=0;
	  }
	  if(!d3)
	  {
	    d1=1;
	    d2^=1;
	  }
	  d3++;

	  // Affichage ! :
	  if(d4|d2)
	  {
	    aff_image_ZR(65536L-abs_fx(SIN_FX[d4]>>1),d4<<1,32);
	    d4++;
	  }
	  else
	    aff_image();

	  // Fade :
	  if(d1)
	  {
	    d1=0;
	    if(d2)
	      cre_palette_pastel(PALETTE_B);
	    else
	      cre_palette_feu(PALETTE_B);
	    fade(PALETTE_A,PALETTE_B);
	  }
	}
	while(!TOUCHES[ECHAP]);

	// Bye-bye :
	cre_palette_unie(PALETTE_B,0,0,0);
	fade(PALETTE_A,PALETTE_B);

	efface_image(0);
	aff_image();
	pose_curseur(12,1);
	aff_texte("B Y E - B Y E  !$");
	etire_ecran(14);

	PALETTES[PALETTE_B+7*3+0]=63;
	PALETTES[PALETTE_B+7*3+1]=32;
	PALETTES[PALETTE_B+7*3+2]=32;
	fade(PALETTE_A,PALETTE_B);

	for(d1=70;d1>0;d1--)
	  retour_balayage();

	// Retour a l'ancien mode :
	cre_palette_unie(PALETTE_B,0,0,0);
	fade(PALETTE_A,PALETTE_B);

	met_mode(ancien_mode);
	lit_palette(PALETTE_B);
	change_palette(PALETTE_A);
	aff_texte("Nicolas ROBERT [NRX 98]\r\n$");
	fade(PALETTE_A,PALETTE_B);

	// Libere la memoire reservee pour les objets :
	liber_DOS(objet);
      }
    }

    // Libere le reste de la memoire (XMS et conventionnelle) :
    fin_NRX();
  }

  // Ancien gestionnaire de clavier :
  change_clavier(touche_normale);
}