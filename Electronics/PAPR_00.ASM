	TITLE	"PAPR Hood Controller - 06/10/20
	SUBTITLE "Definitions"
	LIST	R=DEC,C=132,E=0,MM=OFF,N=102,ST=OFF,T=OFF,X=ON,P=16F18325


;	Developed for:	Open Source PAPR Mask

; 05/22/20  00_000 JRH	From Generic-14_00_14
; 05/24/20  00_001 JRH	Begin PAPR program development
; 05/27/20  00_002 JRH	Button DeBounce
; 05/28/20  00_003 JRH	Low-Power Sleep
; 06/01/20  00_004 JRH	Move Bootstrap to upper Ram, A/D Read
; 06/05/20  00_005 JRH	Add PWM_Table, CheckBatt, Toggle Fan if Lo-Batt
; 06/08/20  00_006 JRH	Use Cmp1 to track Fan Speed (C13 = 10nF)
;			Sync A/D with Fan Pulse, Speed# in Bank_r0
; 06/09/20  00_007 JRH	Add RPM Capture (PRELIM)
; 06/10/20  00_008 JRH	Measure RPM Period over 4 cycles
; 06/10/20  00_009 JRH	Add RPM-Calc and scale PWM6 for 1.000v = 1000 RPM
; 06/17/20  00_010 JRH	Complete External EEP transfer to Internal EEP
; 06/24/20  00_011 JRH	Shut down power if no pulses for 5 seconds




;-------------------------------------------------------------------

;	#DEFINE RELEASE 1

MLCKSUM:	EQU  0xF3	; Normal Checksum

REV00:		EQU  'A'
REV01:		EQU  '0'	; Mainline Revision
REV02:		EQU  '0'
REV03:		EQU  0x00	; Max = x3F

	__IDLOCS 0x8000, 0x3FFF
	__IDLOCS 0x8001, 0x3FFF
	__IDLOCS 0x8002, 0x3FFF
	__IDLOCS 0x8003, 0x3FFF

DEVNUM:		EQU  0xFF	; Default Device Address

;---------------------------------------------------------------------
;			Adjustable Parameters
;---------------------------------------------------------------------

VPC:		EQU  100

VOLTS_1:	SET   600 * VPC	;  6.00v
VOLTS_2:	SET   700 * VPC	;  7.00v
VOLTS_3:	SET   800 * VPC	;  8.00v
VOLTS_4:	SET   900 * VPC	;  9.00v
VOLTS_5:	SET  1000 * VPC	; 10.00v
VOLTS_6:	SET  1100 * VPC	; 11.00v
VOLTS_7:	SET  1200 * VPC	; 12.00v


	Page



;---------------------------------------------------------------------
;	GSTIME 12032B12V2V2P2.54BF  Fan Characteristics
;---------------------------------------------------------------------
;
;  Like other Brushless DC Fans, this fan's current waveform is not
;  smooth.  The current drops to Zero for 200uS at a repetition of
;  4 times per revolution.  This corresponds to the internal 4 coils
;  and magnets.
;
;  The waveform peaks just before dropping to Zero, then peaks again
;  with a "u" shaped curve between peaks.  The valley depth is highly
;  dependent on load caused by input or output air flow restriction.
;
;  Since the current and voltage has an abnormal step when the current
;  drops to Zero, most digital filtering techniques are not effective.
;
;  To aid in filtering, the A/D readings are synchronized with the
;  Speed Output Zero Pulse in an attempt to remove its effects.
;  An on-board voltage Comparator is used to detect the Zero pulse.
;
;  Since the Amperage Valley can dip close to Zero, the comparator
;  reference must be quite Low. The 1.024v internal Reference is
;  divided by the DAC to create a 64mV threshold.
;
;  It would be highly advantageous to measure Air Flow.  Since the
;  current is discontinuous, Wattage measurement errors are very high.
;  Fan Speed and applied Voltage measurements are more accurate and
;  should be uniform for a given Fan.


;		EEPROM Action
;
; When the external EEPROM is inserted, the program will read and store
; the contens in the internal EEPROM.
;
; To indicate that the read action was performed, the Fan will begin to
; run at low speed even though the button was not pressed.
;
; The First EEProm takes about 46mS to write 32 Bytes (16 words) and 300uS to Read
;

EEP_RADDR:	EQU  0x020	; Address of 32 Bytes of Data


	Page



;---------------------	14 Pin Package pinout  -----------------------
;
;****				; Pin  1 +5
PA5:		EQU  00100000B	; Pin  2 A5/AN05/CKI
PA4:		EQU  00010000B	; Pin  3 A4/AN04/CKO
PA3:		EQU  00001000B	; Pin  4 A3/MCLR
PC5:		EQU  00100000B	; Pin  5 C5/AN21
PC4:		EQU  00010000B	; Pin  6 C4/AN20
PC3:		EQU  00001000B	; Pin  7 C3/AN19/CxIN3-
PC2:		EQU  00000100B	; Pin  8 C2/AN18/CxIN2-
PC1:		EQU  00000010B	; Pin  9 C1/AN17/CxIN1-
PC0:		EQU  00000001B	; Pin 10 C0/AN16/C2IN0+
PA2:		EQU  00000100B	; Pin 11 A2/AN02	DAC1Ref-	Vref-
PA1:		EQU  00000010B	; Pin 12 A1/AN01/CxIN0-/DAC1Ref+/PGMC	Vref+
PA0:		EQU  00000001B	; Pin 13 A0/AN00/C1IN0+/DAC1Out /PGMD
;****				; Pin 14 GND

;---------------------	PortA x00C / LatA x10C	----------------------

BA_PB:		EQU  5		;  2 - Push Button		AN05
BA_CS:		EQU  4		;  3 -		EEP CS		AN04
BA_EO:		EQU  3		;  4 -		EEP DO	MCLR
BA_BAT:		EQU  2		; 11 - Battery Volts		AN02
BA_TX:		EQU  1		; 12 - UART Tx	EEP CK	PGMC	AN01
BA_RX:		EQU  0		; 13 - UART_Rx	EEP DI	PGMD	AN00

PAIOM:		EQU  00101101B	; ( TRISA) 1=In, 0=Out
PAINIT:		EQU  00101111B	; ( PORTA)
ANSU_A:		EQU  00000100B	; (ANSELA) 0- Dig  1- Analog

RA5SUO:		EQU  00000000B	; (RA5PPS)
RA4SUO:		EQU  00000000B	; (RA4PPS)
RA2SUO:		EQU  00000000B	; (RA2PPS)
RA1SUO:		EQU  00010100B	; (RA1PPS) UART Tx
RA0SUO:		EQU  00000000B	; (RA0PPS)

RXPPSU:		EQU  00000000B	; ( RXPPS) UART Rx = RA0

IOCAPS:		EQU  00000000B	; ( IOCAP)		**Punch
IOCANS:		EQU  00100000B	; ( IOCAN) Push Button

RA1SEO:		EQU  00011000B	; (RA1PPS)	SPI SCK	EEPCK
RA0SEO:		EQU  00011001B	; (RA0PPS)	SPI SD0	EEPDI
SDIPSU:		EQU  00000011B	; (SSP1DATPPS)	SPI SDI	EEPDO (A3)


;---------------------	PortC x00E / LatC x10E	----------------------

BCTEST1:	EQU  5		;  5 -				AN21
BCTEST0:	EQU  4		;  6 -				AN20
BC_FV:		EQU  3		;  7 - Fan Volts		AN19
BC_FA:		EQU  2		;  8 - Fan Amps			AN18
BC_VC:		EQU  1		;  9 - Vout Control		AN17
BC_OE:		EQU  0		; 10 - Switcher Enable		AN16

PCIOM:		EQU  00001100B	; ( TRISC) Tris value 1=In, 0=Out
PCINIT:		EQU  00111110B	; ( PORTC)
ANSU_C:		EQU  00001100B	; (ANSELC) 0- Dig  1- Analog

RC5SUO:		EQU  00000011B	; (RC5PPS) PWM6 Fan Speed					**Patch
RC4SUO:		EQU  00010110B	; (RC4PPS) Cmp1 Fan Rotation					**Patch
RC3SUO:		EQU  00000000B	; (RC3PPS)
RC2SUO:		EQU  00000000B	; (RC2PPS)
RC1SUO:		EQU  00000010B	; (RC1PPS) Out Volts Ctl (PWM)
RC0SUO:		EQU  00000000B	; (RC0PPS)


	Page



;---------------------	Chip Peripheral resources  -------------------
;
; UART1 - 38400 Debug	Osc = 32MHz %4 %207 = 38646
;
; FSR0	- Mainline GP indexing
; FSR1	- Mainline GP indexing, Boot GET ptr
;
; TMR0	- A/D Timing			CLC1 - n/u
; TMR1	- n/u				CLC2 - n/u
; TMR2	- PWM5 Clock			CLC3 - n/u
; TMR3	- n/u				CLC4 - n/u
; TMR4	- n/u				PWM5 - Output Voltage Control
; TMR5	- n/u				PWM6 - Fan Rotation Period
; TMR6	- n/u				CMP1 - Fan Speed Pulse Capture
; TMR7	- n/u				CMP2 - n/u
; MSS1	- Ext EEP I/O
; MSS2	- n/u
;
;DELAYx		A CD FGHIJKLMNOPQRSTUVWZY	Remaining Availability
;FLAGx		ABCDEFGHIJKLMNOPQRSTUVWXYZ


INT1SU:		EQU  01000000B	; (INTCON0) .GIE.PEIE.-----.-----.-----.------.-----.-----
PIE0SU:		EQU  00000000B	; ( PIE0 )  .---.----.-----.-----.-----.------.-----.-----
PIE1SU:		EQU  00110000B	; ( PIE1 )  .---.----.RC1IE.TX1IE.-----.------.-----.-----	!!Send RST response!!
PIE2SU:		EQU  00000000B	; ( PIE2 )  .---.----.-----.-----.-----.------.-----.-----
PIE3SU:		EQU  00000000B	; ( PIE3 )  .---.----.-----.-----.-----.------.-----.-----
PIE4SU:		EQU  00000000B	; ( PIE4 )  .---.----.-----.-----.-----.------.-----.-----

PMD0SU:		EQU  00111010B	; (PMD0) .SYS .FVR .--- .--- .--- .NVM .CLKR.IOC	INVERTED!
PMD1SU:		EQU  11111000B	; (PMD1) .NCO .TMR6.TMR5.TMR4.TMR3.TMR2.TMR1.TMR0
PMD2SU:		EQU  10011101B	; (PMD2) .----.DAC1.ADC-.----.----.CMP2.CMP1.----
PMD3SU:		EQU  11001111B	; (PMD3) .CWG2.CWG1.PWM6.PWM5.CCP4.CCP3.CCP2.CCP1
PMD4SU:		EQU  11011101B	; (PMD4) .----.----.UART.----.----.MSP2.MSP1.----
PMD5SU:		EQU  11111111B	; (PMD5) .----.----.----.CLC4.CLC3.CLC2.CLC1.DSM

WDT_SU:		EQU  11001101B	;  (WDTCON) 64mS during Run
TMR0S0:		EQU  11100001B	;  (T0CON0) En, 8b, Post%2
TMR0S1:		EQU  01000011B	;  (T0CON1) Fosc/4, Pre%8
TMR1SU:		EQU  00110111B	;   (T1CON) Fosc/4, Pre/8 -Xosc, -Sync, En
TMR2SU:		EQU  11111100B	;   (T2CON) Post%16, On, Pre%1 (32KHz PWM5, PWM6)

TMR0SP:		EQU  200-1	;   (TH) Fosc/4 /8 /N /2 = 2.5KHz   400uS/ov
TMR2SP:		EQU  256-1	;   ( PR2 )

T1GSU:		EQU  10101110B	;  (T1GCON) En \ Tog -SP Gate=Cmp1

VREFSU:		EQU  11010100B	; (FVRCON ) 1.024 to DAC
DAC0SU:		EQU  11011000B	; (DACCON0) On, NoOut ref+=FVR ref-=GND
DAC1SU:		EQU  2		; (DACCON1) 0.480v ?? actually 0.412v
CM1SU0:		EQU  11111110B	; (CM1CON0) On, Inv, HS, +Hys, T1Sync
CM1SU1:		EQU  01101010B	; (CM1CON1) \Int, +DAC1, -RC2 (Amps)
ADCSU0:		EQU  00001001B	;  (ADCON0) Chan-2, A/D Pwr-On.  (vbatt)
ADCSU1:		EQU  10101000B	;  (ADCON1) Right, Fosc/32 (1MHz), Ref= VDD & GND
ADCSU2:		EQU  00000000B	;  (ADACT)  Auto Trigger - Off		**Punch

CH_BATT:	EQU  00001001B	;  (ADCON0) Chan-02, Battery Volts
CH_FANA:	EQU  01001001B	;  (ADCON0) Chan-18, Fan Amps
CH_FANV:	EQU  01001101B	;  (ADCON0) Chan-19, Fan Volts

UTXSU1:		EQU  10100111B	;  (TX1STA) 8bit, TXen, Async, HiBaud
URCSU1:		EQU  10111001B	;  (RC1STA) SPen, 8bit, RXen
BCTL1SU:	EQU  11101100B	; (BAUD1CON) TXhi 16B -WU -AB		32MHz
UBAUD:		EQU  208-1	;  (SP1BRG) Serial Baudrate = 38400	Osc%4

PWM5SU:		EQU  11111111B	; (PWM5CON) En, Out- (Inverted)
PWM6SU:		EQU  11101111B	; (PWM6CON) En, Out+
PWMTSU:		EQU  11110101B	; (PWMTMRS) 6 = Tmr2, 5 = Tmr2

SSPSSU:		EQU  11111110B	; (SSP1STAT) SMP=1 In \_  CKE=1 Out \_
SSP1SU:		EQU  11001010B	; (SSP1CON1) Dis, CKP=0  SPI Master Adj Clk
SSP2SU:		EQU  00000000B	; (SSP1CON2)	Idle Clk = 0		**Punch
SSP3SU:		EQU  00000000B	; (SSP1CON3)				**Punch
SSPBDU:		EQU  00000111B	;  (SSP1ADD) Fosc/32

	NOLIST
	SUBTITLE "RAM Definitions"
	LIST


	Page



	CBLOCK	0x0020		; 020-06F  ----  Mainline Data	------	Bank_r0
FLAG1:		1		; 020	- - G.P. Flags
RPMCNT:		1		; 021	- - RPM Pulse Counter
FSPEED:		2		; 022	- - Fan PWM Value
xxx024:		1		; 024	- -
	ENDC

	CBLOCK	0x060
DELAY1:		1		; 060	  - 10mS  Timing
DELAY2:		1		; 061	  - 250mS Timing
DELAYB:		1		; 062	  - Push Button DeBounce
DELAYE:		1		; 063	  - Error Fan Toggle Timing
DELAYK:		1		; 064	  - Kill power if Fan Disconnected
xxx064:		7		; 065-06B -
PUP:		4		; 06C-06F - 55,AA,5A,A5 values for Power-Up Test
	ENDC

	CBLOCK 0x070		;-----	Common RAM in All Banks  -----	Bank_All

MTEMP:		8		; 070-077 - Mainline  G.P. registers +0 to +7
ITEMPD:		1		; 078	- - Interrupt G.P. reg
xxx079:		1		; 079	- -
xxx07A:		1		; 07A	- -
xxx07B:		1		; 07B	- -
xxx07C:		1		; 07C	- -
xxx07D:		1		; 07D	- -
				;			;***************************
ROMSUM:		1		; 07E	- - Checksum	; Do Not Move these values *
FLAG7:		1		; 07F	- - See Below	;***************************
	ENDC

	CBLOCK	0x0A0		; 0A0-0EF  ---------------------------	Bank_r1
AD_DATA:
AD_BATT:	4		; 0A0-0A3 - Battery Voltage	18.6 cnts/v
AD_FANA:	4		; 0A4-0A7 - Fan Amps
AD_FANV:	4		; 0A8-0AB - Fan Volts
RPMVAL:		4		; 0AC-0AF - Fan RPM
ADCNT:		1		; 0B0	- - A/D Channel Counter		*** MUST be Bank 1 ***
xxx0B1:		11		; 0B1-0BB
PERVAL:		2		; 0BC-0BD - Period (Filtered)
PERRAW:		2		; 0BE-0BF - Period (Raw)

	ENDC
NADAT0:		EQU  AD_BATT+3	; 0A3	- - NEW - OLD
NADAT1:		EQU  AD_FANA+3	; 0A7
NADAT2:		EQU  AD_FANV+3	; 0AB


	Page



	CBLOCK	0x120		; 120-16F  ---------------------------	Bank_r2
	ENDC

	CBLOCK	0x1A0		; 1A0-1EF  ---------------------------	Bank_r3
	ENDC

	CBLOCK	0x220		; 220-26F  ---------------------------	Bank_r4

EEPBUF:		64		; 220-25F - External EEP I/O Buffer
	ENDC

	CBLOCK	0x2A0		; 2A0-2EF  ---------------------------	Bank_r5
	ENDC

	CBLOCK	0x320		; 320-36F  ---------------------------	Bank_r6
	ENDC

	CBLOCK	0x3A0		; 3A0-3EF  ---------------------------	Bank_r7
	ENDC

	CBLOCK	0x420		; 420-46F  ---------------------------	Bank_r8
	ENDC

	CBLOCK	0x4A0		; 4A0-4EF  ---------------------------	Bank_r9
	ENDC

	CBLOCK	0x520		; 520-56F  ---------------------------	Bank_r10

PGMBUF:		64		; 520-15F - Flash Write
PGMTRY:		1		; 560	  - Flash Write Try's
;		1		; 561	  -
;		1		; 562	  -
;		1		; 563	  -
	ENDC

RFWRAP:		EQU  5		;	  - Creates circular buffer
SB_LEN:		EQU  48

	CBLOCK	0x5A0		; 5A0-5EF  ------  Bootstrap  --------	Bank_r11

RFIFO:		(1<<RFWRAP)	; 5A0-5BF - Serial Input FIFO
SBUFFER:	SB_LEN		; 5C0-5EF - Serial Packet Buffer
	ENDC

	CBLOCK	0x620		; 620-64F  ---------------------------	Bank_r12
BOOTBANK:
RF_LEN:		1		; 650	  - Recv FiFo Length
RFGETP:		1		; 651	  - Recv FiFo Get pointer
RFPUTP:		1		; 652	  - Recv FiFo Put pointer
BSTATE:		1		; 653	  - Packet State Machine flags
BP_LEN:		1		; 654	  - Packet Data Length
BP_PTR:		1		; 655	  - Serial Get Pointer
BPTYPE:		1		; 656	  - Packet TYPE
DELAYZ:		1		; 657	- - Activity LED timing
CRC16:		2		; 658-659 - Boot Packet CRC
ADDRB:		2		; 65A-65B - Address.0.1
xxx65C:		4		; 65C-65F -
	ENDC


	Page



;-------------	0x020 - FLAG1 - Bit Definitions  ---------------------

