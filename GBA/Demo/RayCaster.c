/*
   Ray casting
   ===========

// TODO :
// - corriger les problemes d'approximation (utilisation de INV[]),
// - empecher le placement trop pres d'un mur (en le longeant).

   Le ray casting est une sorte de "ray tracing" ultra simplifie :
   - on ne fait les calculs que sur la largeur de l'ecran, pas sur toute la surface,
   - on ne s'amuse pas a calculer les rayons reflechis ou diffractes (!).

   En gros il s'agit donc de decouper l'ecran en tranches verticales d'un pixel de large. Pour
   chaque point xe de l'ecran :
   - on trouve la droite qui part de la camera et passe par ce point,
   - on recherche les intersections de ce rayon avec les murs de la carte,
   - on prend l'intersection la plus proche,
   - on dessine la "tranche" de mur correspondante (la hauteur est fonction de la distance).

   Petit rappel des equations de base de la 3D (dans le repere de la camera) :
   xe = XO + Dcam * x / z
   ye = YO - Dcam * y / z

   On a pour chaque point xe de l'ecran un vecteur point-camera :
   Vo = (xe-XO , Dcam)

   Il faut maintenant faire le changement de repere (rotation et deplacement de la camera) :
          |COS -SIN|
   Mrot = |        |
          |SIN  COS|

   V = Mrot.Vo

   Donc :
   Vx = (xe-XO)*COS-Dcam*SIN
   Vz = (xe-XO)*SIN+Dcam*COS

   Pour aller plus vite nous travaillerons par increments :
   Vx = -XO*COS-Dcam*SIN
   dVx = COS
   Vz = -XO*SIN+Dcam*COS
   dVz = SIN
   Boucle(xe : de 0 a XM)
      // traitements
      Vx+ = dVx
      Vz+ = dVz
   FinBoucle

   En pratique on cherche les intersections verticales et horizontales separement. Etude du cas des
   intersections verticales :

   1) On part de la 1ere intersection, qui pour x est :
   - si Vx<0 : x = round(xcam)
   - si Vx>0 : x = round(xcam) + 1
   Note : dans le cas Vx<0, il faut decrementer un poil pour tomber sur le bon mur en memoire.

   2) Pour ce qui est de la variation de x, on a :
   - si Vx<0 : dx = -1
   - si Vx>0 : dx = 1

   3) Il faut trouver la 1ere intersection en z :
   Equations de la droite (notre rayon !) :
   x = xcam + k * Vx
   z = zcam + k * Vz

   Donc : k = (x-xcam)/Vx
   Donc : z = zcam + (x-xcam)*Vz/Vx

   Si on definit dz = Vz/Vx on a alors : z = zcam + (x-xcam)*dz

   4) Ensuite z va varier de maniere constante de : dx*Vz/Vx
   ...donc si Vx<0, alors dz = -dz

   5) On recherche alors les intersections avec la carte en memoire :
   - s'il y a une intersection, alors la distance est : dist = Dcam*(x-xcam)/Vx
   - sinon a chaque iteration on fait : x+=dx et z+=dz

   Lorsqu'on a trouve le mur le plus pres, il suffit de dessiner la tranche de ce mur a l'ecran :
   ymin = YO + Dcam*(ycam-hauteur)/dist
   ymax = YO + Dcam*ycam/dist


   Mapping du sol
   ==============
   
   On sait que y=ycam (camera parallele au sol) :
   ye = YO+Dcam*ycam/z

   On retrouve donc les autres coordonnees :
   z = Dcam*ycam/(ye-YO)
   x = (xe-XO)*z/Dcam = (xe-XO)*ycam/(ye-YO)

   Si on pose : K = ycam/(ye-YO)
   On a alors :
   x = K*(xe-XO)
   z = K*Dcam

   Il faut maintenant faire le changement de repere :
   x' = xcam+x*COS-z*SIN = xcam+(xe-XO)*K*COS-Dcam*K*SIN
   z' = zcam+x*SIN+z*COS = zcam+(xe-XO)*K*SIN+Dcam*K*COS

   Comme d'habitude on travaille par increments :
   (ici on parle de x et z a la place de x' et z')

   Boucle(ye : de 1 a YM)
      K = ycam/(ye-YO)
      dx = K*COS
      dz = K*SIN
      x = xcam-XO*dx-Dcam*dz
      z = zcam-XO*dz+Dcam*dx
      Boucle(xe : de 0 a XM)
         // affichage de la texture correspondant a (x,z)
         x+ = dx
         z+ = dz
      FinBoucle
   FinBoucle
*/

