#include "z80.h"

typedef void (*Function)(void);

typedef union
{
   struct
   {
      unsigned char l;
      unsigned char h;
   }
   b;
   unsigned short w;
}
Register16;

typedef struct
{
   Register16 af,bc,de,hl,ix,iy,sp,pc;
   Register16 af2,bc2,de2,hl2;
   unsigned char i;
}
Registers;

#define CF 0x01
#define NF 0x02
#define PF 0x04
#define VF PF
#define HF 0x10
#define ZF 0x40
#define SF 0x80

#define A Z80.af.b.h
#define F Z80.af.b.l
#define AF Z80.af.w

#define B Z80.bc.b.h
#define C Z80.bc.b.l
#define BC Z80.bc.w

#define D Z80.de.b.h
#define E Z80.de.b.l
#define DE Z80.de.w

#define H Z80.hl.b.h
#define L Z80.hl.b.l
#define HL Z80.hl.w

#define HX Z80.ix.b.h
#define LX Z80.ix.b.l
#define IX Z80.ix.w

#define HY Z80.iy.b.h
#define LY Z80.iy.b.l
#define IY Z80.iy.w

#define SP Z80.sp.w
#define PC Z80.pc.w
#define I Z80.i

static Registers Z80;
static unsigned short EA;

static unsigned char SZ[256];   /* zero and sign flags */
static unsigned char SZ_BIT[256];/* zero, sign and parity/overflow (=zero) flags for BIT opcode */
static unsigned char SZP[256];/* zero, sign and parity flags */
static unsigned char SZHV_inc[256]; /* zero, sign, half carry and overflow flags INC r8 */
static unsigned char SZHV_dec[256]; /* zero, sign, half carry and overflow flags DEC r8 */

//////////////////
// Basic macros //
//////////////////
#define OP(prefix,opcode) inline void prefix##_##opcode(void)
#define OP_IWRAM(prefix,opcode) inline void CODE_IN_IWRAM prefix##_##opcode(void)
#define EXEC(prefix,opcode) {(*Z80##prefix[opcode])();}

#define RM8(addr) cpcMemory[addr]
#define RM16(addr,r) {((Register16*)&r)->b.l=cpcMemory[addr];((Register16*)&r)->b.h=cpcMemory[addr+1];}

#define WM8(addr,value) {cpcMemory[addr]=value;}
#define WM16(addr,r) {cpcMemory[addr]=((Register16*)&r)->b.l;cpcMemory[addr+1]=((Register16*)&r)->b.h;}

#define ARG8() cpcMemory[PC++]
#define ARG16() (cpcMemory[PC++]|(cpcMemory[PC++]<<8))

#define EAIX() {EA=IX+(signed short)ARG8();}
#define EAIY() {EA=IY+(signed short)ARG8();}

#define POP(r) {((Register16*)&r)->b.l=cpcMemory[SP++];((Register16*)&r)->b.h=cpcMemory[SP++];}
#define PUSH(r) {cpcMemory[--SP]=((Register16*)&r)->b.h;cpcMemory[--SP]=((Register16*)&r)->b.l;}

#define JP() {PC=ARG16();}
#define JP_COND(cond) if(cond) {PC=ARG16();} else {PC+=2;}
#define JR() {PC+=(signed char)cpcMemory[PC]+1;}
#define JR_COND(cond,opcode) if(cond) {PC+=(signed char)cpcMemory[PC]+1;} else {PC++;}

#define CALL() {unsigned short addr=ARG16();PUSH(PC);PC=addr;}
#define CALL_COND(cond,opcode) if(cond) {unsigned short addr=ARG16();PUSH(PC);PC=addr;} else {PC+=2;}

#define RET_COND(cond,opcode) if(cond) {POP(PC);}
#define RETN() POP(PC)
#define RETI() POP(PC)

///////////////////////////
// Illegal, IN, OUT, RST //
///////////////////////////
static unsigned short illegCount;
static unsigned short illegLastPc;
void CODE_IN_IWRAM illeg(void)
{
   ++illegCount;
	illegLastPc=PC;
}

unsigned char keyboardLine;
unsigned char CODE_IN_IWRAM IN(unsigned short port)
{
   port>>=8;
   if(port==0xF4)
   {
      if(keyboardLine==8) // V B F G T R { ]
         return((0xFF-8)|((REG_KEYS&KEY_R)>>5)); // KEY_R=256 => 8 (T)
      if(keyboardLine==4) // ; , K L I O ç à
         return((0xFF-32)|((REG_KEYS&KEY_L)>>4)); // KEY_L=512 => 32 (K)
      if(keyboardLine==1) // 0 2 1 5 8 7 COPY gauche
         return((0xFF-32)|((REG_KEYS&KEY_START)<<2)); // KEY_START=8 => 32 (1)
      return(0xFF);
   }
   else if(port==0xF5)
      return(vblCounter&1); // VSYNC
   return(0);
}
unsigned char crtcRegister;
void CODE_IN_IWRAM OUT(unsigned short port,unsigned char value)
{
   static unsigned char previousValue;

   port>>=8;
   if(port==0x7F)
   {
      if(value&0x40)
         CommonCpcHardPenSet(previousValue,value&0x3F,PALRAM);
      else
         previousValue=value;
   }
   else if(port==0xF6)
   {
      if(value&0x40)
         keyboardLine=value&0x3F;
   }
   else if(port==0xBC)
		crtcRegister=value;
	else if(port==0xBD)
	{
   	if(crtcRegister==12)
			cpcScreen=(cpcScreen&0x3FF)|(value<<10);
   	else if(crtcRegister==13)
			cpcScreen=(cpcScreen&0xFC00)|(value<<2);
	}
}

static unsigned long chrono;
static unsigned short vblChrono;
static unsigned char crtcMode;
void CODE_IN_IWRAM RST(unsigned short addr)
{
   unsigned short arg;
   unsigned long chronoCurrent;
   
   arg=PC-1;
   if(arg==0xBC14)
     	CommonDmaForce(0,&cpcMemory[cpcScreen],0x4000>>2,DMA_32NOW);
   else if(arg==0xBC0E)
	{
	   cpcScreen=0xC000;
      crtcMode=A;
	}
   else if(arg==0xBC11)
   {
      if(crtcMode==2)
         F=F&~(CF|ZF);
      else if(crtcMode==1)
         F=(F&~CF)|ZF;
      else
         F=(F&~ZF)|CF;
   }
   else if(arg==0xBC32)
      CommonCpcSoftPenSet(A,B,PALRAM);
   else if(arg==0xBD25)
      CommonCpcSoftPaletteSet(&cpcMemory[DE]+1,PALRAM);
   else if(arg==0xBD10)
   {
      vblChrono=vblCounter;
      chrono=(DE<<16)|HL;
   }
   else if(arg==0xBD0D)
   {
      chronoCurrent=chrono+(unsigned short)(vblCounter-vblChrono)*5;
      DE=chronoCurrent>>16;
      HL=chronoCurrent;
   }
   POP( PC );
}

/***************************************************************
 * LD   I,A
 ***************************************************************/
#define LD_I_A {\
   I = A;\
}

/***************************************************************
 * LD   A,I
 ***************************************************************/
#define LD_A_I {\
   A = I;\
   F = (F & CF) | SZ[A];\
}

/***************************************************************
 * INC  r8
 ***************************************************************/
inline unsigned char INC(unsigned char value)
{
   unsigned char res = value + 1;
   F = (F & CF) | SZHV_inc[res];
   return (unsigned char)res;
}

/***************************************************************
 * DEC  r8
 ***************************************************************/
inline unsigned char DEC(unsigned char value)
{
   unsigned char res = value - 1;
   F = (F & CF) | SZHV_dec[res];
   return res;
}

/***************************************************************
 * RLCA
 ***************************************************************/
#define RLCA \
   A = (A << 1) | (A >> 7);\
   F = (F & (SF | ZF | PF)) | (A & CF)

/***************************************************************
 * RRCA
 ***************************************************************/
#define RRCA\
   F = (F & (SF | ZF | PF)) | (A & CF);\
   A = (A >> 1) | (A << 7);

/***************************************************************
 * RLA
 ***************************************************************/
#define RLA {\
   unsigned char res = (A << 1) | (F & CF);\
   unsigned char c = (A & 0x80) ? CF : 0;\
   F = (F & (SF | ZF | PF)) | c;\
   A = res;\
}

/***************************************************************
 * RRA
 ***************************************************************/
#define RRA {\
   unsigned char res = (A >> 1) | (F << 7);\
   unsigned char c = (A & 0x01) ? CF : 0;\
   F = (F & (SF | ZF | PF)) | c;\
   A = res;\
}

/***************************************************************
 * RRD
 ***************************************************************/
#define RRD {\
   unsigned char n = RM8(HL);\
   WM8( HL, (n >> 4) | (A << 4) );\
   A = (A & 0xf0) | (n & 0x0f);\
   F = (F & CF) | SZP[A];\
}

/***************************************************************
 * RLD
 ***************************************************************/
#define RLD {\
   unsigned char n = RM8(HL);\
   WM8( HL, (n << 4) | (A & 0x0f) );\
   A = (A & 0xf0) | (n >> 4);\
   F = (F & CF) | SZP[A];\
}

/***************************************************************
 * ADD  A,n
 ***************************************************************/
#define ADD(value)\
{\
   unsigned val = value;\
   unsigned res = A + val;\
   F = SZ[(unsigned char)res] | ((res >> 8) & CF) |\
   ((A ^ res ^ val) & HF) |\
   (((val ^ A ^ 0x80) & (val ^ res) & 0x80) >> 5);\
   A = (unsigned char)res;\
}

/***************************************************************
 * ADC  A,n
 ***************************************************************/
#define ADC(value)\
{\
   unsigned val = value;\
   unsigned res = A + val + (F & CF);\
   F = SZ[res & 0xff] | ((res >> 8) & CF) |\
   ((A ^ res ^ val) & HF) |\
   (((val ^ A ^ 0x80) & (val ^ res) & 0x80) >> 5);\
   A = res;\
}

/***************************************************************
 * SUB  n
 ***************************************************************/
#define SUB(value)\
{\
   unsigned val = value;\
   unsigned res = A - val;\
   F = SZ[res & 0xff] | ((res >> 8) & CF) | NF |\
   ((A ^ res ^ val) & HF) |\
   (((val ^ A) & (A ^ res) & 0x80) >> 5);\
   A = res;\
}

/***************************************************************
 * SBC  A,n
 ***************************************************************/
#define SBC(value)\
{\
   unsigned val = value;\
   unsigned res = A - val - (F & CF);\
   F = SZ[res & 0xff] | ((res >> 8) & CF) | NF |\
   ((A ^ res ^ val) & HF) |\
   (((val ^ A) & (A ^ res) & 0x80) >> 5);\
   A = res;\
}

/***************************************************************
 * NEG
 ***************************************************************/
#define NEG {\
   unsigned char value = A;\
   A = 0;\
   SUB(value);\
}

/***************************************************************
 * DAA
 ***************************************************************/
#define DAA {\
   unsigned char cf, nf, hf, lo, hi, diff;\
   cf = F & CF;\
   nf = F & NF;\
   hf = F & HF;\
   lo = A & 15;\
   hi = A >> 4;\
   \
   if (cf)\
      diff = (lo <= 9 && !hf) ? 0x60 : 0x66;\
   else if (lo >= 10)\
      diff = hi <= 8 ? 0x06 : 0x66;\
   else if (hi >= 10)\
      diff = hf ? 0x66 : 0x60;\
   else\
      diff = hf ? 0x06 : 0x00;\
   if (nf) \
      A -= diff;\
   else \
      A += diff;\
   \
   F = SZP[A] | (F & NF);\
   if (cf || (lo <= 9 ? hi >= 10 : hi >= 9)) F |= CF;\
   if (nf ? hf && lo <= 5 : lo >= 10)F |= HF;\
}

/***************************************************************
 * AND  n
 ***************************************************************/
#define AND(value)\
   A &= value;\
   F = SZP[A] | HF

/***************************************************************
 * OR   n
 ***************************************************************/
#define OR(value)\
   A |= value;\
   F = SZP[A]

/***************************************************************
 * XOR  n
 ***************************************************************/
#define XOR(value)\
   A ^= value;\
   F = SZP[A]

/***************************************************************
 * CP   n
 ***************************************************************/
#define CP(value)\
{\
   unsigned val = value;\
   unsigned res = A - val;\
   F = (SZ[res & 0xff] & (SF | ZF)) |\
   ((res >> 8) & CF) | NF |\
   ((A ^ res ^ val) & HF) |\
   ((((val ^ A) & (A ^ res)) >> 5) & VF);\
}

/***************************************************************
 * EX   AF,AF'
 ***************************************************************/
#define EX_AF {\
   Register16 tmp;\
   tmp = Z80.af; Z80.af = Z80.af2; Z80.af2 = tmp;\
}

/***************************************************************
 * EX   DE,HL
 ***************************************************************/
#define EX_DE_HL {\
   Register16 tmp;\
   tmp = Z80.de; Z80.de = Z80.hl; Z80.hl = tmp;\
}

/***************************************************************
 * EXX
 ***************************************************************/
#define EXX {\
   Register16 tmp;\
   tmp = Z80.bc; Z80.bc = Z80.bc2; Z80.bc2 = tmp;\
   tmp = Z80.de; Z80.de = Z80.de2; Z80.de2 = tmp;\
   tmp = Z80.hl; Z80.hl = Z80.hl2; Z80.hl2 = tmp;\
}

/***************************************************************
 * EX   (SP),r16
 ***************************************************************/
#define EXSP(DR)\
{\
   unsigned short tmp; \
   RM16( SP, tmp );\
   WM16( SP, DR );\
   DR = tmp;\
}


/***************************************************************
 * ADD16
 ***************************************************************/
#define ADD16(DR,SR)\
{\
   unsigned long res = DR + SR;\
   F = (F & (SF | ZF | VF)) |\
   (((DR ^ res ^ SR) >> 8) & HF) |\
   ((res >> 16) & CF);\
   DR = res;\
}

/***************************************************************
 * ADC  r16,r16
 ***************************************************************/
#define ADC16(Reg)\
{\
   unsigned long res = HL + Reg + (F & CF);\
   F = (((HL ^ res ^ Reg) >> 8) & HF) |\
   ((res >> 16) & CF) |\
   ((res >> 8) & SF) |\
   ((res & 0xffff) ? 0 : ZF) |\
   (((Reg ^ HL ^ 0x8000) & (Reg ^ res) & 0x8000) >> 13); \
   HL = res;\
}

/***************************************************************
 * SBC  r16,r16
 ***************************************************************/
#define SBC16(Reg)\
{\
   unsigned long res = HL - Reg - (F & CF);\
   F = (((HL ^ res ^ Reg) >> 8) & HF) | NF |\
   ((res >> 16) & CF) |\
   ((res >> 8) & SF) |\
   ((res & 0xffff) ? 0 : ZF) |\
   (((Reg ^ HL) & (HL ^ res) &0x8000) >> 13);\
   HL = res;\
}

/***************************************************************
 * RLC  r8
 ***************************************************************/
inline unsigned char RLC(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x80) ? CF : 0;
   res = ((res << 1) | (res >> 7)) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * RRC  r8
 ***************************************************************/
inline unsigned char RRC(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x01) ? CF : 0;
   res = ((res >> 1) | (res << 7)) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * RL   r8
 ***************************************************************/
inline unsigned char RL(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x80) ? CF : 0;
   res = ((res << 1) | (F & CF)) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * RR   r8
 ***************************************************************/
inline unsigned char RR(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x01) ? CF : 0;
   res = ((res >> 1) | (F << 7)) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * SLA  r8
 ***************************************************************/
inline unsigned char SLA(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x80) ? CF : 0;
   res = (res << 1) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * SRA  r8
 ***************************************************************/
inline unsigned char SRA(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x01) ? CF : 0;
   res = ((res >> 1) | (res & 0x80)) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * SLL  r8
 ***************************************************************/
inline unsigned char SLL(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x80) ? CF : 0;
   res = ((res << 1) | 0x01) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * SRL  r8
 ***************************************************************/
inline unsigned char SRL(unsigned char value)
{
   unsigned res = value;
   unsigned c = (res & 0x01) ? CF : 0;
   res = (res >> 1) & 0xff;
   F = SZP[res] | c;
   return res;
}

/***************************************************************
 * BIT  bit,r8
 ***************************************************************/
#undef BIT
#define BIT(bit,reg)\
   F = (F & CF) | HF | SZ_BIT[reg & (1<<bit)]

/***************************************************************
 * BIT  bit,(IX/Y+o)
 ***************************************************************/
#define BIT_XY(bit,reg)\
   F = (F & CF) | HF | SZ_BIT[reg & (1<<bit)]

/***************************************************************
 * RES  bit,r8
 ***************************************************************/
inline unsigned char RES(unsigned char bit, unsigned char value)
{
   return value & ~(1<<bit);
}

/***************************************************************
 * SET  bit,r8
 ***************************************************************/
inline unsigned char SET(unsigned char bit, unsigned char value)
{
   return value | (1<<bit);
}

/***************************************************************
 * LDI
 ***************************************************************/
#define LDI {\
   WM8( DE, RM8(HL) );\
   F &= SF | ZF | CF;\
   HL++; DE++; BC--;\
   if( BC ) F |= VF;\
}

/***************************************************************
 * CPI
 ***************************************************************/