;B1:		EQU  7		;
;B1:		EQU  6		;
;B1:		EQU  5		;
;B1:		EQU  4		;
B1RPMT:		EQU  3		; RPM Calculate Trigger
B1ASYNC:	EQU  2		; A/D Sync Flag
B1PUSH:		EQU  1		; Push Button One Shot
B1ERRT:		EQU  0		; Error Toggle


;-------------	0x07F - FLAG7 - Bit Definitions  ---------------------

B7LOCK:		EQU  7		; Mainline Lockout during programming
B7CKSUM:	EQU  6		; Checksum is Bad
B7XMIT:		EQU  5		; Serial Xmit Enabled
B7EPDONE:	EQU  4		; Delay Mainline until Ext. EEP read
B7ERRF:		EQU  3		; Error Flag
;B7:		EQU  2		;
;B7:		EQU  1		;
;B7:		EQU  0		;


;-------------	Miscellaneous Constants  -----------------------------

DB_BIT:		EQU  7		;  60mS Button Debounce
TIME10MS:	EQU  20		;  10mS Code Section		500uS/cnt
TIME250MS:	EQU  25		; 250mS Code Section		 10mS/cnt
TIME_KILL:	EQU  5*4	; 5 Sec Disconnect Shutdown	250mS/cnt
TIME_ERR:	EQU  3*4	; 2 Sec Error Fan Toggle	250mS/cnt
;TIME_ERR:	EQU  2		; Test FAST			250mS/cnt		**Patch

#DEFINE	SWPOWER	LATC, BC_OE	; Switcher Enable


	NOLIST

; Disable USELESS warnings
;
	ERRORLEVEL 0
	ERRORLEVEL -302 ; Register in operand not in bunk_0.  Ensure that bunk bits are correct.
	ERRORLEVEL -306
	ERRORLEVEL -224 ; Use of this instruction is not recommended.

;@@@	TOPROM: EQU	0x0800		;  2K	PIC16F18313  8p
;@@@	TOPRAM: EQU	0x20EF		; 256
;@@@	TOPROM: EQU	0x0800		;  2K	PIC16F18323 14p
;@@@	TOPRAM: EQU	0x20EF		; 256
;@@@	TOPROM: EQU	0x1000		;  4K	PIC16F18324 14p
;@@@	TOPRAM: EQU	0x21EF		; 512
;@@@	TOPROM: EQU	0x4000		; 16K	PIC16F18326 14p
;@@@	TOPRAM: EQU	0x27EF		; 2048

MAXROM:		EQU  0x2000	;  8K	PIC16F18325 14p
TOPROM:		EQU  0x2000
TOPRAM:		EQU  0x23EF	; 1024

	__MAXRAM	0xFFF
	__BADRAM	0x00D, 0x00F
	__BADRAM	0x08D, 0x08F, 0x095, 0x096, 0x098, 0x099, 0x09A
	__BADRAM	0x10D, 0x10F-0x110, 0x11A-0x11F
	__BADRAM	0x18D, 0x18F-0x196, 0x198
	__BADRAM	0x20D, 0x20F-0x210, 0x218
	__BADRAM	0x290, 0x299-0x29E
	__BADRAM	0x30D, 0x30F-0x310, 0x319-0x31F
	__BADRAM	0x38D, 0x38F-0x390, 0x394-0x396, 0x39B
	__BADRAM	0x40D, 0x40F-0x410
	__BADRAM	0x48D, 0x48F-0x497
	__BADRAM	0x50C-0x51F
	__BADRAM	0x58C-0x59F
	__BADRAM	0x60C-0x616, 0x61D-0x61E, 0x650-0x66F
	__BADRAM	0x68C-0x690, 0x69A-0x69F, 0X6A0-0x6EF
	__BADRAM	0x70C-0x710, 0x71A-0x71F, 0x720-0x76F
	__BADRAM	0x78C-0x7EF
	__BADRAM	0x80C-0x86F
	__BADRAM	0x88C-0x890, 0x897-0x89A, 0x89C-0x8EF
	__BADRAM	0x90C-0x910, 0x917, 0x920-0x96F
	__BADRAM	0x98C-0x9EF
	__BADRAM	0xA0C-0xA6F
	__BADRAM	0xA8C-0xAEF
	__BADRAM	0xB0C-0xB6F
	__BADRAM	0xB8C-0xBEF
	__BADRAM	0xC0C-0xC6F
	__BADRAM	0xC8C-0xCEF
	__BADRAM	0xD0C-0xD6F
	__BADRAM	0xD8C-0xDEF
	__BADRAM	0xE0C-0xE0E, 0xE23, 0xE26-0xE27, 0xE30-0xE6F
	__BADRAM	0xE8C-0xE8F, 0xE93, 0xE96-0xE9F, 0xEA6-0xEEF
	__BADRAM	0xF0C-0xF0E, 0xF38-0xF6F, 0xF8C-0xFE3, 0xFEC

;---------------------	CONFIG1 Options  -----------------------------

_FEXTOSC_LP:	EQU  0x3FF8	; LP (crystal oscillator) optimized for 32.768 kHz
_FEXTOSC_XT:	EQU  0x3FF9	; XT (crystal oscillator) from 100 kHz to 4 MHz
_FEXTOSC_HS:	EQU  0x3FFA	; HS (crystal oscillator) above 4 MHz
_FEXTOSC_OFF:	EQU  0x3FFC	; Oscillator not enabled
_FEXTOSC_ECL:	EQU  0x3FFD	; EC (external clock) below 100 kHz
_FEXTOSC_ECM:	EQU  0x3FFE	; EC (external clock) for 100 kHz to 8 MHz
_FEXTOSC_ECH:	EQU  0x3FFF	; EC (external clock) above 8 MHz

_RSTOSC_HFINT32:EQU  0x3F8F	; HFINTOSC with 2x PLL (32MHz)
_RSTOSC_EXT4X:	EQU  0x3F9F	; EXTOSC with 4x PLL, with EXTOSC operating per FEXTOSC bits
_RSTOSC_SOSC:	EQU  0x3FBF	; SOSC (31kHz)
_RSTOSC_LFINT:	EQU  0x3FCF	; LFINTOSC (31kHz)
_RSTOSC_HFINT1:	EQU  0x3FEF	; HFINTOSC (1MHz)
_RSTOSC_EXT1X:	EQU  0x3FFF	; EXTOSC operating per FEXTOSC bits

_CLKOUTEN_ON:	EQU  0x3EFF	; CLKOUT function is enabled	; FOSC/4 clock appears at OSC2
_CLKOUTEN_OFF:	EQU  0x3FFF	; CLKOUT function is disabled	; I/O or oscillator function on OSC2

_CSWEN_OFF:	EQU  0x37FF	; The OSCCON1 NOSC and NDIV bits cannot be changed by user software
_CSWEN_ON:	EQU  0x3FFF	; Writing to NOSC and NDIV is allowed

_FCMEN_OFF:	EQU  0x1FFF	; Fail-Safe Clock Monitor is disabled
_FCMEN_ON:	EQU  0x3FFF	; Fail-Safe Clock Monitor is enabled

;---------------------	CONFIG2 Options  -----------------------------

_MCLRE_OFF:	EQU  0x3FFE	; MCLR/VPP pin function is digital input	; MCLR internally disabled
				;	Weak pull-up under control of port pins WPU control bit.
_MCLRE_ON:	EQU  0x3FFF	; MCLR/VPP pin function is MCLR			; Weak pull-up enabled

_PWRTE_ON:	EQU  0x3FFD	; PWRT enabled
_PWRTE_OFF:	EQU  0x3FFF	; PWRT disabled

_WDTE_OFF:	EQU  0x3FF3	; WDT disabled	; SWDTEN is ignored
_WDTE_SWDTEN:	EQU  0x3FF7	; WDT controlled by the SWDTEN bit in the WDTCON register
_WDTE_SLEEP:	EQU  0x3FFB	; WDT enabled while running and disabled in SLEEP/IDLE	; SWDTEN is ignored
_WDTE_ON:	EQU  0x3FFF	; WDT enabled, SWDTEN is ignored

_LPBOREN_ON:	EQU  0x3FDF	; ULPBOR enabled
_LPBOREN_OFF:	EQU  0x3FFF	; ULPBOR disabled

_BOREN_OFF:	EQU  0x3F3F	; Brown-out Reset disabled
_BOREN_SBOREN:	EQU  0x3F7F	; Brown-out Reset enabled according to SBOREN
_BOREN_SLEEP:	EQU  0x3FBF	; Brown-out Reset enabled while running, disabled in Sleep, SBOREN is ignored
_BOREN_ON:	EQU  0x3FFF	; Brown-out Reset enabled, SBOREN bit ignored

_BORV_HIGH:	EQU  0x3DFF	; Brown-out voltage (Vbor) set to 2.7V
_BORV_LOW:	EQU  0x3FFF	; Brown-out voltage (Vbor) set to 2.45V

_PPS1WAY_OFF:	EQU  0x37FF	; The PPSLOCK bit can be set and cleared repeatedly (subject to the unlock sequence)
_PPS1WAY_ON:	EQU  0x3FFF	; The PPSLOCK bit can be cleared and set only once
				;	PPS registers remain locked after one clear/set cycle

_STVREN_OFF:	EQU  0x2FFF	; Stack Overflow or Underflow will not cause a Reset
_STVREN_ON:	EQU  0x3FFF	; Stack Overflow or Underflow will cause a Reset

_DEBUG_ON:	EQU  0x1FFF	; Background debugger enabled
_DEBUG_OFF:	EQU  0x3FFF	; Background debugger disabled

;---------------------	CONFIG3 Options  -----------------------------

_WRT_ALL:	EQU  0x3FFC	; 0000h to 07FFh write protected, no addresses may be modified
_WRT_HALF:	EQU  0x3FFD	; 0000h to 03FFh write-protected, 0400h to 07FFh may be modified
_WRT_BOOT:	EQU  0x3FFE	; 0000h to 01FFh write-protected, 0200h to 07FFh may be modified
_WRT_OFF:	EQU  0x3FFF	; Write protection off

_LVP_OFF:	EQU  0x1FFF	; High Voltage on MCLR/VPP must be used for programming.
_LVP_ON:	EQU  0x3FFF	; Low Voltage programming enabled. MCLR/VPP pin function is MCLR.
;				;	MCLRE configuration bit is ignored.

;---------------------	CONFIG4 Options  -----------------------------

_CP_ON:		EQU  0x3FFE	; User Flash code protection enabled
_CP_OFF:	EQU  0x3FFF	; User Flash code protection disabled

_CPD_ON:	EQU  0x3FFD	; Data EEP code protection enabled
_CPD_OFF:	EQU  0x3FFF	; Data EEP code protection disabled

_CONFIG1:	EQU  0x8007
_CONFIG2:	EQU  0x8008
_CONFIG3:	EQU  0x8009
_CONFIG4:	EQU  0x800A


;************	WARNING:	 MUST use Brownout Reset or will not start reliably	****************

	LIST


	__CONFIG _CONFIG1, _FEXTOSC_OFF & _RSTOSC_HFINT32 & _CLKOUTEN_OFF & _CSWEN_OFF & _FCMEN_OFF
	__CONFIG _CONFIG2, _MCLRE_OFF & _PWRTE_OFF & _WDTE_SLEEP & _LPBOREN_OFF & _BOREN_ON & _BORV_HIGH & _PPS1WAY_OFF & _STVREN_ON & _DEBUG_OFF
	__CONFIG _CONFIG3, _WRT_OFF & _LVP_OFF
	IFDEF	RELEASE
	__CONFIG _CONFIG4, _CP_ON & _CPD_OFF
	ELSE
	__CONFIG _CONFIG4, _CP_OFF & _CPD_OFF
	ENDIF

	NOLIST

;---------------------	All_Banks  -----------------------------------

INDF0:		EQU  0x000
INDF1:		EQU  0x001
PCL:		EQU  0x002
STATUS:		EQU  0x003
FSR0:		EQU  0x004
FSR0L:		EQU  0x004
FSR0H:		EQU  0x005
FSR1:		EQU  0x006
FSR1L:		EQU  0x006
FSR1H:		EQU  0x007
BSR:		EQU  0x008
WREG:		EQU  0x009
PCH:		EQU  0x00A
INTCON0:	EQU  0x00B

;---------------------	Bank_00  -------------------------------------

PORTA:		EQU  0x00C
PORTC:		EQU  0x00E

PIR0:		EQU  0x010
PIR1:		EQU  0x011
PIR2:		EQU  0x012
PIR3:		EQU  0x013
PIR4:		EQU  0x014
TMR0L:		EQU  0x015
TMR0H:		EQU  0x016
T0CON0:		EQU  0x017
T0CON1:		EQU  0x018
TMR1L:		EQU  0x019
TMR1H:		EQU  0x01A
T1CON:		EQU  0x01B
T1GCON:		EQU  0x01C
TMR2:		EQU  0x01D
PR2:		EQU  0x01E
T2CON:		EQU  0x01F

;---------------------	Bank_01  -------------------------------------

TRISA:		EQU  0x08C
TRISC:		EQU  0x08E
PIE0:		EQU  0x090
PIE1:		EQU  0x091
PIE2:		EQU  0x092
PIE3:		EQU  0x093
PIE4:		EQU  0x094
WDTCON:		EQU  0x097
ADRES:		EQU  0x09B
ADRESL:		EQU  0x09B
ADRESH:		EQU  0x09C
ADCON0:		EQU  0x09D
ADCON1:		EQU  0x09E
ADACT:		EQU  0x09F

;---------------------	Bank_02  -------------------------------------

LATA:		EQU  0x10C
LATC:		EQU  0x10E
CM1CON0:	EQU  0x111
CM1CON1:	EQU  0x112
CM2CON0:	EQU  0x113
CM2CON1:	EQU  0x114
CMOUT:		EQU  0x115
BORCON:		EQU  0x116
FVRCON:		EQU  0x117
DACCON0:	EQU  0x118
DACCON1:	EQU  0x119

;---------------------	Bank_03  -------------------------------------

ANSELA:		EQU  0x18C
ANSELC:		EQU  0x18E
VREGCON:	EQU  0x197
RC1REG:		EQU  0x199
TX1REG:		EQU  0x19A
SP1BRGL:	EQU  0x19B
SP1BRGH:	EQU  0x19C
RC1STA:		EQU  0x19D
TX1STA:		EQU  0x19E
BAUD1CON:	EQU  0x19F

;---------------------	Bank_04  -------------------------------------

WPUA:		EQU  0x20C
WPUC:		EQU  0x20E
SSP1BUF:	EQU  0x211
SSP1ADD:	EQU  0x212
SSP1MSK:	EQU  0x213
SSP1STAT:	EQU  0x214
SSP1CON1:	EQU  0x215
SSP1CON2:	EQU  0x216
SSP1CON3:	EQU  0x217
SSP2BUF:	EQU  0x219
SSP2ADD:	EQU  0x21A
SSP2MSK:	EQU  0x21B
SSP2STAT:	EQU  0x21C
SSP2CON1:	EQU  0x21D
SSP2CON2:	EQU  0x21E
SSP2CON3:	EQU  0x21F

;---------------------	Bank_05  -------------------------------------

ODCONA:		EQU  0x28C
ODCONC:		EQU  0x28E
CCPR1L:		EQU  0x291
CCPR1H:		EQU  0x292
CCP1CON:	EQU  0x293
CCP1CAP:	EQU  0x294
CCPR2L:		EQU  0x295
CCPR2H:		EQU  0x296
CCP2CON:	EQU  0x297
CCP2CAP:	EQU  0x298
CCPTMRS:	EQU  0x29F

;---------------------	Bank_06  -------------------------------------

SLRCONA:	EQU  0x30C
SLRCONC:	EQU  0x30E
CCPR3L:		EQU  0x311
CCPR3H:		EQU  0x312
CCP3CON:	EQU  0x313
CCP3CAP:	EQU  0x314
CCPR4L:		EQU  0x315
CCPR4H:		EQU  0x316
CCP4CON:	EQU  0x317
CCP4CAP:	EQU  0x318

;---------------------	Bank_07  -------------------------------------

INLVLA:		EQU  0x38C
INLVLC:		EQU  0x38E
IOCAP:		EQU  0x391
IOCAN:		EQU  0x392
IOCAF:		EQU  0x393
IOCCP:		EQU  0x397
IOCCN:		EQU  0x398
IOCCF:		EQU  0x399
CLKRCON:	EQU  0x39A
MDCON:		EQU  0x39C
MDSRC:		EQU  0x39D
MDCARH:		EQU  0x39E
MDCARL:		EQU  0x39F

;---------------------	Bank_08  -------------------------------------

CCDNA:		EQU  0x40C
CCDNC:		EQU  0x40E
TMR3L:		EQU  0x411
TMR3H:		EQU  0x412
T3CON:		EQU  0x413
T3GCON:		EQU  0x414
TMR4:		EQU  0x415
PR4:		EQU  0x416
T4CON:		EQU  0x417
TMR5L:		EQU  0x418
TMR5H:		EQU  0x419
T5CON:		EQU  0x41A
T5GCON:		EQU  0x41B
TMR6:		EQU  0x41C
PR6:		EQU  0x41D
T6CON:		EQU  0x41E
CCDCON:		EQU  0x41F

;---------------------	Bank_09  -------------------------------------

CCDPA:		EQU  0x48C
CCDPC:		EQU  0x48E
NCO1ACCL:	EQU  0x498
NCO1ACCH:	EQU  0x499
NCO1ACCU:	EQU  0x49A
NCO1INCL:	EQU  0x49B
NCO1INCH:	EQU  0x49C
NCO1INCU:	EQU  0x49D
NCO1CON:	EQU  0x49E
NCO1CLK:	EQU  0x49F

;---------------------	Bank_12  -------------------------------------

PWM5DCL:	EQU  0x617
PWM5DCH:	EQU  0x618
PWM5CON:	EQU  0x619
PWM6DCL:	EQU  0x61A
PWM6DCH:	EQU  0x61B
PWM6CON:	EQU  0x61C
PWMTMRS:	EQU  0x61F

;---------------------	Bank_13  -------------------------------------

CWG1CLKCON:	EQU  0x691
CWG1ISM:	EQU  0x692
CWG1DBR:	EQU  0x693
CWG1DBF:	EQU  0x694
CWG1CON0:	EQU  0x695
CWG1CON1:	EQU  0x696
CWG1AS0:	EQU  0x697
CWG1AS1:	EQU  0x698
CWG1STR:	EQU  0x699

;---------------------	Bank_14  -------------------------------------

CWG2CLKCON:	EQU  0x711
CWG2ISM:	EQU  0x712
CWG2DBR:	EQU  0x713
CWG2DBF:	EQU  0x714
CWG2CON0:	EQU  0x715
CWG2CON1:	EQU  0x716
CWG2AS0:	EQU  0x717
CWG2AS1:	EQU  0x718
CWG2STR:	EQU  0x719

;---------------------	Bank_17  -------------------------------------

NVMADR:		EQU  0x891
NVMADRL:	EQU  0x891
NVMADRH:	EQU  0x892
NVMDAT:		EQU  0x893
NVMDATL:	EQU  0x893
NVMDATH:	EQU  0x894
NVMCON1:	EQU  0x895
NVMCON2:	EQU  0x896
PWRCON0:	EQU  0x89B

;---------------------	Bank_18  -------------------------------------

