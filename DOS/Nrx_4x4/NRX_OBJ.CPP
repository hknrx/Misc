//////////////////
//       	//
// Bibliotheque //
//       	//
//////////////////
#include <stdio.h>

///////////////////////////
//       		 //
// Definitions des types //
//       		 //
///////////////////////////
typedef void 	      Vide;
typedef unsigned char Octet;
typedef unsigned int  Entier;
typedef int 	      EntierS;
typedef unsigned long Long;
typedef long 	      Flottant;

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

/////////////////////////
//                     //
// Programme principal //
//                     //
/////////////////////////
Vide main(Vide)
{
  FILE*  fichier;
  Entier total;
  Octet  n;

  Octet  nb_objets=6+5;
  Octet  nb_boules=2+1;
  Octet  nb_pts=28+42;
  Octet  nb_polys=21+35;
  Octet  nb_num_pts=81+150;

/**********/
/*        */
/* OBJETS */
/*        */
/**********/

  Objet objet[6+5];
  Boule boule[2+1];
  Point pt[28+42];
  Poly  poly[21+35];
  Octet num_pt[81+150]={1,3,0,
			2,3,1,
			0,2,1,

			0,1,5,4,
			1,2,6,5,
			2,3,7,6,
			3,0,4,7,
			10,9,5,6,
			4,8,11,7,
			6,7,11,10,
			9,10,11,8,
			5,9,8,4,

			0,1,5,4,
			1,2,6,5,
			2,3,7,6,
			3,0,4,7,
			4,5,9,8,
			5,6,10,9,
			6,7,11,10,
			7,4,8,11,
			8,9,10,11,

			0,1,4,5,
			1,2,3,4,
			2,12,15,3,
			12,13,14,15,
			13,29,30,14,
			33,32,27,26,
			32,31,28,27,
			31,30,29,28,
			15,14,30,31,
			13,12,28,29,
			15,31,32,24,20,16,8,4,3,
			27,28,12,2,1,7,11,19,23,
			5,4,8,9,
			17,16,20,21,
			32,33,25,24,
			1,0,6,7,
			11,10,18,19,
			23,22,26,27,
			0,5,9,35,34,6,
			36,17,21,39,38,18,10,37,
			25,33,26,22,41,40,
			34,35,36,37,
			38,39,40,41,
			35,9,8,
			16,36,35,8,
			16,17,36,
			7,6,34,
			7,34,37,11,
			37,10,11,
			39,21,20,
			24,40,39,20,
			24,25,40,
			19,18,38,
			19,38,41,23,
			41,22,23};

  ////////////
  //        //
  // Pirate //
  //        //
  ////////////

  // Objet pirate :
  objet[0+0].nb_boules=1;
  objet[0+0].boule=(Boule far*)(0+0);
  objet[0+0].nb_pts=0;
  objet[0+0].nb_polys=0;
  objet[0+0].nb_sous_objets=5;
  objet[0+0].sous_objet=(Objet far*)(1+0);

  // Sous-objet tete :
  objet[1+0].nb_boules=1;
  objet[1+0].boule=(Boule far*)(0+1);
  objet[1+0].nb_pts=4;
  objet[1+0].pt=(Point far*)(0+0);
  objet[1+0].nb_polys=3;
  objet[1+0].poly=(Poly far*)(0+0);
  objet[1+0].nb_sous_objets=0;

  // Sous-objet jambe droite :
  objet[2+0].nb_boules=0;
  objet[2+0].nb_pts=12;
  objet[2+0].pt=(Point far*)(0+4);
  objet[2+0].nb_polys=9;
  objet[2+0].poly=(Poly far*)(0+3);
  objet[2+0].nb_sous_objets=0;

  // Sous-objet jambe gauche :
  objet[3+0].nb_boules=0;
  objet[3+0].nb_pts=12;
  objet[3+0].pt=(Point far*)(0+4);
  objet[3+0].nb_polys=9;
  objet[3+0].poly=(Poly far*)(0+3);
  objet[3+0].nb_sous_objets=0;

  // Sous-objet bras droit :
  objet[4+0].nb_boules=0;
  objet[4+0].nb_pts=12;
  objet[4+0].pt=(Point far*)(0+16);
  objet[4+0].nb_polys=9;
  objet[4+0].poly=(Poly far*)(0+12);
  objet[4+0].nb_sous_objets=0;

  // Sous-objet bras gauche :
  objet[5+0].nb_boules=0;
  objet[5+0].nb_pts=12;
  objet[5+0].pt=(Point far*)(0+16);
  objet[5+0].nb_polys=9;
  objet[5+0].poly=(Poly far*)(0+12);
  objet[5+0].nb_sous_objets=0;

  // Corps du pirate :
  boule[0+0].pt.x3D_O=0.0*65536L;
  boule[0+0].pt.y3D_O=0.6*65536L;
  boule[0+0].pt.z3D_O=0.0*65536L;
  boule[0+0].r=0.25*65536L;
  boule[0+0].deforme_x=1.0*65536L;
  boule[0+0].deforme_y=0.9*65536L;
  boule[0+0].deforme_z=1.0*65536L;
  boule[0+0].texture=0;

  // Tete du pirate :
  boule[0+1].pt.x3D_O=0.0*65536L;
  boule[0+1].pt.y3D_O=0.0*65536L;
  boule[0+1].pt.z3D_O=0.0*65536L;
  boule[0+1].r=0.25*65536L;
  boule[0+1].deforme_x=1.0*65536L;
  boule[0+1].deforme_y=1.0*65536L;
  boule[0+1].deforme_z=1.0*65536L;
  boule[0+1].texture=0;

  // Nez du pirate :
  pt[0+0].x3D_O=-0.03*65536L;
  pt[0+0].y3D_O=-0.05*65536L;
  pt[0+0].z3D_O=0.24*65536L;
  pt[1+0].x3D_O=0.0*65536L;
  pt[1+0].y3D_O=-0.05*65536L;
  pt[1+0].z3D_O=0.3*65536L;
  pt[2+0].x3D_O=0.03*65536L;
  pt[2+0].y3D_O=-0.05*65536L;
  pt[2+0].z3D_O=0.24*65536L;
  pt[3+0].x3D_O=0.0*65536L;
  pt[3+0].y3D_O=0.1*65536L;
  pt[3+0].z3D_O=0.23*65536L;

  poly[0+0].nb_pts=3;
  poly[0+0].num_pt=(Octet far*)(0+0);
  poly[0+0].texture=0;
  poly[1+0].nb_pts=3;
  poly[1+0].num_pt=(Octet far*)(3+0);
  poly[1+0].texture=0;
  poly[2+0].nb_pts=3;
  poly[2+0].num_pt=(Octet far*)(6+0);
  poly[2+0].texture=0;

  // Jambe du pirate :
  pt[0+4].x3D_O=-0.08*65536L;
  pt[0+4].y3D_O=0.0*65536L;
  pt[0+4].z3D_O=-0.08*65536L;
  pt[1+4].x3D_O=0.08*65536L;
  pt[1+4].y3D_O=0.0*65536L;
  pt[1+4].z3D_O=-0.08*65536L;
  pt[2+4].x3D_O=0.08*65536L;
  pt[2+4].y3D_O=0.0*65536L;
  pt[2+4].z3D_O=0.08*65536L;
  pt[3+4].x3D_O=-0.08*65536L;
  pt[3+4].y3D_O=0.0*65536L;
  pt[3+4].z3D_O=0.08*65536L;
  pt[4+4].x3D_O=-0.08*65536L;
  pt[4+4].y3D_O=-0.45*65536L;
  pt[4+4].z3D_O=-0.08*65536L;
  pt[5+4].x3D_O=0.08*65536L;
  pt[5+4].y3D_O=-0.45*65536L;
  pt[5+4].z3D_O=-0.08*65536L;
  pt[6+4].x3D_O=0.08*65536L;
  pt[6+4].y3D_O=-0.35*65536L;
  pt[6+4].z3D_O=0.08*65536L;
  pt[7+4].x3D_O=-0.08*65536L;
  pt[7+4].y3D_O=-0.35*65536L;
  pt[7+4].z3D_O=0.08*65536L;
  pt[8+4].x3D_O=-0.08*65536L;
  pt[8+4].y3D_O=-0.45*65536L;
  pt[8+4].z3D_O=0.2*65536L;
  pt[9+4].x3D_O=0.08*65536L;
  pt[9+4].y3D_O=-0.45*65536L;
  pt[9+4].z3D_O=0.2*65536L;
  pt[10+4].x3D_O=0.08*65536L;
  pt[10+4].y3D_O=-0.4*65536L;
  pt[10+4].z3D_O=0.2*65536L;
  pt[11+4].x3D_O=-0.08*65536L;
  pt[11+4].y3D_O=-0.4*65536L;
  pt[11+4].z3D_O=0.2*65536L;

  poly[0+3].nb_pts=4;
  poly[0+3].num_pt=(Octet far*)(0+9);
  poly[0+3].texture=0;
  poly[1+3].nb_pts=4;
  poly[1+3].num_pt=(Octet far*)(4+9);
  poly[1+3].texture=0;
  poly[2+3].nb_pts=4;
  poly[2+3].num_pt=(Octet far*)(8+9);
  poly[2+3].texture=0;
  poly[3+3].nb_pts=4;
  poly[3+3].num_pt=(Octet far*)(12+9);
  poly[3+3].texture=0;
  poly[4+3].nb_pts=4;
  poly[4+3].num_pt=(Octet far*)(16+9);
  poly[4+3].texture=0;
  poly[5+3].nb_pts=4;
  poly[5+3].num_pt=(Octet far*)(20+9);
  poly[5+3].texture=0;
  poly[6+3].nb_pts=4;
  poly[6+3].num_pt=(Octet far*)(24+9);
  poly[6+3].texture=0;
  poly[7+3].nb_pts=4;
  poly[7+3].num_pt=(Octet far*)(28+9);
  poly[7+3].texture=0;
  poly[8+3].nb_pts=4;
  poly[8+3].num_pt=(Octet far*)(32+9);
  poly[8+3].texture=0;

  // Bras du pirate :
  pt[0+16].x3D_O=-0.06*65536L;
  pt[0+16].y3D_O=0.0*65536L;
  pt[0+16].z3D_O=-0.06*65536L;
  pt[1+16].x3D_O=0.06*65536L;
  pt[1+16].y3D_O=0.0*65536L;
  pt[1+16].z3D_O=-0.06*65536L;
  pt[2+16].x3D_O=0.06*65536L;
  pt[2+16].y3D_O=0.0*65536L;
  pt[2+16].z3D_O=0.06*65536L;
  pt[3+16].x3D_O=-0.06*65536L;
  pt[3+16].y3D_O=0.0*65536L;
  pt[3+16].z3D_O=0.06*65536L;
  pt[4+16].x3D_O=-0.1*65536L;
  pt[4+16].y3D_O=-0.45*65536L;
  pt[4+16].z3D_O=-0.08*65536L;
  pt[5+16].x3D_O=0.08*65536L;
  pt[5+16].y3D_O=-0.45*65536L;
  pt[5+16].z3D_O=-0.08*65536L;
  pt[6+16].x3D_O=0.08*65536L;
  pt[6+16].y3D_O=-0.45*65536L;
  pt[6+16].z3D_O=0.08*65536L;
  pt[7+16].x3D_O=-0.08*65536L;
  pt[7+16].y3D_O=-0.45*65536L;
  pt[7+16].z3D_O=0.08*65536L;
  pt[8+16].x3D_O=-0.03*65536L;
  pt[8+16].y3D_O=-0.5*65536L;
  pt[8+16].z3D_O=-0.03*65536L;
  pt[9+16].x3D_O=0.03*65536L;
  pt[9+16].y3D_O=-0.5*65536L;
  pt[9+16].z3D_O=-0.03*65536L;
  pt[10+16].x3D_O=0.03*65536L;
  pt[10+16].y3D_O=-0.5*65536L;
  pt[10+16].z3D_O=0.03*65536L;
  pt[11+16].x3D_O=-0.03*65536L;
  pt[11+16].y3D_O=-0.5*65536L;
  pt[11+16].z3D_O=0.03*65536L;

  poly[0+12].nb_pts=4;
  poly[0+12].num_pt=(Octet far*)(0+45);
  poly[0+12].texture=0;
  poly[1+12].nb_pts=4;
  poly[1+12].num_pt=(Octet far*)(4+45);
  poly[1+12].texture=0;
  poly[2+12].nb_pts=4;
  poly[2+12].num_pt=(Octet far*)(8+45);
  poly[2+12].texture=0;
  poly[3+12].nb_pts=4;
  poly[3+12].num_pt=(Octet far*)(12+45);
  poly[3+12].texture=0;
  poly[4+12].nb_pts=4;
  poly[4+12].num_pt=(Octet far*)(16+45);
  poly[4+12].texture=0;
  poly[5+12].nb_pts=4;
  poly[5+12].num_pt=(Octet far*)(20+45);
  poly[5+12].texture=0;
  poly[6+12].nb_pts=4;
  poly[6+12].num_pt=(Octet far*)(24+45);
  poly[6+12].texture=0;
  poly[7+12].nb_pts=4;
  poly[7+12].num_pt=(Octet far*)(28+45);
  poly[7+12].texture=0;
  poly[8+12].nb_pts=4;
  poly[8+12].num_pt=(Octet far*)(32+45);
  poly[8+12].texture=0;

  /////////
  //     //
  // 4x4 //
  //     //
  /////////

  // Objet 4x4 :
  objet[0+6].nb_boules=0;
  objet[0+6].nb_pts=42;
  objet[0+6].pt=(Point far*)(0+28);
  objet[0+6].nb_polys=35;
  objet[0+6].poly=(Poly far*)(0+21);
  objet[0+6].nb_sous_objets=4;
  objet[0+6].sous_objet=(Objet far*)(1+6);

  // Sous-objet roue AV-GA :
  objet[1+6].nb_boules=1;
  objet[1+6].boule=(Boule far*)(0+2);
  objet[1+6].nb_pts=0;
  objet[1+6].nb_polys=0;
  objet[1+6].nb_sous_objets=0;

  // Sous-objet roue AV-DR :
  objet[2+6].nb_boules=1;
  objet[2+6].boule=(Boule far*)(0+2);
  objet[2+6].nb_pts=0;
  objet[2+6].nb_polys=0;
  objet[2+6].nb_sous_objets=0;

  // Sous-objet roue AR-GA :
  objet[3+6].nb_boules=1;
  objet[3+6].boule=(Boule far*)(0+2);
  objet[3+6].nb_pts=0;
  objet[3+6].nb_polys=0;
  objet[3+6].nb_sous_objets=0;

  // Sous-objet roue AR-DR :
  objet[4+6].nb_boules=1;
  objet[4+6].boule=(Boule far*)(0+2);
  objet[4+6].nb_pts=0;
  objet[4+6].nb_polys=0;
  objet[4+6].nb_sous_objets=0;

  // Caisse :
  pt[0+28].x3D_O=0.7*65536L;
  pt[0+28].y3D_O=0.46*65536L;
  pt[0+28].z3D_O=2.4*65536L;
  pt[1+28].x3D_O=0.8*65536L;
  pt[1+28].y3D_O=0.86*65536L;
  pt[1+28].z3D_O=2.5*65536L;
  pt[2+28].x3D_O=0.8*65536L;
  pt[2+28].y3D_O=1.16*65536L;
  pt[2+28].z3D_O=2.3*65536L;
  pt[3+28].x3D_O=-0.8*65536L;
  pt[3+28].y3D_O=1.16*65536L;
  pt[3+28].z3D_O=2.3*65536L;
  pt[4+28].x3D_O=-0.8*65536L;
  pt[4+28].y3D_O=0.86*65536L;
  pt[4+28].z3D_O=2.5*65536L;
  pt[5+28].x3D_O=-0.7*65536L;
  pt[5+28].y3D_O=0.46*65536L;
  pt[5+28].z3D_O=2.4*65536L;
  pt[6+28].x3D_O=0.7*65536L;
  pt[6+28].y3D_O=0.46*65536L;
  pt[6+28].z3D_O=2.2*65536L;
  pt[7+28].x3D_O=0.8*65536L;
  pt[7+28].y3D_O=0.86*65536L;
  pt[7+28].z3D_O=2.1*65536L;
  pt[8+28].x3D_O=-0.8*65536L;
  pt[8+28].y3D_O=0.86*65536L;
  pt[8+28].z3D_O=2.1*65536L;
  pt[9+28].x3D_O=-0.7*65536L;
  pt[9+28].y3D_O=0.46*65536L;
  pt[9+28].z3D_O=2.2*65536L;
  pt[10+28].x3D_O=0.7*65536L;
  pt[10+28].y3D_O=0.46*65536L;
  pt[10+28].z3D_O=1.4*65536L;
  pt[11+28].x3D_O=0.8*65536L;
  pt[11+28].y3D_O=0.86*65536L;
  pt[11+28].z3D_O=1.5*65536L;
  pt[12+28].x3D_O=0.8*65536L;
  pt[12+28].y3D_O=1.36*65536L;
  pt[12+28].z3D_O=1.5*65536L;
  pt[13+28].x3D_O=0.6*65536L;
  pt[13+28].y3D_O=1.76*65536L;
  pt[13+28].z3D_O=1.2*65536L;
  pt[14+28].x3D_O=-0.6*65536L;
  pt[14+28].y3D_O=1.76*65536L;
  pt[14+28].z3D_O=1.2*65536L;
  pt[15+28].x3D_O=-0.8*65536L;
  pt[15+28].y3D_O=1.36*65536L;
  pt[15+28].z3D_O=1.5*65536L;
  pt[16+28].x3D_O=-0.8*65536L;
  pt[16+28].y3D_O=0.86*65536L;
  pt[16+28].z3D_O=1.5*65536L;
  pt[17+28].x3D_O=-0.7*65536L;
  pt[17+28].y3D_O=0.46*65536L;
  pt[17+28].z3D_O=1.4*65536L;
  pt[18+28].x3D_O=0.7*65536L;
  pt[18+28].y3D_O=0.46*65536L;
  pt[18+28].z3D_O=0.4*65536L;
  pt[19+28].x3D_O=0.8*65536L;
  pt[19+28].y3D_O=0.86*65536L;
  pt[19+28].z3D_O=0.3*65536L;
  pt[20+28].x3D_O=-0.8*65536L;
  pt[20+28].y3D_O=0.86*65536L;
  pt[20+28].z3D_O=0.3*65536L;
  pt[21+28].x3D_O=-0.7*65536L;
  pt[21+28].y3D_O=0.46*65536L;
  pt[21+28].z3D_O=0.4*65536L;
  pt[22+28].x3D_O=0.7*65536L;
  pt[22+28].y3D_O=0.46*65536L;
  pt[22+28].z3D_O=-0.4*65536L;
  pt[23+28].x3D_O=0.8*65536L;
  pt[23+28].y3D_O=0.86*65536L;
  pt[23+28].z3D_O=-0.3*65536L;
  pt[24+28].x3D_O=-0.8*65536L;
  pt[24+28].y3D_O=0.86*65536L;
  pt[24+28].z3D_O=-0.3*65536L;
  pt[25+28].x3D_O=-0.7*65536L;
  pt[25+28].y3D_O=0.46*65536L;
  pt[25+28].z3D_O=-0.4*65536L;
  pt[26+28].x3D_O=0.7*65536L;
  pt[26+28].y3D_O=0.46*65536L;
  pt[26+28].z3D_O=-0.6*65536L;
  pt[27+28].x3D_O=0.8*65536L;
  pt[27+28].y3D_O=0.86*65536L;
  pt[27+28].z3D_O=-0.7*65536L;
  pt[28+28].x3D_O=0.8*65536L;
  pt[28+28].y3D_O=1.36*65536L;
  pt[28+28].z3D_O=-0.7*65536L;
  pt[29+28].x3D_O=0.6*65536L;
  pt[29+28].y3D_O=1.76*65536L;
  pt[29+28].z3D_O=-0.5*65536L;
  pt[30+28].x3D_O=-0.6*65536L;
  pt[30+28].y3D_O=1.76*65536L;
  pt[30+28].z3D_O=-0.5*65536L;
  pt[31+28].x3D_O=-0.8*65536L;
  pt[31+28].y3D_O=1.36*65536L;
  pt[31+28].z3D_O=-0.7*65536L;
  pt[32+28].x3D_O=-0.8*65536L;
  pt[32+28].y3D_O=0.86*65536L;
  pt[32+28].z3D_O=-0.7*65536L;
  pt[33+28].x3D_O=-0.7*65536L;
  pt[33+28].y3D_O=0.46*65536L;
  pt[33+28].z3D_O=-0.6*65536L;
  pt[34+28].x3D_O=0.4*65536L;
  pt[34+28].y3D_O=0.46*65536L;
  pt[34+28].z3D_O=2.1*65536L;
  pt[35+28].x3D_O=-0.4*65536L;
  pt[35+28].y3D_O=0.46*65536L;
  pt[35+28].z3D_O=2.1*65536L;
  pt[36+28].x3D_O=-0.4*65536L;
  pt[36+28].y3D_O=0.46*65536L;
  pt[36+28].z3D_O=1.5*65536L;
  pt[37+28].x3D_O=0.4*65536L;
  pt[37+28].y3D_O=0.46*65536L;
  pt[37+28].z3D_O=1.5*65536L;
  pt[38+28].x3D_O=0.4*65536L;
  pt[38+28].y3D_O=0.46*65536L;
  pt[38+28].z3D_O=0.3*65536L;
  pt[39+28].x3D_O=-0.4*65536L;
  pt[39+28].y3D_O=0.46*65536L;
  pt[39+28].z3D_O=0.3*65536L;
  pt[40+28].x3D_O=-0.4*65536L;
  pt[40+28].y3D_O=0.46*65536L;
  pt[40+28].z3D_O=-0.3*65536L;
  pt[41+28].x3D_O=0.4*65536L;
  pt[41+28].y3D_O=0.46*65536L;
  pt[41+28].z3D_O=-0.3*65536L;

  poly[0+21].nb_pts=4;
  poly[0+21].num_pt=(Octet far*)(0+81);
  poly[0+21].texture=0;
  poly[1+21].nb_pts=4;
  poly[1+21].num_pt=(Octet far*)(4+81);
  poly[1+21].texture=0;
  poly[2+21].nb_pts=4;
  poly[2+21].num_pt=(Octet far*)(8+81);
  poly[2+21].texture=0;
  poly[3+21].nb_pts=4;
  poly[3+21].num_pt=(Octet far*)(12+81);
  poly[3+21].texture=0;
  poly[4+21].nb_pts=4;
  poly[4+21].num_pt=(Octet far*)(16+81);
  poly[4+21].texture=0;
  poly[5+21].nb_pts=4;
  poly[5+21].num_pt=(Octet far*)(20+81);
  poly[5+21].texture=0;
  poly[6+21].nb_pts=4;
  poly[6+21].num_pt=(Octet far*)(24+81);
  poly[6+21].texture=0;
  poly[7+21].nb_pts=4;
  poly[7+21].num_pt=(Octet far*)(28+81);
  poly[7+21].texture=0;
  poly[8+21].nb_pts=4;
  poly[8+21].num_pt=(Octet far*)(32+81);
  poly[8+21].texture=0;
  poly[9+21].nb_pts=4;
  poly[9+21].num_pt=(Octet far*)(36+81);
  poly[9+21].texture=0;
  poly[10+21].nb_pts=9;
  poly[10+21].num_pt=(Octet far*)(40+81);
  poly[10+21].texture=0;
  poly[11+21].nb_pts=9;
  poly[11+21].num_pt=(Octet far*)(49+81);
  poly[11+21].texture=0;
  poly[12+21].nb_pts=4;
  poly[12+21].num_pt=(Octet far*)(58+81);
  poly[12+21].texture=0;
  poly[13+21].nb_pts=4;
  poly[13+21].num_pt=(Octet far*)(62+81);
  poly[13+21].texture=0;
  poly[14+21].nb_pts=4;
  poly[14+21].num_pt=(Octet far*)(66+81);
  poly[14+21].texture=0;
  poly[15+21].nb_pts=4;
  poly[15+21].num_pt=(Octet far*)(70+81);
  poly[15+21].texture=0;
  poly[16+21].nb_pts=4;
  poly[16+21].num_pt=(Octet far*)(74+81);
  poly[16+21].texture=0;
  poly[17+21].nb_pts=4;
  poly[17+21].num_pt=(Octet far*)(78+81);
  poly[17+21].texture=0;
  poly[18+21].nb_pts=6;
  poly[18+21].num_pt=(Octet far*)(82+81);
  poly[18+21].texture=0;
  poly[19+21].nb_pts=8;
  poly[19+21].num_pt=(Octet far*)(88+81);
  poly[19+21].texture=0;
  poly[20+21].nb_pts=6;
  poly[20+21].num_pt=(Octet far*)(96+81);
  poly[20+21].texture=0;
  poly[21+21].nb_pts=4;
  poly[21+21].num_pt=(Octet far*)(102+81);
  poly[21+21].texture=0;
  poly[22+21].nb_pts=4;
  poly[22+21].num_pt=(Octet far*)(106+81);
  poly[22+21].texture=0;
  poly[23+21].nb_pts=3;
  poly[23+21].num_pt=(Octet far*)(110+81);
  poly[23+21].texture=0;
  poly[24+21].nb_pts=4;
  poly[24+21].num_pt=(Octet far*)(113+81);
  poly[24+21].texture=0;
  poly[25+21].nb_pts=3;
  poly[25+21].num_pt=(Octet far*)(117+81);
  poly[25+21].texture=0;
  poly[26+21].nb_pts=3;
  poly[26+21].num_pt=(Octet far*)(120+81);
  poly[26+21].texture=0;
  poly[27+21].nb_pts=4;
  poly[27+21].num_pt=(Octet far*)(123+81);
  poly[27+21].texture=0;
  poly[28+21].nb_pts=3;
  poly[28+21].num_pt=(Octet far*)(127+81);
  poly[28+21].texture=0;
  poly[29+21].nb_pts=3;
  poly[29+21].num_pt=(Octet far*)(130+81);
  poly[29+21].texture=0;
  poly[30+21].nb_pts=4;
  poly[30+21].num_pt=(Octet far*)(133+81);
  poly[30+21].texture=0;
  poly[31+21].nb_pts=3;
  poly[31+21].num_pt=(Octet far*)(137+81);
  poly[31+21].texture=0;
  poly[32+21].nb_pts=3;
  poly[32+21].num_pt=(Octet far*)(140+81);
  poly[32+21].texture=0;
  poly[33+21].nb_pts=4;
  poly[33+21].num_pt=(Octet far*)(143+81);
  poly[33+21].texture=0;
  poly[34+21].nb_pts=3;
  poly[34+21].num_pt=(Octet far*)(147+81);
  poly[34+21].texture=0;

  // Roue de 4x4 :
  boule[0+2].pt.x3D_O=0.0*65536L;
  boule[0+2].pt.y3D_O=0.0*65536L;
  boule[0+2].pt.z3D_O=0.0*65536L;
  boule[0+2].r=0.18*65536L;
  boule[0+2].deforme_x=1.0*65536L;
  boule[0+2].deforme_y=0.5*65536L;
  boule[0+2].deforme_z=0.5*65536L;
  boule[0+2].texture=0;

/********/
/*      */
/* CODE */
/*      */
/********/

  // Ouvre le fichier :
  fichier=fopen("OBJETS.DAT","wb");
  if(fichier)
  {
    // Totaux :
    total=nb_objets*sizeof(Objet)+
	  nb_boules*sizeof(Boule)+
	  nb_pts*sizeof(Point)+
	  nb_polys*sizeof(Poly)+
	  nb_num_pts*sizeof(Octet);
    fwrite(&total,sizeof(Entier),1,fichier);
    fwrite(&nb_num_pts,sizeof(Octet),5,fichier);

    // Objets :
    for(n=0;n<nb_objets;n++)
    {
      fwrite(&objet[n].nb_boules,sizeof(Octet),1,fichier);
      fwrite(&objet[n].boule,sizeof(Octet),1,fichier);

      fwrite(&objet[n].nb_pts,sizeof(Octet),1,fichier);
      fwrite(&objet[n].pt,sizeof(Octet),1,fichier);
      fwrite(&objet[n].nb_polys,sizeof(Octet),1,fichier);
      fwrite(&objet[n].poly,sizeof(Octet),1,fichier);

      fwrite(&objet[n].nb_sous_objets,sizeof(Octet),1,fichier);
      fwrite(&objet[n].sous_objet,sizeof(Octet),1,fichier);
    }

    // Boules :
    for(n=0;n<nb_boules;n++)
    {
      fwrite(&boule[n].pt.x3D_O,sizeof(Flottant),3,fichier);
      fwrite(&boule[n].r,sizeof(Flottant),5,fichier);
    }

    // Points :
    for(n=0;n<nb_pts;n++)
      fwrite(&pt[n].x3D_O,sizeof(Flottant),3,fichier);

    // Polys :
    for(n=0;n<nb_polys;n++)
    {
      fwrite(&poly[n].nb_pts,sizeof(Octet),1,fichier);
      fwrite(&poly[n].num_pt,sizeof(Octet),1,fichier);
      fwrite(&poly[n].texture,sizeof(Long),1,fichier);
    }

    // Num_pts :
    fwrite(num_pt,sizeof(Octet),nb_num_pts,fichier);

    // OK ! :
    puts("OBJETS : OK");

    // Ferme le fichier :
    fclose(fichier);
  }
}