#define CPI {\
   unsigned char val = RM8(HL);\
   unsigned char res = A - val;\
   HL++; BC--;\
   F = (F & CF) | SZ[res] | ((A^val^res)&HF) | NF;\
   if( F & HF ) res -= 1;\
   if( BC ) F |= VF;\
}

/***************************************************************
 * INI
 ***************************************************************/
#define INI {\
   unsigned t;\
   unsigned char io = IN(BC);\
   B--;\
   WM8( HL, io );\
   HL++;\
   F = SZ[B];\
   t = (unsigned)((C + 1) & 0xff) + (unsigned)io;\
   if( io & SF ) F |= NF;\
   if( t & 0x100 ) F |= HF | CF;\
   F |= SZP[(unsigned char)(t & 0x07) ^ B] & PF;\
}

/***************************************************************
 * OUTI
 ***************************************************************/
#define OUTI {\
   unsigned t;\
   unsigned char io = RM8(HL);\
   B--;\
   OUT( BC, io );\
   HL++;\
   F = SZ[B];\
   t = (unsigned)L + (unsigned)io;\
   if( io & SF ) F |= NF;\
   if( t & 0x100 ) F |= HF | CF;\
   F |= SZP[(unsigned char)(t & 0x07) ^ B] & PF;\
}

/***************************************************************
 * LDD
 ***************************************************************/
#define LDD {\
   WM8( DE, RM8(HL) );\
   F &= SF | ZF | CF;\
   HL--; DE--; BC--;\
   if( BC ) F |= VF;\
}

/***************************************************************
 * CPD
 ***************************************************************/
#define CPD {\
   unsigned char val = RM8(HL);\
   unsigned char res = A - val;\
   HL--; BC--;\
   F = (F & CF) | SZ[res] | ((A^val^res)&HF) | NF;\
   if( F & HF ) res -= 1;\
   if( BC ) F |= VF;\
}

/***************************************************************
 * IND
 ***************************************************************/
#define IND {\
   unsigned t;\
   unsigned char io = IN(BC);\
   B--;\
   WM8( HL, io );\
   HL--;\
   F = SZ[B];\
   t = ((unsigned)(C - 1) & 0xff) + (unsigned)io;\
   if( io & SF ) F |= NF;\
   if( t & 0x100 ) F |= HF | CF;\
   F |= SZP[(unsigned char)(t & 0x07) ^ B] & PF;\
}

/***************************************************************
 * OUTD
 ***************************************************************/
#define OUTD {\
   unsigned t;\
   unsigned char io = RM8(HL);\
   B--;\
   OUT( BC, io );\
   HL--;\
   F = SZ[B];\
   t = (unsigned)L + (unsigned)io;\
   if( io & SF ) F |= NF;\
   if( t & 0x100 ) F |= HF | CF;\
   F |= SZP[(unsigned char)(t & 0x07) ^ B] & PF;\
}

/***************************************************************
 * LDIR
 ***************************************************************/
#define LDIR \
   do \
   { \
      WM8( DE++,  RM8(HL++) );\
   } \
   while(--BC); \
   F &= SF | ZF | CF;

/***************************************************************
 * CPIR
 ***************************************************************/
#define CPIR \
   CPI;\
   if( BC && !(F & ZF) )\
   {\
      PC -= 2;\
   }

/***************************************************************
 * INIR
 ***************************************************************/
#define INIR \
   INI;\
   if( B )\
   {\
      PC -= 2;\
   }

/***************************************************************
 * OTIR
 ***************************************************************/
#define OTIR \
   OUTI;\
   if( B )\
   {\
      PC -= 2;\
   }

/***************************************************************
 * LDDR
 ***************************************************************/
#define LDDR \
   do \
   { \
      WM8( DE, RM8(HL) );\
      HL--; DE--; \
   } \
   while(--BC); \
   F &= SF | ZF | CF;

/***************************************************************
 * CPDR
 ***************************************************************/
#define CPDR \
   CPD;\
   if( BC && !(F & ZF) )\
   {\
      PC -= 2;\
   }

/***************************************************************
 * INDR
 ***************************************************************/
#define INDR \
   IND;\
   if( B )\
   {\
      PC -= 2;\
   }

/***************************************************************
 * OTDR
 ***************************************************************/
#define OTDR \
   OUTD;\
   if( B )\
   {\
      PC -= 2;\
   }

/***************************************************************
 * EI
 ***************************************************************/
#define EI {\
}