PMD0:		EQU  0x911
PMD1:		EQU  0x912
PMD2:		EQU  0x913
PMD3:		EQU  0x914
PMD4:		EQU  0x915
PMD5:		EQU  0x916
CPUDOZE:	EQU  0x918
OSCCON1:	EQU  0x919
OSCCON2:	EQU  0x91A
OSCCON3:	EQU  0x91B
OSCSTAT1:	EQU  0x91C
OSCEN:		EQU  0x91D
OSCTUNE:	EQU  0x91E
OSCFRQ:		EQU  0x91F

;---------------------	Bank_28  -------------------------------------

PPSLOCK:	EQU  0xE0F	; Peripheral Input Pin selection
INTPPS:		EQU  0xE10	;
T0CKIPPS:	EQU  0xE11	; 0000 0000- RA0
T1CKIPPS:	EQU  0xE12	; 0000 0001- RA1
T1GPPS:		EQU  0xE13	; 0000 0010- RA2
CCP1PPS:	EQU  0xE14	; 0000 0011- RA3
CCP2PPS:	EQU  0xE15	; 0000 0100- RA4
CCP3PPS:	EQU  0xE16	; 0000 0101- RA5
CCP4PPS:	EQU  0xE17	; 0000 011x- n/u
CWG1PPS:	EQU  0xE18
CWG2PPS:	EQU  0xE19	; 0000 10xx- n/u
MDCIN1PPS:	EQU  0xE1A	; 0000 1100- RB4
MDCIN2PPS:	EQU  0xE1B	; 0000 1101- RB5
MDMINPPS:	EQU  0xE1C	; 0000 1110- RB6
SSP2CLKPPS:	EQU  0xE1D	; 0000 1111- RB7
SSP2DATPPS:	EQU  0xE1E
SSP2SSPPS:	EQU  0xE1F	; 0001 0000- RC0
SSP1CLKPPS:	EQU  0xE20	; 0001 0001- RC1
SSP1DATPPS:	EQU  0xE21	; 0001 0010- RC2
SSP1SSPPS:	EQU  0xE22	; 0001 0011- RC3
RXPPS:		EQU  0xE24	; 0001 0100- RC4
CKPPS:		EQU  0xE25	; 0001 0101- RC5
CLCIN0PPS:	EQU  0xE28	; 0001 0110- RC6
CLCIN1PPS:	EQU  0xE29	; 0001 0111- RC7
CLCIN2PPS:	EQU  0xE2A
CLCIN3PPS:	EQU  0xE2B	; 0001 1xxx- n/u
T3CKIPPS:	EQU  0xE2C	; 001x xxxx- n/u
T3GPPS:		EQU  0xE2D	; 01xx xxxx- n/u
T5CKIPPS:	EQU  0xE2E	; 1xxx xxxx- n/u
T5GPPS:		EQU  0xE2F

;---------------------	Bank_29  -------------------------------------
;
;				;  Peripheral Output Pin selection

RA0PPS:		EQU  0xE90	; 00000- Latx	  -----
RA1PPS:		EQU  0xE91	; 00001		  10100- UART TX
RA2PPS:		EQU  0xE92	; 00010- PWM5	  10101- DT
RA4PPS:		EQU  0xE94	; 00011- PWM6	  10110- C1OUT
RA5PPS:		EQU  0xE95	; 00100- CLC1OUT  10111- C2OUT
RC0PPS:		EQU  0xEA0	; 00101- CLC2OUT  11000- SCK1
RC1PPS:		EQU  0xEA1	; -----		  11001- SDO1
RC2PPS:		EQU  0xEA2	; 01000- CWG1A	  11010- SCK2
RC3PPS:		EQU  0xEA3	; 01001- CWG1B	  11011- SDO2
RC4PPS:		EQU  0xEA4	; 01010- CWG1C	  11100- TMRO
RC5PPS:		EQU  0xEA5	; 01011- CWG1D	  11101- NCO
;				; 01100- CCP1	  11110- CLKREF
;				; 01101- CCP2	  11111- DSM

;---------------------	Bank_30  -------------------------------------

CLCDATA:	EQU  0xF0F
CLC1CON:	EQU  0xF10
CLC1POL:	EQU  0xF11
CLC1SEL0:	EQU  0xF12
CLC1SEL1:	EQU  0xF13
CLC1SEL2:	EQU  0xF14
CLC1SEL3:	EQU  0xF15
CLC1GLS0:	EQU  0xF16
CLC1GLS1:	EQU  0xF17
CLC1GLS2:	EQU  0xF18
CLC1GLS3:	EQU  0xF19
CLC2CON:	EQU  0xF1A
CLC2POL:	EQU  0xF1B
CLC2SEL0:	EQU  0xF1C
CLC2SEL1:	EQU  0xF1D
CLC2SEL2:	EQU  0xF1E
CLC2SEL3:	EQU  0xF1F
CLC2GLS0:	EQU  0xF20
CLC2GLS1:	EQU  0xF21
CLC2GLS2:	EQU  0xF22
CLC2GLS3:	EQU  0xF23
CLC3CON:	EQU  0xF24
CLC3POL:	EQU  0xF25
CLC3SEL0:	EQU  0xF26
CLC3SEL1:	EQU  0xF27
CLC3SEL2:	EQU  0xF28
CLC3SEL3:	EQU  0xF29
CLC3GLS0:	EQU  0xF2A
CLC3GLS1:	EQU  0xF2B
CLC3GLS2:	EQU  0xF2C
CLC3GLS3:	EQU  0xF2D
CLC4CON:	EQU  0xF2E
CLC4POL:	EQU  0xF2F
CLC4SEL0:	EQU  0xF30
CLC4SEL1:	EQU  0xF31
CLC4SEL2:	EQU  0xF32
CLC4SEL3:	EQU  0xF33
CLC4GLS0:	EQU  0xF34
CLC4GLS1:	EQU  0xF35
CLC4GLS2:	EQU  0xF36
CLC4GLS3:	EQU  0xF37

;---------------------	Bank_31  -------------------------------------

STATUS_SHAD:	EQU  0xFE4
WREG_SHAD:	EQU  0xFE5
BSR_SHAD:	EQU  0xFE6
PCLATH_SHAD:	EQU  0xFE7
FSR0L_SHAD:	EQU  0xFE8
FSR0H_SHAD:	EQU  0xFE9
FSR1L_SHAD:	EQU  0xFEA
FSR1H_SHAD:	EQU  0xFEB
STKPTR:		EQU  0xFED
TOSL:		EQU  0xFEE
TOSH:		EQU  0xFEF


;---------------------	0x003 - STATUS bits  -------------------------

NOT_TO:		EQU  4		; WD Timeout Occured
NOT_PD:		EQU  3		; Sleep
Z:		EQU  2		; Zero
DC:		EQU  1		; Digit Cy
C:		EQU  0		; Carry

;---------------------	0x00B - INTCON0 Bits  ------------------------

GIE:		EQU  7		; Global Interrupt Enable
PEIE:		EQU  6		; Peripheral En
INTEDG:		EQU  0		;

;---------------------	0x010 - PIR0 Bits  ---------------------------	Bank_00

TMR0IF:		EQU  5
IOCIF:		EQU  4
;		EQU  3
;		EQU  2
;		EQU  1
INTF:		EQU  0

;---------------------	0x011 - PIR1 Bits  ---------------------------

TMR1GIF:	EQU  7		; T1 Gate
ADIF:		EQU  6		; A/D complete
RC1IF:		EQU  5		; UART 1 Receive
TX1IF:		EQU  4		; UART 1 Xmit TBMT
SSP1IF:		EQU  3		;
BCL1IF:		EQU  2		;
TMR2IF:		EQU  1		; TMR2:PR2 Match
TMR1IF:		EQU  0		; TMR1 Overflow

;---------------------	0x012 - PIR2 Bits  ---------------------------

TMR6IF:		EQU  7
CMP2IF:		EQU  6		; Comparitor 2
CMP1IF:		EQU  5		; Comparitor 1
NVMIF:		EQU  4		;
SSP2IF:		EQU  3
BCL2IF:		EQU  2
TMR4IF:		EQU  1
NCO1IF:		EQU  0

;---------------------	0x013 - PIR3 Bits  ---------------------------

OSFIF:		EQU  7
CSWIF:		EQU  6
TMR3GIF:	EQU  5
TMR3IF:		EQU  4
CLC4IF:		EQU  3
CLC3IF:		EQU  2
CLC2IF:		EQU  1
CLC1IF:		EQU  0

;---------------------	0x014 - PIR4 Bits  --------------------------- Bank_00

CGW2IF:		EQU  7
CWG1IF:		EQU  6
TMR5GIF:	EQU  5
TMR5IF:		EQU  4
CCP4IF:		EQU  3
CCP3IF:		EQU  2
CCP2IF:		EQU  1
CCP1IF:		EQU  0

;---------------------	0x017 - T0CON0 Bits  -------------------------

T0EN:		EQU  7		; Enable
T0OUT:		EQU  5		; Output Bit
T016BIT:	EQU  4		; 16 Bit select
T0OUTPS3:	EQU  3		;
T0OUTPS2:	EQU  2		; Post Scalar N+1
T0OUTPS1:	EQU  1		;
T0OUTPS0:	EQU  0		;

;---------------------	0x018 - T0CON1 Bits  -------------------------

T0CS2:		EQU  7		; 000- T0CKI+	011- HFINTOSC	110- SOSC
T0CS1:		EQU  6		; 001- T0CKI-	100- LFINTOSC	111- CLC1
T0CS0:		EQU  5		; 010- Fosc/4	101- n/u
T0ASYNC:	EQU  4		; Sync with Fosc % 4
T0CKPS3:	EQU  3		;
T0CKPS2:	EQU  2		; Prescale 2 ^ N
T0CKPS1:	EQU  1		;
T0CKPS0:	EQU  0		;

;---------------------	0x01B - T1CON Bits  --------------------------	Bank_00

TMR1CS1:	EQU  7		; 00- Fosc/4	10- Ext Osc
TMR1CS0:	EQU  6		; 01- Fosc	11- LFintOsc
T1CKPS1:	EQU  5		; 00- %1	10- %4
T1CKPS0:	EQU  4		; 01- %2	11- %8
T1OSCEN:	EQU  3		; Secondary Osc En
T1SYNC:		EQU  2		; -Sync to Fosc
;		EQU  1		;
TMR1EN:		EQU  0		;  Timer Enable

;---------------------	0x01C - T1GCON Bits  -------------------------

T1GEN:		EQU  7		; Gate Enable
T1GPOL:		EQU  6		; Gate Polarity
T1GTM:		EQU  5		; Gate Toggle En
T1GSPM:		EQU  4		; Gate Single-Pulse En
T1GGO:		EQU  3		; Gate Single-Pulse Go
T1GVAL:		EQU  2		; Gate Status
T1GSS1:		EQU  1		; 00- Gate Pin	10- C1OUT
T1GSS0:		EQU  0		; 01- T1ovrflo	11- C2OUT

;---------------------	0x01F - T2CON Bits  --------------------------

;		EQU  7
T2OTPS3:	EQU  6		; Post-Scale	1111-16  1011-12  0111-8  0011-4
T2OTPS2:	EQU  5		;		1110-15  1010-11  0110-7  0010-3
T2OTPS1:	EQU  4		;		1101-14  1001-10  0101-6  0001-2
T2OTPS0:	EQU  3		;		1100-13  1000-9   0100-5  0000-1
TMR2EN:		EQU  2		; Enable
T2CKPS1:	EQU  1		;		11- /64 01- /4
T2CKPS0:	EQU  0		; Pre-Scale	10- /16 00- /1



;---------------------	0x090 - PIE0 Bits  ---------------------------	Bank_01

;		EQU  7
;		EQU  6
TMR0IE:		EQU  5		; TMR1 Overflow
IOCIE:		EQU  4		; IOC
;		EQU  3		;
;		EQU  2		;
;		EQU  1		;
INTE:		EQU  0		; External Interrupt

;---------------------	0x091 - PIE1 Bits  ---------------------------

TMR1GIE:	EQU  7		; T1Gate
ADIE:		EQU  6		; A/D complete
RC1IE:		EQU  5		; UART 1 Receive
TX1IE:		EQU  4		; UART 1 Xmit
SSP1IE:		EQU  3		;
BCL1IE:		EQU  2		;
TMR2IE:		EQU  1		; TMR2:PR2 Match
TMR1IE:		EQU  0		; TMR1 Overflow

;---------------------	0x092 - PIE2 Bits  ---------------------------

TMR6IE:		EQU  7
C2IE:		EQU  6		; Comparitor 2
C1IE:		EQU  5		; Comparitor 1
NVMIE:		EQU  4		; NVM write complete
SSP2IE:		EQU  3
BCL2IE:		EQU  2
TMR4IE:		EQU  1
NCO1IE:		EQU  0		; NCO rollover

;---------------------	0x093 - PIE3 Bits  ---------------------------

OSFIE:		EQU  7
CSWIE:		EQU  6
TMR3GIE:	EQU  5
TMR3IE:		EQU  4
CLC4IE:		EQU  3
CLC3IE:		EQU  2
CLC2IE:		EQU  1
CLC1IE:		EQU  0

;---------------------	0x094 - PIE4 Bits  ---------------------------	Bank_01

CGW2IE:		EQU  7
CWG1IE:		EQU  6		; CWG Shutdown
TMR5GEF:	EQU  5
TMR5IE:		EQU  4
CCP4IE:		EQU  3
CCP3IE:		EQU  2
CCP2IE:		EQU  1
CCP1IE:		EQU  0

;---------------------	0x097 - WDTCON Bits  -------------------------

WDTPS4:		EQU  5		; xC1-	1mS  xCD-  64mS  xD9-	4s  xE5- 256s
WDTPS3:		EQU  4		; xC3-	2mS  xCF- 128mS  xDB-	8s
WDTPS2:		EQU  3		; xC5-	4mS  xD1- 256mS  xDD-  16s  xE7-xFF- 1mS
WDTPS1:		EQU  2		; xC7-	8mS  xD3- 512mS  xDF-  32s
WDTPS0:		EQU  1		; xC9- 16mS  xD5-    1s  xE1-  64s
SWDTEN:		EQU  0		; xCB- 32mS  xD7-    2s  xE3- 128s

;---------------------	0x09D - ADCON0 Bits  -------------------------

CHS5:		EQU  7		; 0- A0    010000- C0
CHS4:		EQU  6		; 1- A1    010001- C1
CHS3:		EQU  5		; 2- A2    010010- C2	011100- AVss
CHS2:		EQU  4		; 3- n/u   010011- C3	011101- Temperature
CHS1:		EQU  3		; 4- A4    010100- C4	011110- DAC1 output
CHS0:		EQU  2		; 5- A5    010101- C5	011111- FVR
ADRUN:		EQU  1		; Set to Start, wait for 0 = Stop
ADON:		EQU  0		; A/D Power control

ADCNEXT:	EQU  (1<<CHS0)

;---------------------	0x09E - ADCON1 Bits  -------------------------	Bank_01

ADFM:		EQU  7		; 1- Right Justify	0- Left Justify
ADCS2:		EQU  6		; 000- Fosc %2	100- Fosc %4
ADCS1:		EQU  5		; 001- Fosc %8	101- Fosc %16
ADCS0:		EQU  4		; 010- Fosc %32 110- Fosc %64
;		EQU  3		; 011- Frc	111- Frc
ADNREF:		EQU  2		;  0- Vref- = Gnd	 1- Vref- = RA0
ADPREF1:	EQU  1		; 00- Vref+ = Vdd	10- Vref+ = RA1
ADPREF0:	EQU  0		; 01- n/u		11- Vref+ = FVR

;---------------------	0x09F - ADACT Bits  -------------------------

TRIGSEL3:	EQU  7		; 0000- None	 0110- Cmp1  1100- CCP1
TRIGSEL2:	EQU  6		; 0011- Tmr0 ov  0111- Cmp2  1101- CCP2
TRIGSEL1:	EQU  5		; 0100- Tmr1 ov  1000- CLC1
TRIGSEL0:	EQU  4		; 0101- Tmr2 ov  1001- CLC2



;---------------------	0x111 - CM1CON0 Bits  ------------------------	Bank_02
;---------------------	0x113 - CM2CON0 Bits  ------------------------

CMON:		EQU  7		; Enable
CMCOUT:		EQU  6		; Output Status
;		EQU  5		;
CMPOL:		EQU  4		; Polarity
;		EQU  3		;
CMSP:		EQU  2		; Speed (always 1)
CMHYS:		EQU  1		; Hysteresis
CMSYNC:		EQU  0		; Tmr1 Sync

;---------------------	0x112 - CM1CON1 Bits  ------------------------
;---------------------	0x114 - CM2CON1 Bits  ------------------------

CMINTP:		EQU  7		; / Interrupt enable
CMINTN:		EQU  6		; \ Interrupt enable

CMPCH2:		EQU  5		; 000- RA0	011- n/u	110- FVR
CMPCH1:		EQU  4		; 001- n/u	100- n/u	111- Gnd
CMPCH0:		EQU  3		; 010- n/u	101- DAC1

CMNCH2:		EQU  2		; 000- RA1	011- RC3	110- FVR
CMNCH1:		EQU  1		; 001- RC1	100- n/u	111- Gnd
CMNCH0:		EQU  0		; 010- RC2	101- n/u

;---------------------	0x115 - CMOUT Bits  --------------------------

MC1OUT:		EQU  0
MC2OUT:		EQU  1

;---------------------	0x116 - BORCON Bits  -------------------------

SBOREN:		EQU  7
BORRDY:		EQU  0

;---------------------	0x117 - FVRCON Bits  -------------------------	Bank_02

FVREN:		EQU  7		; Enable
FVRDY:		EQU  6		; Ready
TSEN:		EQU  5
TSRNG:		EQU  4
CAFVR1:		EQU  3
CAFVR0:		EQU  2
ADFVR1:		EQU  1
ADFVR0:		EQU  0

;---------------------	0x118 - DACCON0 Bits  ------------------------

DAC1EN:		EQU  7		; Enable
;		EQU  6		;
DAC1OE:		EQU  5		; Output Enable
DAC1PSS1:	EQU  3		; 00- Vref+ = Vdd	10- Vref+ = FVR
DAC1PSS0:	EQU  2		; 01- Vref+ = RA1	11- n/u
;		EQU  1		;
DAC1NSS:	EQU  0		; 0- Vref- = Gnd	1- Vref- = RA2

;---------------------	0x119 - DACCON1 Values	----------------------
;
; 0- 0.000	 8- 1.250	16- 2.500	24- 3.750
; 1- 0.156	 9- 1.406	17- 2.656	25- 3.906
; 2- 0.312	10- 1.562	18- 2.812	26- 4.062
; 3- 0.468	11- 1.718	19- 2.968	27- 4.218
; 4- 0.625	12- 1.875	20- 3.125	28- 4.375
; 5- 0.781	13- 2.031	21- 3.281	29- 4.531
; 6- 0.937	14- 2.187	22- 3.437	30- 4.687
; 7- 1.093	15- 2.343	23- 3.593	31- 4.843



;---------------------	0x197 - VREGCON Bits  ------------------------	Bank_03

