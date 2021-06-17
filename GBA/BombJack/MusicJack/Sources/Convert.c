/*
** Bomb Jack - MusicJack\Sources\Convert.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include <stdio.h>
#include <string.h>

////////////
// Macros //
////////////
#define BUFFER_SIZE   2048
#define ITEMS_PER_ROW 30

//////////
// main //
//////////
int main(int argc,char** argv)
{
   FILE* fileIn;
   FILE* fileOut;
   unsigned short items;
   unsigned short size;
   unsigned short index;
   unsigned char buffer[BUFFER_SIZE];

   // Check the arguments
   if(argc!=4)
   {
      fprintf(stderr,"Usage: %s inputFileName outputFileName arrayName\n",argv[0]);
      return(1);
   }

   // Open the input file (binary data)
   fileIn=fopen(argv[1],"rb");
   if(!fileIn)
   {
      fprintf(stderr,"Error: couldn't open %s for reading\n",argv[1]);
      return(1);
   }

   // Open the output file (text)
   fileOut=fopen(argv[2],"w");
   if(!fileOut)
   {
      fprintf(stderr,"Error: couldn't open %s for writing\n",argv[2]);
      fclose(fileIn);
      return(1);
   }

   // Create the text file
   items=0;
   fprintf(fileOut,"const unsigned char %s[]=\n{",argv[3]);
   do
   {
      size=fread(buffer,sizeof(unsigned char),BUFFER_SIZE,fileIn);
      for(index=0;index<size;++index)
      {
         if(items)
            --items;
         else
         {
            items=ITEMS_PER_ROW-1;
            fputs("\n   ",fileOut);
         }
         fprintf(fileOut,"%d,",buffer[index]);
      }
   }
   while(size==BUFFER_SIZE);
   if(ftell(fileIn)>0)
      fseek(fileOut,-1,SEEK_CUR); // If there were data, then remove the last comma
   fputs("\n};\n",fileOut);

   // Close the files
   fclose(fileOut);
   fclose(fileIn);

   // Bye bye...
   return(0);
}