/**********************************************************
* opcodes with DD/FD CB prefix
* rotate, shift and bit operations with (IX+o)
**********************************************************/
OP(xycb,00) { B = RLC( RM8(EA) ); WM8( EA,B );} /* RLC  B=(XY+o)    */
OP(xycb,01) { C = RLC( RM8(EA) ); WM8( EA,C );} /* RLC  C=(XY+o)    */
OP(xycb,02) { D = RLC( RM8(EA) ); WM8( EA,D );} /* RLC  D=(XY+o)    */
OP(xycb,03) { E = RLC( RM8(EA) ); WM8( EA,E );} /* RLC  E=(XY+o)    */
OP(xycb,04) { H = RLC( RM8(EA) ); WM8( EA,H );} /* RLC  H=(XY+o)    */
OP(xycb,05) { L = RLC( RM8(EA) ); WM8( EA,L );} /* RLC  L=(XY+o)    */
OP(xycb,06) { WM8( EA, RLC( RM8(EA) ) );} /* RLC  (XY+o)      */
OP(xycb,07) { A = RLC( RM8(EA) ); WM8( EA,A );} /* RLC  A=(XY+o)    */
OP(xycb,08) { B = RRC( RM8(EA) ); WM8( EA,B );} /* RRC  B=(XY+o)    */
OP(xycb,09) { C = RRC( RM8(EA) ); WM8( EA,C );} /* RRC  C=(XY+o)    */
OP(xycb,0a) { D = RRC( RM8(EA) ); WM8( EA,D );} /* RRC  D=(XY+o)    */
OP(xycb,0b) { E = RRC( RM8(EA) ); WM8( EA,E );} /* RRC  E=(XY+o)    */
OP(xycb,0c) { H = RRC( RM8(EA) ); WM8( EA,H );} /* RRC  H=(XY+o)    */
OP(xycb,0d) { L = RRC( RM8(EA) ); WM8( EA,L );} /* RRC  L=(XY+o)    */
OP(xycb,0e) { WM8( EA,RRC( RM8(EA) ) );} /* RRC  (XY+o)      */
OP(xycb,0f) { A = RRC( RM8(EA) ); WM8( EA,A );} /* RRC  A=(XY+o)    */
OP(xycb,10) { B = RL( RM8(EA) ); WM8( EA,B );} /* RL   B=(XY+o)    */
OP(xycb,11) { C = RL( RM8(EA) ); WM8( EA,C );} /* RL   C=(XY+o)    */
OP(xycb,12) { D = RL( RM8(EA) ); WM8( EA,D );} /* RL   D=(XY+o)    */
OP(xycb,13) { E = RL( RM8(EA) ); WM8( EA,E );} /* RL   E=(XY+o)    */
OP(xycb,14) { H = RL( RM8(EA) ); WM8( EA,H );} /* RL   H=(XY+o)    */
OP(xycb,15) { L = RL( RM8(EA) ); WM8( EA,L );} /* RL   L=(XY+o)    */
OP(xycb,16) { WM8( EA,RL( RM8(EA) ) );} /* RL   (XY+o)      */
OP(xycb,17) { A = RL( RM8(EA) ); WM8( EA,A );} /* RL   A=(XY+o)    */
OP(xycb,18) { B = RR( RM8(EA) ); WM8( EA,B );} /* RR   B=(XY+o)    */
OP(xycb,19) { C = RR( RM8(EA) ); WM8( EA,C );} /* RR   C=(XY+o)    */
OP(xycb,1a) { D = RR( RM8(EA) ); WM8( EA,D );} /* RR   D=(XY+o)    */
OP(xycb,1b) { E = RR( RM8(EA) ); WM8( EA,E );} /* RR   E=(XY+o)    */
OP(xycb,1c) { H = RR( RM8(EA) ); WM8( EA,H );} /* RR   H=(XY+o)    */
OP(xycb,1d) { L = RR( RM8(EA) ); WM8( EA,L );} /* RR   L=(XY+o)    */
OP(xycb,1e) { WM8( EA,RR( RM8(EA) ) );} /* RR   (XY+o)      */
OP(xycb,1f) { A = RR( RM8(EA) ); WM8( EA,A );} /* RR   A=(XY+o)    */
OP(xycb,20) { B = SLA( RM8(EA) ); WM8( EA,B );} /* SLA  B=(XY+o)    */
OP(xycb,21) { C = SLA( RM8(EA) ); WM8( EA,C );} /* SLA  C=(XY+o)    */
OP(xycb,22) { D = SLA( RM8(EA) ); WM8( EA,D );} /* SLA  D=(XY+o)    */
OP(xycb,23) { E = SLA( RM8(EA) ); WM8( EA,E );} /* SLA  E=(XY+o)    */
OP(xycb,24) { H = SLA( RM8(EA) ); WM8( EA,H );} /* SLA  H=(XY+o)    */
OP(xycb,25) { L = SLA( RM8(EA) ); WM8( EA,L );} /* SLA  L=(XY+o)    */
OP(xycb,26) { WM8( EA,SLA( RM8(EA) ) );} /* SLA  (XY+o)      */
OP(xycb,27) { A = SLA( RM8(EA) ); WM8( EA,A );} /* SLA  A=(XY+o)    */
OP(xycb,28) { B = SRA( RM8(EA) ); WM8( EA,B );} /* SRA  B=(XY+o)    */
OP(xycb,29) { C = SRA( RM8(EA) ); WM8( EA,C );} /* SRA  C=(XY+o)    */
OP(xycb,2a) { D = SRA( RM8(EA) ); WM8( EA,D );} /* SRA  D=(XY+o)    */
OP(xycb,2b) { E = SRA( RM8(EA) ); WM8( EA,E );} /* SRA  E=(XY+o)    */
OP(xycb,2c) { H = SRA( RM8(EA) ); WM8( EA,H );} /* SRA  H=(XY+o)    */
OP(xycb,2d) { L = SRA( RM8(EA) ); WM8( EA,L );} /* SRA  L=(XY+o)    */
OP(xycb,2e) { WM8( EA,SRA( RM8(EA) ) );} /* SRA  (XY+o)      */
OP(xycb,2f) { A = SRA( RM8(EA) ); WM8( EA,A );} /* SRA  A=(XY+o)    */
OP(xycb,30) { B = SLL( RM8(EA) ); WM8( EA,B );} /* SLL  B=(XY+o)    */
OP(xycb,31) { C = SLL( RM8(EA) ); WM8( EA,C );} /* SLL  C=(XY+o)    */
OP(xycb,32) { D = SLL( RM8(EA) ); WM8( EA,D );} /* SLL  D=(XY+o)    */
OP(xycb,33) { E = SLL( RM8(EA) ); WM8( EA,E );} /* SLL  E=(XY+o)    */
OP(xycb,34) { H = SLL( RM8(EA) ); WM8( EA,H );} /* SLL  H=(XY+o)    */
OP(xycb,35) { L = SLL( RM8(EA) ); WM8( EA,L );} /* SLL  L=(XY+o)    */
OP(xycb,36) { WM8( EA,SLL( RM8(EA) ) );} /* SLL  (XY+o)      */
OP(xycb,37) { A = SLL( RM8(EA) ); WM8( EA,A );} /* SLL  A=(XY+o)    */
OP(xycb,38) { B = SRL( RM8(EA) ); WM8( EA,B );} /* SRL  B=(XY+o)    */
OP(xycb,39) { C = SRL( RM8(EA) ); WM8( EA,C );} /* SRL  C=(XY+o)    */
OP(xycb,3a) { D = SRL( RM8(EA) ); WM8( EA,D );} /* SRL  D=(XY+o)    */
OP(xycb,3b) { E = SRL( RM8(EA) ); WM8( EA,E );} /* SRL  E=(XY+o)    */
OP(xycb,3c) { H = SRL( RM8(EA) ); WM8( EA,H );} /* SRL  H=(XY+o)    */
OP(xycb,3d) { L = SRL( RM8(EA) ); WM8( EA,L );} /* SRL  L=(XY+o)    */
OP(xycb,3e) { WM8( EA,SRL( RM8(EA) ) );} /* SRL  (XY+o)      */
OP(xycb,3f) { A = SRL( RM8(EA) ); WM8( EA,A );} /* SRL  A=(XY+o)    */
OP(xycb,46) { BIT_XY(0,RM8(EA));} /* BIT  0,(XY+o)    */
OP(xycb,40) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,41) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,42) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,43) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,44) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,45) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,47) { xycb_46();} /* BIT  0,(XY+o)    */
OP(xycb,4e) { BIT_XY(1,RM8(EA));} /* BIT  1,(XY+o)    */
OP(xycb,48) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,49) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,4a) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,4b) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,4c) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,4d) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,4f) { xycb_4e();} /* BIT  1,(XY+o)    */
OP(xycb,56) { BIT_XY(2,RM8(EA));} /* BIT  2,(XY+o)    */
OP(xycb,50) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,51) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,52) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,53) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,54) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,55) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,57) { xycb_56();} /* BIT  2,(XY+o)    */
OP(xycb,5e) { BIT_XY(3,RM8(EA));} /* BIT  3,(XY+o)    */
OP(xycb,58) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,59) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,5a) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,5b) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,5c) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,5d) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,5f) { xycb_5e();} /* BIT  3,(XY+o)    */
OP(xycb,66) { BIT_XY(4,RM8(EA));} /* BIT  4,(XY+o)    */
OP(xycb,60) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,61) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,62) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,63) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,64) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,65) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,67) { xycb_66();} /* BIT  4,(XY+o)    */
OP(xycb,6e) { BIT_XY(5,RM8(EA));} /* BIT  5,(XY+o)    */
OP(xycb,68) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,69) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,6a) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,6b) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,6c) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,6d) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,6f) { xycb_6e();} /* BIT  5,(XY+o)    */
OP(xycb,76) { BIT_XY(6,RM8(EA));} /* BIT  6,(XY+o)    */
OP(xycb,70) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,71) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,72) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,73) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,74) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,75) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,77) { xycb_76();} /* BIT  6,(XY+o)    */
OP(xycb,7e) { BIT_XY(7,RM8(EA));} /* BIT  7,(XY+o)    */
OP(xycb,78) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,79) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,7a) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,7b) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,7c) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,7d) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,7f) { xycb_7e();} /* BIT  7,(XY+o)    */
OP(xycb,80) { B = RES(0, RM8(EA) ); WM8( EA,B );} /* RES  0,B=(XY+o)  */
OP(xycb,81) { C = RES(0, RM8(EA) ); WM8( EA,C );} /* RES  0,C=(XY+o)  */
OP(xycb,82) { D = RES(0, RM8(EA) ); WM8( EA,D );} /* RES  0,D=(XY+o)  */
OP(xycb,83) { E = RES(0, RM8(EA) ); WM8( EA,E );} /* RES  0,E=(XY+o)  */
OP(xycb,84) { H = RES(0, RM8(EA) ); WM8( EA,H );} /* RES  0,H=(XY+o)  */
OP(xycb,85) { L = RES(0, RM8(EA) ); WM8( EA,L );} /* RES  0,L=(XY+o)  */
OP(xycb,86) { WM8( EA, RES(0,RM8(EA)) );} /* RES  0,(XY+o)    */
OP(xycb,87) { A = RES(0, RM8(EA) ); WM8( EA,A );} /* RES  0,A=(XY+o)  */
OP(xycb,88) { B = RES(1, RM8(EA) ); WM8( EA,B );} /* RES  1,B=(XY+o)  */
OP(xycb,89) { C = RES(1, RM8(EA) ); WM8( EA,C );} /* RES  1,C=(XY+o)  */
OP(xycb,8a) { D = RES(1, RM8(EA) ); WM8( EA,D );} /* RES  1,D=(XY+o)  */
OP(xycb,8b) { E = RES(1, RM8(EA) ); WM8( EA,E );} /* RES  1,E=(XY+o)  */
OP(xycb,8c) { H = RES(1, RM8(EA) ); WM8( EA,H );} /* RES  1,H=(XY+o)  */
OP(xycb,8d) { L = RES(1, RM8(EA) ); WM8( EA,L );} /* RES  1,L=(XY+o)  */
OP(xycb,8e) { WM8( EA, RES(1,RM8(EA)) );} /* RES  1,(XY+o)    */
OP(xycb,8f) { A = RES(1, RM8(EA) ); WM8( EA,A );} /* RES  1,A=(XY+o)  */
OP(xycb,90) { B = RES(2, RM8(EA) ); WM8( EA,B );} /* RES  2,B=(XY+o)  */
OP(xycb,91) { C = RES(2, RM8(EA) ); WM8( EA,C );} /* RES  2,C=(XY+o)  */
OP(xycb,92) { D = RES(2, RM8(EA) ); WM8( EA,D );} /* RES  2,D=(XY+o)  */
OP(xycb,93) { E = RES(2, RM8(EA) ); WM8( EA,E );} /* RES  2,E=(XY+o)  */
OP(xycb,94) { H = RES(2, RM8(EA) ); WM8( EA,H );} /* RES  2,H=(XY+o)  */
OP(xycb,95) { L = RES(2, RM8(EA) ); WM8( EA,L );} /* RES  2,L=(XY+o)  */
OP(xycb,96) { WM8( EA, RES(2,RM8(EA)) );} /* RES  2,(XY+o)    */
OP(xycb,97) { A = RES(2, RM8(EA) ); WM8( EA,A );} /* RES  2,A=(XY+o)  */
OP(xycb,98) { B = RES(3, RM8(EA) ); WM8( EA,B );} /* RES  3,B=(XY+o)  */
OP(xycb,99) { C = RES(3, RM8(EA) ); WM8( EA,C );} /* RES  3,C=(XY+o)  */
OP(xycb,9a) { D = RES(3, RM8(EA) ); WM8( EA,D );} /* RES  3,D=(XY+o)  */
OP(xycb,9b) { E = RES(3, RM8(EA) ); WM8( EA,E );} /* RES  3,E=(XY+o)  */
OP(xycb,9c) { H = RES(3, RM8(EA) ); WM8( EA,H );} /* RES  3,H=(XY+o)  */
OP(xycb,9d) { L = RES(3, RM8(EA) ); WM8( EA,L );} /* RES  3,L=(XY+o)  */
OP(xycb,9e) { WM8( EA, RES(3,RM8(EA)) );} /* RES  3,(XY+o)    */
OP(xycb,9f) { A = RES(3, RM8(EA) ); WM8( EA,A );} /* RES  3,A=(XY+o)  */
OP(xycb,a0) { B = RES(4, RM8(EA) ); WM8( EA,B );} /* RES  4,B=(XY+o)  */
OP(xycb,a1) { C = RES(4, RM8(EA) ); WM8( EA,C );} /* RES  4,C=(XY+o)  */
OP(xycb,a2) { D = RES(4, RM8(EA) ); WM8( EA,D );} /* RES  4,D=(XY+o)  */
OP(xycb,a3) { E = RES(4, RM8(EA) ); WM8( EA,E );} /* RES  4,E=(XY+o)  */
OP(xycb,a4) { H = RES(4, RM8(EA) ); WM8( EA,H );} /* RES  4,H=(XY+o)  */
OP(xycb,a5) { L = RES(4, RM8(EA) ); WM8( EA,L );} /* RES  4,L=(XY+o)  */
OP(xycb,a6) { WM8( EA, RES(4,RM8(EA)) );} /* RES  4,(XY+o)    */
OP(xycb,a7) { A = RES(4, RM8(EA) ); WM8( EA,A );} /* RES  4,A=(XY+o)  */
OP(xycb,a8) { B = RES(5, RM8(EA) ); WM8( EA,B );} /* RES  5,B=(XY+o)  */
OP(xycb,a9) { C = RES(5, RM8(EA) ); WM8( EA,C );} /* RES  5,C=(XY+o)  */
OP(xycb,aa) { D = RES(5, RM8(EA) ); WM8( EA,D );} /* RES  5,D=(XY+o)  */
OP(xycb,ab) { E = RES(5, RM8(EA) ); WM8( EA,E );} /* RES  5,E=(XY+o)  */
OP(xycb,ac) { H = RES(5, RM8(EA) ); WM8( EA,H );} /* RES  5,H=(XY+o)  */
OP(xycb,ad) { L = RES(5, RM8(EA) ); WM8( EA,L );} /* RES  5,L=(XY+o)  */
OP(xycb,ae) { WM8( EA, RES(5,RM8(EA)) );} /* RES  5,(XY+o)    */
OP(xycb,af) { A = RES(5, RM8(EA) ); WM8( EA,A );} /* RES  5,A=(XY+o)  */
OP(xycb,b0) { B = RES(6, RM8(EA) ); WM8( EA,B );} /* RES  6,B=(XY+o)  */
OP(xycb,b1) { C = RES(6, RM8(EA) ); WM8( EA,C );} /* RES  6,C=(XY+o)  */
OP(xycb,b2) { D = RES(6, RM8(EA) ); WM8( EA,D );} /* RES  6,D=(XY+o)  */
OP(xycb,b3) { E = RES(6, RM8(EA) ); WM8( EA,E );} /* RES  6,E=(XY+o)  */
OP(xycb,b4) { H = RES(6, RM8(EA) ); WM8( EA,H );} /* RES  6,H=(XY+o)  */
OP(xycb,b5) { L = RES(6, RM8(EA) ); WM8( EA,L );} /* RES  6,L=(XY+o)  */
OP(xycb,b6) { WM8( EA, RES(6,RM8(EA)) );} /* RES  6,(XY+o)    */
OP(xycb,b7) { A = RES(6, RM8(EA) ); WM8( EA,A );} /* RES  6,A=(XY+o)  */
OP(xycb,b8) { B = RES(7, RM8(EA) ); WM8( EA,B );} /* RES  7,B=(XY+o)  */
OP(xycb,b9) { C = RES(7, RM8(EA) ); WM8( EA,C );} /* RES  7,C=(XY+o)  */
OP(xycb,ba) { D = RES(7, RM8(EA) ); WM8( EA,D );} /* RES  7,D=(XY+o)  */
OP(xycb,bb) { E = RES(7, RM8(EA) ); WM8( EA,E );} /* RES  7,E=(XY+o)  */
OP(xycb,bc) { H = RES(7, RM8(EA) ); WM8( EA,H );} /* RES  7,H=(XY+o)  */
OP(xycb,bd) { L = RES(7, RM8(EA) ); WM8( EA,L );} /* RES  7,L=(XY+o)  */
OP(xycb,be) { WM8( EA, RES(7,RM8(EA)) );} /* RES  7,(XY+o)    */
OP(xycb,bf) { A = RES(7, RM8(EA) ); WM8( EA,A );} /* RES  7,A=(XY+o)  */
OP(xycb,c0) { B = SET(0, RM8(EA) ); WM8( EA,B );} /* SET  0,B=(XY+o)  */
OP(xycb,c1) { C = SET(0, RM8(EA) ); WM8( EA,C );} /* SET  0,C=(XY+o)  */
OP(xycb,c2) { D = SET(0, RM8(EA) ); WM8( EA,D );} /* SET  0,D=(XY+o)  */
OP(xycb,c3) { E = SET(0, RM8(EA) ); WM8( EA,E );} /* SET  0,E=(XY+o)  */
OP(xycb,c4) { H = SET(0, RM8(EA) ); WM8( EA,H );} /* SET  0,H=(XY+o)  */
OP(xycb,c5) { L = SET(0, RM8(EA) ); WM8( EA,L );} /* SET  0,L=(XY+o)  */
OP(xycb,c6) { WM8( EA, SET(0,RM8(EA)) );} /* SET  0,(XY+o)    */
OP(xycb,c7) { A = SET(0, RM8(EA) ); WM8( EA,A );} /* SET  0,A=(XY+o)  */
OP(xycb,c8) { B = SET(1, RM8(EA) ); WM8( EA,B );} /* SET  1,B=(XY+o)  */
OP(xycb,c9) { C = SET(1, RM8(EA) ); WM8( EA,C );} /* SET  1,C=(XY+o)  */
OP(xycb,ca) { D = SET(1, RM8(EA) ); WM8( EA,D );} /* SET  1,D=(XY+o)  */
OP(xycb,cb) { E = SET(1, RM8(EA) ); WM8( EA,E );} /* SET  1,E=(XY+o)  */
OP(xycb,cc) { H = SET(1, RM8(EA) ); WM8( EA,H );} /* SET  1,H=(XY+o)  */
OP(xycb,cd) { L = SET(1, RM8(EA) ); WM8( EA,L );} /* SET  1,L=(XY+o)  */
OP(xycb,ce) { WM8( EA, SET(1,RM8(EA)) );} /* SET  1,(XY+o)    */
OP(xycb,cf) { A = SET(1, RM8(EA) ); WM8( EA,A );} /* SET  1,A=(XY+o)  */
OP(xycb,d0) { B = SET(2, RM8(EA) ); WM8( EA,B );} /* SET  2,B=(XY+o)  */
OP(xycb,d1) { C = SET(2, RM8(EA) ); WM8( EA,C );} /* SET  2,C=(XY+o)  */
OP(xycb,d2) { D = SET(2, RM8(EA) ); WM8( EA,D );} /* SET  2,D=(XY+o)  */
OP(xycb,d3) { E = SET(2, RM8(EA) ); WM8( EA,E );} /* SET  2,E=(XY+o)  */
OP(xycb,d4) { H = SET(2, RM8(EA) ); WM8( EA,H );} /* SET  2,H=(XY+o)  */
OP(xycb,d5) { L = SET(2, RM8(EA) ); WM8( EA,L );} /* SET  2,L=(XY+o)  */
OP(xycb,d6) { WM8( EA, SET(2,RM8(EA)) );} /* SET  2,(XY+o)    */
OP(xycb,d7) { A = SET(2, RM8(EA) ); WM8( EA,A );} /* SET  2,A=(XY+o)  */
OP(xycb,d8) { B = SET(3, RM8(EA) ); WM8( EA,B );} /* SET  3,B=(XY+o)  */
OP(xycb,d9) { C = SET(3, RM8(EA) ); WM8( EA,C );} /* SET  3,C=(XY+o)  */
OP(xycb,da) { D = SET(3, RM8(EA) ); WM8( EA,D );} /* SET  3,D=(XY+o)  */
OP(xycb,db) { E = SET(3, RM8(EA) ); WM8( EA,E );} /* SET  3,E=(XY+o)  */
OP(xycb,dc) { H = SET(3, RM8(EA) ); WM8( EA,H );} /* SET  3,H=(XY+o)  */
OP(xycb,dd) { L = SET(3, RM8(EA) ); WM8( EA,L );} /* SET  3,L=(XY+o)  */
OP(xycb,de) { WM8( EA, SET(3,RM8(EA)) );} /* SET  3,(XY+o)    */
OP(xycb,df) { A = SET(3, RM8(EA) ); WM8( EA,A );} /* SET  3,A=(XY+o)  */
OP(xycb,e0) { B = SET(4, RM8(EA) ); WM8( EA,B );} /* SET  4,B=(XY+o)  */
OP(xycb,e1) { C = SET(4, RM8(EA) ); WM8( EA,C );} /* SET  4,C=(XY+o)  */
OP(xycb,e2) { D = SET(4, RM8(EA) ); WM8( EA,D );} /* SET  4,D=(XY+o)  */
OP(xycb,e3) { E = SET(4, RM8(EA) ); WM8( EA,E );} /* SET  4,E=(XY+o)  */
OP(xycb,e4) { H = SET(4, RM8(EA) ); WM8( EA,H );} /* SET  4,H=(XY+o)  */
OP(xycb,e5) { L = SET(4, RM8(EA) ); WM8( EA,L );} /* SET  4,L=(XY+o)  */
OP(xycb,e6) { WM8( EA, SET(4,RM8(EA)) );} /* SET  4,(XY+o)    */
OP(xycb,e7) { A = SET(4, RM8(EA) ); WM8( EA,A );} /* SET  4,A=(XY+o)  */
OP(xycb,e8) { B = SET(5, RM8(EA) ); WM8( EA,B );} /* SET  5,B=(XY+o)  */
OP(xycb,e9) { C = SET(5, RM8(EA) ); WM8( EA,C );} /* SET  5,C=(XY+o)  */
OP(xycb,ea) { D = SET(5, RM8(EA) ); WM8( EA,D );} /* SET  5,D=(XY+o)  */
OP(xycb,eb) { E = SET(5, RM8(EA) ); WM8( EA,E );} /* SET  5,E=(XY+o)  */
OP(xycb,ec) { H = SET(5, RM8(EA) ); WM8( EA,H );} /* SET  5,H=(XY+o)  */
OP(xycb,ed) { L = SET(5, RM8(EA) ); WM8( EA,L );} /* SET  5,L=(XY+o)  */
OP(xycb,ee) { WM8( EA, SET(5,RM8(EA)) );} /* SET  5,(XY+o)    */
OP(xycb,ef) { A = SET(5, RM8(EA) ); WM8( EA,A );} /* SET  5,A=(XY+o)  */
OP(xycb,f0) { B = SET(6, RM8(EA) ); WM8( EA,B );} /* SET  6,B=(XY+o)  */
OP(xycb,f1) { C = SET(6, RM8(EA) ); WM8( EA,C );} /* SET  6,C=(XY+o)  */
OP(xycb,f2) { D = SET(6, RM8(EA) ); WM8( EA,D );} /* SET  6,D=(XY+o)  */
OP(xycb,f3) { E = SET(6, RM8(EA) ); WM8( EA,E );} /* SET  6,E=(XY+o)  */
OP(xycb,f4) { H = SET(6, RM8(EA) ); WM8( EA,H );} /* SET  6,H=(XY+o)  */
OP(xycb,f5) { L = SET(6, RM8(EA) ); WM8( EA,L );} /* SET  6,L=(XY+o)  */
OP(xycb,f6) { WM8( EA, SET(6,RM8(EA)) );} /* SET  6,(XY+o)    */
OP(xycb,f7) { A = SET(6, RM8(EA) ); WM8( EA,A );} /* SET  6,A=(XY+o)  */
OP(xycb,f8) { B = SET(7, RM8(EA) ); WM8( EA,B );} /* SET  7,B=(XY+o)  */
OP(xycb,f9) { C = SET(7, RM8(EA) ); WM8( EA,C );} /* SET  7,C=(XY+o)  */
OP(xycb,fa) { D = SET(7, RM8(EA) ); WM8( EA,D );} /* SET  7,D=(XY+o)  */
OP(xycb,fb) { E = SET(7, RM8(EA) ); WM8( EA,E );} /* SET  7,E=(XY+o)  */
OP(xycb,fc) { H = SET(7, RM8(EA) ); WM8( EA,H );} /* SET  7,H=(XY+o)  */
OP(xycb,fd) { L = SET(7, RM8(EA) ); WM8( EA,L );} /* SET  7,L=(XY+o)  */
OP(xycb,fe) { WM8( EA, SET(7,RM8(EA)) );} /* SET  7,(XY+o)    */
OP(xycb,ff) { A = SET(7, RM8(EA) ); WM8( EA,A );} /* SET  7,A=(XY+o)  */

static const Function Z80xycb[0x100]=
{
   (Function)xycb_00,(Function)xycb_01,(Function)xycb_02,(Function)xycb_03,(Function)xycb_04,(Function)xycb_05,(Function)xycb_06,(Function)xycb_07,
   (Function)xycb_08,(Function)xycb_09,(Function)xycb_0a,(Function)xycb_0b,(Function)xycb_0c,(Function)xycb_0d,(Function)xycb_0e,(Function)xycb_0f,
   (Function)xycb_10,(Function)xycb_11,(Function)xycb_12,(Function)xycb_13,(Function)xycb_14,(Function)xycb_15,(Function)xycb_16,(Function)xycb_17,
   (Function)xycb_18,(Function)xycb_19,(Function)xycb_1a,(Function)xycb_1b,(Function)xycb_1c,(Function)xycb_1d,(Function)xycb_1e,(Function)xycb_1f,
   (Function)xycb_20,(Function)xycb_21,(Function)xycb_22,(Function)xycb_23,(Function)xycb_24,(Function)xycb_25,(Function)xycb_26,(Function)xycb_27,
   (Function)xycb_28,(Function)xycb_29,(Function)xycb_2a,(Function)xycb_2b,(Function)xycb_2c,(Function)xycb_2d,(Function)xycb_2e,(Function)xycb_2f,
   (Function)xycb_30,(Function)xycb_31,(Function)xycb_32,(Function)xycb_33,(Function)xycb_34,(Function)xycb_35,(Function)xycb_36,(Function)xycb_37,
   (Function)xycb_38,(Function)xycb_39,(Function)xycb_3a,(Function)xycb_3b,(Function)xycb_3c,(Function)xycb_3d,(Function)xycb_3e,(Function)xycb_3f,
   (Function)xycb_40,(Function)xycb_41,(Function)xycb_42,(Function)xycb_43,(Function)xycb_44,(Function)xycb_45,(Function)xycb_46,(Function)xycb_47,
   (Function)xycb_48,(Function)xycb_49,(Function)xycb_4a,(Function)xycb_4b,(Function)xycb_4c,(Function)xycb_4d,(Function)xycb_4e,(Function)xycb_4f,
   (Function)xycb_50,(Function)xycb_51,(Function)xycb_52,(Function)xycb_53,(Function)xycb_54,(Function)xycb_55,(Function)xycb_56,(Function)xycb_57,
   (Function)xycb_58,(Function)xycb_59,(Function)xycb_5a,(Function)xycb_5b,(Function)xycb_5c,(Function)xycb_5d,(Function)xycb_5e,(Function)xycb_5f,
   (Function)xycb_60,(Function)xycb_61,(Function)xycb_62,(Function)xycb_63,(Function)xycb_64,(Function)xycb_65,(Function)xycb_66,(Function)xycb_67,
   (Function)xycb_68,(Function)xycb_69,(Function)xycb_6a,(Function)xycb_6b,(Function)xycb_6c,(Function)xycb_6d,(Function)xycb_6e,(Function)xycb_6f,
   (Function)xycb_70,(Function)xycb_71,(Function)xycb_72,(Function)xycb_73,(Function)xycb_74,(Function)xycb_75,(Function)xycb_76,(Function)xycb_77,
   (Function)xycb_78,(Function)xycb_79,(Function)xycb_7a,(Function)xycb_7b,(Function)xycb_7c,(Function)xycb_7d,(Function)xycb_7e,(Function)xycb_7f,
   (Function)xycb_80,(Function)xycb_81,(Function)xycb_82,(Function)xycb_83,(Function)xycb_84,(Function)xycb_85,(Function)xycb_86,(Function)xycb_87,
   (Function)xycb_88,(Function)xycb_89,(Function)xycb_8a,(Function)xycb_8b,(Function)xycb_8c,(Function)xycb_8d,(Function)xycb_8e,(Function)xycb_8f,
   (Function)xycb_90,(Function)xycb_91,(Function)xycb_92,(Function)xycb_93,(Function)xycb_94,(Function)xycb_95,(Function)xycb_96,(Function)xycb_97,
   (Function)xycb_98,(Function)xycb_99,(Function)xycb_9a,(Function)xycb_9b,(Function)xycb_9c,(Function)xycb_9d,(Function)xycb_9e,(Function)xycb_9f,
   (Function)xycb_a0,(Function)xycb_a1,(Function)xycb_a2,(Function)xycb_a3,(Function)xycb_a4,(Function)xycb_a5,(Function)xycb_a6,(Function)xycb_a7,
   (Function)xycb_a8,(Function)xycb_a9,(Function)xycb_aa,(Function)xycb_ab,(Function)xycb_ac,(Function)xycb_ad,(Function)xycb_ae,(Function)xycb_af,
   (Function)xycb_b0,(Function)xycb_b1,(Function)xycb_b2,(Function)xycb_b3,(Function)xycb_b4,(Function)xycb_b5,(Function)xycb_b6,(Function)xycb_b7,
   (Function)xycb_b8,(Function)xycb_b9,(Function)xycb_ba,(Function)xycb_bb,(Function)xycb_bc,(Function)xycb_bd,(Function)xycb_be,(Function)xycb_bf,
   (Function)xycb_c0,(Function)xycb_c1,(Function)xycb_c2,(Function)xycb_c3,(Function)xycb_c4,(Function)xycb_c5,(Function)xycb_c6,(Function)xycb_c7,
   (Function)xycb_c8,(Function)xycb_c9,(Function)xycb_ca,(Function)xycb_cb,(Function)xycb_cc,(Function)xycb_cd,(Function)xycb_ce,(Function)xycb_cf,
   (Function)xycb_d0,(Function)xycb_d1,(Function)xycb_d2,(Function)xycb_d3,(Function)xycb_d4,(Function)xycb_d5,(Function)xycb_d6,(Function)xycb_d7,
   (Function)xycb_d8,(Function)xycb_d9,(Function)xycb_da,(Function)xycb_db,(Function)xycb_dc,(Function)xycb_dd,(Function)xycb_de,(Function)xycb_df,
   (Function)xycb_e0,(Function)xycb_e1,(Function)xycb_e2,(Function)xycb_e3,(Function)xycb_e4,(Function)xycb_e5,(Function)xycb_e6,(Function)xycb_e7,
   (Function)xycb_e8,(Function)xycb_e9,(Function)xycb_ea,(Function)xycb_eb,(Function)xycb_ec,(Function)xycb_ed,(Function)xycb_ee,(Function)xycb_ef,
   (Function)xycb_f0,(Function)xycb_f1,(Function)xycb_f2,(Function)xycb_f3,(Function)xycb_f4,(Function)xycb_f5,(Function)xycb_f6,(Function)xycb_f7,
   (Function)xycb_f8,(Function)xycb_f9,(Function)xycb_fa,(Function)xycb_fb,(Function)xycb_fc,(Function)xycb_fd,(Function)xycb_fe,(Function)xycb_ff
};