VREGP1:		EQU  1		; 00- LDO on Full	10- LDO Off, BandGap On
VREGP0:		EQU  0		; 01- LDO Low-Power	11- LDO Off, BandGap as needed

;---------------------	0x19D - RC1STA Bits  -------------------------

SPEN:		EQU  7		; Serial Port Enable
RX9:		EQU  6		; 9-bit Enable
SREN:		EQU  5		; Sync Master single receive
CREN:		EQU  4		; Receive Enable
ADDEN:		EQU  3		; Address Detect (9b M0DE)
FERR:		EQU  2		; Framing Error
OERR:		EQU  1		; Overrun Error
RX9D:		EQU  0		; 9th Bit

;---------------------	0x19E - TX1STA Bits  -------------------------

CSRC:		EQU  7		; Sync Clk Src
TX9:		EQU  6		; 9-bit Enable
TXEN:		EQU  5		; Xmit Enable
SSYNC:		EQU  4		; 1-Sync	0-Async
SENDB:		EQU  3		; Send Sync Break
BRGH:		EQU  2		; 1-Hi Baud	0-Lo Baud
TRMT:		EQU  1		; SR Empty
TX9D:		EQU  0		; 9th Bit

;---------------------	0x19F - BAUD1CON Bits  -----------------------

ABDOVF:		EQU  7		;
RCIDL:		EQU  6		;
;		EQU  5		;
SCKP:		EQU  4		;
BRG16:		EQU  3		;
;		EQU  2		;
WUE:		EQU  1		;
ABDEN:		EQU  0		;

;---------------------	0x214 - SSP1STAT Bits  -----------------------	Bank_04
;---------------------	0x21C - SSP2STAT Bits  -----------------------

SMP:		EQU  7		; Sample time	1- End-of-Data	0- Mid-of-Data
CKE:		EQU  6		; Xmit		1- \_		0- _/
I2C_DAT:	EQU  5		; Data, not Address
I2C_STOP:	EQU  4
I2C_STRT:	EQU  3
R_W:		EQU  2		; Read/Write
UA:		EQU  1		; Update Address
BF:		EQU  0		; Buffer Full

;---------------------	0x215 - SSP1CON1 Bits  -----------------------
;---------------------	0x21D - SSP2CON1 Bits  -----------------------

WCOL:		EQU  7		; Write Collision
SSPOV:		EQU  6		; Receive Overflow
SSPEN:		EQU  5		; SSP Enable
CKP:		EQU  4		; 1-Hi 0-Lo Clock polarity
SSPM3:		EQU  3		; 0000- % 4	0100- SCK -SS ena  1000- IC Mas (osc)
SSPM2:		EQU  2		; 0001- %16	0101- SCK -SS dis  1011- IC Mas manual
SSPM1:		EQU  1		; 0010- %64	0110- IC sl 7bit   1110- IC sl 7b St/St
SSPM0:		EQU  0		; 0011- TMR2%2	0111- IC sl 10bit  1111- IC sl 10bSt/St

;---------------------	0x216 - SSP1CON2 Bits  -----------------------
;---------------------	0x21E - SSP2CON2 Bits  -----------------------

GCEN:		EQU  7		; General Call
ACKSTAT:	EQU  6		; Ack Status
ACKDT:		EQU  5		; Ack Data
ACKEN:		EQU  4		; Ack En
RCEN:		EQU  3		; Receive Enable
PEN:		EQU  2		; STOP condition
RSEN:		EQU  1		; Repeated START en
SEN:		EQU  0		; Stretch Enable

;---------------------	0x217 - SSP1CON3 Bits  -----------------------	Bank_04
;---------------------	0x21F - SSP2CON3 Bits  -----------------------

DHEN:		EQU  0
AHEN:		EQU  1
SBCDE:		EQU  2
SDAHT:		EQU  3
BOEN:		EQU  4		; 1 - Ignore Buffer Overflow
SCIE:		EQU  5
PCIE:		EQU  6
ACKTIM:		EQU  7



;---------------------	0x29F - CCPTMRS Bits -------------------------	Bank_05

C4TSEL1:	EQU  7
C4TSEL0:	EQU  6
C3TSEL1:	EQU  5
C3TSEL0:	EQU  4
C2TSEL1:	EQU  3
C2TSEL0:	EQU  2
C1TSEL1:	EQU  1
C1TSEL0:	EQU  0

;---------------------	0x293 - CCP1CON Bits  ------------------------	Bank_05
;---------------------	0x297 - CCP2CON Bits  ------------------------
;---------------------	0x313 - CCP3CON Bits -------------------------	Bank_06
;---------------------	0x317 - CCP4CON Bits -------------------------

CCPMODE0:	EQU  0
CCPMODE1:	EQU  1
CCPMODE2:	EQU  2
CCPMODE3:	EQU  3
CCPFMT:		EQU  4
CCPOUT:		EQU  5
CCPEN:		EQU  7

;---------------------	0x294 - CCP1CAP Bits -------------------------	Bank_05
;---------------------	0x298 - CCP2CAP Bits  ------------------------
;---------------------	0x314 - CCP3CAP Bits -------------------------	Bank_06
;---------------------	0x318 - CCP4CAP Bits -------------------------

CCPCTS0:	EQU  0
CCPCTS1:	EQU  1
CCPCTS2:	EQU  2
CCPCTS3:	EQU  3



;---------------------	0x39A - CLKRCON Bits  ------------------------	Bank_07

CLKRDIV0:	EQU  0
CLKRDIV1:	EQU  1
CLKRDIV2:	EQU  2
CLKRDC0:	EQU  3
CLKRDC1:	EQU  4
CLKREN:		EQU  7

;---------------------	0x39C - MDCON Bits  --------------------------

MDBIT:		EQU  0
MDOUT:		EQU  3
MDOPOL:		EQU  4
MDEN:		EQU  7

;---------------------	0x39D - MDSRC Bits ---------------------------

MDMS0:		EQU  0
MDMS1:		EQU  1
MDMS2:		EQU  2
MDMS3:		EQU  3

;---------------------	0x39E - MDCARH Bits  -------------------------

MDCH0:		EQU  0
MDCH1:		EQU  1
MDCH2:		EQU  2
MDCH3:		EQU  3
MDCHSYNC:	EQU  5
MDCHPOL:	EQU  6

;---------------------	0x39F - MDCARL Bits  -------------------------

MDCL0:		EQU  0
MDCL1:		EQU  1
MDCL2:		EQU  2
MDCL3:		EQU  3
MDCLSYNC:	EQU  5
MDCLPOL:	EQU  6



;---------------------	0x413 - T3CON Bits ---------------------------	Bank_08

TMR3CS1:	EQU  7		; 00- Fosc/4	10- Ext Osc
TMR3CS0:	EQU  6		; 01- Fosc	11- LFintOsc
T3CKPS1:	EQU  5		; 00- %1	10- %4
T3CKPS0:	EQU  4		; 01- %2	11- %8
T3OSCEN:	EQU  3		; Secondary Osc En
T3SYNC:		EQU  2		; -Sync to Fosc
;		EQU  1		;
TMR3EN:		EQU  0		;  Timer Enable

;---------------------	0x414 - T3GCON Bits --------------------------

T3GEN:		EQU  7		; Gate Enable
T3GPOL:		EQU  6		; Gate Polarity
T3GTM:		EQU  5		; Gate Toggle En
T3GSPM:		EQU  4		; Gate Single-Pulse En
T3GGO:		EQU  3		; Gate Single-Pulse Go
T3GVAL:		EQU  2		; Gate Status
T3GSS1:		EQU  1		; 00- Gate Pin	10- TMR2 match PR2
T3GSS0:		EQU  0		; 01- T1ovrflo	11- n/u

;---------------------	0x417 - T4CON Bits ---------------------------

;		EQU  7
T4OTPS3:	EQU  6		; Post-Scale	1111-16  1011-12  0111-8  0011-4
T4OTPS2:	EQU  5		;		1110-15  1010-11  0110-7  0010-3
T4OTPS1:	EQU  4		;		1101-14  1001-10  0101-6  0001-2
T4OTPS0:	EQU  3		;		1100-13  1000-9   0100-5  0000-1
TMR4EN:		EQU  2		; Enable
T4CKPS1:	EQU  1		;		11- /64 01- /4
T4CKPS0:	EQU  0		; Pre-Scale	10- /16 00- /1

;---------------------	0x41A - T5CON Bits ---------------------------	Bank_08

TMR5CS1:	EQU  7		; 00- Fosc/4	10- Ext Osc
TMR5CS0:	EQU  6		; 01- Fosc	11- LFintOsc
T5CKPS1:	EQU  5		; 00- %1	10- %4
T5CKPS0:	EQU  4		; 01- %2	11- %8
T5OSCEN:	EQU  3		; Secondary Osc En
T5SYNC:		EQU  2		; -Sync to Fosc
;		EQU  1		;
TMR5EN:		EQU  0		;  Timer Enable

;---------------------	0x41B - T5GCON Bits --------------------------

T5GEN:		EQU  7		; Gate Enable
T5GPOL:		EQU  6		; Gate Polarity
T5GTM:		EQU  5		; Gate Toggle En
T5GSPM:		EQU  4		; Gate Single-Pulse En
T5GGO:		EQU  3		; Gate Single-Pulse Go
T5GVAL:		EQU  2		; Gate Status
T5GSS1:		EQU  1		; 00- Gate Pin	10- TMR2 match PR2
T5GSS0:		EQU  0		; 01- T1ovrflo	11- n/u

;---------------------	0x41E - T6CON Bits ---------------------------

;		EQU  7
T6OTPS3:	EQU  6		; Post-Scale	1111-16  1011-12  0111-8  0011-4
T6OTPS2:	EQU  5		;		1110-15  1010-11  0110-7  0010-3
T6OTPS1:	EQU  4		;		1101-14  1001-10  0101-6  0001-2
T6OTPS0:	EQU  3		;		1100-13  1000-9   0100-5  0000-1
TMR6EN:		EQU  2		; Enable
T6CKPS1:	EQU  1		;		11- /64 01- /4
T6CKPS0:	EQU  0		; Pre-Scale	10- /16 00- /1

;---------------------	0x41F - CCDCON Bits --------------------------

CCDEN:		EQU  7
CCDS1:		EQU  1
CCDS0:		EQU  0



;---------------------	0x49E - NCO1CON Bits -------------------------	Bank_09

N1PFM:		EQU  0
N1POL:		EQU  4
N1OUT:		EQU  5
N1EN:		EQU  7

;---------------------	0x49F - NCO1CLK Bits -------------------------

N1CKS0:		EQU  0
N1CKS1:		EQU  1
N1PWS0:		EQU  5
N1PWS1:		EQU  6
N1PWS2:		EQU  7



;---------------------	0x619 - PWM5CON Bits  ------------------------	Bank_12

PWM5POL:	EQU  4
PWM5OUT:	EQU  5
PWM5EN:		EQU  7

;---------------------	0x61C - PWM6CON Bits  ------------------------

PWM6POL:	EQU  4
PWM6OUT:	EQU  5
PWM6EN:		EQU  7

;---------------------	0x61F - PWMTMRS Bits -------------------------

P6TSEL1:	EQU  3
P6TSEL0:	EQU  2
P5TSEL1:	EQU  1
P5TSEL0:	EQU  0



;---------------------	0x691 - CWG1CLKCON Bits  ---------------------	Bank_13
;---------------------	0x711 - CWG2CLKCON Bits ----------------------	Bank_14

CWGCS:		EQU  0

;---------------------	0x692 - CWG1ISM Bits -------------------------
;---------------------	0x712 - CWG2ISM Bits -------------------------

CWGISM3:	EQU  3
CWGISM2:	EQU  2
CWGISM1:	EQU  1
CWGISM0:	EQU  0

;---------------------	0x695 - CWG1CON0 Bits  -----------------------
;---------------------	0x715 - CWG2CON0 Bits ------------------------

CWGMODE0:	EQU  0
CWGMODE1:	EQU  1
CWGMODE2:	EQU  2
CWGLD:		EQU  6
CWGEN:		EQU  7

;---------------------	0x696 - CWG1CON1 Bits  -----------------------
;---------------------	0x716 - CWG2CON1 Bits ------------------------

CWG1IN:		EQU  5
;		EQU  4
CWG1POLD:	EQU  3
CWG1POLC:	EQU  2
CWG1POLB:	EQU  1
CWG1POLA:	EQU  0

;---------------------	0x697 - CWG1AS0 Bits  ------------------------
;---------------------	0x717 - CWG2AS0 Bits -------------------------

CWGLSAC0:	EQU  2
CWGLSAC1:	EQU  3
CWGLSBD0:	EQU  4
CWGLSBD1:	EQU  5
CWGREN:		EQU  6
CWGSHUTDOWN:	EQU  7

;---------------------	0x698 - CWG1AS1 Bits  ------------------------	Bank_13
;---------------------	0x718 - CWG2AS1 Bits -------------------------	Bank_14

CWGAS4E:	EQU  4
CWGAS3E:	EQU  3
CWGAS2E:	EQU  2
CWGAS1E:	EQU  1
CWGAS0E:	EQU  0

;---------------------	0x699 - CWG1STR Bits  ------------------------
;---------------------	0x719 - CWG2STR Bits -------------------------

CWGOVRD:	EQU  7
CWGOVRC:	EQU  6
CWGOVRB:	EQU  5
CWGOVRA:	EQU  4
CWGSTRD:	EQU  3
CWGSTRC:	EQU  2
CWGSTRB:	EQU  1
CWGSTRA:	EQU  0



;---------------------	0x895 - NVMCON1 Bits  ------------------------	Bank_17

NVCFGS:		EQU  6		; 1- UserID, DevID, EEP 0- Flash
NVLWLO:		EQU  5		; 0- Only load Buffers	0- Write!
NVFREE:		EQU  4		; 1- Erase!		0- Write!
NVWRERR:	EQU  3		; 1- Error		0- Operation Sucessfull
NVWREN:		EQU  2		; 1-Enable Pgm/Erase	0- Disable Pgm/Erase
NVMWR:		EQU  1		; Write!
NVMRD:		EQU  0		; Read!

;---------------------	0x89B - PWRCON0 Bits  ------------------------

STKOVF:		EQU  7		;
STKUNF:		EQU  6		;
NRWDT:		EQU  4		;
NRMCLR:		EQU  3		;
NOTRI:		EQU  2		;
NOTPOR:		EQU  1		;
NOTBOR:		EQU  0		;



;---------------------	0x911 - PMD0 Bits ----------------------------	Bank_18

IOCMD:		EQU  0
CLKRMD:		EQU  1
NVMMD:		EQU  2
FVRMD:		EQU  6
SYSCMD:		EQU  7

;---------------------	0x912 - PMD1 Bits ----------------------------

TMR0MD:		EQU  0
TMR1MD:		EQU  1
TMR2MD:		EQU  2
TMR3MD:		EQU  3
TMR4MD:		EQU  4
TMR5MD:		EQU  5
TMR6MD:		EQU  6
NCOMD:		EQU  7

;---------------------	0x913 - PMD2 Bits ----------------------------

CMP1MD:		EQU  1
CMP2MD:		EQU  2
ADCMD:		EQU  5
DACMD:		EQU  6

;---------------------	0x914 - PMD3 Bits ----------------------------

CCP1MD:		EQU  0
CCP2MD:		EQU  1
CCP3MD:		EQU  2
CCP4MD:		EQU  3
PWM5MD:		EQU  4
PWM6MD:		EQU  5
CWG1MD:		EQU  6
CWG2MD:		EQU  7

;---------------------	0x915 - PMD4 Bits ----------------------------

MSSP1MD:	EQU  1
MSSP2MD:	EQU  2
UART1MD:	EQU  5

;---------------------	0x916 - PMD5 Bits ----------------------------	Bank_18

DSMMD:		EQU  0
CLC1MD:		EQU  1
CLC2MD:		EQU  2
CLC3MD:		EQU  3
CLC4MD:		EQU  4

;---------------------	0x918 - CPUDOZE Bits -------------------------

DOE:		EQU  4
ROI:		EQU  5
DOZEN:		EQU  6
IDLEN:		EQU  7

DOZE0:		EQU  0
DOZE1:		EQU  1
DOZE2:		EQU  2

;---------------------	0x919 - OSCCON1 Bits  ------------------------

IRCF3:		EQU  6		; 0000- 31.00KHz  0100-62.5KHz	1000- 125KHz 1010- 2MHz
IRCF2:		EQU  5		; 0001- 31.00KHz  0101- 125KHz	1001- 250KHz 1011- 4MHz
IRCF1:		EQU  4		; 0010- 31.25KHz  0110- 250KHz	1010- 500KHz 1110- 8MHz
IRCF0:		EQU  3		; 0011- 31.25KHz  1011- 500KHz	1011- 1MHz   1111-16MHz
;		EQU  2		;
SCS1:		EQU  1		;
SCS0:		EQU  0		; 00- Primary	01- Secondary	1x- Internal

;---------------------	0x91A - OSCCON2 Bits  ------------------------

NOSC2:		EQU  6		; 000- HFOSC (32 MHz)	100- LFINTOSC
NOSC1:		EQU  5		; 001- EXT x4		110- HFINTOSC (1 MHz)
NOSC0:		EQU  4		; 011- SOSC		111- EXTOSC
CDIV3:		EQU  3		; 0000- 1	0100- 16	1000- 256
CDIV2:		EQU  2		; 0001- 2	0101- 32	1001- 512
CDIV1:		EQU  1		; 0010- 4	0110- 64	101x- n/u
CDIV0:		EQU  0		; 0011- 8	0111- 128	11xx- n/u

;---------------------	0x91B - OSCCON3 Bits -------------------------	Bank_18

NOSCR:		EQU  3
ORDY:		EQU  4
SOSCBE:		EQU  5
SOSCPWR:	EQU  6
CSWHOLD:	EQU  7

;---------------------	0x91C - OSCSTAT1 Bits  -----------------------

PLLR:		EQU  0
ADOR:		EQU  2
SOR:		EQU  3
LFOR:		EQU  4
HFOR:		EQU  6
EXTOR:		EQU  7

;---------------------	0x91D - OSCEN Bits ---------------------------

ADOEN:		EQU  2
SOSCEN:		EQU  3
LFOEN:		EQU  4
HFOEN:		EQU  6
EXTOEN:		EQU  7



;---------------------	0xE0F - PPSLOCK Bits -------------------------	Bank_28

PPSLOCKED:	EQU  0

;---------------------	0xF0F - CLCDATA Bits -------------------------	Bank_30

MLC1OUT:	EQU  0
MLC2OUT:	EQU  1
MLC3OUT:	EQU  2
MLC4OUT:	EQU  3

;---------------------	0xF10 - CLC1CON Bits -------------------------
;---------------------	0xF1A - CLC2CON Bits -------------------------
;---------------------	0xF24 - CLC3CON Bits -------------------------
;---------------------	0xF2E - CLC4CON Bits -------------------------

LC1EN:		EQU  7		; Logic Cell enable
;				;
LC1OUT:		EQU  5		; Output state
LC1INTP:	EQU  4		; Pos edge Int Enable
LC1INTN:	EQU  3		; Neg edge Int Enable
LC1MODE2:	EQU  2		; 0- AndOr	3- S-R Latch	6- JK FF
LC1MODE1:	EQU  1		; 1- OrXor	4- D FF w/S+R	7- Latch
LC1MODE0:	EQU  0		; 2- Nand	5- 2in D FF w/R