#include "Commun.h"

#define CARTE_   4
#define CARTE    (1<<CARTE_)
#define TEXTURE_ 6
#define TEXTURE  (1<<TEXTURE_)
#define HAUTEUR_ 1
#define HAUTEUR  (1<<HAUTEUR_)
#define VITESSE_ 3
#define DMIN     (0.3*VIRGULE)
#define DCAM_    6

#define XM (XM4/2)
#define YM YM5
#define XO (XM/2)
#define YO (YM/2)

extern unsigned short textures[];
unsigned char carte[CARTE*CARTE]={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                                  1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,
                                  1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,
                                  1,0,0,0,0,0,0,0,0,3,3,3,0,0,0,1,
                                  1,0,0,0,0,0,0,0,0,3,3,3,0,0,0,1,
                                  1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,
                                  2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,1,
                                  2,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,
                                  2,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,
                                  2,2,0,2,2,2,2,0,0,0,0,1,0,0,0,1,
                                  2,0,0,0,0,0,2,2,2,0,0,1,0,2,0,1,
                                  2,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,
                                  2,0,0,3,0,0,3,0,0,3,0,0,0,0,0,1,
                                  2,0,0,0,0,0,0,0,0,0,0,1,0,2,0,1,
                                  2,0,0,0,0,0,2,2,2,0,0,1,0,0,0,1,
                                  2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1};

///////////////////
// initRayCaster //
///////////////////
void initRayCaster(void)
{
   unsigned short xy;

   // Vide le buffer video courant
   ecran=(unsigned short*)((unsigned long)VRAM|BACKVRAM);
   for(xy=0;xy<XM*YM;xy+=2)
      *(unsigned long*)&ecran[xy]=0;

   // On passe en mode 5
   REG_DISPCNT=5|BG2_ENABLE|BACKBUFFER;
   ecran=VRAM;

   // Etire le buffer pour prendre tout l'ecran
   REG_BG2PA=(XM<<8)/240;
   REG_BG2PB=0;
   REG_BG2PC=0;
   REG_BG2PD=(YM<<8)/160;
}

///////////////////
// deplacementRC //
///////////////////
void deplacementRC(signed long* xcam,signed long* zcam,unsigned char A)
{
   signed long m,n;
   
   m=-SINUS[A]>>VITESSE_;
   n=*xcam+m;
   if(m>0)
      m=DMIN;
   else
      m=-DMIN;
   if(!carte[((n+m)>>VIRGULE_)|((*zcam>>(VIRGULE_-CARTE_))&~(CARTE-1))])
      *xcam=n;

   m=SINUS[(unsigned char)(A+64)]>>VITESSE_;
   n=*zcam+m;
   if(m>0)
      m=DMIN;
   else
      m=-DMIN;
   if(!carte[(*xcam>>VIRGULE_)|(((n+m)>>(VIRGULE_-CARTE_))&~(CARTE-1))])
      *zcam=n;
}