/**********************************************************
 * opcodes with CB prefix
 * rotate, shift and bit operations
 **********************************************************/
OP(cb,00) { B = RLC(B);} /* RLC  B           */
OP(cb,01) { C = RLC(C);} /* RLC  C           */
OP(cb,02) { D = RLC(D);} /* RLC  D           */
OP(cb,03) { E = RLC(E);} /* RLC  E           */
OP(cb,04) { H = RLC(H);} /* RLC  H           */
OP(cb,05) { L = RLC(L);} /* RLC  L           */
OP(cb,06) { WM8( HL, RLC(RM8(HL)) );} /* RLC  (HL)        */
OP(cb,07) { A = RLC(A);} /* RLC  A           */
OP(cb,08) { B = RRC(B);} /* RRC  B           */
OP(cb,09) { C = RRC(C);} /* RRC  C           */
OP(cb,0a) { D = RRC(D);} /* RRC  D           */
OP(cb,0b) { E = RRC(E);} /* RRC  E           */
OP(cb,0c) { H = RRC(H);} /* RRC  H           */
OP(cb,0d) { L = RRC(L);} /* RRC  L           */
OP(cb,0e) { WM8( HL, RRC(RM8(HL)) );} /* RRC  (HL)        */
OP(cb,0f) { A = RRC(A);} /* RRC  A           */
OP(cb,10) { B = RL(B);} /* RL   B           */
OP(cb,11) { C = RL(C);} /* RL   C           */
OP(cb,12) { D = RL(D);} /* RL   D           */
OP(cb,13) { E = RL(E);} /* RL   E           */
OP(cb,14) { H = RL(H);} /* RL   H           */
OP(cb,15) { L = RL(L);} /* RL   L           */
OP(cb,16) { WM8( HL, RL(RM8(HL)) );} /* RL   (HL)        */
OP(cb,17) { A = RL(A);} /* RL   A           */
OP(cb,18) { B = RR(B);} /* RR   B           */
OP(cb,19) { C = RR(C);} /* RR   C           */
OP(cb,1a) { D = RR(D);} /* RR   D           */
OP(cb,1b) { E = RR(E);} /* RR   E           */
OP(cb,1c) { H = RR(H);} /* RR   H           */
OP(cb,1d) { L = RR(L);} /* RR   L           */
OP(cb,1e) { WM8( HL, RR(RM8(HL)) );} /* RR   (HL)        */
OP(cb,1f) { A = RR(A);} /* RR   A           */
OP(cb,20) { B = SLA(B);} /* SLA  B           */
OP(cb,21) { C = SLA(C);} /* SLA  C           */
OP(cb,22) { D = SLA(D);} /* SLA  D           */
OP(cb,23) { E = SLA(E);} /* SLA  E           */
OP(cb,24) { H = SLA(H);} /* SLA  H           */
OP(cb,25) { L = SLA(L);} /* SLA  L           */
OP(cb,26) { WM8( HL, SLA(RM8(HL)) );} /* SLA  (HL)        */
OP(cb,27) { A = SLA(A);} /* SLA  A           */
OP(cb,28) { B = SRA(B);} /* SRA  B           */
OP(cb,29) { C = SRA(C);} /* SRA  C           */
OP(cb,2a) { D = SRA(D);} /* SRA  D           */
OP(cb,2b) { E = SRA(E);} /* SRA  E           */
OP(cb,2c) { H = SRA(H);} /* SRA  H           */
OP(cb,2d) { L = SRA(L);} /* SRA  L           */
OP(cb,2e) { WM8( HL, SRA(RM8(HL)) );} /* SRA  (HL)        */
OP(cb,2f) { A = SRA(A);} /* SRA  A           */
OP(cb,30) { B = SLL(B);} /* SLL  B           */
OP(cb,31) { C = SLL(C);} /* SLL  C           */
OP(cb,32) { D = SLL(D);} /* SLL  D           */
OP(cb,33) { E = SLL(E);} /* SLL  E           */
OP(cb,34) { H = SLL(H);} /* SLL  H           */
OP(cb,35) { L = SLL(L);} /* SLL  L           */
OP(cb,36) { WM8( HL, SLL(RM8(HL)) );} /* SLL  (HL)        */
OP(cb,37) { A = SLL(A);} /* SLL  A           */
OP(cb,38) { B = SRL(B);} /* SRL  B           */
OP(cb,39) { C = SRL(C);} /* SRL  C           */
OP(cb,3a) { D = SRL(D);} /* SRL  D           */
OP(cb,3b) { E = SRL(E);} /* SRL  E           */
OP(cb,3c) { H = SRL(H);} /* SRL  H           */
OP(cb,3d) { L = SRL(L);} /* SRL  L           */
OP(cb,3e) { WM8( HL, SRL(RM8(HL)) );} /* SRL  (HL)        */
OP(cb,3f) { A = SRL(A);} /* SRL  A           */
OP(cb,40) { BIT(0,B);} /* BIT  0,B         */
OP(cb,41) { BIT(0,C);} /* BIT  0,C         */
OP(cb,42) { BIT(0,D);} /* BIT  0,D         */
OP(cb,43) { BIT(0,E);} /* BIT  0,E         */
OP(cb,44) { BIT(0,H);} /* BIT  0,H         */
OP(cb,45) { BIT(0,L);} /* BIT  0,L         */
OP(cb,46) { BIT(0,RM8(HL));} /* BIT  0,(HL)      */
OP(cb,47) { BIT(0,A);} /* BIT  0,A         */
OP(cb,48) { BIT(1,B);} /* BIT  1,B         */
OP(cb,49) { BIT(1,C);} /* BIT  1,C         */
OP(cb,4a) { BIT(1,D);} /* BIT  1,D         */
OP(cb,4b) { BIT(1,E);} /* BIT  1,E         */
OP(cb,4c) { BIT(1,H);} /* BIT  1,H         */
OP(cb,4d) { BIT(1,L);} /* BIT  1,L         */
OP(cb,4e) { BIT(1,RM8(HL));} /* BIT  1,(HL)      */
OP(cb,4f) { BIT(1,A);} /* BIT  1,A         */
OP(cb,50) { BIT(2,B);} /* BIT  2,B         */
OP(cb,51) { BIT(2,C);} /* BIT  2,C         */
OP(cb,52) { BIT(2,D);} /* BIT  2,D         */
OP(cb,53) { BIT(2,E);} /* BIT  2,E         */
OP(cb,54) { BIT(2,H);} /* BIT  2,H         */
OP(cb,55) { BIT(2,L);} /* BIT  2,L         */
OP(cb,56) { BIT(2,RM8(HL));} /* BIT  2,(HL)      */
OP(cb,57) { BIT(2,A);} /* BIT  2,A         */
OP(cb,58) { BIT(3,B);} /* BIT  3,B         */
OP(cb,59) { BIT(3,C);} /* BIT  3,C         */
OP(cb,5a) { BIT(3,D);} /* BIT  3,D         */
OP(cb,5b) { BIT(3,E);} /* BIT  3,E         */
OP(cb,5c) { BIT(3,H);} /* BIT  3,H         */
OP(cb,5d) { BIT(3,L);} /* BIT  3,L         */
OP(cb,5e) { BIT(3,RM8(HL));} /* BIT  3,(HL)      */
OP(cb,5f) { BIT(3,A);} /* BIT  3,A         */
OP(cb,60) { BIT(4,B);} /* BIT  4,B         */
OP(cb,61) { BIT(4,C);} /* BIT  4,C         */
OP(cb,62) { BIT(4,D);} /* BIT  4,D         */
OP(cb,63) { BIT(4,E);} /* BIT  4,E         */
OP(cb,64) { BIT(4,H);} /* BIT  4,H         */
OP(cb,65) { BIT(4,L);} /* BIT  4,L         */
OP(cb,66) { BIT(4,RM8(HL));} /* BIT  4,(HL)      */
OP(cb,67) { BIT(4,A);} /* BIT  4,A         */
OP(cb,68) { BIT(5,B);} /* BIT  5,B         */
OP(cb,69) { BIT(5,C);} /* BIT  5,C         */
OP(cb,6a) { BIT(5,D);} /* BIT  5,D         */
OP(cb,6b) { BIT(5,E);} /* BIT  5,E         */
OP(cb,6c) { BIT(5,H);} /* BIT  5,H         */
OP(cb,6d) { BIT(5,L);} /* BIT  5,L         */
OP(cb,6e) { BIT(5,RM8(HL));} /* BIT  5,(HL)      */
OP(cb,6f) { BIT(5,A);} /* BIT  5,A         */
OP(cb,70) { BIT(6,B);} /* BIT  6,B         */
OP(cb,71) { BIT(6,C);} /* BIT  6,C         */
OP(cb,72) { BIT(6,D);} /* BIT  6,D         */
OP(cb,73) { BIT(6,E);} /* BIT  6,E         */
OP(cb,74) { BIT(6,H);} /* BIT  6,H         */
OP(cb,75) { BIT(6,L);} /* BIT  6,L         */
OP(cb,76) { BIT(6,RM8(HL));} /* BIT  6,(HL)      */
OP(cb,77) { BIT(6,A);} /* BIT  6,A         */
OP(cb,78) { BIT(7,B);} /* BIT  7,B         */
OP(cb,79) { BIT(7,C);} /* BIT  7,C         */
OP(cb,7a) { BIT(7,D);} /* BIT  7,D         */
OP(cb,7b) { BIT(7,E);} /* BIT  7,E         */
OP(cb,7c) { BIT(7,H);} /* BIT  7,H         */
OP(cb,7d) { BIT(7,L);} /* BIT  7,L         */
OP(cb,7e) { BIT(7,RM8(HL));} /* BIT  7,(HL)      */
OP(cb,7f) { BIT(7,A);} /* BIT  7,A         */
OP(cb,80) { B = RES(0,B);} /* RES  0,B         */
OP(cb,81) { C = RES(0,C);} /* RES  0,C         */
OP(cb,82) { D = RES(0,D);} /* RES  0,D         */
OP(cb,83) { E = RES(0,E);} /* RES  0,E         */
OP(cb,84) { H = RES(0,H);} /* RES  0,H         */
OP(cb,85) { L = RES(0,L);} /* RES  0,L         */
OP(cb,86) { WM8( HL, RES(0,RM8(HL)) );} /* RES  0,(HL)      */
OP(cb,87) { A = RES(0,A);} /* RES  0,A         */
OP(cb,88) { B = RES(1,B);} /* RES  1,B         */
OP(cb,89) { C = RES(1,C);} /* RES  1,C         */
OP(cb,8a) { D = RES(1,D);} /* RES  1,D         */
OP(cb,8b) { E = RES(1,E);} /* RES  1,E         */
OP(cb,8c) { H = RES(1,H);} /* RES  1,H         */
OP(cb,8d) { L = RES(1,L);} /* RES  1,L         */
OP(cb,8e) { WM8( HL, RES(1,RM8(HL)) );} /* RES  1,(HL)      */
OP(cb,8f) { A = RES(1,A);} /* RES  1,A         */
OP(cb,90) { B = RES(2,B);} /* RES  2,B         */
OP(cb,91) { C = RES(2,C);} /* RES  2,C         */
OP(cb,92) { D = RES(2,D);} /* RES  2,D         */
OP(cb,93) { E = RES(2,E);} /* RES  2,E         */
OP(cb,94) { H = RES(2,H);} /* RES  2,H         */
OP(cb,95) { L = RES(2,L);} /* RES  2,L         */
OP(cb,96) { WM8( HL, RES(2,RM8(HL)) );} /* RES  2,(HL)      */
OP(cb,97) { A = RES(2,A);} /* RES  2,A         */
OP(cb,98) { B = RES(3,B);} /* RES  3,B         */
OP(cb,99) { C = RES(3,C);} /* RES  3,C         */
OP(cb,9a) { D = RES(3,D);} /* RES  3,D         */
OP(cb,9b) { E = RES(3,E);} /* RES  3,E         */
OP(cb,9c) { H = RES(3,H);} /* RES  3,H         */
OP(cb,9d) { L = RES(3,L);} /* RES  3,L         */
OP(cb,9e) { WM8( HL, RES(3,RM8(HL)) );} /* RES  3,(HL)      */
OP(cb,9f) { A = RES(3,A);} /* RES  3,A         */
OP(cb,a0) { B = RES(4,B);} /* RES  4,B         */
OP(cb,a1) { C = RES(4,C);} /* RES  4,C         */
OP(cb,a2) { D = RES(4,D);} /* RES  4,D         */
OP(cb,a3) { E = RES(4,E);} /* RES  4,E         */
OP(cb,a4) { H = RES(4,H);} /* RES  4,H         */
OP(cb,a5) { L = RES(4,L);} /* RES  4,L         */
OP(cb,a6) { WM8( HL, RES(4,RM8(HL)) );} /* RES  4,(HL)      */
OP(cb,a7) { A = RES(4,A);} /* RES  4,A         */
OP(cb,a8) { B = RES(5,B);} /* RES  5,B         */
OP(cb,a9) { C = RES(5,C);} /* RES  5,C         */
OP(cb,aa) { D = RES(5,D);} /* RES  5,D         */
OP(cb,ab) { E = RES(5,E);} /* RES  5,E         */
OP(cb,ac) { H = RES(5,H);} /* RES  5,H         */
OP(cb,ad) { L = RES(5,L);} /* RES  5,L         */
OP(cb,ae) { WM8( HL, RES(5,RM8(HL)) );} /* RES  5,(HL)      */
OP(cb,af) { A = RES(5,A);} /* RES  5,A         */
OP(cb,b0) { B = RES(6,B);} /* RES  6,B         */
OP(cb,b1) { C = RES(6,C);} /* RES  6,C         */
OP(cb,b2) { D = RES(6,D);} /* RES  6,D         */
OP(cb,b3) { E = RES(6,E);} /* RES  6,E         */
OP(cb,b4) { H = RES(6,H);} /* RES  6,H         */
OP(cb,b5) { L = RES(6,L);} /* RES  6,L         */
OP(cb,b6) { WM8( HL, RES(6,RM8(HL)) );} /* RES  6,(HL)      */
OP(cb,b7) { A = RES(6,A);} /* RES  6,A         */
OP(cb,b8) { B = RES(7,B);} /* RES  7,B         */
OP(cb,b9) { C = RES(7,C);} /* RES  7,C         */
OP(cb,ba) { D = RES(7,D);} /* RES  7,D         */
OP(cb,bb) { E = RES(7,E);} /* RES  7,E         */
OP(cb,bc) { H = RES(7,H);} /* RES  7,H         */
OP(cb,bd) { L = RES(7,L);} /* RES  7,L         */
OP(cb,be) { WM8( HL, RES(7,RM8(HL)) );} /* RES  7,(HL)      */
OP(cb,bf) { A = RES(7,A);} /* RES  7,A         */
OP(cb,c0) { B = SET(0,B);} /* SET  0,B         */
OP(cb,c1) { C = SET(0,C);} /* SET  0,C         */
OP(cb,c2) { D = SET(0,D);} /* SET  0,D         */
OP(cb,c3) { E = SET(0,E);} /* SET  0,E         */
OP(cb,c4) { H = SET(0,H);} /* SET  0,H         */
OP(cb,c5) { L = SET(0,L);} /* SET  0,L         */
OP(cb,c6) { WM8( HL, SET(0,RM8(HL)) );} /* SET  0,(HL)      */
OP(cb,c7) { A = SET(0,A);} /* SET  0,A         */
OP(cb,c8) { B = SET(1,B);} /* SET  1,B         */
OP(cb,c9) { C = SET(1,C);} /* SET  1,C         */
OP(cb,ca) { D = SET(1,D);} /* SET  1,D         */
OP(cb,cb) { E = SET(1,E);} /* SET  1,E         */
OP(cb,cc) { H = SET(1,H);} /* SET  1,H         */
OP(cb,cd) { L = SET(1,L);} /* SET  1,L         */
OP(cb,ce) { WM8( HL, SET(1,RM8(HL)) );} /* SET  1,(HL)      */
OP(cb,cf) { A = SET(1,A);} /* SET  1,A         */
OP(cb,d0) { B = SET(2,B);} /* SET  2,B         */
OP(cb,d1) { C = SET(2,C);} /* SET  2,C         */
OP(cb,d2) { D = SET(2,D);} /* SET  2,D         */
OP(cb,d3) { E = SET(2,E);} /* SET  2,E         */
OP(cb,d4) { H = SET(2,H);} /* SET  2,H         */
OP(cb,d5) { L = SET(2,L);} /* SET  2,L         */
OP(cb,d6) { WM8( HL, SET(2,RM8(HL)) );} /* SET  2,(HL)      */
OP(cb,d7) { A = SET(2,A);} /* SET  2,A         */
OP(cb,d8) { B = SET(3,B);} /* SET  3,B         */
OP(cb,d9) { C = SET(3,C);} /* SET  3,C         */
OP(cb,da) { D = SET(3,D);} /* SET  3,D         */
OP(cb,db) { E = SET(3,E);} /* SET  3,E         */
OP(cb,dc) { H = SET(3,H);} /* SET  3,H         */
OP(cb,dd) { L = SET(3,L);} /* SET  3,L         */
OP(cb,de) { WM8( HL, SET(3,RM8(HL)) );} /* SET  3,(HL)      */
OP(cb,df) { A = SET(3,A);} /* SET  3,A         */
OP(cb,e0) { B = SET(4,B);} /* SET  4,B         */
OP(cb,e1) { C = SET(4,C);} /* SET  4,C         */
OP(cb,e2) { D = SET(4,D);} /* SET  4,D         */
OP(cb,e3) { E = SET(4,E);} /* SET  4,E         */
OP(cb,e4) { H = SET(4,H);} /* SET  4,H         */
OP(cb,e5) { L = SET(4,L);} /* SET  4,L         */
OP(cb,e6) { WM8( HL, SET(4,RM8(HL)) );} /* SET  4,(HL)      */
OP(cb,e7) { A = SET(4,A);} /* SET  4,A         */
OP(cb,e8) { B = SET(5,B);} /* SET  5,B         */
OP(cb,e9) { C = SET(5,C);} /* SET  5,C         */
OP(cb,ea) { D = SET(5,D);} /* SET  5,D         */
OP(cb,eb) { E = SET(5,E);} /* SET  5,E         */
OP(cb,ec) { H = SET(5,H);} /* SET  5,H         */
OP(cb,ed) { L = SET(5,L);} /* SET  5,L         */
OP(cb,ee) { WM8( HL, SET(5,RM8(HL)) );} /* SET  5,(HL)      */
OP(cb,ef) { A = SET(5,A);} /* SET  5,A         */
OP(cb,f0) { B = SET(6,B);} /* SET  6,B         */
OP(cb,f1) { C = SET(6,C);} /* SET  6,C         */
OP(cb,f2) { D = SET(6,D);} /* SET  6,D         */
OP(cb,f3) { E = SET(6,E);} /* SET  6,E         */
OP(cb,f4) { H = SET(6,H);} /* SET  6,H         */
OP(cb,f5) { L = SET(6,L);} /* SET  6,L         */
OP(cb,f6) { WM8( HL, SET(6,RM8(HL)) );} /* SET  6,(HL)      */
OP(cb,f7) { A = SET(6,A);} /* SET  6,A         */
OP(cb,f8) { B = SET(7,B);} /* SET  7,B         */
OP(cb,f9) { C = SET(7,C);} /* SET  7,C         */
OP(cb,fa) { D = SET(7,D);} /* SET  7,D         */
OP(cb,fb) { E = SET(7,E);} /* SET  7,E         */
OP(cb,fc) { H = SET(7,H);} /* SET  7,H         */
OP(cb,fd) { L = SET(7,L);} /* SET  7,L         */
OP(cb,fe) { WM8( HL, SET(7,RM8(HL)) );} /* SET  7,(HL)      */
OP(cb,ff) { A = SET(7,A);} /* SET  7,A         */