;---------------------	0xF11 - CLC1POL Bits -------------------------
;---------------------	0xF1B - CLC2POL Bits -------------------------
;---------------------	0xF25 - CLC3POL Bits -------------------------
;---------------------	0xF2F - CLC4POL Bits -------------------------

LCG1POL:	EQU  0
LCG2POL:	EQU  1
LCG3POL:	EQU  2
LCG4POL:	EQU  3
LCCXPOL:	EQU  7

;---------------------	0xF12 - CLC1SEL0 Bits  -----------------------	Bank_30
;---------------------	0xF1C - CLC2SEL0 Bits  -----------------------
;---------------------	0xF26 - CLC3SEL0 Bits  -----------------------
;---------------------	0xF30 - CLC43EL0 Bits  -----------------------

LC1D1S0:	EQU  0		; 00000- CLCin0pps	10000- PWM5 out
LC1D1S1:	EQU  1		; 00001- CLCin1pps	10001- PWM6 out
LC1D1S2:	EQU  2		; 00010- CLCin2pps	10010- SCL1
LC1D1S3:	EQU  3		; 00011- CLCin3pps	10011- SDA1
LC1D1S4:	EQU  4

;---------------------	0xF13 - CLC1SEL1 Bits  -----------------------
;---------------------	0xF1D - CLC2SEL1 Bits  -----------------------
;---------------------	0xF27 - CLC3SEL1 Bits  -----------------------
;---------------------	0xF31 - CLC4SEL1 Bits  -----------------------

LC1D2S0:	EQU  0		; 00100- CLC1out	10100- n/u
LC1D2S1:	EQU  1		; 00101- CLC2out	10101- n/u
LC1D2S2:	EQU  2		; 00110- n/u		10110- UART TX
LC1D2S3:	EQU  3		; 00111- n/u		10111- UART DT
LC1D2S4:	EQU  4

;---------------------	0xF14 - CLC1SEL2 Bits  -----------------------
;---------------------	0xF1E - CLC2SEL2 Bits  -----------------------
;---------------------	0xF28 - CLC3SEL2 Bits  -----------------------
;---------------------	0xF32 - CLC4SEL2 Bits  -----------------------

LC1D3S0:	EQU  0		; 01000- C1 out		11000- Tmr0 ov
LC1D3S1:	EQU  1		; 01001- C2 out		11001- Tmr1 ov
LC1D3S2:	EQU  2		; 01010- DSM out	11010- Tmr2 match
LC1D3S3:	EQU  3		; 01011- CLKR out	11011- IOCIF
LC1D3S4:	EQU  4

;---------------------	0xF15 - CLC1SEL3 Bits  -----------------------	Bank_30
;---------------------	0xF1F - CLC2SEL3 Bits  -----------------------
;---------------------	0xF29 - CLC3SEL3 Bits  -----------------------
;---------------------	0xF33 - CLC4SEL3 Bits  -----------------------

LC1D4S0:	EQU  0		; 01100- CCP1 out	11100- ADCRC
LC1D4S1:	EQU  1		; 01101- CCP2 out	11101- LFintOSC
LC1D4S2:	EQU  2		; 01110- n/u		11110- HFintOsc
LC1D4S3:	EQU  3		; 01111- n/u		11111- Fosc
LC1D4S4:	EQU  4

;---------------------	0xF16 - CLC1GLS0 Bits ------------------------
;---------------------	0xF20 - CLC2GLS0 Bits ------------------------
;---------------------	0xF2A - CLC3GLS0 Bits ------------------------
;---------------------	0xF34 - CLC4GLS0 Bits ------------------------

G1D1N:		EQU  0
G1D1T:		EQU  1
G1D2N:		EQU  2
G1D2T:		EQU  3
G1D3N:		EQU  4
G1D3T:		EQU  5
G1D4N:		EQU  6
G1D4T:		EQU  7

;---------------------	0xF17 - CLC1GLS1 Bits ------------------------
;---------------------	0xF21 - CLC2GLS1 Bits ------------------------
;---------------------	0xF2B - CLC3GLS1 Bits ------------------------
;---------------------	0xF35 - CLC4GLS1 Bits ------------------------

G2D1N:		EQU  0
G2D1T:		EQU  1
G2D2N:		EQU  2
G2D2T:		EQU  3
G2D3N:		EQU  4
G2D3T:		EQU  5
G2D4N:		EQU  6
G2D4T:		EQU  7

;---------------------	0xF18 - CLC1GLS2 Bits ------------------------	Bank_30
;---------------------	0xF22 - CLC2GLS2 Bits ------------------------
;---------------------	0xF2C - CLC3GLS2 Bits ------------------------
;---------------------	0xF36 - CLC4GLS2 Bits ------------------------

G3D1N:		EQU  0
G3D1T:		EQU  1
G3D2N:		EQU  2
G3D2T:		EQU  3
G3D3N:		EQU  4
G3D3T:		EQU  5
G3D4N:		EQU  6
G3D4T:		EQU  7

;---------------------	0xF19 - CLC1GLS3 Bits ------------------------
;---------------------	0xF23 - CLC2GLS3 Bits ------------------------
;---------------------	0xF2D - CLC3GLS3 Bits ------------------------
;---------------------	0xF37 - CLC4GLS3 Bits ------------------------

G4D1N:		EQU  0
G4D1T:		EQU  1
G4D2N:		EQU  2
G4D2T:		EQU  3
G4D3N:		EQU  4
G4D3T:		EQU  5
G4D4N:		EQU  6
G4D4T:		EQU  7



;---------------------	0xFE4 - STATUS_SHAD Bits ---------------------	Bank_31

C_SHAD:		EQU  0
DC_SHAD:	EQU  1
Z_SHAD:		EQU  2

W:		EQU  0
F:		EQU  1
#DEFINE SETBSR	MOVLB	; Jerks don't allow Labels on BANKSEL or PAGESEL statements
#DEFINE SETPCH	MOVLP	; Try to compensate for Mis-typing



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	SUBTITLE "Reset & Interrupt Vectors"
	ORG	0
	LIST


	Page



;---------------------	Reset & Interrupt Vector  --------------------

RESET0:	CLRF	INTCON0		; Disable Interrupts
	SETBSR	(OSCTUNE>>7)	;				Bank-18
	SETPCH	(RESET0>>8)	;				Page 0
	GOTO	BOOT00


INT000:	SETPCH	(RESET0>>8)	; W,STAT,BSR -> Shadow_ Regs	Page 0
	SETBSR	(PIR1>>7)	;				Bank-00
	BTFSS	FLAG7, B7LOCK
	GOTO	INT100		; --> INT700

	CALL	SCREECH		; Set Critical Outputs
;	NOP			; Select this NOP when changing SCREEECH

INT700:	SETBSR	(PIR1>>7)	;				Bank-00
	GOTO	INT080


;---------------------	Descriptor Block  ----------------------------

	FILL	0x3FFF, 0x000D - $
DBLOCK:	DA	HIGH(MAIN00)*0x200+8	; Sizeof:	 Boot\128, EEP\32	0x9000-0x903F
	DA	0x1000+(HIGH(TOPROM)*2) ; Sizeof:	 RAM, ROM\128		0x0000-0x07FF
	DA	HIGH(FPGM00*2)		; Sizeof:	 extEEP, ProtectPage
SIGNON:	DT	"PAPR00_"		; Model  #
	DT	REV00			; Boot Revision
SERNUM:	DT	"00000000"		; Serial # yy day seq
	DT	0xFF			; serial # Checksum


INT080:	BTFSS	PIR1, RC1IF	; -----	UART1 Receive  ---------------
	GOTO	INT090

	SETBSR	(RC1REG>>7)	;				Bank-03
	BTFSS	RC1STA, OERR	; Overrun Error ?
	GOTO	INT086

	MOVF	RC1REG, W	; Flush FiFo (Packet has already been trashed)
	MOVF	RC1REG, W
	CLRF	RC1STA		; Clear Overrun Error
	MOVLW	URCSU1
	MOVWF	RC1STA		; Re-Enable UART Rx

INT084:	SETBSR	(BOOTBANK>>7)	;				Bank-12
	CLRF	BSTATE		; Serial Error - Reset Comm State
	GOTO	INT090

INT086:	MOVF	RC1STA, W	; Fetch UART Error Bits
	MOVWF	ITEMPD
	MOVF	RC1REG, W	; Fetch UART Data
	BTFSC	ITEMPD, FERR
	GOTO	INT084		; Framing Error

	MOVWF	ITEMPD		; Save Data
	BTFSC	FLAG7, B7XMIT
	GOTO	INT092		; Transmitting, Discard data.

	SETBSR	(BOOTBANK>>7)	;				Bank-12
	MOVLW	HIGH(RFIFO+0)
	MOVWF	FSR0H
	MOVLW	LOW( RFIFO+0)
	ADDWF	RFPUTP, W
	MOVWF	FSR0L
	MOVF	ITEMPD, W
	MOVWI	FSR0++		; Data -> RFIFO(RFPUTP)
	INCF	RFPUTP, F
	BCF	RFPUTP, RFWRAP	; Form Circular Buffer
	BTFSS	RF_LEN, RFWRAP
	INCF	RF_LEN, F	; Signal:Receive-Data-Available
	GOTO	INT098


	Page



;---------------------	Send Serial Data  ----------------------------

INT090:	BTFSS	FLAG7, B7XMIT	; UART1 Xmiting?	(Polling!)
	GOTO	INT098

INT092:	SETBSR	(PIR1>>7)	;				Bank-00
	BTFSS	PIR1, TX1IF	; Xmit Hardware Buffer Full ?
	GOTO	INT098

	SETBSR	(BOOTBANK>>7)	;				Bank-12
	MOVF	BP_LEN, F	; Packet Buffer Empty?
	SKPZ
	GOTO	INT096		; Yes.

	SETBSR	(ADCON0>>7)	;				Bank-01
	BCF	PIE1, TX1IE	; Disable TX
	BCF	FLAG7, B7XMIT	; Indicate:	Disabled
	GOTO	INT098

INT096:	MOVLW	HIGH(SBUFFER+0)
	MOVWF	FSR0H
	MOVLW	LOW( SBUFFER+0)
	ADDWF	BP_PTR, W
	INCF	BP_PTR, F	; Increment Buffer pointer
	DECF	BP_LEN, F
	MOVWF	FSR0L
	MOVIW	FSR0++		; W = (BP_PTR)++
	SETBSR	(RC1REG>>7)	;				Bank-03
	MOVWF	TX1REG		; Send to Host

INT098:	BTFSS	FLAG7, B7LOCK
	RETFIE			; Restore Shadow Registers
	RETLW	255


;-------------	Initialize I/O Pin Functions  ------------------------

BOOT00:	CLRF	OSCTUNE		; Use 32MHz calibrated value
	SETBSR	(PIR1>>7)
	MOVLW	PAINIT		; Initialize I/O		Bank-00
	MOVWF	PORTA
	MOVLW	PCINIT
	MOVWF	PORTC

	SETBSR	(ADCON0>>7)	;				Bank-01
	MOVLW	PAIOM
	MOVWF	TRISA
	MOVLW	PCIOM
	MOVWF	TRISC

	SETBSR	(PMD0>>7)	; Shutdown unused Peripherals	Bank-18
	MOVLW	PMD0SU
	MOVWF	PMD0
	MOVLW	PMD1SU
	MOVWF	PMD1
	MOVLW	PMD2SU
	MOVWF	PMD2
	MOVLW	PMD3SU
	MOVWF	PMD3
	MOVLW	PMD4SU
	MOVWF	PMD4
	MOVLW	PMD5SU
	MOVWF	PMD5

	SETBSR	(RC1REG>>7)	; Select Analog I/O		Bank-03
	MOVLW	ANSU_A
	MOVWF	ANSELA
	MOVLW	ANSU_C
	MOVWF	ANSELC

	MOVLW	BCTL1SU
	MOVWF	BAUD1CON
	MOVLW	LOW(UBAUD)	; Setup UART baudrate
	MOVWF	SP1BRGL
	MOVLW	HIGH(UBAUD)
	MOVWF	SP1BRGH
	MOVLW	URCSU1		; Enable UART Rx
	MOVWF	RC1STA
	MOVLW	UTXSU1		; Enable UART Tx
	MOVWF	TX1STA

	NOLIST
	SUBTITLE "Bootstrap Loader & RTOS"
	LIST


	Page



;---------------------	Clear RAM Memory  ----------------------------

BOOT10:	MOVLW	HIGH(TOPRAM)
	MOVWF	FSR0H
	MOVLW	LOW( TOPRAM)
	MOVWF	FSR0L
	MOVLW	0xFF
BOOT16:	MOVWI	FSR0--		; 0x020 - EORam = 0xFF
	BTFSC	FSR0H, 5
	GOTO	BOOT16		; Loop till x1FFF

BOOT20:	CLRF	FLAG7

	SETBSR	(PIR1>>7)	;				Bank-00
	MOVLW	TMR0S0		; Timer 0 = 4mS Delay Timer
	MOVWF	T0CON0
	MOVLW	TMR0S1
	MOVWF	T0CON1
	MOVLW	TMR0SP
	MOVWF	TMR0H

	SETBSR	(ADCON0>>7)	;				Bank-01
	MOVLW	WDT_SU		; WDT = 64mS
	MOVWF	WDTCON

	MOVLW	ADCSU0		; Ch-1 = Src Batt, A/D - On
	MOVWF	ADCON0
	MOVLW	ADCSU1		; Right-Just, 11uS Conversion
	MOVWF	ADCON1
	CLRF	ADACT		; No Auto-Trigger		**Punch

	MOVLW	HIGH(TOPROM)	; -----	Verify Flash Checksum  -------
	MOVWF	MTEMP+0
	SETBSR	(NVMADRL>>7)	;				Bank-17
	BCF	NVMCON1, NVCFGS ; Flash
	CLRF	NVMADRH
	CLRF	NVMADRL
	MOVLW	0
BOOT22:	BSF	NVMCON1, NVMRD	; Initiate read
	NOP
	NOP
	ADDWF	NVMDATH, W
	ADDWF	NVMDATL, W
	INCFSZ	NVMADRL, F
	GOTO	BOOT22

	CLRWDT			; Hit watchdog every 512uS
	INCF	NVMADRH, F
	DECFSZ	MTEMP+0, F	; End of memory ?
	GOTO	BOOT22

	MOVWF	ROMSUM		; Save Checksum
	ANDLW	255
	SKPZ
	BSF	FLAG7, B7CKSUM	; Checksum Error, only allow Bootstrap
	BTFSC	FLAG7, B7CKSUM
	BSF	FLAG7, B7LOCK	; Disable Mainline


	Page



;---------------------	Setup Peripherals  ---------------------------

BOOT24:	SETBSR	(SSP1BUF>>7)	;				Bank-04
	CLRF	WPUA		; No active Pullups
	CLRF	WPUA

	SETBSR	(BOOTBANK>>7)	; Init Bootstrap regs		Bank-12
	CLRF	RF_LEN
	CLRF	RFGETP
	CLRF	RFPUTP
;..	CLRF	BSTATE		; scmack
;..	CLRF	BP_LEN
;..	CLRF	BP_PTR
	MOVLW	0x51		; response to RESET command
	MOVWF	BPTYPE
	MOVLW	2		; Send 2 - xFF (clear serius pipes)
	CALL	SENDHD2
	MOVLW	1
	CALL	SENDPAK
	MOVF	ROMSUM, W
	CALL	SCMAC2		; Response: 1E FF 61 01 ss cc cc

	SETBSR	(PWM5CON>>7)	;				Bank-12
	CLRF	PWM5CON		; Disable PWMs for now
	CLRF	PWM6CON

	SETBSR	(PPSLOCK>>7)	; ***** Setup Inputs  *****	Bank-28
	MOVLW	0x55
	MOVWF	PPSLOCK
	MOVLW	0xAA		; Unlock PPS
	MOVWF	PPSLOCK
	BCF	PPSLOCK, PPSLOCKED
	MOVLW	RXPPSU		; UART Rx
	MOVWF	RXPPS

	SETBSR	(RA0PPS>>7)	;*****	Setup Outputs *****	Bank-29
	MOVLW	RA1SUO
	MOVWF	RA1PPS		; UART Tx

	SETBSR	(PUP>>7)	;				Bank-00
	MOVLW	0x55
	MOVWF	PUP+0		; 55	Setup Soft-Reset Flags
	MOVLW	0xAA
	MOVWF	PUP+1		; AA
	MOVLW	0x5A
	MOVWF	PUP+2		; 5A
	MOVLW	0xA5
	MOVWF	PUP+3		; A5

	NOP			; Patching area
	NOP
	NOP
	NOP
	BTFSS	FLAG7, B7LOCK
	CALL	INIT00		; Perform MainLine I/O Init if Cksum OK

;---------------------	Bootstrap LOOP	------------------------------	Bank 12

BOOT70:	BTFSC	FLAG7, B7LOCK
	CALL	INT000		; Poll UART Interrupts
	SETBSR	(BOOTBANK>>7)	;				Bank-12
	MOVF	RF_LEN, F	; Serial Data available?
	SKPZ
	CALL	BOOT80		; Yes, process

	CLRWDT
	BTFSS	FLAG7, B7LOCK
	GOTO	MAIN00		; Process Mainline

ENDMAIN:SETPCH	(BOOT70>>8)	;				Page 0
	SETBSR	(PUP>>7)	;				Bank-00
	MOVLW	0x55		;	Software RESET logic
	XORWF	PUP+0, W	; 55
	MOVLW	0xAA
	SKPNZ
	XORWF	PUP+1, W	; AA	Test Power-Valid values
	MOVLW	0x5A
	SKPNZ
	XORWF	PUP+2, W	; 5A
	MOVLW	0xA5
	SKPNZ
	XORWF	PUP+3, W	; A5
	SKPNZ
	GOTO	BOOT70		; Loop

SCM510:	RESET			;  Serial Command 51 - Reset_Processor

	NOLIST
	SUBTITLE "Peripheral Drivers"
	LIST


	Page



;-------------	Fetch data from Boot Buffer  -------------------------	Bank 12

GETPAK:	MOVLW	HIGH(SBUFFER+0)
	MOVWF	FSR1H
	MOVLW	LOW( SBUFFER+0)
	ADDWF	BP_PTR, W	; Fetch Bootstrap Buffer address
	MOVWF	FSR1L
GETPNX:	INCF	BP_PTR, F	; Increment Buffer pointer
	MOVIW	FSR1++		; Fetch data
	RETURN


ENABLE_INTS:
	BTFSS	FLAG7, B7LOCK	; Mainline Disabled?
	BSF	INTCON0, GIE	; Enable Interrupts
	RETURN


GETFIFO:MOVLW	HIGH(RFIFO+0)	; -----	Fetch Data from FiFo  --------
	MOVWF	FSR0H
	MOVLW	LOW( RFIFO+0)	; *******************************
	ADDWF	RFGETP, W	; *	Make sure BootBank	*
	MOVWF	FSR0L		; *******************************
	INCF	RFGETP, F
	BCF	RFGETP, RFWRAP	; Form Circular Buffer
	DECF	RF_LEN, F
	MOVIW	FSR0++
	MOVWF	MTEMP+1		; Cache Serial Data
	RETURN


