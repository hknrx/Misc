/*
** Mister Jelly - Sources\Game\Blob\Blob.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include "Blob.h"

////////////
// Macros //
////////////
#define BLOB_SNAIL_MAX_ELEMENTS 32
#define BLOB_RADIUS_SPRITE_BODY 8
#define BLOB_RADIUS_SPRITE_EYE  4

/////////////////
// BlobAddLink //
/////////////////
static inline void BlobAddLink(Blob* blob,unsigned char element1,unsigned char element2,unsigned char flagExternal)
{
   blob->link[blob->nbLinks].element1=element1;
   blob->link[blob->nbLinks].element2=element2;
   blob->link[blob->nbLinks].flagExternal=flagExternal;
   ++blob->nbLinks;
}

////////////////////
// BlobAddSurface //
////////////////////
static inline void BlobAddSurface(Blob* blob,unsigned char element1,unsigned char element2,unsigned char element3)
{
   blob->surface[blob->nbSurfaces].element1=element1;
   blob->surface[blob->nbSurfaces].element2=element2;
   blob->surface[blob->nbSurfaces].element3=element3;
   ++blob->nbSurfaces;
}

/////////////////////
// BlobCreateSnail //
/////////////////////
Blob* BlobCreateSnail(signed long stiffness,signed long damping,signed long length,signed long mass,signed long pression,unsigned char nbElements,BlobVector* position)
{
   Blob* blob;
   signed long cos60deg,sin60deg;
   unsigned char nbLinks[BLOB_SNAIL_MAX_ELEMENTS];
   unsigned char numElementCenter,numElementCurrent,numLinkInternal;
   BlobVector positionCurrent,positionTemp;

   if(nbElements<=2 || nbElements>BLOB_SNAIL_MAX_ELEMENTS)
      return(NULL);

   cos60deg=COS(256/6);
   sin60deg=SIN(256/6);

   blob=malloc(sizeof(Blob));
   blob->stiffness=stiffness;
   blob->damping=damping;
   blob->length=length;
   blob->mass=mass;

   blob->nbElements=nbElements;
   blob->element=malloc(nbElements*sizeof(BlobElement));

   blob->nbLinks=0;
   blob->link=malloc(((nbElements*5)>>1)*sizeof(BlobLink)); // Estimation du nombre de links : 2.5*nbElements (vrai jusqu'a 50 elements)

   blob->nbSurfaces=0;
   blob->surface=malloc((((nbElements-2)*3)>>1)*sizeof(BlobSurface)); // Estimation du nombre de surfaces : 1.5*(nbElements-2)

   numElementCenter=0;
   numLinkInternal=0;
   for(numElementCurrent=0;numElementCurrent<nbElements;++numElementCurrent)
   {
      blob->element[numElementCurrent].force.x=0;
      blob->element[numElementCurrent].force.y=0;
      blob->element[numElementCurrent].speed.x=0;
      blob->element[numElementCurrent].speed.y=0;

      nbLinks[numElementCurrent]=0;

      if(numElementCurrent==0)
      {
         positionCurrent.x=position->x;
         positionCurrent.y=position->y;
      }
      else if(numElementCurrent==1)
      {
         positionCurrent.x+=length;

         BlobAddLink(blob,numElementCenter,numElementCurrent,1);

         ++nbLinks[numElementCenter];
         ++nbLinks[numElementCurrent];
      }
      else
      {
         positionCurrent.x-=blob->element[numElementCenter].position.x;
         positionCurrent.y-=blob->element[numElementCenter].position.y;

         positionTemp.x=(positionCurrent.x*cos60deg-positionCurrent.y*sin60deg)>>FIXED_POINT_SHIFT;
         positionTemp.y=(positionCurrent.x*sin60deg+positionCurrent.y*cos60deg)>>FIXED_POINT_SHIFT;

         positionCurrent.x=positionTemp.x+blob->element[numElementCenter].position.x;
         positionCurrent.y=positionTemp.y+blob->element[numElementCenter].position.y;

         BlobAddLink(blob,numElementCurrent-1,numElementCurrent,1);
         BlobAddLink(blob,numElementCurrent,numElementCenter,0);
         BlobAddSurface(blob,numElementCurrent-1,numElementCurrent,numElementCenter);

         ++nbLinks[numElementCurrent-1];
         nbLinks[numElementCurrent]+=2;
         if(++nbLinks[numElementCenter]>=6)
         {
            BlobAddLink(blob,numElementCurrent,++numElementCenter,0);
            BlobAddSurface(blob,numElementCenter-1,numElementCurrent,numElementCenter);

            ++nbLinks[numElementCurrent];
            ++nbLinks[numElementCenter];

            blob->link[numLinkInternal].flagExternal=0;
            while(!blob->link[++numLinkInternal].flagExternal);
         }
      }

      blob->element[numElementCurrent].position.x=positionCurrent.x;
      blob->element[numElementCurrent].position.y=positionCurrent.y;
   }
   blob->link[blob->nbLinks-1].flagExternal=1;

   return(blob);
}

///////////////////////
// BlobCreateBalloon //
///////////////////////
Blob* BlobCreateBalloon(signed long stiffness,signed long damping,signed long length,signed long mass,signed long pression,unsigned char nbElements,BlobVector* position)
{
   Blob* blob;
   unsigned char numElement,angle;
   BlobVector positionCurrent;

   if(nbElements<=2)
      return(NULL);

   blob=malloc(sizeof(Blob));
   blob->stiffness=stiffness;
   blob->damping=damping;
   blob->length=length;
   blob->mass=mass;
   blob->pression=pression;

   blob->nbElements=nbElements;
   blob->element=malloc(nbElements*sizeof(BlobElement));

   blob->nbLinks=0;
   blob->link=malloc(nbElements*sizeof(BlobLink));

   blob->nbSurfaces=0;
   blob->surface=malloc((nbElements-2)*sizeof(BlobSurface));

   for(numElement=0;numElement<nbElements;++numElement)
   {
      blob->element[numElement].force.x=0;
      blob->element[numElement].force.y=0;
      blob->element[numElement].speed.x=0;
      blob->element[numElement].speed.y=0;

      if(numElement==0)
      {
         positionCurrent.x=position->x;
         positionCurrent.y=position->y;
      }
      else
      {
         angle=(numElement<<8)/nbElements;

         positionCurrent.x+=(length*COS(angle))>>FIXED_POINT_SHIFT;
         positionCurrent.y+=(length*SIN(angle))>>FIXED_POINT_SHIFT;

         BlobAddLink(blob,numElement-1,numElement,1);
         if(numElement>1)
            BlobAddSurface(blob,0,numElement-1,numElement);
      }

      blob->element[numElement].position.x=positionCurrent.x;
      blob->element[numElement].position.y=positionCurrent.y;
   }
   BlobAddLink(blob,numElement-1,0,1);

   return(blob);
}

/////////////////
// BlobDestroy //
/////////////////
void BlobDestroy(Blob* blob)
{
   if(blob)
   {
      free(blob->element);
      free(blob->link);
      free(blob);
   }
}

////////////////////////
// BlobCheckCollision //
////////////////////////
static unsigned char CODE_IN_IWRAM BlobCheckCollision(signed long x,signed long y)
{
   // TODO : verifier s'il y a collision avec le decor (la map)...
   // Solution temporaire :
   if(x<(-128<<FIXED_POINT_SHIFT) || x>=(128<<FIXED_POINT_SHIFT) || y<(-128<<FIXED_POINT_SHIFT) || y>=(128<<FIXED_POINT_SHIFT))
      return(1);
   return(0);
}

//////////////////
// BlobMoveOnce //
//////////////////
static inline void CODE_IN_IWRAM BlobMoveOnce(Blob* blob,BlobVector* gravity)
{
   unsigned char numElement,numSurface,numLink;
   BlobElement* element1;
   BlobElement* element2;
   BlobElement* element3;
   BlobVector deltaPosition1,deltaPosition2,deltaSpeed,force;
   signed long pression,distance,temp;

   // Mise a jour de la force de tous les elements : on prend d'abord en compte la pesanteur (gravite)
   force.x=blob->mass*gravity->x;
   force.y=blob->mass*gravity->y;

   numElement=blob->nbElements;
   while(numElement--)
   {
      element1=&blob->element[numElement];
      element1->force.x+=force.x;
      element1->force.y+=force.y;
   }

   // Calcul de la pression (qui depend de la surface totale)
   temp=0;
   numSurface=blob->nbSurfaces;
   while(numSurface--)
   {
      // Recuperation des pointeurs sur les elements concernes
      element1=&blob->element[blob->surface[numSurface].element1];
      element2=&blob->element[blob->surface[numSurface].element2];
      element3=&blob->element[blob->surface[numSurface].element3];

      deltaPosition1.x=element2->position.x-element1->position.x;
      deltaPosition1.y=element2->position.y-element1->position.y;

      deltaPosition2.x=element3->position.x-element1->position.x;
      deltaPosition2.y=element3->position.y-element1->position.y;

      temp+=(deltaPosition2.x*deltaPosition1.y-deltaPosition2.y*deltaPosition1.x)>>FIXED_POINT_SHIFT;
   }
   pression=(blob->pression<<FIXED_POINT_SHIFT)/temp;

   // Mise a jour des forces en fonction des liens entre elements (raideur et amortissement des ressorts)
   // On en profite pour egalement mettre a jour les forces en fonction de la pression du gaz interne
   numLink=blob->nbLinks;
   while(numLink--)
   {
      // Recuperation des pointeurs sur les 2 elements concernes
      element1=&blob->element[blob->link[numLink].element1];
      element2=&blob->element[blob->link[numLink].element2];

      // Calcul de la distance entre les 2 elements
      deltaPosition1.x=element2->position.x-element1->position.x;
      deltaPosition1.y=element2->position.y-element1->position.y;

      distance=(deltaPosition1.x*deltaPosition1.x+deltaPosition1.y*deltaPosition1.y)>>FIXED_POINT_SHIFT;
      if(distance<(SQRTNB<<SQRT_SHIFT))
         distance=SQRT(distance);
      else
         distance=CommonSqrt(distance)<<(FIXED_POINT_SHIFT/2);

      // Calcul de la difference de vitesse
      deltaSpeed.x=element2->speed.x-element1->speed.x;
      deltaSpeed.y=element2->speed.y-element1->speed.y;

      // Calcul de la force exercee par le ressort (= raideur et amortissement)
      temp=(deltaSpeed.x*deltaPosition1.x+deltaSpeed.y*deltaPosition1.y)/distance;
      temp=(temp*blob->damping+(distance-blob->length)*blob->stiffness)/distance;

      force.x=temp*deltaPosition1.x;
      force.y=temp*deltaPosition1.y;

      // Mise a jour des forces des 2 elements concernes
      element1->force.x+=force.x;
      element1->force.y+=force.y;
      element2->force.x-=force.x;
      element2->force.y-=force.y;

      // Calcul de la force exercee par le gaz (= pression), pour les liens externes uniquement
      if(blob->link[numLink].flagExternal)
      {
         force.x=pression*deltaPosition1.y;
         force.y=pression*deltaPosition1.x;

         // Mise a jour des forces des 2 elements concernes
         element1->force.x-=force.x;
         element1->force.y+=force.y;
         element2->force.x-=force.x;
         element2->force.y+=force.y;
      }
   }

   // Mise a jour de la vitesse et de la position de tous les elements
   // Note : on re-initialise aussi la force (gestion des collisions)
   numElement=blob->nbElements;
   while(numElement--)
      {
      element1=&blob->element[numElement];

      // Mise a jour de la vitesse
      element1->speed.x+=element1->force.x/(blob->mass<<BLOB_EULER_SHIFT);
      element1->speed.y+=element1->force.y/(blob->mass<<BLOB_EULER_SHIFT);

      // Mise a jour de la position (abscisse)
      temp=element1->position.x+(element1->speed.x>>BLOB_EULER_SHIFT);
      if(!BlobCheckCollision(temp,element1->position.y))
      {
         element1->position.x=temp;
         element1->force.x=0;
         element1->force.y=0;
      }
      else
      {
         element1->force.x=-element1->speed.x*blob->mass;
         element1->force.y=-element1->speed.y*BLOB_FRICTION; // OK ??
      }

      // Mise a jour de la position (ordonnee)
      temp=element1->position.y+(element1->speed.y>>BLOB_EULER_SHIFT);
      if(!BlobCheckCollision(element1->position.x,temp))
         element1->position.y=temp;
      else
      {
         element1->force.x-=element1->speed.x*BLOB_FRICTION; // OK ??
         element1->force.y-=element1->speed.y*blob->mass;
      }
   }
}

//////////////
// BlobMove //
//////////////
void CODE_IN_IWRAM BlobMove(Blob* blob,BlobVector* gravity)
{
   unsigned char iteration;

   if(!blob)
      return;

   for(iteration=0;iteration<(1<<BLOB_EULER_SHIFT);++iteration)
      BlobMoveOnce(blob,gravity);
}

/////////////////
// BlobDisplay //
/////////////////
void BlobDisplay(Blob* blob,BlobVector* camPosition,unsigned char camAngle,unsigned char flagSmooth)
{
   signed long cos,sin;
   unsigned short* sprite;
   unsigned char numElement,numLink;
   BlobVector position;
   signed short xe,ye;
   BlobElement* element1;
   BlobElement* element2;

   // Verification de l'existence du blob
   if(!blob)
      return;

   // Calcul du cosinus et du sinus
   cos=COS(camAngle);
   sin=SIN(camAngle);

   // Affichage de tous les elements
   sprite=(unsigned short*)commonSprites;

   numElement=blob->nbElements;
   while(numElement--)
   {
      // Calcul de la position a l'ecran
      position.x=blob->element[numElement].position.x-camPosition->x;
      position.y=blob->element[numElement].position.y-camPosition->y;

      xe=XO4+((position.x*cos-position.y*sin)>>(FIXED_POINT_SHIFT+FIXED_POINT_SHIFT));
      ye=YO4+((position.x*sin+position.y*cos)>>(FIXED_POINT_SHIFT+FIXED_POINT_SHIFT));

      // Ajout d'un sprite (lorsque l'element est visible a l'ecran)
      if(xe>=-BLOB_RADIUS_SPRITE_BODY && xe<XM4+BLOB_RADIUS_SPRITE_BODY && ye>=-BLOB_RADIUS_SPRITE_BODY && ye<YM4+BLOB_RADIUS_SPRITE_BODY)
      {
         *sprite++=((ye-BLOB_RADIUS_SPRITE_BODY)&255)|(1<<13)|(1<<10); // Sprite 256 couleurs semi-transparent
         *sprite++=((xe-BLOB_RADIUS_SPRITE_BODY)&511)|(1<<14);         // Sprite de 16x16 pixels
         *sprite++=0|(1<<10);                                          // Sprite de priorite 1
         ++sprite;

         if(numElement<2)
         {
            // Ajout des yeux !
            *sprite++=((ye-BLOB_RADIUS_SPRITE_EYE)&255)|(1<<13)|(1<<10); // Sprite 256 couleurs
            *sprite++=((xe-BLOB_RADIUS_SPRITE_EYE)&511)|(0<<14);         // Sprite de 8x8 pixels
            *sprite++=8|(0<<10);                                         // Sprite de priorite 0
            ++sprite;
         }
      }
   }

   // Ajout d'element pour lisser la surface
   if(!flagSmooth)
      return;

   numLink=blob->nbLinks;
   while(numLink--)
      if(blob->link[numLink].flagExternal)
      {
         // Recuperation des pointeurs sur les 2 elements concernes
         element1=&blob->element[blob->link[numLink].element1];
         element2=&blob->element[blob->link[numLink].element2];

         // Calcul de la position a l'ecran
         position.x=((element1->position.x+element2->position.x)>>1)-camPosition->x;
         position.y=((element1->position.y+element2->position.y)>>1)-camPosition->y;

         xe=XO4+((position.x*cos-position.y*sin)>>(FIXED_POINT_SHIFT+FIXED_POINT_SHIFT));
         ye=YO4+((position.x*sin+position.y*cos)>>(FIXED_POINT_SHIFT+FIXED_POINT_SHIFT));

         // Ajout d'un sprite (lorsque l'element est visible a l'ecran)
         if(xe>=-BLOB_RADIUS_SPRITE_BODY && xe<XM4+BLOB_RADIUS_SPRITE_BODY && ye>=-BLOB_RADIUS_SPRITE_BODY && ye<YM4+BLOB_RADIUS_SPRITE_BODY)
         {
            *sprite++=((ye-BLOB_RADIUS_SPRITE_BODY)&255)|(1<<13)|(1<<10); // Sprite 256 couleurs semi-transparent
            *sprite++=((xe-BLOB_RADIUS_SPRITE_BODY)&511)|(1<<14);         // Sprite de 16x16 pixels
            *sprite++=0|(1<<10);                                          // Sprite de priorite 1
            ++sprite;
         }
      }
}
