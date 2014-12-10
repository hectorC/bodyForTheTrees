/* Code for the interactive video, sound and performer project "bodyForTheTrees (bFTT)"
 * by Hector Centeno, Jessica Kee, Sachiko Murakami and Adam Owen
 * Licensed under Creative Commons Attribution-ShareAlike 3.0 Unported [ http://creativecommons.org/licenses/by-sa/3.0/ ]
 */
 
<CsoundSynthesizer>
<CsOptions>
-odac
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

gioschandle OSCinit 8010
gkFlex init 0
gkFlex1 init 0
gkFlex2 init 0
gkLeftHand init 0
gkLeftHand1 init 0
gkRightHand1 init 0
gkYaw1 init 0
gkPitch init 0
gkExpArm init 0
gkExp init 0
gkSpike init 0
gkSpikedir init -1

gaVerbL init 0
gaVerbR init 0

instr 10
kcnt init 0

kFLt OSClisten gioschandle, "/flex", "f", gkFlex
kFL1t OSClisten gioschandle, "/flex1", "f", gkFlex1
kFL2t OSClisten gioschandle, "/flex2", "f", gkFlex2
kLHt OSClisten gioschandle, "/leftHand", "f", gkLeftHand
kLH1t OSClisten gioschandle, "/leftHand1", "f", gkLeftHand1
kRHt OSClisten gioschandle, "/rightHand1", "f", gkRightHand1
kYAt OSClisten gioschandle, "/yaw1", "f", gkYaw1
kPIt OSClisten gioschandle, "/pitch", "f", gkPitch

kEAt OSClisten gioschandle, "/exparmed", "i", gkExpArm
kEXt OSClisten gioschandle, "/explode", "f", gkExp
kSPt OSClisten gioschandle, "/spike", "i", gkSpike
kSPdt OSClisten gioschandle, "/spikedir", "i", gkSpikedir

if (kFL1t == 1) then
	if (gkFlex%2 >= 0 && gkFlex%2 <= 0.2 ) then
		event "i", 20, 0, 4, gkFlex1, 1
	endif
endif

if (kSPt == 1) then
	if (gkSpike == 1 ) then
		kcnt = kcnt + 1
		if (kcnt%15 == 0) then
			event "i", 30, 0, 4, gkFlex2
		endif
	else
		kcnt = 0
	endif					
endif

kact active 50
if (gkExp > 0.5 && kact == 0) then
	event "i", 50, 0, 4
endif
endin

instr 20
ifrq	=	p4
kv1	=	p5					; stick hardness	
kinst init 1

if (gkSpikedir == -1) then
	kinst = 1;
endif

if (gkSpikedir == 1) then
	kinst = 3;
endif

asig	STKModalBar cpspch(ifrq), 0.7, 2, 127, 4, 50, 11, 50, 1, 10, 8, 0, 16, kinst

gaVerbL = gaVerbL + asig
gaVerbR = gaVerbR + asig
endin

instr 30
asig pluck 0.7, 120, 120, 0, 3, .5

iolaps  = 2
igrsize = 0.04
ifreq   = iolaps/igrsize
ips     = 1/iolaps

istr = p4  /* timescale */
ipitch = p5 /* pitchscale */
;a1 diskgrain "drum1.wav", 1, ifreq, ipitch, igrsize, ips*istr, 1, iolaps

a1 diskin2 "drum1.wav", p4, 0

gaVerbL = gaVerbL + asig + a1
gaVerbR = gaVerbR + asig + a1
endin

instr 40
	
;	SFile1 sprintf "sample_%d", p4
;	SFile strcat SFile1, ".pvx"

	idur1 filelen "water1.pvx"
	idur2 filelen "water2.pvx"
	
	idur3 filelen "tamrub2.pvx"
	idur4 filelen "harp2.pvx"
	
	kpos1 port gkYaw1, 1	
	kpos1 limit kpos1, 0, idur1
	kpos2 port gkYaw1, 1	
	kpos2 limit kpos2, 0, idur2
	
	kpos3 port gkYaw1, 1	
	kpos3 limit kpos3, 0, idur3
	kpos4 port gkYaw1, 1	
	kpos4 limit kpos4, 0, idur4			
				
	kpitch1 limit gkLeftHand1, 0.1, 10
	kpitch2 limit gkRightHand1, 0.1, 10
	
	if (gkSpikedir == -1) then
		asig1 pvoc kpos1*idur1, kpitch1, "water1.pvx"
		asig2 pvoc kpos2*idur2, kpitch2, "water2.pvx"
	else
		asig1 pvoc kpos3*idur3, kpitch1, "celesta.pvx"
		asig2 pvoc kpos4*idur4, kpitch2, "harp2.pvx"
	endif
	
	gaVerbL = gaVerbL + asig1 + asig2
	gaVerbR = gaVerbR + asig1 + asig2

endin

instr 50
if (gkSpikedir == -1) then
	kpitch1 = 1;
	kpitch2 = 1;
endif

if (gkSpikedir == 1) then
	kpitch1 = gkExp;
	kpitch2 = 1/gkExp;
endif

a1, a2 diskin2 "tamrub.wav", kpitch1, 0
a3, a4 diskin2 "harp.wav", kpitch2, 0

gaVerbL = gaVerbL + (a1 * 1.5) + (a3 * 1.5)
gaVerbR = gaVerbR + (a2 * 1.5) + (a4 * 1.5)
endin

instr 100
aL, aR  freeverb gaVerbL, gaVerbR, 0.9, 0.35
gaVerbL = 0
gaVerbR = 0
	outs aL*0.6, aR*0.6
endin


</CsInstruments>
<CsScore>
f 1 0 8192 20 2 1  ;Hanning function

i 10 0 3600
i 40 0 3600 
i 100 0 3600

e
</CsScore>
</CsoundSynthesizer>