;---------------------	Fetch data from ROM  -------------------------	Bank 17
;
; NOTE:	 Must restore BANK....

GETROM:	SETBSR	(NVMADRL>>7)	;				Bank-17
	BCF	NVMCON1, NVCFGS ; Flash
	BSF	NVMCON1, NVMRD	; Initiate read
	NOP
	NOP
	INCF	NVMADRL, F
	SKPNZ
	INCF	NVMADRH, F	; Bump Flash Address
	MOVF	NVMDATL, W
	MOVWF	MTEMP+7
	MOVF	NVMDATH, W
	RETURN


;---------------------	Fetch data from EEProm	----------------------	Bank 17
;
; NOTE:	 Must restore BANK....

EEREAD:	SETBSR	(NVMADRL>>7)	;				Bank-17
	BTFSC	NVMCON1, NVMWR	; Wait if WRITE in progress
	GOTO	EEREAD

	BSF	NVMCON1, NVCFGS ; Select EEPROM
	BSF	NVMCON1, NVMRD	; Initiate read
	ADDLW	255
	ADDLW	255
	INCF	NVMADRL, F	; Bump Flash Address
	SKPNZ
	INCF	NVMADRH, F
	MOVF	NVMDATL, W	; Fetch EEProm Data
	RETURN


;---------------------	EEADDR - setup EEPROM Address  ---------------
;
; NOTE:	 Must restore BANK....

EEADDR:	SETBSR	(NVMADRL>>7)	;				Bank-17
	BTFSC	NVMCON1, NVMWR	; Wait if WRITE in progress
	GOTO	EEADDR

	MOVWF	NVMADRL

EEADRH:	SETBSR	(NVMADRL>>7)	;				Bank-17
	MOVLW	0xF0
	MOVWF	NVMADRH		; 1st 256 Bytes
	RETLW	255


	Page



;---------------------	EEWRITE - Write to EEPROM  -------------------	Bank-17
;
; NOTE:	 Must restore BANK....

EEPUT0:	CALL	EEADDR		; Save EEProm Address		Bank-17

SAVENXT:MOVIW	FSR1++		; Fetch Data

EEWRITE:SETBSR	(NVMADRL>>7)	;				Bank-17
	BTFSC	NVMCON1, NVMWR	; Wait for previous WRITE to complete
	GOTO	EEWRITE

	MOVWF	NVMDATL		; Put data in Write register
	BSF	NVMCON1, NVCFGS ; Select EEPROM

	BCF	INTCON0, GIE	; Disable All Interrupts
	BSF	NVMCON1, NVWREN ; Enable Writes
	MOVLW	0x55
	MOVWF	NVMCON2
	MOVLW	0xAA
	MOVWF	NVMCON2
	BSF	NVMCON1, NVMWR	; Start WRITE Cycle
	ADDLW	255
	BCF	NVMCON1, NVWREN ; Disable further Writes
	GOTO	ENABLE_INTS


;-------------	Send Bootstrap Response Header	----------------------

SENDHDR:MOVLW	0
SENDHD2:MOVWF	BP_PTR		; Setup Buffer Pointer
	MOVWF	BP_LEN
	CALL	INITCRC
	MOVLW	0x1E
	CALL	SENDPAK		; Unit-Separator	W = DEVNUM
;..	MOVLW	DEVNUM
	CALL	SENDPAK		; Device#
	MOVF	BPTYPE, W
	ADDLW	0x10		; Compute Response TYPE


;-------------	Compute CRC and send via Serial  ---------------------
;
;	NOTE:	 Fsr1 is used during Packet assembly!!!

SENDPAK:MOVWF	MTEMP+1		; Save Byte
	CALL	CALC_CRC	; Keep track of Packet CRC and W = (MTEMP+1)


;-------------	Save data in Boot Buffer  ----------------------------

SENDPB:	MOVWF	MTEMP+1
	INCF	BP_LEN, F	; Keep track of string length

PUTPAK:	MOVLW	HIGH(SBUFFER+0)
	MOVWF	FSR1H
	MOVLW	LOW( SBUFFER+0)
	ADDWF	BP_PTR, W	; Fetch Bootstrap Buffer address
	MOVWF	FSR1L
	MOVF	MTEMP+1, W
PUTPNX:	MOVWI	FSR1++		; Store data in Buffer
	INCF	BP_PTR, F	; Increment Buffer pointer
	RETLW	DEVNUM

	NOLIST
	SUBTITLE "JRHID Decode"
	LIST


	Page



;-----	Packet Header:	1E Ad Ty Ln Dt C1 C2	----------------------	Bank 12
;		State:	0  1  2  3  4  5  6  7

BOOT80:	CALL	GETFIFO		; Serial data -> MTEMP+1
	SETPCH	(TABLEB>>8)	;				Page 1
	NOP
	MOVF	BSTATE, W	; Transfer-Layer Packet State Machine
	INCF	BSTATE, F
	ANDLW	7
TABLEB:	ADDWF	PCL, F
	GOTO	RSTS00		; 0 - Unit-Separator
	GOTO	RSTS10		; 1 - Device Address
	GOTO	RSTS20		; 2 - Type x50-x53
	GOTO	RSTS30		; 3 - Data Len
	GOTO	RSTS40		; 4 - Data
	GOTO	CALC_CRC	; 5 - CRC.Lo
	GOTO	RSTS60		; 6 - CRC.Hi
	NOP			; 7 - n/u

	NOLIST
	IF HIGH($) > (HIGH(TABLEB) & 0x7F)
	MESSG "Boot Table Error - TABLEB"
	LIST OH CRAP
	ENDIF
	SUBTITLE "Serial Decode State machine"
	LIST


RSERR:				; Comm Error

RSTS00:	MOVLW	1		; ------  0 - Record-Seperator  -------
	MOVWF	BSTATE
	MOVLW	0x1E		; Unit Separator?
	XORWF	MTEMP+1, W
	SKPZ
	GOTO	RSTS28		; No, process Pass-Thru

	NOP
	NOP
RSTS08:	RETLW	255


RSTS10:	MOVLW	0x48		; -------------	1 - Device#  ---------
	MOVWF	CRC16+0
	MOVLW	0x3F		; CRC = 0xFFFF + CRC(0x1E)
	MOVWF	CRC16+1
	CALL	CALC_CRC	; Keep track of Packet CRC

	NOP
	XORLW	DEVNUM
	GOTO	RSTS24


	Page



RSTS20:	CALL	CALC_CRC	; --------------  2 - Type  -----------	Bank 12
	MOVWF	BPTYPE		; Save TYPE
	XORLW	0x50
	ANDLW	0xFC		; Check if in range of 0x50 - 0x53
RSTS24:	SKPNZ
	GOTO	RSTS08


RSTS26:	DECF	BSTATE, W	; --- Pass-Thru --- rewind RFIFO
	ADDWF	RF_LEN, F
	SUBWF	RFGETP, W
	ANDLW	(1<<RFWRAP)-1	; maintain circular buffer
	MOVWF	RFGETP
PASS1E:	MOVLW	0x1E
	MOVWF	MTEMP+1		; 1st character always Unit Seperator..

RSTS28:	BTFSS	FLAG7, B7LOCK	; Handle alternate Packets
	GOTO	MDEC00
	GOTO	RSTEND



RSTS30:	CALL	CALC_CRC	; --------------  3 - Data Len  -------
	MOVWF	BP_LEN
	SKPNZ
	INCF	BSTATE, F	; Len = 0, Handle NO data
	ADDLW	262-SB_LEN
	SKPNC
	GOTO	RSTS26		; Error - packet too long

BDINIT:	MOVLW	4
	MOVWF	BP_PTR		; Setup to save Packet data
	RETLW	255


;				;--------------  4 - Data  -----------
;
RSTS40:	CALL	CALC_CRC	; Keep track of Packet CRC and fetch Serial Data
	CALL	PUTPAK		; Save to Serial Buffer
	DECFSZ	BP_LEN, F
	DECF	BSTATE, F	; Stay at this state
	RETLW	255


;---------------------	Process Bootstrap Commands  ------------------

				;--------------  5 - CRC.Lo  ---------
RSTS60:	CALL	CALC_CRC
	MOVF	CRC16+0, W	; --------------  6 - CRC.Hi  ---------
	IORWF	CRC16+1, W
	SKPZ
	GOTO	RSERR		; Bad CRC

	CALL	BDINIT		; BP_PTR = SBUFFER+4

	CALL	GETPAK		; Fetch Length
	MOVWF	MTEMP+2
	CALL	GETPNX		; Fetch Addr.0
	MOVWF	ADDRB+0
	MOVWF	MTEMP+0
	ANDLW	15
	MOVWF	FSR0H
	CALL	GETPNX		; Fetch Addr.1
	MOVWF	ADDRB+1
	MOVWF	MTEMP+1
	MOVWF	FSR0L		; For RAM   R/W
	SETBSR	(NVMADRL>>7)	;				Bank-17
	MOVWF	NVMADRL		; For Flash R/W
	CLRC
	RRF	MTEMP+0, W
	MOVWF	NVMADRH		; Word Addressing
	RRF	NVMADRL, F
	SETBSR	(BOOTBANK>>7)	;				Bank-12

	SETPCH	(RSTS60>>8)	;				Page 1
	NOP
	MOVF	BPTYPE, W	; Fixed Transport-Layer Commands
	ANDLW	3
	ADDWF	PCL, F
	GOTO	SCM500		; 50 - Read  Descriptor Block
	GOTO	SCM510		; 51 - Reset Processor
	GOTO	SCM520		; 52 - Read  Flash/EEPROM/Ram
	GOTO	SCM530		; 53 - Write Flash/EEPROM/Ram

	NOLIST
	IF $ > 0x0200
	MESSG "Boot Table Error - 0x0200"
	LIST OH CRAP
	ENDIF
	LIST


	Page



;-------------	Type 0x50 - Read Descriptor Block  -------------------	Bank 12

SCM500:	MOVLW	44		; Descriptor Block = 44 Bytes
	MOVWF	MTEMP+2
	MOVLW	HIGH(DBLOCK)
	MOVWF	ADDRB+0		; Address for Response
	MOVLW	LOW( DBLOCK)
	MOVWF	ADDRB+1
	SETBSR	(NVMADRL>>7)	;				Bank-17
	MOVLW	HIGH(DBLOCK)
	MOVWF	NVMADRH		; Point to Descriptor Block
	MOVLW	LOW( DBLOCK)
	MOVWF	NVMADRL
	SETBSR	(BOOTBANK>>7)	;				Bank-12


;---------------------	Read from Chip	------------------------------

SCM520:	CALL	SENDHDR		; Init CRC & send Header
	MOVF	MTEMP+2, W
	ADDLW	2
	CALL	SENDPAK		; #Data Bytes + 2 Address Bytes
	MOVF	ADDRB+0, W
	CALL	SENDPAK		; Addr.0
	MOVF	ADDRB+1, W
	CALL	SENDPAK		; Addr.1
	BTFSS	ADDRB+0, 7
	GOTO	SCM526		; 0x0000 - 0x7FFF	Read Flash

	BTFSS	ADDRB+0, 4	; 0x9000 - 0x90FF	Read EEprom
	GOTO	SCM524		; 0x8000 - 0x8FFF	Read RAM


;---------------------	Read from EEProm  ----------------------------

	CALL	EEADRH		; Addr.H = xF0			Bank-17

SCM522:	CALL	EEREAD		;				Bank-17
	SETBSR	(BOOTBANK>>7)	;				Bank-12
	CALL	SENDPAK
	DECFSZ	MTEMP+2, F
	GOTO	SCM522

	GOTO	SCMFF8		; Finish Packet & xmit


;---------------------	Read from RAM  -------------------------------

SCM524:	MOVIW	FSR0++		; Index = (Packet RAM Address)++
	CALL	SENDPAK
	DECFSZ	MTEMP+2, F
	GOTO	SCM524

	GOTO	SCMFF8		; Finish Packet & xmit


;---------------------	Read from Flash  -----------------------------

SCM526:	CLRC
	RRF	MTEMP+2, F	; Compute #words
SCM528:	CALL	GETROM		;				Bank-17
	SETBSR	(BOOTBANK>>7)	;				Bank-12
	CALL	SENDPAK		; Send MSByte
	MOVF	MTEMP+7, W
	CALL	SENDPAK		; Send LSByte
	DECFSZ	MTEMP+2, F
	GOTO	SCM528
	GOTO	SCMFF8		; Finish Packet & xmit


	Page



;---------------------	Check Write-Address  -------------------------	Bank 12
;
; MTEMP+2 - Length

SCM530:	BTFSS	ADDRB+0, 7	; ROM ?
	GOTO	FPGM00		; Yes..

	BTFSS	ADDRB+0, 4	; 0x9000 - 0x90FF	Write EEprom
	GOTO	SCM534		; 0x8000 - 0x8FFF	Write RAM


;---------------------	Write to EEPROM  -----------------------------

	CALL	EEADRH		; Addr.H = xF0			Bank-17

SCM532:	SETBSR	(BOOTBANK>>7)	;				Bank-12
	CALL	GETPAK
	CALL	EEWRITE		; Write to internal EEPROM	Bank-17
	CALL	EEREAD		; Wait for write to finish & inc. Addr
	CLRWDT
	SETBSR	(BOOTBANK>>7)	;				Bank-12
	CALL	GETPAK		; Skip crap
	DECF	MTEMP+2, F	; Handle WORD counting
	DECFSZ	MTEMP+2, F
	GOTO	SCM532		; Loop for All locations
	GOTO	SCMACK		; Send Ack


;---------------------	Write to RAM  --------------------------------

SCM534:	CALL	GETPAK		; Fetch a Word of Data
	MOVWI	FSR0++
	DECFSZ	MTEMP+2, F
	GOTO	SCM534		; Loop for All locations

	MOVLW	255		; Indicate:	Serial Activity....
	MOVWF	DELAYZ
	GOTO	SCMACK		; Send Ack

	NOLIST
	IF $ < 0x0200
	FILL	0x3FFF, 0x0200 - $
	ENDIF
	LIST


	Page



;---------------------	Write to Flash	------------------------------	Bank 17
;
; Mtemp+0 = Sub-Page	Mtemp+1 = Addr(Data)	Mtemp+2 = Length(Bytes)

FPGM00:	MOVLW	HIGH(FPGM00*2)	; Protect WRITE routine  (0200 - 027F)
	XORWF	ADDRB+0, W
	SKPNZ
	GOTO	RSTEND		; Ignore Write....

	CLRF	INTCON0		; Disable All Interrupts
	BSF	FLAG7, B7LOCK	; Disable Mainline

ROMWRT:	SETBSR	(NVMADRL>>7)	;				Bank-17
	MOVLW	11100000B
	ANDWF	NVMADRL, W
	MOVWF	NVMADRL		; Set NVMADR = Start of 32 Word ErasePage
	MOVWF	MTEMP+0		; Save Address
	CLRF	PGMTRY
	MOVLW	32
	MOVWF	MTEMP+3
	MOVLW	HIGH(PGMBUF+0)
	MOVWF	FSR0H
	MOVLW	LOW( PGMBUF+0)	; Point to Start-of-PgmBuffer
	MOVWF	FSR0L
	BCF	NVMCON1, NVCFGS ; Flash
FPGM04:	BSF	NVMCON1, NVMRD	; Initiate read
	NOP
	NOP
	MOVF	NVMDATL, W	; Save Old Data to PgmBuf
	MOVWI	FSR0++
	MOVF	NVMDATH, W	; "Little Endean"
	MOVWI	FSR0++
	INCF	NVMADRL, F
	DECFSZ	MTEMP+3, F	; 32 Words ?
	GOTO	FPGM04

	MOVF	MTEMP+1, W	; Point to location in buffer that will
	ANDLW	63		; be modified
	ADDLW	LOW(PGMBUF+0)
	MOVWF	FSR0L
FPGM06:	MOVIW	FSR1++
	MOVWI	FSR0++		; Move NEW data -> Pgm_Buffer
	DECFSZ	MTEMP+2, F
	GOTO	FPGM06

;---------------------	Erase Flash  ---------------------------------

FPGM10:	MOVF	MTEMP+0, W	; Set NVMADR = Start of 64Byte ErasePage
	MOVWF	NVMADRL
	BCF	NVMCON1, NVCFGS ; Not CFG area
	BSF	NVMCON1, NVFREE ; Enable Page-Erase
	BSF	NVMCON1, NVWREN ; Enable Flash-Write
	MOVLW	0x55
	MOVWF	NVMCON2
	MOVLW	0xAA
	MOVWF	NVMCON2
	BSF	NVMCON1, NVMWR	; Perform Erase of 32 Words
	NOP
	NOP

;---------------------	Program 32 Words  ----------------------------

	MOVLW	LOW(PGMBUF+0)	; Point to Start-of-PgmBuffer
	MOVWF	FSR0L
	BSF	NVMCON1, NVWREN ; Enable Flash-Write
	BSF	NVMCON1, NVLWLO ; Load ONLY
	BSF	MTEMP+2, 5	; (32)

FPGM12:	MOVIW	FSR0++		; Move 32 Words from PgmBuffer -> Holding Reg's
	MOVWF	NVMDATL
	MOVIW	FSR0++
	MOVWF	NVMDATH
	DECF	MTEMP+2, W
	SKPNZ
	BCF	NVMCON1, NVLWLO ; Activate Write if last Location
	MOVLW	0x55
	MOVWF	NVMCON2
	MOVLW	0xAA
	MOVWF	NVMCON2
	BSF	NVMCON1, NVMWR	; Move Data to Write Latch
	NOP
	NOP
	INCF	NVMADRL, F
	DECFSZ	MTEMP+2, F	; Loop for 32 Words
	GOTO	FPGM12


	Page



;---------------------	Verify 32 Words  -----------------------------	Bank 17

FPGM14:	BCF	NVMCON1, NVWREN ; Disable further Writes
	CLRWDT

	INCF	PGMTRY, F
	BTFSC	PGMTRY, 2	; Only allow 4 Try's!
	GOTO	RSTEND

	MOVLW	LOW(PGMBUF+0)	; Point to Start-of-PgmBuffer
	MOVWF	FSR0L
	MOVF	MTEMP+0, W	; Set NVMADR = Start of 32 Word ErasePage
	MOVWF	NVMADRL
	MOVLW	32
	MOVWF	MTEMP+3
FPGM16:	BCF	NVMCON1, NVCFGS ; Flash
	BSF	NVMCON1, NVMRD	; Initiate read
	NOP
	NOP
	INCF	NVMADRL, F
	MOVIW	FSR0++
	XORWF	NVMDATL, W
	SKPZ
	GOTO	FPGM10		; Verify Error, Re-Program

	MOVIW	FSR0++
	XORWF	NVMDATH, W
	SKPZ
	GOTO	FPGM10		; Verify Error, Re-Program

	DECFSZ	MTEMP+3, F	; Loop for 64 Bytes
	GOTO	FPGM16

	NOP			; Allow room for a Debug statement..
	SETBSR	(BOOTBANK>>7)	;				Bank-12