static const Function Z80cb[0x100]=
{
   (Function)cb_00,(Function)cb_01,(Function)cb_02,(Function)cb_03,(Function)cb_04,(Function)cb_05,(Function)cb_06,(Function)cb_07,
   (Function)cb_08,(Function)cb_09,(Function)cb_0a,(Function)cb_0b,(Function)cb_0c,(Function)cb_0d,(Function)cb_0e,(Function)cb_0f,
   (Function)cb_10,(Function)cb_11,(Function)cb_12,(Function)cb_13,(Function)cb_14,(Function)cb_15,(Function)cb_16,(Function)cb_17,
   (Function)cb_18,(Function)cb_19,(Function)cb_1a,(Function)cb_1b,(Function)cb_1c,(Function)cb_1d,(Function)cb_1e,(Function)cb_1f,
   (Function)cb_20,(Function)cb_21,(Function)cb_22,(Function)cb_23,(Function)cb_24,(Function)cb_25,(Function)cb_26,(Function)cb_27,
   (Function)cb_28,(Function)cb_29,(Function)cb_2a,(Function)cb_2b,(Function)cb_2c,(Function)cb_2d,(Function)cb_2e,(Function)cb_2f,
   (Function)cb_30,(Function)cb_31,(Function)cb_32,(Function)cb_33,(Function)cb_34,(Function)cb_35,(Function)cb_36,(Function)cb_37,
   (Function)cb_38,(Function)cb_39,(Function)cb_3a,(Function)cb_3b,(Function)cb_3c,(Function)cb_3d,(Function)cb_3e,(Function)cb_3f,
   (Function)cb_40,(Function)cb_41,(Function)cb_42,(Function)cb_43,(Function)cb_44,(Function)cb_45,(Function)cb_46,(Function)cb_47,
   (Function)cb_48,(Function)cb_49,(Function)cb_4a,(Function)cb_4b,(Function)cb_4c,(Function)cb_4d,(Function)cb_4e,(Function)cb_4f,
   (Function)cb_50,(Function)cb_51,(Function)cb_52,(Function)cb_53,(Function)cb_54,(Function)cb_55,(Function)cb_56,(Function)cb_57,
   (Function)cb_58,(Function)cb_59,(Function)cb_5a,(Function)cb_5b,(Function)cb_5c,(Function)cb_5d,(Function)cb_5e,(Function)cb_5f,
   (Function)cb_60,(Function)cb_61,(Function)cb_62,(Function)cb_63,(Function)cb_64,(Function)cb_65,(Function)cb_66,(Function)cb_67,
   (Function)cb_68,(Function)cb_69,(Function)cb_6a,(Function)cb_6b,(Function)cb_6c,(Function)cb_6d,(Function)cb_6e,(Function)cb_6f,
   (Function)cb_70,(Function)cb_71,(Function)cb_72,(Function)cb_73,(Function)cb_74,(Function)cb_75,(Function)cb_76,(Function)cb_77,
   (Function)cb_78,(Function)cb_79,(Function)cb_7a,(Function)cb_7b,(Function)cb_7c,(Function)cb_7d,(Function)cb_7e,(Function)cb_7f,
   (Function)cb_80,(Function)cb_81,(Function)cb_82,(Function)cb_83,(Function)cb_84,(Function)cb_85,(Function)cb_86,(Function)cb_87,
   (Function)cb_88,(Function)cb_89,(Function)cb_8a,(Function)cb_8b,(Function)cb_8c,(Function)cb_8d,(Function)cb_8e,(Function)cb_8f,
   (Function)cb_90,(Function)cb_91,(Function)cb_92,(Function)cb_93,(Function)cb_94,(Function)cb_95,(Function)cb_96,(Function)cb_97,
   (Function)cb_98,(Function)cb_99,(Function)cb_9a,(Function)cb_9b,(Function)cb_9c,(Function)cb_9d,(Function)cb_9e,(Function)cb_9f,
   (Function)cb_a0,(Function)cb_a1,(Function)cb_a2,(Function)cb_a3,(Function)cb_a4,(Function)cb_a5,(Function)cb_a6,(Function)cb_a7,
   (Function)cb_a8,(Function)cb_a9,(Function)cb_aa,(Function)cb_ab,(Function)cb_ac,(Function)cb_ad,(Function)cb_ae,(Function)cb_af,
   (Function)cb_b0,(Function)cb_b1,(Function)cb_b2,(Function)cb_b3,(Function)cb_b4,(Function)cb_b5,(Function)cb_b6,(Function)cb_b7,
   (Function)cb_b8,(Function)cb_b9,(Function)cb_ba,(Function)cb_bb,(Function)cb_bc,(Function)cb_bd,(Function)cb_be,(Function)cb_bf,
   (Function)cb_c0,(Function)cb_c1,(Function)cb_c2,(Function)cb_c3,(Function)cb_c4,(Function)cb_c5,(Function)cb_c6,(Function)cb_c7,
   (Function)cb_c8,(Function)cb_c9,(Function)cb_ca,(Function)cb_cb,(Function)cb_cc,(Function)cb_cd,(Function)cb_ce,(Function)cb_cf,
   (Function)cb_d0,(Function)cb_d1,(Function)cb_d2,(Function)cb_d3,(Function)cb_d4,(Function)cb_d5,(Function)cb_d6,(Function)cb_d7,
   (Function)cb_d8,(Function)cb_d9,(Function)cb_da,(Function)cb_db,(Function)cb_dc,(Function)cb_dd,(Function)cb_de,(Function)cb_df,
   (Function)cb_e0,(Function)cb_e1,(Function)cb_e2,(Function)cb_e3,(Function)cb_e4,(Function)cb_e5,(Function)cb_e6,(Function)cb_e7,
   (Function)cb_e8,(Function)cb_e9,(Function)cb_ea,(Function)cb_eb,(Function)cb_ec,(Function)cb_ed,(Function)cb_ee,(Function)cb_ef,
   (Function)cb_f0,(Function)cb_f1,(Function)cb_f2,(Function)cb_f3,(Function)cb_f4,(Function)cb_f5,(Function)cb_f6,(Function)cb_f7,
   (Function)cb_f8,(Function)cb_f9,(Function)cb_fa,(Function)cb_fb,(Function)cb_fc,(Function)cb_fd,(Function)cb_fe,(Function)cb_ff
};

/**********************************************************
 * IX register related opcodes (DD prefix)
 **********************************************************/
OP(dd,09) { ADD16(IX,BC);} /* ADD  IX,BC       */
OP(dd,19) { ADD16(IX,DE);} /* ADD  IX,DE       */
OP(dd,21) { IX = ARG16();} /* LD   IX,w        */
OP(dd,22) { EA = ARG16(); WM16( EA, IX );} /* LD   (w),IX      */
OP(dd,23) { IX++;} /* INC  IX          */
OP(dd,24) { HX = INC(HX);} /* INC  HX          */
OP(dd,25) { HX = DEC(HX);} /* DEC  HX          */
OP(dd,26) { HX = ARG8();} /* LD   HX,n        */
OP(dd,29) { ADD16(IX,IX);} /* ADD  IX,IX       */
OP(dd,2a) { EA = ARG16(); RM16( EA, IX );} /* LD   IX,(w)      */
OP(dd,2b) { IX--;} /* DEC  IX          */
OP(dd,2c) { LX = INC(LX);} /* INC  LX          */
OP(dd,2d) { LX = DEC(LX);} /* DEC  LX          */
OP(dd,2e) { LX = ARG8();} /* LD   LX,n        */
OP(dd,34) { EAIX(); WM8( EA, INC(RM8(EA)) );} /* INC  (IX+o)      */
OP(dd,35) { EAIX(); WM8( EA, DEC(RM8(EA)) );} /* DEC  (IX+o)      */
OP(dd,36) { EAIX(); WM8( EA, ARG8() );} /* LD   (IX+o),n    */
OP(dd,39) { ADD16(IX,SP);} /* ADD  IX,SP       */
OP(dd,44) { B = HX;} /* LD   B,HX        */
OP(dd,45) { B = LX;} /* LD   B,LX        */
OP(dd,46) { EAIX(); B = RM8(EA);} /* LD   B,(IX+o)    */
OP(dd,4c) { C = HX;} /* LD   C,HX        */
OP(dd,4d) { C = LX;} /* LD   C,LX        */
OP(dd,4e) { EAIX(); C = RM8(EA);} /* LD   C,(IX+o)    */
OP(dd,54) { D = HX;} /* LD   D,HX        */
OP(dd,55) { D = LX;} /* LD   D,LX        */
OP(dd,56) { EAIX(); D = RM8(EA);} /* LD   D,(IX+o)    */
OP(dd,5c) { E = HX;} /* LD   E,HX        */
OP(dd,5d) { E = LX;} /* LD   E,LX        */
OP(dd,5e) { EAIX(); E = RM8(EA);} /* LD   E,(IX+o)    */
OP(dd,60) { HX = B;} /* LD   HX,B        */
OP(dd,61) { HX = C;} /* LD   HX,C        */
OP(dd,62) { HX = D;} /* LD   HX,D        */
OP(dd,63) { HX = E;} /* LD   HX,E        */
OP(dd,64) {} /* LD   HX,HX       */
OP(dd,65) { HX = LX;} /* LD   HX,LX       */
OP(dd,66) { EAIX(); H = RM8(EA);} /* LD   H,(IX+o)    */
OP(dd,67) { HX = A;} /* LD   HX,A        */
OP(dd,68) { LX = B;} /* LD   LX,B        */
OP(dd,69) { LX = C;} /* LD   LX,C        */
OP(dd,6a) { LX = D;} /* LD   LX,D        */
OP(dd,6b) { LX = E;} /* LD   LX,E        */
OP(dd,6c) { LX = HX;} /* LD   LX,HX       */
OP(dd,6d) {} /* LD   LX,LX       */
OP(dd,6e) { EAIX(); L = RM8(EA);} /* LD   L,(IX+o)    */
OP(dd,6f) { LX = A;} /* LD   LX,A        */
OP(dd,70) { EAIX(); WM8( EA, B );} /* LD   (IX+o),B    */
OP(dd,71) { EAIX(); WM8( EA, C );} /* LD   (IX+o),C    */
OP(dd,72) { EAIX(); WM8( EA, D );} /* LD   (IX+o),D    */
OP(dd,73) { EAIX(); WM8( EA, E );} /* LD   (IX+o),E    */
OP(dd,74) { EAIX(); WM8( EA, H );} /* LD   (IX+o),H    */
OP(dd,75) { EAIX(); WM8( EA, L );} /* LD   (IX+o),L    */
OP(dd,77) { EAIX(); WM8( EA, A );} /* LD   (IX+o),A    */
OP(dd,7c) { A = HX;} /* LD   A,HX        */
OP(dd,7d) { A = LX;} /* LD   A,LX        */
OP(dd,7e) { EAIX(); A = RM8(EA);} /* LD   A,(IX+o)    */
OP(dd,84) { ADD(HX);} /* ADD  A,HX        */
OP(dd,85) { ADD(LX);} /* ADD  A,LX        */
OP(dd,86) { EAIX(); ADD(RM8(EA));} /* ADD  A,(IX+o)    */
OP(dd,8c) { ADC(HX);} /* ADC  A,HX        */
OP(dd,8d) { ADC(LX);} /* ADC  A,LX        */
OP(dd,8e) { EAIX(); ADC(RM8(EA));} /* ADC  A,(IX+o)    */
OP(dd,94) { SUB(HX);} /* SUB  HX          */
OP(dd,95) { SUB(LX);} /* SUB  LX          */
OP(dd,96) { EAIX(); SUB(RM8(EA));} /* SUB  (IX+o)      */
OP(dd,9c) { SBC(HX);} /* SBC  A,HX        */
OP(dd,9d) { SBC(LX);} /* SBC  A,LX        */
OP(dd,9e) { EAIX(); SBC(RM8(EA));} /* SBC  A,(IX+o)    */
OP(dd,a4) { AND(HX);} /* AND  HX          */
OP(dd,a5) { AND(LX);} /* AND  LX          */
OP(dd,a6) { EAIX(); AND(RM8(EA));} /* AND  (IX+o)      */
OP(dd,ac) { XOR(HX);} /* XOR  HX          */
OP(dd,ad) { XOR(LX);} /* XOR  LX          */
OP(dd,ae) { EAIX(); XOR(RM8(EA));} /* XOR  (IX+o)      */
OP(dd,b4) { OR(HX);} /* OR   HX          */
OP(dd,b5) { OR(LX);} /* OR   LX          */
OP(dd,b6) { EAIX(); OR(RM8(EA));} /* OR   (IX+o)      */
OP(dd,bc) { CP(HX);} /* CP   HX          */
OP(dd,bd) { CP(LX);} /* CP   LX          */
OP(dd,be) { EAIX(); CP(RM8(EA));} /* CP   (IX+o)      */
OP(dd,cb) { unsigned char op=ARG8();EAIX(); EXEC(xycb,op);} /* DD CB xx xx */
OP(dd,e1) { POP( IX );} /* POP  IX          */
OP(dd,e3) { EXSP( IX );} /* EX   (SP),IX     */
OP(dd,e5) { PUSH( IX );} /* PUSH IX          */
OP(dd,e9) { PC = IX; } /* JP   (IX)        */
OP(dd,f9) { SP = IX;} /* LD   SP,IX       */