/////////
// sol //
/////////
void CODE_IN_IWRAM sol(signed long xcam,signed long ycam,signed long zcam,unsigned char A)
{
   unsigned char xe,ye;
   unsigned short xy;
   signed long sin,cos,K,dx,dz,x,z;

   sin=SINUS[A];
   cos=SINUS[(unsigned char)(A+64)];

   xy=(YO+1)*XM5;
   for(ye=1;ye<YO;++ye)
   {
      K=(ycam*INV[ye])>>VIRGULE_;
      dx=(K*cos)>>VIRGULE_;
      dz=(K*sin)>>VIRGULE_;
      x=xcam-XO*dx-(dz<<DCAM_);
      z=zcam-XO*dz+(dx<<DCAM_);

      for(xe=0;xe<XM;++xe)
      {
         ecran[xy++]=(x^z)>>(VIRGULE_-TEXTURE_);
         x+=dx;
         z+=dz;
      }
      xy+=XM5-XM;
   }
}

///////////////
// rayCaster //
///////////////
void CODE_IN_IWRAM rayCaster(signed long xcam,signed long ycam,signed long zcam,unsigned char A)
{
   signed long sin,cos;
   signed short dX[YO-1],dZ[YO-1],X[YO-1],Z[YO-1];
   signed long K,Kv,Kh;
   signed long Vx,xv,xh,dx;
   signed long Vz,zv,zh,dz;
   signed short xe,ye,ymin,ymax;
   unsigned short xy_ecran,x_texture,y_texture,dy_texture;
   unsigned char num_texture;

   // Retrouve le sinus & cosinus
   sin=SINUS[A];
   cos=SINUS[(unsigned char)(A+64)];

   // Preparation pour le mapping du sol
   ye=YO-1; // On va du bas (YM-1) jusqu'a l'horizon (YO+1), mais on fait un changement de repere (-YO)
   while(ye)
   {
      K=(ycam*INV[ye--])>>VIRGULE_;
      dx=(K*cos)>>VIRGULE_;
      dz=(K*sin)>>VIRGULE_;
      dX[ye]=dx;
      dZ[ye]=dz;
      X[ye]=xcam-XO*dx-(dz<<DCAM_);
      Z[ye]=zcam-XO*dz+(dx<<DCAM_);
   }

   // Preparation pour le ray casting
   Vx=-(sin<<DCAM_)-XO*cos;
   Vz=(cos<<DCAM_)-XO*sin;

   // Parcourt tout l'ecran
   for(xe=0;xe<XM;++xe)
   {
      // Intersections verticales
      xv=xcam;
      zv=zcam;
      Kv=1<<30;
      if(Vx)
      {
         xv&=~(VIRGULE-1);
         if(Vx>0)
         {
            K=INV[Vx>>VIRGULE_];
            dx=VIRGULE;
            //dz=(Vz*K)>>VIRGULE_;
            //dz=((long long)Vz<<VIRGULE_)/Vx;
            dz=(Vz<<(VIRGULE_-4))/(Vx>>4);
            xv+=VIRGULE;
            zv+=(dz*(xv-xcam))>>VIRGULE_;
            //xv+=4; // Ajout d'une constante pour corriger l'approximation qui laisse voir entre 2 murs (ok ?)
         }
         else
         {
            K=-INV[-Vx>>VIRGULE_];
            dx=-VIRGULE;
            //dz=-(Vz*K)>>VIRGULE_;
            //dz=-((long long)Vz<<VIRGULE_)/Vx;
            dz=-(Vz<<(VIRGULE_-4))/(Vx>>4);
            zv-=(dz*(xv-xcam))>>VIRGULE_;
            --xv; // Pour tomber sur le bon mur en memoire (xv etait a la limite !)
         }
         while((unsigned long)zv<(CARTE<<VIRGULE_))
         {
            if(carte[(xv>>VIRGULE_)|((zv>>(VIRGULE_-CARTE_))&~(CARTE-1))])
            {
               Kv=((xv-xcam)*K)>>VIRGULE_;
               break;
            }
            xv+=dx;
            zv+=dz;
         }
      }

      // Intersections horizontales
      xh=xcam;
      zh=zcam;
      Kh=1<<30;
      if(Vz)
      {
         zh&=~(VIRGULE-1);
         if(Vz>0)
         {
            K=INV[Vz>>VIRGULE_];
            dz=VIRGULE;
            //dx=(Vx*K)>>VIRGULE_;
            //dx=((long long)Vx<<VIRGULE_)/Vz;
            dx=(Vx<<(VIRGULE_-4))/(Vz>>4);
            zh+=VIRGULE;
            xh+=(dx*(zh-zcam))>>VIRGULE_;
         }
         else
         {
            K=-INV[-Vz>>VIRGULE_];
            dz=-VIRGULE;
            //dx=-(Vx*K)>>VIRGULE_;
            //dx=-((long long)Vx<<VIRGULE_)/Vz;
            dx=-(Vx<<(VIRGULE_-4))/(Vz>>4);
            xh-=(dx*(zh-zcam))>>VIRGULE_;
            --zh;
         }
         while((unsigned long)xh<(CARTE<<VIRGULE_))
         {
            if(carte[(xh>>VIRGULE_)|((zh>>(VIRGULE_-CARTE_))&~(CARTE-1))])
            {
               Kh=((zh-zcam)*K)>>VIRGULE_;
               break;
            }
            xh+=dx;
            zh+=dz;
         }
      }

      // Prend le mur le plus pres
      if((Kv<Kh && Kv>0) || Kh<0) // BUG : Kv et Kh sont parfois negatifs !
      {
         K=Kv;
         num_texture=carte[(xv>>VIRGULE_)|((zv>>(VIRGULE_-CARTE_))&~(CARTE-1))];
         x_texture=(zv>>(VIRGULE_-TEXTURE_))&(TEXTURE-1);
      }
      else
      {
         K=Kh;
         num_texture=carte[(xh>>VIRGULE_)|((zh>>(VIRGULE_-CARTE_))&~(CARTE-1))];
         x_texture=(xh>>(VIRGULE_-TEXTURE_))&(TEXTURE-1);
      }

      // Derniers preparatifs !
      //ymin=YO+(((ycam-(HAUTEUR<<VIRGULE_))*INV[K])>>VIRGULE_);
      //ymax=YO+((ycam*INV[K])>>VIRGULE_);
      ymin=YO+((ycam-(HAUTEUR<<VIRGULE_))/K);
      ymax=YO+(ycam/K);

      x_texture|=num_texture<<(TEXTURE_+TEXTURE_);
      dy_texture=K<<(16-VIRGULE_-HAUTEUR_); // On change la virgule fixe pour plus de precision...

      if(ymin<0)
      {
         y_texture=-ymin*dy_texture;
         ymin=0;
      }
      else
         y_texture=0;

      if(ymax>YM)
         ymax=YM;

      xy_ecran=xe;
      ye=0;

      // Affichage du plafond
      while(ye<ymin)
      {
         ecran[xy_ecran]=RGB(7,7,7);
         xy_ecran+=XM5;
         ++ye;
      }

      // Affichage du morceau de mur
      while(ye<ymax)
      {
         ecran[xy_ecran]=textures[x_texture|((y_texture>>(16-TEXTURE_-TEXTURE_))&((TEXTURE-1)<<TEXTURE_))];
         xy_ecran+=XM5;
         y_texture+=dy_texture;
         ++ye;
      }

      // Mapping du sol
      ye-=YO;
      while(ye<YO-1)
      {
         x_texture=(X[ye]+xe*dX[ye])>>(VIRGULE_-TEXTURE_)&(TEXTURE-1);
         y_texture=(Z[ye]+xe*dZ[ye])>>(VIRGULE_-TEXTURE_-TEXTURE_)&((TEXTURE-1)<<TEXTURE_);
         ecran[xy_ecran]=textures[x_texture|y_texture];
         xy_ecran+=XM5;
         ++ye;
      }
      
      // Rayon suivant !
      Vx+=cos;
      Vz+=sin;
   }
}