;---------------------	Send Acknowledge  ----------------------------	Bank 12

SCMACK:	CALL	SENDHDR		; <1E FF 63 00 cc cc>
	MOVLW	0		; Len = 0
SCMAC2:	CALL	SENDPAK

SCMFF8:	CALL	SENDCRC		; Finish Response Packet & Xmit

RSTEND:	SETBSR	(BOOTBANK>>7)	;				Bank-12
	CLRF	BSTATE		; Stop Packet State machine
	RETLW	255


;---------------------	Add Byte to CRC  -----------------------------

CALC_CRC:
	MOVF	MTEMP+1, W	; Fetch Serial Data

CALC_0:	XORWF	CRC16+1, F	; Xor Data with CRC.Lo
	MOVLW	8
	MOVWF	MTEMP+0
CALC_2:	CLRC
	RRF	CRC16+0, F	; 16bit Shift-Right
	RRF	CRC16+1, F
	SKPC
	GOTO	CALC_4		; Cy = 0

	MOVLW	0xA0
	XORWF	CRC16+0, F	; 16+14+1 polynominal
	MOVLW	0x01
	XORWF	CRC16+1, F	; 1010 0000 0000 0001
CALC_4:	DECFSZ	MTEMP+0, F
	GOTO	CALC_2		; Loop for 8 Bits	Max = 102inst = 8*12+6

	MOVF	MTEMP+1, W	; Restore W
	RETURN


	Page



;-------------	Complete Packet transmission  ------------------------	Bank 12

SENDCRC:MOVF	CRC16+1, W
	CALL	SENDPB		; Send & Reset CRC
	MOVF	CRC16+0, W
	CALL	SENDPB
SENDTST:CLRF	BP_PTR		; BP_PTR = SBUFFER+0
	BSF	FLAG7, B7XMIT	; Enable Bootstrap Xmit Logic
	SETBSR	(ADCON0>>7)	;				Bank-01
	BSF	PIE1, TX1IE	; Enable TX Interrupt
	SETBSR	(BOOTBANK>>7)	;				Bank-12

INITCRC:MOVLW	0xFF
	MOVWF	CRC16+0
	MOVWF	CRC16+1		; Reset CRC to 0xFFFF
	RETLW	255

	NOLIST
;*********************************************************
;**							**
;**	When changing SCREEECH, NOP out the Call in the **
;**	Interrupt routine, program, then replace Call.	**
;**							**
;*********************************************************
	LIST


;-----	Ensure proper I/O when Mainline Disabled  --------------------

SCREECH:SETBSR	(ADCON0>>7)	;				Bank-01
	MOVLW	PAIOM
	MOVWF	TRISA		; UART Rx as Input
	SETBSR	(LATA>>7)	;				Bank-02
	MOVLW	(1<<BCTEST1)	; Toggle Pin-5
	XORWF	LATC, F
	BCF	LATA, BA_CS	; Ext EEP - Off
	SETBSR	(RA0PPS>>7)	;				Bank-29
	MOVLW	RA1SUO
	MOVWF	RA1PPS		; UART Tx
	CLRF	RC5PPS		; Enable BCTEST1
	NOP
	NOP
	RETLW	255


	NOLIST			; Handle Page overlap..
	IF $ > 0x0300
	MESSG "Page Overlap - x0300"
	LIST OH CRAP
	ENDIF
	FILL	0x3FFF, 0x0300 - $

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MAIN00:		EQU  0x0302	; Mainline Loop		GoTo ENDMAIN	Bank 0
MDEC00:		EQU  0x0303	; Decode Host Packets	GoTo RSTEND	Bank 0
INIT00:		EQU  0x0304	; Initialize		"Return"	Bank 0
INT100:		EQU  0x0305	; Interrupts		GoTo INT700	Bank 0

	LIST

;---------------------	Mainline Entry Vectors	----------------------

	DB	REV01, REV02	; Mainline Revision
	DB	REV03, MLCKSUM	; Mainline Checksum
MAIN00:	GOTO	MAIN02		; Mainline Code				Bank 0
MDEC00:	GOTO	RSTEND		;					Bank 0
INIT00:	GOTO	INIT02		;					Bank 0
INT100:	GOTO	INT700		;					Bank 0

	NOLIST
	SUBTITLE "Mainline Initialization"
	LIST


	Page



;---------------------	Mainline Initialization  ---------------------

INIT02:	SETBSR	(ADCON0>>7)	;				Bank-01
	CLRF	PIE0		;		**Punch
	MOVLW	PIE1SU		; Setup Interrupts
	MOVWF	PIE1		;	!!enable TX for RST response!!
	BTFSS	FLAG7, B7XMIT
	BCF	PIE1, TX1IE	;	!!no response after SLEEP
	MOVLW	PIE2SU
	MOVWF	PIE2
	CLRF	PIE3		;		**Punch
	CLRF	PIE4		;		**Punch
	CLRF	ADCNT		; Setup A/D table pointer
	MOVLW	8		; Set Initial Battery Voltage High
	MOVWF	AD_BATT+0	;  too prevent Low-Batt issues
	BCF	FLAG7, B7ERRF

	SETBSR	(LATA>>7)	; Setup Amps Comparator		Bank-02
	MOVLW	VREFSU
	MOVWF	FVRCON		; Reference = 1.024	0x117
	MOVLW	DAC0SU
	MOVWF	DACCON0		; Divide Fref		0x118
	MOVLW	DAC1SU
	MOVWF	DACCON1		; Cmp+ @ 0.032v		0x119
	MOVLW	CM1SU0
	MOVWF	CM1CON0		; Cmp- = Amps		0x111
	MOVLW	CM1SU1
	MOVWF	CM1CON1		;			0x112

	SETBSR	(PWM5CON>>7)	; Setup Out Volts PWM		Bank-12
	CLRF	PWM5DCL		;			0x617
	CLRF	PWM5DCH		;			0x618
	MOVLW	PWM5SU
	MOVWF	PWM5CON		;			0x619
	CLRF	PWM6DCL		;			0x61A
	CLRF	PWM6DCH		;			0x61B
	MOVLW	PWM6SU
	MOVWF	PWM6CON		;			0x61C
	MOVLW	PWMTSU
	MOVWF	PWMTMRS		;			0x61F

;	SETBSR	(PPSLOCK>>7)	; Setup Inputs			Bank-28

	SETBSR	(RA0PPS>>7)	; Setup Outputs			Bank-29
	MOVLW	RC1SUO
	MOVWF	RC1PPS		; RC1 = PWM5
	MOVLW	RC4SUO
	MOVWF	RC4PPS		; RC4 = Cmp1	Fan Speed Capture
	MOVLW	RC5SUO
	MOVWF	RC5PPS		; RC5 = LatC

	SETBSR	(PIR1>>7)	;				Bank-00
	MOVLW	T1GSU
	MOVWF	T1GCON		; Toggle Gate w/Cmp1	0x01C
	MOVLW	TMR1SU
	MOVWF	T1CON		; RPM Period Capture	0x01B
	MOVLW	TMR2SP
	MOVWF	PR2		; 10 Bit PWM5/PWM6	0x01E
	MOVLW	TMR2SU
	MOVWF	T2CON		; 32KHz PWM5/PWM6	0x01F

	CLRF	FLAG1
	CLRF	RPMCNT
	CLRF	FSPEED+0
	CLRF	FSPEED+1
	MOVLW	16+7		; Delay Sleep for 1.75 Sec
	MOVWF	DELAYZ
	MOVLW	TIME10MS	; 10mS Timing
	MOVWF	DELAY1
	MOVLW	TIME250MS	; 250mS Timing
	MOVWF	DELAY2
	MOVWF	DELAYB
	MOVLW	TIME_ERR
	MOVWF	DELAYE		; Error Toggle Timing
	MOVLW	TIME_KILL
	MOVWF	DELAYK		; Setup Disconnect Shutdown

	MOVLW	INT1SU
	MOVWF	INTCON0
	BSF	INTCON0, GIE	; Enable Interrupts
	RETLW	255

	NOLIST

;@@@		SETBSR	(PPSLOCK>>7)	; Lock PPS registers		Bank-28
;@@@		MOVLW	0x55
;@@@		MOVWF	PPSLOCK
;@@@		MOVLW	0xAA
;@@@		MOVWF	PPSLOCK
;@@@		BSF	PPSLOCK, PPSLOCKED

	IF $ > 0x0380
	MESSG "Page Overlap - x0380"
	LIST OH CRAP
	ENDIF
	FILL	0x3FFF, 0x0380 - $
	SUBTITLE "Mainline Loop"
	LIST


	Page



;-----------------------------	Mainline  ----------------------------	Bank 0
;
; This entry from the OS is executed as fast as possible.  The OS
; only delays execution to service Serial Debug requests, i.e. R/W of
; Ram, Flash, EEProm.  Since not all Mainline code has to be executed
; this quickly, the Mainline is broken into 3 sections that execute at
; 500uS, 10mS and 250mS. The Mainline code should never take more than
; a total of 500uS (4000 instructions) to prevent the delay of 500uS
; code.
;

MAIN02:	SETBSR	(PIR1>>7)	; ----------------------------	Bank-00
	BTFSC	FLAG1, B1RPMT	;
	CALL	RPM_CALC	; Calculate RPM everY 250mS

;---------------------------------------------------------------
;								|
	BTFSS	PIR1, TMR2IF	; 500uS ?			|
	GOTO	MAIN90		;				|
;				;				|
	BCF	PIR1, TMR2IF	; Reset 2KHz flag		|
;								|
;---------------------	500uS Code  ----------------------------

	CALL	PUSH00		; DeBounce Switch Input		Bank-00
	SKPNC			; One-Shot?
	CALL	NEXT_SPEED	; Yes, Step through Speeds	Bank-02


;---------------------------------------------------------------
				;				|
MAIN30:	SETBSR	(PIR1>>7)	;				|
	DECFSZ	DELAY1, F	; 10mS ?			|
	GOTO	MAIN90		;				|
				;				|
	MOVLW	TIME10MS	; Reset 10mS Timer		|
	MOVWF	DELAY1		;				|
;								|
;---------------------	10mS Code  -----------------------------

	BTFSS	FLAG7, B7EPDONE
	GOTO	EXTEEP


	CALL	AD_FILTER	; Remove A/D Jitter		Bank-00


	Page



;---------------------------------------------------------------
				;				|
MAIN60:	DECFSZ	DELAY2, F	; 250mS				|
	GOTO	MAIN90		;				|
				;				|
	MOVLW	TIME250MS	; Reset 250mS Timer		|
	MOVWF	DELAY2		;				|
;								|
;---------------------	250mS Code  ----------------------------

;..	SETBSR	(PIR1>>7)	;				Bank-00
	BSF	FLAG1, B1RPMT	; Perform RPM Divide on next pass

	BTFSC	FLAG7, B7ERRF	; Error Condition?
	DECFSZ	DELAYE, F
	GOTO	MAIN62

	MOVLW	TIME_ERR	; Yes, Toogle Fan Speed
	MOVWF	DELAYE
	MOVLW	1<<B1ERRT
	XORWF	FLAG1, F
	ANDWF	FLAG1, W

	MOVLW	0x2A		;  7.00v						**Patch
	SKPZ
	MOVLW	0xF0		; 11.50v
	MOVWF	FSPEED+0

MAIN62:	DECFSZ	DELAYK, F	; Fan Disconnect?
	GOTO	MAIN64

	INCF	DELAYK, F
	BCF	SWPOWER		; Shutdown
	CLRF	FSPEED+0

MAIN64:	MOVF	DELAYB, F	; Button still pushed
	SKPZ
	GOTO	MAIN68		; Yes..

	MOVLW	7
	ANDWF	DELAYZ, F	; Delay for Uploads & Startup
	SKPZ
	DECF	DELAYZ, F
	SKPZ
	GOTO	MAIN68

	CALL	SET_VOLTS	; Transfer F-Speed to PWM	Bank-00

	SETBSR	(LATA>>7)	;				Bank-02
	BTFSS	SWPOWER		; Off?
	CALL	DREAM0		; Yes, Power everything down and Wait....
;	BSF	SWPOWER		;							**Patch

MAIN68:	CALL	CHECK_BATT	;				Bank-01


;---------------------	Super-Fast Code  -----------------------------

MAIN90:	SETBSR	(PIR1>>7)	;				Bank-00
	BTFSC	FLAG1, B1ASYNC	; A/D Enabled?
	GOTO	MAIN92		; Yes, 2.4mS Pulse Filter

	BTFSC	PIR2, CMP1IF	; Motor Speed Pulse?
	CALL	RPM_FILTER	; Yes, Read & Filter RPM, Start A/D
	GOTO	MAIN98

MAIN92:	BTFSS	PIR0, TMR0IF	; 400uS A/D Timing ?
	GOTO	MAIN98

	BCF	PIR0, TMR0IF	; Reset A/D Timeout Flag

	CALL	ADREAD		; Read 3 A/D Channels		Bank-01
	MOVF	ADCNT, F
	SKPNZ
	CALL	RPM_SYNC	; Setup for next Speed Pulse	Bank-00


MAIN98:	GOTO	ENDMAIN		; End-of-Mainline, loop back to OS

	NOLIST
	IF $ > 0x04FF
	MESSG "Page Overlap - x0500"
	LIST OH CRAP
	ENDIF
	FILL	0x3FFF, 0x04FF - $

	SUBTITLE "Subroutines"
	LIST
RST500:	RESET


	Page



;---------------------	Push Button Debounce  ------------------------	Bank 0
;			 _
; Cy = One-Shot	________| |_______________________
;			 _______   _   _
; 0xFF			|	\ | \ | \
;			|	 \|  \|  \	DELAY_B value
;			|		  \
; threshold __________	|  ______________  \
;		        /		    |
;	Bounce	       /		    |
;	      /|  /|  /			    |
; 0x00 ______/ |_/ |_/			    |_____
;

PUSH00:	SETBSR	(PORTA>>7)	;				Bank-00
	BTFSS	PORTA, BA_PB	; Button Pressed?
	GOTO	PUSH02

	BTFSC	DELAYB, DB_BIT	; No, Above threshold ?
	DECF	DELAYB, F	; Decrement until below threshold
	CLRC
	BTFSC	DELAYB, DB_BIT
	RETLW	255

	CLRF	DELAYB		; Set to 0x00 if below threshold
	BCF	FLAG1, B1PUSH	; Reset OneShot
	RETLW	255

PUSH02:	MOVLW	255
	BTFSS	DELAYB, DB_BIT
	INCF	DELAYB, F	; Increment until above threshold
	BTFSC	DELAYB, DB_BIT
	MOVWF	DELAYB		; Set to 0xFF if above threshold
	CLRC
	BTFSC	DELAYB, 7
	BTFSC	FLAG1, B1PUSH	; One-Shot?
	RETLW	255

	BSF	FLAG1, B1PUSH
	SETC			; Set Carry ONCE...
	RETLW	255



;-------------	Power-Down, Wait for Button  -------------------------

DREAM0:	BCF	INTCON0, GIE	; Disable Interrupts
	SETBSR	(ADCON0>>7)	;				Bank-01
	BSF	PIE0, IOCIE	; Enable PB Interrupt
	CLRF	PIE1		; Disable Serial Int's

	SETBSR	(RA0PPS>>7)	; Diable PWM Output			Bank-29
	CLRF	RC1PPS		; RC1 = LatC
	CLRF	RC4PPS		; RC4 = LatC
	CLRF	RC5PPS		; RC5 = LatC

	SETBSR	(LATA>>7)	;				Bank-02
	CLRF	LATA		; Gnd all outputs
	CLRF	LATC
	CLRF	FVRCON		; Ref - Off
	CLRF	DACCON0		; DAC - Off
	CLRF	CM1CON0		; Cmp1 - Off
	SETBSR	(IOCAN>>7)	;				Bank-07
	MOVLW	IOCANS
	MOVWF	IOCAN		; Wake on Push Button
	CLRF	IOCAP		;			**Punch
	CLRF	IOCCN		;			**Punch
	CLRF	IOCCP		;			**Punch
	CLRF	IOCAF
	CLRF	IOCCF

	SLEEP
	NOP
	NOP
	CLRWDT
	GOTO	INIT02		; Initialize all I/O		Bank-00


	Page



;-------------	Scan 3 A/D Channels and store results  ---------------	Bank 1

ADREAD:	SETBSR	(ADCON0>>7)	;				Bank-01
	MOVF	ADCNT, W
	ANDLW	6		; WREG = 0,2,4
	MOVWF	FSR0L
	MOVLW	HIGH(ADTAB)	; In Flash..
	MOVWF	FSR0H
	MOVIW	FSR0++
	MOVWF	ADCON0		; Select next A/D Channel
	MOVIW	FSR0++
	MOVWF	FSR0L		; FSR0 = Data Location
	MOVLW	HIGH(AD_DATA)
	MOVWF	FSR0H

	INCF	ADCNT, F	; Scan through A/D Control Table
	BTFSS	ADCNT, 0
	GOTO	ADRD00		; Settling time complete?	20

	MOVIW	FSR0--
	SUBWF	ADRESL, W	; -------------	Average  -------------
	MOVWF	NADAT2
	MOVF	INDF0, W
	SUBWFB	ADRESH, W	; NADAT(H/L) = New - Old
	MOVWF	NADAT1
	MOVLW	0
	SKPC			; Setup MSB Borrow
	MOVLW	-1
	MOVWF	NADAT0
	RETLW	255		; (31 inst)

ADRD00:	BSF	ADCON0, ADRUN	; Start after 250uS settling time
	BTFSC	ADCON0, 2	; Last channel?		09,49,4D
	CLRF	ADCNT		; Yes, reset Table pointer

	MOVIW	++FSR0		; F = (+2)
	ADDWF	NADAT2, W
	MOVWI	FSR0--		; (2) += ADRESL + (1)
	MOVF	INDF0, W
	ADDWFC	NADAT1, W
	MOVWI	FSR0--		; (1) += ADRESH - (0)
	MOVF	INDF0, W
	ADDWFC	NADAT0, W
	MOVWF	INDF0		; (0) += Carry - Borrow
	RETLW	255		; (34 inst)  65 vs 54



AD_FILTER:
	SETBSR	(ADCON0>>7)	;				Bank-01
	BTFSS	AD_BATT+2, 7
	INCF	AD_BATT+2, F	; Move Filter+2 toward 0x80
	BTFSC	AD_BATT+2, 7
	DECF	AD_BATT+2, F

	MOVLW	4
	BTFSS	AD_FANA+2, 7
	ADDWF	AD_FANA+2, F
	BTFSC	AD_FANA+2, 7
	SUBWF	AD_FANA+2, F

	BTFSS	AD_FANV+2, 7
	ADDWF	AD_FANV+2, F
	BTFSC	AD_FANV+2, 7
	SUBWF	AD_FANV+2, F

;	BTFSS	PERVAL+2, 7
;	ADDWF	PERVAL+2, F
;	BTFSC	PERVAL+2, 7
;	SUBWF	PERVAL+2, F

	SETBSR	(PIR1>>7)	;				Bank-00
	RETLW	255


	Page