static const Function Z80dd[0x100]=
{
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)dd_09,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)dd_19,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)dd_21,(Function)dd_22,(Function)dd_23,(Function)dd_24,(Function)dd_25,(Function)dd_26,(Function)illeg,
   (Function)illeg,(Function)dd_29,(Function)dd_2a,(Function)dd_2b,(Function)dd_2c,(Function)dd_2d,(Function)dd_2e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_34,(Function)dd_35,(Function)dd_36,(Function)illeg,
   (Function)illeg,(Function)dd_39,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_44,(Function)dd_45,(Function)dd_46,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_4c,(Function)dd_4d,(Function)dd_4e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_54,(Function)dd_55,(Function)dd_56,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_5c,(Function)dd_5d,(Function)dd_5e,(Function)illeg,
   (Function)dd_60,(Function)dd_61,(Function)dd_62,(Function)dd_63,(Function)dd_64,(Function)dd_65,(Function)dd_66,(Function)dd_67,
   (Function)dd_68,(Function)dd_69,(Function)dd_6a,(Function)dd_6b,(Function)dd_6c,(Function)dd_6d,(Function)dd_6e,(Function)dd_6f,
   (Function)dd_70,(Function)dd_71,(Function)dd_72,(Function)dd_73,(Function)dd_74,(Function)dd_75,(Function)illeg,(Function)dd_77,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_7c,(Function)dd_7d,(Function)dd_7e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_84,(Function)dd_85,(Function)dd_86,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_8c,(Function)dd_8d,(Function)dd_8e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_94,(Function)dd_95,(Function)dd_96,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_9c,(Function)dd_9d,(Function)dd_9e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_a4,(Function)dd_a5,(Function)dd_a6,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_ac,(Function)dd_ad,(Function)dd_ae,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_b4,(Function)dd_b5,(Function)dd_b6,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_bc,(Function)dd_bd,(Function)dd_be,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)dd_cb,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)dd_e1,(Function)illeg,(Function)dd_e3,(Function)illeg,(Function)dd_e5,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)dd_e9,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)dd_f9,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg
};

/**********************************************************
 * IY register related opcodes (FD prefix)
 **********************************************************/
OP(fd,09) { ADD16(IY,BC);} /* ADD  IY,BC       */
OP(fd,19) { ADD16(IY,DE);} /* ADD  IY,DE       */
OP(fd,21) { IY = ARG16();} /* LD   IY,w        */
OP(fd,22) { EA = ARG16(); WM16( EA, IY );} /* LD   (w),IY      */
OP(fd,23) { IY++;} /* INC  IY          */
OP(fd,24) { HY = INC(HY);} /* INC  HY          */
OP(fd,25) { HY = DEC(HY);} /* DEC  HY          */
OP(fd,26) { HY = ARG8();} /* LD   HY,n        */
OP(fd,29) { ADD16(IY,IY);} /* ADD  IY,IY       */
OP(fd,2a) { EA = ARG16(); RM16( EA, IY );} /* LD   IY,(w)      */
OP(fd,2b) { IY--;} /* DEC  IY          */
OP(fd,2c) { LY = INC(LY);} /* INC  LY          */
OP(fd,2d) { LY = DEC(LY);} /* DEC  LY          */
OP(fd,2e) { LY = ARG8();} /* LD   LY,n        */
OP(fd,34) { EAIY(); WM8( EA, INC(RM8(EA)) );} /* INC  (IY+o)      */
OP(fd,35) { EAIY(); WM8( EA, DEC(RM8(EA)) );} /* DEC  (IY+o)      */
OP(fd,36) { EAIY(); WM8( EA, ARG8() );} /* LD   (IY+o),n    */
OP(fd,39) { ADD16(IY,SP);} /* ADD  IY,SP       */
OP(fd,44) { B = HY;} /* LD   B,HY        */
OP(fd,45) { B = LY;} /* LD   B,LY        */
OP(fd,46) { EAIY(); B = RM8(EA);} /* LD   B,(IY+o)    */
OP(fd,4c) { C = HY;} /* LD   C,HY        */
OP(fd,4d) { C = LY;} /* LD   C,LY        */
OP(fd,4e) { EAIY(); C = RM8(EA);} /* LD   C,(IY+o)    */
OP(fd,54) { D = HY;} /* LD   D,HY        */
OP(fd,55) { D = LY;} /* LD   D,LY        */
OP(fd,56) { EAIY(); D = RM8(EA);} /* LD   D,(IY+o)    */
OP(fd,5c) { E = HY;} /* LD   E,HY        */
OP(fd,5d) { E = LY;} /* LD   E,LY        */
OP(fd,5e) { EAIY(); E = RM8(EA);} /* LD   E,(IY+o)    */
OP(fd,60) { HY = B;} /* LD   HY,B        */
OP(fd,61) { HY = C;} /* LD   HY,C        */
OP(fd,62) { HY = D;} /* LD   HY,D        */
OP(fd,63) { HY = E;} /* LD   HY,E        */
OP(fd,64) { } /* LD   HY,HY       */
OP(fd,65) { HY = LY;} /* LD   HY,LY       */
OP(fd,66) { EAIY(); H = RM8(EA);} /* LD   H,(IY+o)    */
OP(fd,67) { HY = A;} /* LD   HY,A        */
OP(fd,68) { LY = B;} /* LD   LY,B        */
OP(fd,69) { LY = C;} /* LD   LY,C        */
OP(fd,6a) { LY = D;} /* LD   LY,D        */
OP(fd,6b) { LY = E;} /* LD   LY,E        */
OP(fd,6c) { LY = HY;} /* LD   LY,HY       */
OP(fd,6d) { } /* LD   LY,LY       */
OP(fd,6e) { EAIY(); L = RM8(EA);} /* LD   L,(IY+o)    */
OP(fd,6f) { LY = A;} /* LD   LY,A        */
OP(fd,70) { EAIY(); WM8( EA, B );} /* LD   (IY+o),B    */
OP(fd,71) { EAIY(); WM8( EA, C );} /* LD   (IY+o),C    */
OP(fd,72) { EAIY(); WM8( EA, D );} /* LD   (IY+o),D    */
OP(fd,73) { EAIY(); WM8( EA, E );} /* LD   (IY+o),E    */
OP(fd,74) { EAIY(); WM8( EA, H );} /* LD   (IY+o),H    */
OP(fd,75) { EAIY(); WM8( EA, L );} /* LD   (IY+o),L    */
OP(fd,77) { EAIY(); WM8( EA, A );} /* LD   (IY+o),A    */
OP(fd,7c) { A = HY;} /* LD   A,HY        */
OP(fd,7d) { A = LY;} /* LD   A,LY        */
OP(fd,7e) { EAIY(); A = RM8(EA);} /* LD   A,(IY+o)    */
OP(fd,84) { ADD(HY);} /* ADD  A,HY        */
OP(fd,85) { ADD(LY);} /* ADD  A,LY        */
OP(fd,86) { EAIY(); ADD(RM8(EA));} /* ADD  A,(IY+o)    */
OP(fd,8c) { ADC(HY);} /* ADC  A,HY        */
OP(fd,8d) { ADC(LY);} /* ADC  A,LY        */
OP(fd,8e) { EAIY(); ADC(RM8(EA));} /* ADC  A,(IY+o)    */
OP(fd,94) { SUB(HY);} /* SUB  HY          */
OP(fd,95) { SUB(LY);} /* SUB  LY          */
OP(fd,96) { EAIY(); SUB(RM8(EA));} /* SUB  (IY+o)      */
OP(fd,9c) { SBC(HY);} /* SBC  A,HY        */
OP(fd,9d) { SBC(LY);} /* SBC  A,LY        */
OP(fd,9e) { EAIY(); SBC(RM8(EA));} /* SBC  A,(IY+o)    */
OP(fd,a4) { AND(HY);} /* AND  HY          */
OP(fd,a5) { AND(LY);} /* AND  LY          */
OP(fd,a6) { EAIY(); AND(RM8(EA));} /* AND  (IY+o)      */
OP(fd,ac) { XOR(HY);} /* XOR  HY          */
OP(fd,ad) { XOR(LY);} /* XOR  LY          */
OP(fd,ae) { EAIY(); XOR(RM8(EA));} /* XOR  (IY+o)      */
OP(fd,b4) { OR(HY);} /* OR   HY          */
OP(fd,b5) { OR(LY);} /* OR   LY          */
OP(fd,b6) { EAIY(); OR(RM8(EA));} /* OR   (IY+o)      */
OP(fd,bc) { CP(HY);} /* CP   HY          */
OP(fd,bd) { CP(LY);} /* CP   LY          */
OP(fd,be) { EAIY(); CP(RM8(EA));} /* CP   (IY+o)      */
OP(fd,cb) { unsigned char op=ARG8();EAIY(); EXEC(xycb,op);} /* FD CB xx xx   */
OP(fd,e1) { POP( IY );} /* POP  IY          */
OP(fd,e3) { EXSP( IY );} /* EX   (SP),IY     */
OP(fd,e5) { PUSH( IY );} /* PUSH IY          */
OP(fd,e9) { PC = IY; } /* JP   (IY)        */
OP(fd,f9) { SP = IY;} /* LD   SP,IY       */

static const Function Z80fd[0x100]=
{
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)fd_09,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)fd_19,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)fd_21,(Function)fd_22,(Function)fd_23,(Function)fd_24,(Function)fd_25,(Function)fd_26,(Function)illeg,
   (Function)illeg,(Function)fd_29,(Function)fd_2a,(Function)fd_2b,(Function)fd_2c,(Function)fd_2d,(Function)fd_2e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_34,(Function)fd_35,(Function)fd_36,(Function)illeg,
   (Function)illeg,(Function)fd_39,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_44,(Function)fd_45,(Function)fd_46,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_4c,(Function)fd_4d,(Function)fd_4e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_54,(Function)fd_55,(Function)fd_56,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_5c,(Function)fd_5d,(Function)fd_5e,(Function)illeg,
   (Function)fd_60,(Function)fd_61,(Function)fd_62,(Function)fd_63,(Function)fd_64,(Function)fd_65,(Function)fd_66,(Function)fd_67,
   (Function)fd_68,(Function)fd_69,(Function)fd_6a,(Function)fd_6b,(Function)fd_6c,(Function)fd_6d,(Function)fd_6e,(Function)fd_6f,
   (Function)fd_70,(Function)fd_71,(Function)fd_72,(Function)fd_73,(Function)fd_74,(Function)fd_75,(Function)illeg,(Function)fd_77,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_7c,(Function)fd_7d,(Function)fd_7e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_84,(Function)fd_85,(Function)fd_86,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_8c,(Function)fd_8d,(Function)fd_8e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_94,(Function)fd_95,(Function)fd_96,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_9c,(Function)fd_9d,(Function)fd_9e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_a4,(Function)fd_a5,(Function)fd_a6,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_ac,(Function)fd_ad,(Function)fd_ae,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_b4,(Function)fd_b5,(Function)fd_b6,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_bc,(Function)fd_bd,(Function)fd_be,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)fd_cb,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)fd_e1,(Function)illeg,(Function)fd_e3,(Function)illeg,(Function)fd_e5,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)fd_e9,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)fd_f9,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg
};

/**********************************************************
 * special opcodes (ED prefix)
 **********************************************************/
OP_IWRAM(ed,40) { B = IN(BC); F = (F & CF) | SZP[B];} /* IN   B,(C)       */
OP_IWRAM(ed,41) { OUT(BC, B);} /* OUT  (C),B       */
OP_IWRAM(ed,42) { SBC16( BC );} /* SBC  HL,BC       */
OP_IWRAM(ed,43) { EA = ARG16(); WM16( EA, BC );} /* LD   (w),BC      */
OP_IWRAM(ed,44) { NEG;} /* NEG              */
OP_IWRAM(ed,45) { RETN();} /* RETN;            */
OP_IWRAM(ed,46) { } /* IM   0           */
OP_IWRAM(ed,47) { LD_I_A;} /* LD   I,A         */
OP_IWRAM(ed,48) { C = IN(BC); F = (F & CF) | SZP[C];} /* IN   C,(C)       */
OP_IWRAM(ed,49) { OUT(BC, C);} /* OUT  (C),C       */
OP_IWRAM(ed,4a) { ADC16( BC );} /* ADC  HL,BC       */
OP_IWRAM(ed,4b) { EA = ARG16(); RM16( EA, BC );} /* LD   BC,(w)      */
OP_IWRAM(ed,4c) { NEG;} /* NEG              */
OP_IWRAM(ed,4d) { RETI();} /* RETI             */
OP_IWRAM(ed,4e) { } /* IM   0           */
OP_IWRAM(ed,4f) { } /* LD   R,A         */
OP_IWRAM(ed,50) { D = IN(BC); F = (F & CF) | SZP[D];} /* IN   D,(C)       */
OP_IWRAM(ed,51) { OUT(BC, D);} /* OUT  (C),D       */
OP_IWRAM(ed,52) { SBC16( DE );} /* SBC  HL,DE       */
OP_IWRAM(ed,53) { EA = ARG16(); WM16( EA, DE );} /* LD   (w),DE      */
OP_IWRAM(ed,54) { NEG;} /* NEG              */
OP_IWRAM(ed,55) { RETN();} /* RETN;            */
OP_IWRAM(ed,56) { } /* IM   1           */
OP_IWRAM(ed,57) { LD_A_I;} /* LD   A,I         */
OP_IWRAM(ed,58) { E = IN(BC); F = (F & CF) | SZP[E];} /* IN   E,(C)       */
OP_IWRAM(ed,59) { OUT(BC, E);} /* OUT  (C),E       */
OP_IWRAM(ed,5a) { ADC16( DE );} /* ADC  HL,DE       */
OP_IWRAM(ed,5b) { EA = ARG16(); RM16( EA, DE );} /* LD   DE,(w)      */
OP_IWRAM(ed,5c) { NEG;} /* NEG              */
OP_IWRAM(ed,5d) { RETI();} /* RETI             */
OP_IWRAM(ed,5e) { } /* IM   2           */
OP_IWRAM(ed,5f) { } /* LD   A,R         */
OP_IWRAM(ed,60) { H = IN(BC); F = (F & CF) | SZP[H];} /* IN   H,(C)       */
OP_IWRAM(ed,61) { OUT(BC, H);} /* OUT  (C),H       */
OP_IWRAM(ed,62) { SBC16( HL );} /* SBC  HL,HL       */
OP_IWRAM(ed,63) { EA = ARG16(); WM16( EA, HL );} /* LD   (w),HL      */
OP_IWRAM(ed,64) { NEG;} /* NEG              */
OP_IWRAM(ed,65) { RETN();} /* RETN;            */
OP_IWRAM(ed,66) { } /* IM   0           */
OP_IWRAM(ed,67) { RRD;} /* RRD  (HL)        */
OP_IWRAM(ed,68) { L = IN(BC); F = (F & CF) | SZP[L];} /* IN   L,(C)       */
OP_IWRAM(ed,69) { OUT(BC, L);} /* OUT  (C),L       */
OP_IWRAM(ed,6a) { ADC16( HL );} /* ADC  HL,HL       */
OP_IWRAM(ed,6b) { EA = ARG16(); RM16( EA, HL );} /* LD   HL,(w)      */
OP_IWRAM(ed,6c) { NEG;} /* NEG              */
OP_IWRAM(ed,6d) { RETI();} /* RETI             */
OP_IWRAM(ed,6e) { } /* IM   0           */
OP_IWRAM(ed,6f) { RLD;} /* RLD  (HL)        */
OP_IWRAM(ed,70) { unsigned char res = IN(BC); F = (F & CF) | SZP[res];} /* IN   0,(C)       */
OP_IWRAM(ed,71) { OUT(BC, 0);} /* OUT  (C),0       */
OP_IWRAM(ed,72) { SBC16( SP );} /* SBC  HL,SP       */
OP_IWRAM(ed,73) { EA = ARG16(); WM16( EA, SP );} /* LD   (w),SP      */
OP_IWRAM(ed,74) { NEG;} /* NEG              */
OP_IWRAM(ed,75) { RETN();} /* RETN;            */
OP_IWRAM(ed,76) { } /* IM   1           */
OP_IWRAM(ed,78) { A = IN(BC); F = (F & CF) | SZP[A];} /* IN   E,(C)       */
OP_IWRAM(ed,79) { OUT(BC, A);} /* OUT  (C),A       */
OP_IWRAM(ed,7a) { ADC16( SP );} /* ADC  HL,SP       */
OP_IWRAM(ed,7b) { EA = ARG16(); RM16( EA, SP );} /* LD   SP,(w)      */
OP_IWRAM(ed,7c) { NEG;} /* NEG              */
OP_IWRAM(ed,7d) { RETI();} /* RETI             */
OP_IWRAM(ed,7e) { } /* IM   2           */
OP_IWRAM(ed,a0) { LDI;} /* LDI              */
OP_IWRAM(ed,a1) { CPI;} /* CPI              */
OP_IWRAM(ed,a2) { INI;} /* INI              */
OP_IWRAM(ed,a3) { OUTI;} /* OUTI             */
OP_IWRAM(ed,a8) { LDD;} /* LDD              */
OP_IWRAM(ed,a9) { CPD;} /* CPD              */
OP_IWRAM(ed,aa) { IND;} /* IND              */
OP_IWRAM(ed,ab) { OUTD;} /* OUTD             */
OP_IWRAM(ed,b0) { LDIR;} /* LDIR             */
OP_IWRAM(ed,b1) { CPIR;} /* CPIR             */
OP_IWRAM(ed,b2) { INIR;} /* INIR             */
OP_IWRAM(ed,b3) { OTIR;} /* OTIR             */
OP_IWRAM(ed,b8) { LDDR;} /* LDDR             */
OP_IWRAM(ed,b9) { CPDR;} /* CPDR             */
OP_IWRAM(ed,ba) { INDR;} /* INDR             */
OP_IWRAM(ed,bb) { OTDR;} /* OTDR             */

