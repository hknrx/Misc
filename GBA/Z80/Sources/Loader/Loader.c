/*
** Z80 - Sources\Loader\Loader.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include <stdio.h>
#include <string.h>

//////////
// main //
//////////
int main(int argc,char** argv)
{
   char SNA[0x100+0x10000];
   FILE* file;
   unsigned char fileName[256];
   unsigned long counter;

   // Check the arguments
   if(argc!=4)
   {
      fprintf(stderr,"Usage: %s name inPath outPath\n",argv[0]);
      return(1);
   }

   // Open and read the snapshot file
   sprintf(fileName,"%s/%s.SNA",argv[2],argv[1]);
   file=fopen(fileName,"rb");
   if(!file)
   {
      fputs("Error: couldn't open the snapshot file\n",stderr);
      return(1);
   }
   fread(SNA,sizeof(SNA),sizeof(char),file);
   fclose(file);

   // Open the data file
   sprintf(fileName,"%s/%s.s",argv[3],argv[1]);
   file=fopen(fileName,"w");
   if(!file)
   {
      fputs("Error: couldn't write to the data file\n",stderr);
      return(1);
   }
   fprintf(stdout,"Creating %s... ",fileName);
   fflush(stdout);

   // Write the header of our data file
   fprintf(file,".section .rodata\n.global SNA_%s\nSNA_%s:",argv[1],argv[1]);

   // Write the data...
   for(counter=0;counter<sizeof(SNA);++counter)
   {
      if(counter&15)
         fputc(',',file);
      else
         fputs("\n.byte ",file);
      fprintf(file,"%d",(unsigned char)SNA[counter]);
   }

   // Close the output file
   fputc('\n',file);
   fclose(file);

   // Bye bye...
   fputs("Done\n",stdout);
   return(0);
}