;-------------	Read & Filter RPM if Available  ----------------------	Bank 0
;
;_______ 1 ________ 2 ________ 3 ________ 4 ________ 0 ________ 1 ____
; Pulse	|_|        |_|        |_|        |_|        |_|        |_|
;_A/D Cy____|_|_|______|_|_|______|_|_|______|_|_|______|_|_|_______|_
;___________					   ______________
; T1GEN	    |_____________________________________|		 |____
;	   ____					    __		______
;_T1GVAL__|    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_|  |________|


RPM_FILTER:
	BCF	PIR2, CMP1IF	; Reset Pulse capture Flag
	CLRF	TMR0L
	BCF	PIR0, TMR0IF	; Sync A/D Timer with Motor Speed Pulse
	BSF	FLAG1, B1ASYNC	; Allow A/D Reads

	MOVF	RPMCNT, F
	SKPNZ			; Time to Save Speed Interval?
	BTFSS	PIR1, TMR1GIF	; Was a capture performed?
	GOTO	RPM_10

	MOVF	TMR1H, W
	MOVWF	MTEMP+0		;		Avg = 22 inst
	MOVF	TMR1L, W
	MOVWF	MTEMP+1
	CLRF	TMR1H		; Reset Counter
	CLRF	TMR1L
	SETBSR	(ADCON0>>7)	;				Bank-01
	MOVWF	PERRAW+1	; Save Raw.Lo
	MOVF	MTEMP+0, W
	MOVWF	PERRAW+0	; Save Raw.Hi
	SUBLW	0x2C
	SKPC			; Discard values < 0x2D00
	BTFSC	PERRAW+0, 7	; Discard Values > 0x7FFF
	GOTO	RPM_08

	MOVF	PERRAW+1, W	; Save Val.Lo
	MOVWF	PERVAL+1
	MOVF	PERRAW+0, W	; Save Val.Hi
	MOVWF	PERVAL+0

RPM_08:	SETBSR	(LATA>>7)	;				Bank-02			**Test
	BSF	LATC, BCTEST1

	SETBSR	(PIR1>>7)	;				Bank-00

RPM_10:	DECFSZ	RPMCNT, W	; Beginning of 4 Cycle period?
	RETLW	255

	BCF	T1GCON, T1GEN	; Disable Gate until last Pulse
	MOVLW	TIME_KILL
	MOVWF	DELAYK		; Disable Disconnect Shutdown
	RETLW	255		; This acts like a Pulse filter



SETRPM:	SKPNC			; Diff > 0x1FF ?
	RETLW	32

	MOVF	PERRAW+0, W	; Yes..
	MOVWF	PERVAL+0
	MOVF	PERRAW+1, W	; Val = Raw
	MOVWF	PERVAL+1
	MOVLW	0x7F
	MOVWF	PERVAL+2
	RETLW	1


	Page



;-------------	Prep for next Fan Speed Pulse  -----------------------

RPM_SYNC:
	SETBSR	(LATA>>7)	;				Bank-02			**Test
	BCF	LATC, BCTEST1
	SETBSR	(PIR1>>7)	;				Bank-00
	BCF	FLAG1, B1ASYNC	; Stop A/D until next RPM Pulse

	BTFSS	RPMCNT, 2	; Last of 4 RPM Pulses?
	GOTO	RPM_S0

;-----	Use Tmr1 Gate logic to stop capture after 4 Pulses  ----------

	BCF	T1GCON, T1GTM	; Reset Toggle FF
	BSF	T1GCON, T1GTM
	BSF	T1GCON, T1GGO	; Enable Single-Pulse Logic
	BTFSS	T1GCON, T1GVAL	; noise?
	BSF	T1GCON, T1GPOL	; No, trigger Toggle FF
	BCF	T1GCON, T1GPOL
	BSF	T1GCON, T1GEN	; Use Gate to end Capture on next Pulse
	BCF	PIR1, TMR1GIF
	CLRF	RPMCNT		; Reset Cycle Counter
	RETLW	255

RPM_S0:	MOVF	RPMCNT, F
	SKPNZ
	BSF	T1GCON, T1GGO	; Enable Single-Pulse Logic
	INCF	RPMCNT, F	; Count #Pulses
	RETLW	255


;---------------------	Set Fan Voltage  -----------------------------	Bank 0

NEXT_SPEED:
	SETBSR	(PIR1>>7)	;				Bank-00
	MOVLW	256 / 8		;							**Test
	ADDWF	FSPEED+0, F
	BTFSC	FLAG7, B7ERRF	; Error!  Power Down
	CLRF	FSPEED+0

	SETBSR	(LATA>>7)	;				Bank-02
	SKPNZ
	BCF	SWPOWER		; Off, Disable Switcher
	SKPZ
	BSF	SWPOWER		; On, Enable Switcher

SET_VOLTS:
	SETBSR	(PIR1>>7)	;				Bank-00
	MOVF	FSPEED+0, W
	MOVWF	MTEMP+0
	MOVF	FSPEED+1, W
	SETBSR	(PWM5CON>>7)	; Setup Out Volts PWM		Bank-12			**Test
	MOVWF	PWM5DCL
	MOVF	MTEMP+0, W
	MOVWF	PWM5DCH
	SETBSR	(PIR1>>7)	;				Bank-00
	RETLW	255



CHECK_BATT:
	SETBSR	(ADCON0>>7)	;				Bank-01
	MOVLW	LOW( 0x0106)
	SUBWF	AD_BATT+1, W
	MOVLW	HIGH(0x0106)
	SUBWFB	AD_BATT+0, W
	SKPC
	BSF	FLAG7, B7ERRF	; Indicate Error
	RETLW	255


	Page



;---------------------	16 Bit Divide  -------------------------------	Bank 0
;
;		RPMVAL{2.3} = 1,000,000 / PERVAL  uses: Temp{0.1}

RPM_CALC:
	BCF	FLAG1, B1RPMT	; Once every 250mS
	SETBSR	(ADCON0>>7)	;				Bank-01
	MOVLW	0x05
	MOVWF	RPMVAL+0	; 60,000,000 (Tmr1 Clock) "03 93 87 00"
	MOVLW	0xD9
	MOVWF	RPMVAL+1
	MOVLW	0xEA
	MOVWF	RPMVAL+2
;..	MOVLW	0xF3
	CLRF	RPMVAL+3

	MOVLW	20
	MOVWF	MTEMP+1		; Compute 16 Bit Dividend

RPM_C0:	MOVF	PERVAL+1, W
	SUBWF	RPMVAL+1, W
	MOVWF	MTEMP+0		; Save Difference.Lo
	MOVF	PERVAL+0, W
	SUBWFB	RPMVAL+0, W
	SKPNC
	MOVWF	RPMVAL+0	; Save result.Hi if (+)
	MOVF	MTEMP+0, W
	SKPNC
	MOVWF	RPMVAL+1	; Save result.Lo
	RLF	RPMVAL+3, F
	RLF	RPMVAL+2, F	; Shift in Cy
	RLF	RPMVAL+1, F
	RLF	RPMVAL+0, F
	DECFSZ	MTEMP+1, F
	BRA	RPM_C0

	CLRF	RPMVAL+0	; Clear Remainder
	CLRF	RPMVAL+1
	MOVF	RPMVAL+2, W
	MOVWF	MTEMP+0
	MOVF	RPMVAL+3, W
	BTFSC	RPMVAL+3, 5	; Round and truncate to 10 Bits
	ADDLW	0x20
	ANDLW	0xC0
	MOVWF	RPMVAL+3

	SETBSR	(PWM5CON>>7)	;				Bank-12			**Test
	MOVWF	PWM6DCL
	MOVF	MTEMP+0, W
	MOVWF	PWM6DCH

	SETBSR	(PIR1>>7)	;				Bank-00
	RETLW	255


	Page



;-------------	Fetch External EEP if available  ---------------------	Bank 4
;
; Executing this code after a 10mS delay allows the Bootstrap time to
; send the RESET packet.

EXTEEP:	SETBSR	(PPSLOCK>>7)	; ----	Inputs  ----		Bank-28
	MOVLW	SDIPSU		; SPI SDI EEPDO (A3)
	MOVWF	SSP1DATPPS	;			0xE21
	SETBSR	(RA0PPS>>7)	; ----	Outputs  ----		Bank-29
	MOVLW	RA0SEO		; SPI SD0 EEPDI
	MOVWF	RA0PPS		;			0xE90
	MOVLW	RA1SEO		; SPI SCK EEPCK
	MOVWF	RA1PPS		;			0xE91
	CLRF	RC5PPS		; Enable BCTEST1

	SETBSR	(ADCON0>>7)	;				Bank-01
	BCF	TRISA, BA_RX	; RA0 = SPI D0 (Output)

	SETBSR	(SSP1BUF>>7)	;				Bank-04
	BTFSC	SSP1CON1, SSPEN
	GOTO	EXTE06		; Only Setup Once..

	MOVLW	SSPBDU
	MOVWF	SSP1ADD		; SPI Baud		0x212
	MOVLW	SSPSSU
	MOVWF	SSP1STAT	;			0x214
	MOVLW	SSP1SU
	MOVWF	SSP1CON1	; Disabled		0x215
;..	MOVLW	SSP2SU
	CLRF	SSP1CON2	;	**Punch		0x216
;..	MOVLW	SSP3SU
	CLRF	SSP1CON3	;	**Punch		0x217
	BSF	SSP1CON1, SSPEN	; Enable SPI

;---------------------------------------------------------------------

EXTE06:	CALL	EXREAD		; Read 32 Bytes --> EEPBUF
	CALL	EXPCHK		; Check if EEProm inserted
	SKPNZ
	GOTO	EEPE90		; Read Error

	CALL	EXTBUF		; FSR0 = (EXTBUF), Temp0 = 32
	MOVLW	0x20
	CALL	EEADDR		; NVMADDR = xF020 (Int.EEP)

EXTE10:	MOVIW	FSR0++		; Fetch Data
	CALL	EEWRITE		; Write to Int.EEP
	CALL	EEREAD		; Wait for write to finish & inc. Addr
	SETBSR	(LATA>>7)	;				Bank-02			**Test
	MOVLW	(1<<BCTEST1)	; Toggle Pin-5
	XORWF	LATC, F
	CLRWDT
	DECFSZ	MTEMP+0, F
	GOTO	EXTE10		; Write all 32 Bytes


	Page



;-------------	Switch Header back to UART  --------------------------

EEPE80:	CALL	NEXT_SPEED	; Signal: EEP Transfer Complete
	CLRF	FSPEED		; Lowest Speed

EEPE90:	SETBSR	(ADCON0>>7)	;				Bank-01
	BSF	TRISA, BA_RX	; RA0 = UART Rx (Input)

	SETBSR	(PMD0>>7)	;				Bank-18
;	BSF	PMD4, MSSP1MD	; Power-down EEP SPI port

	SETBSR	(PPSLOCK>>7)	;				Bank-28
	MOVLW	RXPPSU		; UART Rx
	MOVWF	RXPPS

	SETBSR	(RA0PPS>>7)	;				Bank-29
	CLRF	RA0PPS		; SPI_SDO --> UART Rx
	MOVLW	RA1SUO
	MOVWF	RA1PPS		; SPI_SCK --> UART Tx
	MOVLW	RC5SUO
	MOVWF	RC5PPS		; RC5 = PWM6	Fan Speed Volts

	BSF	INTCON0, GIE	; Enable Interrupts

EEPE98:	BSF	FLAG7, B7EPDONE	; Never to return....
	GOTO	MAIN98



;-------------	Read 32 Bytes from External EEP  ---------------------	Bank 4

EXREAD:	CALL	EXTBUF		; FSR0 = (EXTBUF), Temp0 = 32

	CALL	EEPCS1		; EEP_CS = 1		W = Read Command
;..	MOVLW	0x18
	CALL	SPIONE		; Command: Read	 2 MSAddr = 0
	MOVLW	EEP_RADDR
	CALL	SPIONE		; Send Address.Lo
	CALL	DLY004
	CLRF	SSP1BUF		; Fetch 1st Byte
	GOTO	EXRD02

EXRD00:	MOVF	SSP1BUF, W	; W = Received Data
	CLRF	SSP1BUF
	MOVWI	FSR0++		; EEP Data -> Buffer
EXRD02:	CALL	SPIDAT
	DECFSZ	MTEMP+0, F	; Loop for all Bytes
	GOTO	EXRD00

	MOVF	SSP1BUF, W
	MOVWI	FSR0++		; Save last Byte

EEPCS0:	SETBSR	(LATA>>7)	;				Bank-02
	BCF	LATA, BA_CS	; EEP_CS = 0
	SETBSR	(SSP1BUF>>7)	;				Bank-04
	RETLW	255



EXPCHK:	CLRF	MTEMP+0		; Verify data from Ext.EEP
	COMF	EEPBUF+1, W
	IORWF	MTEMP+0, F
	COMF	EEPBUF+2, W	;  Verify the Version# is not x00 or xFF  ???
	IORWF	MTEMP+0, F
	COMF	EEPBUF+3, W
	IORWF	MTEMP+0, F
	RETURN			; Zero = ERROR


	Page



;-------------	Support routines for External EEP  -------------------	Bank 4

EEPCS1:	BCF	INTCON0, GIE	; Disable Interrupts
	SETBSR	(LATA>>7)	;				Bank-02			**Test
	BSF	LATA, BA_CS	; EEP_CS = 1
	SETBSR	(SSP1BUF>>7)	;				Bank-04
	RETLW	0x18		; Read Command 2 MSAddr = 0


EXTBUF:	MOVLW	LOW( EEPBUF)	; FSR0 = (EXTBUF+0)
	MOVWF	FSR0L
	MOVLW	HIGH(EEPBUF)
	MOVWF	FSR0H
	MOVLW	32		; 16 Words
	MOVWF	MTEMP+0
	RETLW	255


SPIONE:	MOVWF	SSP1BUF		; Xmit Data via SPI		Bank-04
SPISTAT:NOP
	NOP
	NOP
SPIDAT:	SETBSR	(LATA>>7)	;				Bank-02			**Test
	BSF	LATC, BCTEST1	; On Rising Edge
	CALL	DLY007
	BCF	LATC, BCTEST1
	CALL	DLY007
	BSF	LATC, BCTEST1	; Simulate EEP Data
	CALL	DLY007
	BCF	LATC, BCTEST1
	CALL	DLY007
	BSF	LATC, BCTEST1
	CALL	DLY007
	BCF	LATC, BCTEST1
	CALL	DLY007
	BSF	LATC, BCTEST1
	CALL	DLY007
	BCF	LATC, BCTEST1
	SETBSR	(SSP1BUF>>7)	;				Bank-04
	RETLW	255


DLY007:	NOP			; 875nS
DLY006:	NOP			; 750nS
DLY005:	CLRC			; 625nS
DLY004:	RETLW	255		; 500nS

	NOLIST
	IF $ > 0x06FF
	MESSG "Page Overlap - x0700"
	LIST OH CRAP
	ENDIF
	FILL	0x3FFF, 0x06FF - $

	SUBTITLE "Tables"
	LIST
RST700:	RESET


	Page


;---------------------	A/D Scan Control Table  ----------------------

;	Next ADCON val, Last Ram Location	*** Must be @ xx00

ADTAB:	DT	CH_BATT, LOW(AD_FANV+1)	; Start Bat Volts Read, Save Fan Volts
	DT	CH_FANA, LOW(AD_BATT+1)	; Start Fan Amps  Read, Save Bat Volts
	DT	CH_FANV, LOW(AD_FANA+1)	; Start Fan Volts Read, Save Fan Amps
	DT	CH_FANV, LOW(0x0EC+1)


;-------------	Initial PWM value vs Output Voltage  -----------------

PWMTAB:	DT  0x05, 0x40, 0x09, 0x40	;  6.10  6.20  0
	DT  0x0D, 0x80, 0x11, 0x80	;  6.30  6.40  2
	DT  0x15, 0xC0, 0x1A, 0x00	;  6.50  6.60  4
	DT  0x1E, 0x00, 0x22, 0x40	;  6.70  6.80  6
	DT  0x26, 0x40, 0x2A, 0x80	;  6.90  7.00  8
	DT  0x2E, 0xC0, 0x32, 0xC0	;  7.10  7.20  10
	DT  0x37, 0x00, 0x3B, 0x00	;  7.30  7.40  12
	DT  0x3F, 0x40, 0x43, 0x80	;  7.50  7.60  14
	DT  0x47, 0x80, 0x4B, 0xC0	;  7.70  7.80  16
	DT  0x4F, 0xC0, 0x54, 0x00	;  7.90  8.00  18
	DT  0x58, 0x40, 0x5C, 0x40	;  8.10  8.20  20
	DT  0x60, 0x80, 0x64, 0x80	;  8.30  8.40  22
	DT  0x68, 0xC0, 0x6D, 0x00	;  8.50  8.60  24
	DT  0x71, 0x00, 0x75, 0x40	;  8.70  8.80  26
	DT  0x79, 0x40, 0x7D, 0x80	;  8.90  9.00  28
	DT  0x81, 0xC0, 0x85, 0xC0	;  9.10  9.20  30
	DT  0x8A, 0x00, 0x8E, 0x00	;  9.30  9.40  32
	DT  0x92, 0x40, 0x96, 0x80	;  9.50  9.60  34
	DT  0x9A, 0x80, 0x9E, 0xC0	;  9.70  9.80  36
	DT  0xA2, 0xC0, 0xA7, 0x00	;  9.90 10.00  38
	DT  0xAB, 0x40, 0xAF, 0x40	; 10.10 10.20  40
	DT  0xB3, 0x80, 0xB7, 0x80	; 10.30 10.40  42
	DT  0xBB, 0xC0, 0xC0, 0x00	; 10.50 10.60  44
	DT  0xC4, 0x00, 0xC8, 0x40	; 10.70 10.80  46
	DT  0xCC, 0x40, 0xD0, 0x80	; 10.90 11.00  48
	DT  0xD4, 0xC0, 0xD8, 0xC0	; 11.10 11.20  50
	DT  0xDD, 0x00, 0xE1, 0x00	; 11.30 11.40  52
	DT  0xE5, 0x40, 0xE9, 0x80	; 11.50 11.60  54
	DT  0xED, 0x80, 0xF1, 0xC0	; 11.70 11.80  56
	DT  0xF5, 0xC0, 0xFA, 0x00	; 11.90 12.00  58

	NOLIST
	IF $ > 0x0800
	MESSG "Page Overlap - x0800"
	LIST OH CRAP
	ENDIF
	FILL	0x3FFF, 0x07FF - $
	RESET

	SUBTITLE "EEProm"
	LIST


	Page


;---------------------	MicroChip EEProm Data  -----------------------

	ORG	0x2120

;	DE	0xAA, 0x55


;---------------------	JRHID EEProm Data  ---------------------------

	ORG	0x4820
	DE	255, 255, 255, 255	; Clear EEPROM for ExtEEP Testing		**Test
	DE	255, 255, 255, 255
	DE	255, 255, 255, 255
	DE	255, 255, 255, 255
	DE	255, 255, 255, 255
	DE	255, 255, 255, 255
	DE	255, 255, 255, 255
	DE	255, 255, 255, 255


	END