static const Function Z80ed[0x100]=
{
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)ed_40,(Function)ed_41,(Function)ed_42,(Function)ed_43,(Function)ed_44,(Function)ed_45,(Function)ed_46,(Function)ed_47,
   (Function)ed_48,(Function)ed_49,(Function)ed_4a,(Function)ed_4b,(Function)ed_4c,(Function)ed_4d,(Function)ed_4e,(Function)ed_4f,
   (Function)ed_50,(Function)ed_51,(Function)ed_52,(Function)ed_53,(Function)ed_54,(Function)ed_55,(Function)ed_56,(Function)ed_57,
   (Function)ed_58,(Function)ed_59,(Function)ed_5a,(Function)ed_5b,(Function)ed_5c,(Function)ed_5d,(Function)ed_5e,(Function)ed_5f,
   (Function)ed_60,(Function)ed_61,(Function)ed_62,(Function)ed_63,(Function)ed_64,(Function)ed_65,(Function)ed_66,(Function)ed_67,
   (Function)ed_68,(Function)ed_69,(Function)ed_6a,(Function)ed_6b,(Function)ed_6c,(Function)ed_6d,(Function)ed_6e,(Function)ed_6f,
   (Function)ed_70,(Function)ed_71,(Function)ed_72,(Function)ed_73,(Function)ed_74,(Function)ed_75,(Function)ed_76,(Function)illeg,
   (Function)ed_78,(Function)ed_79,(Function)ed_7a,(Function)ed_7b,(Function)ed_7c,(Function)ed_7d,(Function)ed_7e,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)ed_a0,(Function)ed_a1,(Function)ed_a2,(Function)ed_a3,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)ed_a8,(Function)ed_a9,(Function)ed_aa,(Function)ed_ab,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)ed_b0,(Function)ed_b1,(Function)ed_b2,(Function)ed_b3,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)ed_b8,(Function)ed_b9,(Function)ed_ba,(Function)ed_bb,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,
   (Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg,(Function)illeg
};

/**********************************************************
 * main opcodes
 **********************************************************/
OP_IWRAM(op,00) {} /* NOP              */
OP_IWRAM(op,01) { BC = ARG16();} /* LD   BC,w        */
OP_IWRAM(op,02) { WM8( BC, A );} /* LD   (BC),A      */
OP_IWRAM(op,03) { BC++;} /* INC  BC          */
OP_IWRAM(op,04) { B = INC(B);} /* INC  B           */
OP_IWRAM(op,05) { B = DEC(B);} /* DEC  B           */
OP_IWRAM(op,06) { B = ARG8();} /* LD   B,n         */
OP_IWRAM(op,07) { RLCA;} /* RLCA             */
OP_IWRAM(op,08) { EX_AF;} /* EX   AF,AF'      */
OP_IWRAM(op,09) { ADD16(HL,BC);} /* ADD  HL,BC       */
OP_IWRAM(op,0a) { A = RM8( BC );} /* LD   A,(BC)      */
OP_IWRAM(op,0b) { BC--; } /* DEC  BC          */
OP_IWRAM(op,0c) { C = INC(C);} /* INC  C           */
OP_IWRAM(op,0d) { C = DEC(C);} /* DEC  C           */
OP_IWRAM(op,0e) { C = ARG8();} /* LD   C,n         */
OP_IWRAM(op,0f) { RRCA;} /* RRCA             */
OP_IWRAM(op,10) { B--; JR_COND( B, 0x10 );} /* DJNZ o           */
OP_IWRAM(op,11) { DE = ARG16();} /* LD   DE,w        */
OP_IWRAM(op,12) { WM8( DE, A );} /* LD   (DE),A      */
OP_IWRAM(op,13) { DE++;} /* INC  DE          */
OP_IWRAM(op,14) { D = INC(D);} /* INC  D           */
OP_IWRAM(op,15) { D = DEC(D);} /* DEC  D           */
OP_IWRAM(op,16) { D = ARG8();} /* LD   D,n         */
OP_IWRAM(op,17) { RLA;} /* RLA              */
OP_IWRAM(op,18) { JR();} /* JR   o           */
OP_IWRAM(op,19) { ADD16(HL,DE);} /* ADD  HL,DE       */
OP_IWRAM(op,1a) { A = RM8( DE );} /* LD   A,(DE)      */
OP_IWRAM(op,1b) { DE--; } /* DEC  DE          */
OP_IWRAM(op,1c) { E = INC(E);} /* INC  E           */
OP_IWRAM(op,1d) { E = DEC(E);} /* DEC  E           */
OP_IWRAM(op,1e) { E = ARG8();} /* LD   E,n         */
OP_IWRAM(op,1f) { RRA;} /* RRA              */
OP_IWRAM(op,20) { JR_COND( !(F & ZF), 0x20 );} /* JR   NZ,o        */
OP_IWRAM(op,21) { HL = ARG16();} /* LD   HL,w        */
OP_IWRAM(op,22) { EA = ARG16(); WM16( EA, HL );} /* LD   (w),HL      */
OP_IWRAM(op,23) { HL++;} /* INC  HL          */
OP_IWRAM(op,24) { H = INC(H);} /* INC  H           */
OP_IWRAM(op,25) { H = DEC(H);} /* DEC  H           */
OP_IWRAM(op,26) { H = ARG8();} /* LD   H,n         */
OP_IWRAM(op,27) { DAA;} /* DAA              */
OP_IWRAM(op,28) { JR_COND( F & ZF, 0x28 );} /* JR   Z,o         */
OP_IWRAM(op,29) { ADD16(HL,HL);} /* ADD  HL,HL       */
OP_IWRAM(op,2a) { EA = ARG16(); RM16( EA, HL );} /* LD   HL,(w)      */
OP_IWRAM(op,2b) { HL--; } /* DEC  HL          */
OP_IWRAM(op,2c) { L = INC(L);} /* INC  L           */
OP_IWRAM(op,2d) { L = DEC(L);} /* DEC  L           */
OP_IWRAM(op,2e) { L = ARG8();} /* LD   L,n         */
OP_IWRAM(op,2f) { A ^= 0xff; F = (F&(SF|ZF|PF|CF))|HF|NF;} /* CPL              */
OP_IWRAM(op,30) { JR_COND( !(F & CF), 0x30 );} /* JR   NC,o        */
OP_IWRAM(op,31) { SP = ARG16();} /* LD   SP,w        */
OP_IWRAM(op,32) { EA = ARG16(); WM8( EA, A );} /* LD   (w),A       */
OP_IWRAM(op,33) { SP++;} /* INC  SP          */
OP_IWRAM(op,34) { WM8( HL, INC(RM8(HL)) );} /* INC  (HL)        */
OP_IWRAM(op,35) { WM8( HL, DEC(RM8(HL)) );} /* DEC  (HL)        */
OP_IWRAM(op,36) { WM8( HL, ARG8() );} /* LD   (HL),n      */
OP_IWRAM(op,37) { F = (F & (SF|ZF|PF)) | CF;} /* SCF              */
OP_IWRAM(op,38) { JR_COND( F & CF, 0x38 );} /* JR   C,o         */
OP_IWRAM(op,39) { ADD16(HL,SP);} /* ADD  HL,SP       */
OP_IWRAM(op,3a) { EA = ARG16(); A = RM8( EA );} /* LD   A,(w)       */
OP_IWRAM(op,3b) { SP--;} /* DEC  SP          */
OP_IWRAM(op,3c) { A = INC(A);} /* INC  A           */
OP_IWRAM(op,3d) { A = DEC(A);} /* DEC  A           */
OP_IWRAM(op,3e) { A = ARG8();} /* LD   A,n         */
OP_IWRAM(op,3f) { F = ((F&(SF|ZF|PF|CF))|((F&CF)<<4))^CF;} /* CCF              */
OP_IWRAM(op,40) {} /* LD   B,B         */
OP_IWRAM(op,41) { B = C;} /* LD   B,C         */
OP_IWRAM(op,42) { B = D;} /* LD   B,D         */
OP_IWRAM(op,43) { B = E;} /* LD   B,E         */
OP_IWRAM(op,44) { B = H;} /* LD   B,H         */
OP_IWRAM(op,45) { B = L;} /* LD   B,L         */
OP_IWRAM(op,46) { B = RM8(HL);} /* LD   B,(HL)      */
OP_IWRAM(op,47) { B = A;} /* LD   B,A         */
OP_IWRAM(op,48) { C = B;} /* LD   C,B         */
OP_IWRAM(op,49) {} /* LD   C,C         */
OP_IWRAM(op,4a) { C = D;} /* LD   C,D         */
OP_IWRAM(op,4b) { C = E;} /* LD   C,E         */
OP_IWRAM(op,4c) { C = H;} /* LD   C,H         */
OP_IWRAM(op,4d) { C = L;} /* LD   C,L         */
OP_IWRAM(op,4e) { C = RM8(HL);} /* LD   C,(HL)      */
OP_IWRAM(op,4f) { C = A;} /* LD   C,A         */
OP_IWRAM(op,50) { D = B;} /* LD   D,B         */
OP_IWRAM(op,51) { D = C;} /* LD   D,C         */
OP_IWRAM(op,52) {} /* LD   D,D         */
OP_IWRAM(op,53) { D = E;} /* LD   D,E         */
OP_IWRAM(op,54) { D = H;} /* LD   D,H         */
OP_IWRAM(op,55) { D = L;} /* LD   D,L         */
OP_IWRAM(op,56) { D = RM8(HL);} /* LD   D,(HL)      */
OP_IWRAM(op,57) { D = A;} /* LD   D,A         */
OP_IWRAM(op,58) { E = B;} /* LD   E,B         */
OP_IWRAM(op,59) { E = C;} /* LD   E,C         */
OP_IWRAM(op,5a) { E = D;} /* LD   E,D         */
OP_IWRAM(op,5b) {} /* LD   E,E         */
OP_IWRAM(op,5c) { E = H;} /* LD   E,H         */
OP_IWRAM(op,5d) { E = L;} /* LD   E,L         */
OP_IWRAM(op,5e) { E = RM8(HL);} /* LD   E,(HL)      */
OP_IWRAM(op,5f) { E = A;} /* LD   E,A         */
OP_IWRAM(op,60) { H = B;} /* LD   H,B         */
OP_IWRAM(op,61) { H = C;} /* LD   H,C         */
OP_IWRAM(op,62) { H = D;} /* LD   H,D         */
OP_IWRAM(op,63) { H = E;} /* LD   H,E         */
OP_IWRAM(op,64) {} /* LD   H,H         */
OP_IWRAM(op,65) { H = L;} /* LD   H,L         */
OP_IWRAM(op,66) { H = RM8(HL);} /* LD   H,(HL)      */
OP_IWRAM(op,67) { H = A;} /* LD   H,A         */
OP_IWRAM(op,68) { L = B;} /* LD   L,B         */
OP_IWRAM(op,69) { L = C;} /* LD   L,C         */
OP_IWRAM(op,6a) { L = D;} /* LD   L,D         */
OP_IWRAM(op,6b) { L = E;} /* LD   L,E         */
OP_IWRAM(op,6c) { L = H;} /* LD   L,H         */
OP_IWRAM(op,6d) {} /* LD   L,L         */
OP_IWRAM(op,6e) { L = RM8(HL);} /* LD   L,(HL)      */
OP_IWRAM(op,6f) { L = A;} /* LD   L,A         */
OP_IWRAM(op,70) { WM8( HL, B );} /* LD   (HL),B      */
OP_IWRAM(op,71) { WM8( HL, C );} /* LD   (HL),C      */
OP_IWRAM(op,72) { WM8( HL, D );} /* LD   (HL),D      */
OP_IWRAM(op,73) { WM8( HL, E );} /* LD   (HL),E      */
OP_IWRAM(op,74) { WM8( HL, H );} /* LD   (HL),H      */
OP_IWRAM(op,75) { WM8( HL, L );} /* LD   (HL),L      */
OP_IWRAM(op,76) { } /* HALT             */
OP_IWRAM(op,77) { WM8( HL, A );} /* LD   (HL),A      */
OP_IWRAM(op,78) { A = B;} /* LD   A,B         */
OP_IWRAM(op,79) { A = C;} /* LD   A,C         */
OP_IWRAM(op,7a) { A = D;} /* LD   A,D         */
OP_IWRAM(op,7b) { A = E;} /* LD   A,E         */
OP_IWRAM(op,7c) { A = H;} /* LD   A,H         */
OP_IWRAM(op,7d) { A = L;} /* LD   A,L         */
OP_IWRAM(op,7e) { A = RM8(HL);} /* LD   A,(HL)      */
OP_IWRAM(op,7f) {} /* LD   A,A         */
OP_IWRAM(op,80) { ADD(B);} /* ADD  A,B         */
OP_IWRAM(op,81) { ADD(C);} /* ADD  A,C         */
OP_IWRAM(op,82) { ADD(D);} /* ADD  A,D         */
OP_IWRAM(op,83) { ADD(E);} /* ADD  A,E         */
OP_IWRAM(op,84) { ADD(H);} /* ADD  A,H         */
OP_IWRAM(op,85) { ADD(L);} /* ADD  A,L         */
OP_IWRAM(op,86) { ADD(RM8(HL));} /* ADD  A,(HL)      */
OP_IWRAM(op,87) { ADD(A);} /* ADD  A,A         */
OP_IWRAM(op,88) { ADC(B);} /* ADC  A,B         */
OP_IWRAM(op,89) { ADC(C);} /* ADC  A,C         */
OP_IWRAM(op,8a) { ADC(D);} /* ADC  A,D         */
OP_IWRAM(op,8b) { ADC(E);} /* ADC  A,E         */
OP_IWRAM(op,8c) { ADC(H);} /* ADC  A,H         */
OP_IWRAM(op,8d) { ADC(L);} /* ADC  A,L         */
OP_IWRAM(op,8e) { ADC(RM8(HL));} /* ADC  A,(HL)      */
OP_IWRAM(op,8f) { ADC(A);} /* ADC  A,A         */
OP_IWRAM(op,90) { SUB(B);} /* SUB  B           */
OP_IWRAM(op,91) { SUB(C);} /* SUB  C           */
OP_IWRAM(op,92) { SUB(D);} /* SUB  D           */
OP_IWRAM(op,93) { SUB(E);} /* SUB  E           */
OP_IWRAM(op,94) { SUB(H);} /* SUB  H           */
OP_IWRAM(op,95) { SUB(L);} /* SUB  L           */
OP_IWRAM(op,96) { SUB(RM8(HL));} /* SUB  (HL)        */
OP_IWRAM(op,97) { SUB(A);} /* SUB  A           */
OP_IWRAM(op,98) { SBC(B);} /* SBC  A,B         */
OP_IWRAM(op,99) { SBC(C);} /* SBC  A,C         */
OP_IWRAM(op,9a) { SBC(D);} /* SBC  A,D         */
OP_IWRAM(op,9b) { SBC(E);} /* SBC  A,E         */
OP_IWRAM(op,9c) { SBC(H);} /* SBC  A,H         */
OP_IWRAM(op,9d) { SBC(L);} /* SBC  A,L         */
OP_IWRAM(op,9e) { SBC(RM8(HL));} /* SBC  A,(HL)      */
OP_IWRAM(op,9f) { SBC(A);} /* SBC  A,A         */
OP_IWRAM(op,a0) { AND(B);} /* AND  B           */
OP_IWRAM(op,a1) { AND(C);} /* AND  C           */
OP_IWRAM(op,a2) { AND(D);} /* AND  D           */
OP_IWRAM(op,a3) { AND(E);} /* AND  E           */
OP_IWRAM(op,a4) { AND(H);} /* AND  H           */
OP_IWRAM(op,a5) { AND(L);} /* AND  L           */
OP_IWRAM(op,a6) { AND(RM8(HL));} /* AND  (HL)        */
OP_IWRAM(op,a7) { AND(A);} /* AND  A           */
OP_IWRAM(op,a8) { XOR(B);} /* XOR  B           */
OP_IWRAM(op,a9) { XOR(C);} /* XOR  C           */
OP_IWRAM(op,aa) { XOR(D);} /* XOR  D           */
OP_IWRAM(op,ab) { XOR(E);} /* XOR  E           */
OP_IWRAM(op,ac) { XOR(H);} /* XOR  H           */
OP_IWRAM(op,ad) { XOR(L);} /* XOR  L           */
OP_IWRAM(op,ae) { XOR(RM8(HL));} /* XOR  (HL)        */
OP_IWRAM(op,af) { XOR(A);} /* XOR  A           */
OP_IWRAM(op,b0) { OR(B);} /* OR   B           */
OP_IWRAM(op,b1) { OR(C);} /* OR   C           */
OP_IWRAM(op,b2) { OR(D);} /* OR   D           */
OP_IWRAM(op,b3) { OR(E);} /* OR   E           */
OP_IWRAM(op,b4) { OR(H);} /* OR   H           */
OP_IWRAM(op,b5) { OR(L);} /* OR   L           */
OP_IWRAM(op,b6) { OR(RM8(HL));} /* OR   (HL)        */
OP_IWRAM(op,b7) { OR(A);} /* OR   A           */
OP_IWRAM(op,b8) { CP(B);} /* CP   B           */
OP_IWRAM(op,b9) { CP(C);} /* CP   C           */
OP_IWRAM(op,ba) { CP(D);} /* CP   D           */
OP_IWRAM(op,bb) { CP(E);} /* CP   E           */
OP_IWRAM(op,bc) { CP(H);} /* CP   H           */
OP_IWRAM(op,bd) { CP(L);} /* CP   L           */
OP_IWRAM(op,be) { CP(RM8(HL));} /* CP   (HL)        */
OP_IWRAM(op,bf) { CP(A);} /* CP   A           */
OP_IWRAM(op,c0) { RET_COND( !(F & ZF), 0xc0 );} /* RET  NZ          */
OP_IWRAM(op,c1) { POP( BC );} /* POP  BC          */
OP_IWRAM(op,c2) { JP_COND( !(F & ZF) );} /* JP   NZ,a        */
OP_IWRAM(op,c3) { JP();} /* JP   a           */
OP_IWRAM(op,c4) { CALL_COND( !(F & ZF), 0xc4 );} /* CALL NZ,a        */
OP_IWRAM(op,c5) { PUSH( BC );} /* PUSH BC          */
OP_IWRAM(op,c6) { ADD(ARG8());} /* ADD  A,n         */
OP_IWRAM(op,c7) { RST(0x00);} /* RST  0           */
OP_IWRAM(op,c8) { RET_COND( F & ZF, 0xc8 );} /* RET  Z           */
OP_IWRAM(op,c9) { POP( PC ); } /* RET              */
OP_IWRAM(op,ca) { JP_COND( F & ZF );} /* JP   Z,a         */
OP_IWRAM(op,cb) { EXEC(cb,ARG8());} /* **** CB xx       */
OP_IWRAM(op,cc) { CALL_COND( F & ZF, 0xcc );} /* CALL Z,a         */
OP_IWRAM(op,cd) { CALL();} /* CALL a           */
OP_IWRAM(op,ce) { ADC(ARG8());} /* ADC  A,n         */
OP_IWRAM(op,cf) { RST(0x08);} /* RST  1           */
OP_IWRAM(op,d0) { RET_COND( !(F & CF), 0xd0 );} /* RET  NC          */
OP_IWRAM(op,d1) { POP( DE );} /* POP  DE          */
OP_IWRAM(op,d2) { JP_COND( !(F & CF) );} /* JP   NC,a        */
OP_IWRAM(op,d3) { unsigned n = ARG8() | (A << 8); OUT( n, A );} /* OUT  (n),A       */
OP_IWRAM(op,d4) { CALL_COND( !(F & CF), 0xd4 );} /* CALL NC,a        */
OP_IWRAM(op,d5) { PUSH( DE );} /* PUSH DE          */
OP_IWRAM(op,d6) { SUB(ARG8());} /* SUB  n           */
OP_IWRAM(op,d7) { RST(0x10);} /* RST  2           */
OP_IWRAM(op,d8) { RET_COND( F & CF, 0xd8 );} /* RET  C           */
OP_IWRAM(op,d9) { EXX;} /* EXX              */
OP_IWRAM(op,da) { JP_COND( F & CF );} /* JP   C,a         */
OP_IWRAM(op,db) { unsigned n = ARG8() | (A << 8); A = IN( n );} /* IN   A,(n)       */
OP_IWRAM(op,dc) { CALL_COND( F & CF, 0xdc );} /* CALL C,a         */
OP_IWRAM(op,dd) { EXEC(dd,ARG8());} /* **** DD xx       */
OP_IWRAM(op,de) { SBC(ARG8());} /* SBC  A,n         */
OP_IWRAM(op,df) { RST(0x18);} /* RST  3           */
OP_IWRAM(op,e0) { RET_COND( !(F & PF), 0xe0 );} /* RET  PO          */
OP_IWRAM(op,e1) { POP( HL );} /* POP  HL          */
OP_IWRAM(op,e2) { JP_COND( !(F & PF) );} /* JP   PO,a        */
OP_IWRAM(op,e3) { EXSP( HL );} /* EX   HL,(SP)     */
OP_IWRAM(op,e4) { CALL_COND( !(F & PF), 0xe4 );} /* CALL PO,a        */
OP_IWRAM(op,e5) { PUSH( HL );} /* PUSH HL          */
OP_IWRAM(op,e6) { AND(ARG8());} /* AND  n           */
OP_IWRAM(op,e7) { RST(0x20);} /* RST  4           */
OP_IWRAM(op,e8) { RET_COND( F & PF, 0xe8 );} /* RET  PE          */
OP_IWRAM(op,e9) { PC = HL; } /* JP   (HL)        */
OP_IWRAM(op,ea) { JP_COND( F & PF );} /* JP   PE,a        */
OP_IWRAM(op,eb) { EX_DE_HL;} /* EX   DE,HL       */
OP_IWRAM(op,ec) { CALL_COND( F & PF, 0xec );} /* CALL PE,a        */
OP_IWRAM(op,ed) { EXEC(ed,ARG8());} /* **** ED xx       */
OP_IWRAM(op,ee) { XOR(ARG8());} /* XOR  n           */
OP_IWRAM(op,ef) { RST(0x28);} /* RST  5           */
OP_IWRAM(op,f0) { RET_COND( !(F & SF), 0xf0 );} /* RET  P           */
OP_IWRAM(op,f1) { POP( AF );} /* POP  AF          */
OP_IWRAM(op,f2) { JP_COND( !(F & SF) );} /* JP   P,a         */
OP_IWRAM(op,f3) { } /* DI               */
OP_IWRAM(op,f4) { CALL_COND( !(F & SF), 0xf4 );} /* CALL P,a         */
OP_IWRAM(op,f5) { PUSH( AF );} /* PUSH AF          */
OP_IWRAM(op,f6) { OR(ARG8());} /* OR   n           */
OP_IWRAM(op,f7) { RST(0x30);} /* RST  6           */
OP_IWRAM(op,f8) { RET_COND( F & SF, 0xf8 );} /* RET  M           */
OP_IWRAM(op,f9) { SP = HL;} /* LD   SP,HL       */
OP_IWRAM(op,fa) { JP_COND(F & SF);} /* JP   M,a         */
OP_IWRAM(op,fb) { EI;} /* EI               */
OP_IWRAM(op,fc) { CALL_COND( F & SF, 0xfc );} /* CALL M,a         */
OP_IWRAM(op,fd) { EXEC(fd,ARG8());} /* **** FD xx       */
OP_IWRAM(op,fe) { CP(ARG8());} /* CP   n           */
OP_IWRAM(op,ff) { RST(0x38);} /* RST  7           */

static const Function Z80op[0x100]=
{
   (Function)op_00,(Function)op_01,(Function)op_02,(Function)op_03,(Function)op_04,(Function)op_05,(Function)op_06,(Function)op_07,
   (Function)op_08,(Function)op_09,(Function)op_0a,(Function)op_0b,(Function)op_0c,(Function)op_0d,(Function)op_0e,(Function)op_0f,
   (Function)op_10,(Function)op_11,(Function)op_12,(Function)op_13,(Function)op_14,(Function)op_15,(Function)op_16,(Function)op_17,
   (Function)op_18,(Function)op_19,(Function)op_1a,(Function)op_1b,(Function)op_1c,(Function)op_1d,(Function)op_1e,(Function)op_1f,
   (Function)op_20,(Function)op_21,(Function)op_22,(Function)op_23,(Function)op_24,(Function)op_25,(Function)op_26,(Function)op_27,
   (Function)op_28,(Function)op_29,(Function)op_2a,(Function)op_2b,(Function)op_2c,(Function)op_2d,(Function)op_2e,(Function)op_2f,
   (Function)op_30,(Function)op_31,(Function)op_32,(Function)op_33,(Function)op_34,(Function)op_35,(Function)op_36,(Function)op_37,
   (Function)op_38,(Function)op_39,(Function)op_3a,(Function)op_3b,(Function)op_3c,(Function)op_3d,(Function)op_3e,(Function)op_3f,
   (Function)op_40,(Function)op_41,(Function)op_42,(Function)op_43,(Function)op_44,(Function)op_45,(Function)op_46,(Function)op_47,
   (Function)op_48,(Function)op_49,(Function)op_4a,(Function)op_4b,(Function)op_4c,(Function)op_4d,(Function)op_4e,(Function)op_4f,
   (Function)op_50,(Function)op_51,(Function)op_52,(Function)op_53,(Function)op_54,(Function)op_55,(Function)op_56,(Function)op_57,
   (Function)op_58,(Function)op_59,(Function)op_5a,(Function)op_5b,(Function)op_5c,(Function)op_5d,(Function)op_5e,(Function)op_5f,
   (Function)op_60,(Function)op_61,(Function)op_62,(Function)op_63,(Function)op_64,(Function)op_65,(Function)op_66,(Function)op_67,
   (Function)op_68,(Function)op_69,(Function)op_6a,(Function)op_6b,(Function)op_6c,(Function)op_6d,(Function)op_6e,(Function)op_6f,
   (Function)op_70,(Function)op_71,(Function)op_72,(Function)op_73,(Function)op_74,(Function)op_75,(Function)op_76,(Function)op_77,
   (Function)op_78,(Function)op_79,(Function)op_7a,(Function)op_7b,(Function)op_7c,(Function)op_7d,(Function)op_7e,(Function)op_7f,
   (Function)op_80,(Function)op_81,(Function)op_82,(Function)op_83,(Function)op_84,(Function)op_85,(Function)op_86,(Function)op_87,
   (Function)op_88,(Function)op_89,(Function)op_8a,(Function)op_8b,(Function)op_8c,(Function)op_8d,(Function)op_8e,(Function)op_8f,
   (Function)op_90,(Function)op_91,(Function)op_92,(Function)op_93,(Function)op_94,(Function)op_95,(Function)op_96,(Function)op_97,
   (Function)op_98,(Function)op_99,(Function)op_9a,(Function)op_9b,(Function)op_9c,(Function)op_9d,(Function)op_9e,(Function)op_9f,
   (Function)op_a0,(Function)op_a1,(Function)op_a2,(Function)op_a3,(Function)op_a4,(Function)op_a5,(Function)op_a6,(Function)op_a7,
   (Function)op_a8,(Function)op_a9,(Function)op_aa,(Function)op_ab,(Function)op_ac,(Function)op_ad,(Function)op_ae,(Function)op_af,
   (Function)op_b0,(Function)op_b1,(Function)op_b2,(Function)op_b3,(Function)op_b4,(Function)op_b5,(Function)op_b6,(Function)op_b7,
   (Function)op_b8,(Function)op_b9,(Function)op_ba,(Function)op_bb,(Function)op_bc,(Function)op_bd,(Function)op_be,(Function)op_bf,
   (Function)op_c0,(Function)op_c1,(Function)op_c2,(Function)op_c3,(Function)op_c4,(Function)op_c5,(Function)op_c6,(Function)op_c7,
   (Function)op_c8,(Function)op_c9,(Function)op_ca,(Function)op_cb,(Function)op_cc,(Function)op_cd,(Function)op_ce,(Function)op_cf,
   (Function)op_d0,(Function)op_d1,(Function)op_d2,(Function)op_d3,(Function)op_d4,(Function)op_d5,(Function)op_d6,(Function)op_d7,
   (Function)op_d8,(Function)op_d9,(Function)op_da,(Function)op_db,(Function)op_dc,(Function)op_dd,(Function)op_de,(Function)op_df,
   (Function)op_e0,(Function)op_e1,(Function)op_e2,(Function)op_e3,(Function)op_e4,(Function)op_e5,(Function)op_e6,(Function)op_e7,
   (Function)op_e8,(Function)op_e9,(Function)op_ea,(Function)op_eb,(Function)op_ec,(Function)op_ed,(Function)op_ee,(Function)op_ef,
   (Function)op_f0,(Function)op_f1,(Function)op_f2,(Function)op_f3,(Function)op_f4,(Function)op_f5,(Function)op_f6,(Function)op_f7,
   (Function)op_f8,(Function)op_f9,(Function)op_fa,(Function)op_fb,(Function)op_fc,(Function)op_fd,(Function)op_fe,(Function)op_ff
};

/****************************************************************************
 * Processor initialization
 ****************************************************************************/
void z80_init(void)
{
   int i, p;

   for (i = 0; i < 256; i++)
   {
      p = 0;
      if( i&0x01 ) ++p;
      if( i&0x02 ) ++p;
      if( i&0x04 ) ++p;
      if( i&0x08 ) ++p;
      if( i&0x10 ) ++p;
      if( i&0x20 ) ++p;
      if( i&0x40 ) ++p;
      if( i&0x80 ) ++p;
      SZ[i] = i ? i & SF : ZF;
      SZ_BIT[i] = i ? i & SF : ZF | PF;
      SZP[i] = SZ[i] | ((p & 1) ? 0 : PF);
      SZHV_inc[i] = SZ[i];
      if( i == 0x80 ) SZHV_inc[i] |= VF;
      if( (i & 0x0f) == 0x00 ) SZHV_inc[i] |= HF;
      SZHV_dec[i] = SZ[i] | NF;
      if( i == 0x7f ) SZHV_dec[i] |= VF;
      if( (i & 0x0f) == 0x0f ) SZHV_dec[i] |= HF;
   }
}

/****************************************************************************
 * Reset registers to their initial values
 ****************************************************************************/
void z80_reset(unsigned short address)
{
   int byte;
   for(byte=0;byte<sizeof(Z80);++byte)
      *((unsigned char*)&Z80+byte)=0;

   IX = IY = 0xffff; /* IX and IY are FFFF after a reset! */
   F = ZF;/* Zero flag is set */

   PC=address;

	cpcScreen=0xC000;

	illegCount=0;
	illegLastPc=0;
}

/****************************************************************************
 * Execute 'cycles' T-states. Return number of T-states really executed
 ****************************************************************************/
void CODE_IN_IWRAM z80_execute(void)
{
   *(unsigned short*)0x2000000=PC;
   *(unsigned short*)0x2000002=cpcMemory[PC];
   *(unsigned short*)0x2000004=(unsigned short)SP;
   *(unsigned short*)0x2000006=cpcMemory[SP]|(cpcMemory[SP+1]<<8);
   *(unsigned short*)0x2000008=illegCount;
   *(unsigned short*)0x200000A=illegLastPc;
   *(unsigned short*)0x200000C=cpcMemory[illegLastPc];
   *(unsigned short*)0x200000E=cpcScreen;
   EXEC(op,ARG8());
}

void z80_loadSNA(unsigned char* SNA)
{
   AF=SNA[0x11]|(SNA[0x12]<<8);
   BC=SNA[0x13]|(SNA[0x14]<<8);
   DE=SNA[0x15]|(SNA[0x16]<<8);
   HL=SNA[0x17]|(SNA[0x18]<<8);
   IX=SNA[0x1D]|(SNA[0x1E]<<8);
   IY=SNA[0x1F]|(SNA[0x20]<<8);
   SP=SNA[0x21]|(SNA[0x22]<<8);
   PC=SNA[0x23]|(SNA[0x24]<<8);
   Z80.af2.w=SNA[0x26]|(SNA[0x27]<<8);
   Z80.bc2.w=SNA[0x28]|(SNA[0x29]<<8);
   Z80.de2.w=SNA[0x2A]|(SNA[0x2B]<<8);
   Z80.hl2.w=SNA[0x2C]|(SNA[0x2D]<<8);

	crtcRegister=SNA[0x42];
	cpcScreen=(SNA[0x43+12]<<10)|(SNA[0x43+13]<<2);

	illegCount=0;
	illegLastPc=0;
}
