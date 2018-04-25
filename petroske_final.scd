(
var synthDef, score;
var	outputPath, headerFormat, sampleFormat, numOutputChannels, sampleRate;
var sinCosPanLaw, cmRatioFunc, beatsToTime;
var sinGrainSynth;
var fmSinSynth;
var noisyFMSinGrainSynth;
var agsNoiseSynth;
var sinRingModSynth;
var metallicAMSynth;
var percussiveNoise;
var simpleAMSynth;
var vocalEAhhSynth;

var randomDingsRM;

var etudeBaseFreq, etudeBPM;

// set the NRT vars here...
outputPath = "~/Desktop/petroske_final.wav"; // output file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
numOutputChannels = 2;                // stereo --> 2 channels
sampleRate = 44100;

etudeBaseFreq = 315;
etudeBPM = 90;

score = CtkScore.new;

/////////////////////// Utility Functions ///////////////////////////

// Convert the index of a beat to a time in seconds.
beatsToTime = {arg beats;
	beats / (etudeBPM / 60);
};

// sine-cosine panning law coefficient function
// angle argument in degrees
sinCosPanLaw = { arg angleInDegrees = 0;
	var angleInRadians;
	var theta;

	angleInRadians = angleInDegrees/180*pi;

	theta = pi/4 - angleInRadians;

	[theta.cos, theta.sin]
};

// function to calculate c:m
// n, n >=1 ratio between f0 and f1
// p, p = 0, 1, 2, 3, ... partial number
cmRatioFunc = {arg n, p;
    var cm;

    p.even.if({
        cm = [                        // p is even case
            (p)/2 * (1 + n) + 1,      // carrier
            (1 + n)                   // modulator
        ]
    },{
        cm = [                        // p is odd case
            (p + 1)/2 * (1 + n) - 1,  // carrier
            (1 + n)                   // modulator
            ]
    });
    cm
};

//////////////////// Synth Defs /////////////////////////////

simpleAMSynth = CtkSynthDef.new(\simpleAMSynth, {arg dur, ris = 0.1, dec = 0.1, gain = -12, cFreq, mFreq, mIndexGain, panAngle;
	var mIndex, amp, ampEnv, carrier, normFac;

	mIndex = mIndexGain.dbamp;
	ampEnv = EnvGen.kr(Env([0,1,1,0],[ris,dur - ris - dec, dec], \lin));
	amp = gain.dbamp;

	normFac = (1 + (2*mIndex)).reciprocal;

	carrier = SinOsc.ar(cFreq, 0, (2*SinOsc.ar(mFreq, 0, mIndex)) + 1);
	carrier = amp * ampEnv * normFac * carrier;

	Out.ar(0, carrier * sinCosPanLaw.value(panAngle));
});

metallicAMSynth = CtkSynthDef.new(\metallicAMSynth, {arg dur, gain = -12, cFreq, mFreq, mIndexGain, ris = 0.1, panAngle;
	var env, mIndex, amp, carrier;

	mIndex = mIndexGain.dbamp;
	env = EnvGen.kr(Env([0, 1, 0], [ris, dur - ris], [4, -2]));
	amp = env * gain.dbamp;

	carrier = 0;
	[[cFreq, 0], [cFreq * 2, -5], [cFreq * 3, -10]].do{arg cPartial;
		carrier = carrier + SinOsc.ar(cPartial[0], 0, cPartial[1].dbamp);
	};
	carrier = carrier * -6.dbamp;

	Out.ar(0, (carrier * (SinOsc.ar(mFreq, 0, mIndex * amp) + amp) * sinCosPanLaw.value(panAngle)));
});

agsNoiseSynth = CtkSynthDef.new(\agsNoiseSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, formFreq = 1760.0, q = 1.0,  panAngle = 0.0;
    var bus = 0;
    var trigger;
    var granSig;
    var out;
    var amp;
    var grainDur, grainFreq, envFreq, wavFreq;
    var ampEnv;

    // initial calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale
    grainFreq = freq;
    envFreq = q.reciprocal * (formFreq/2);
    wavFreq = formFreq;
    grainDur = envFreq.reciprocal;

	ampEnv = EnvGen.kr(Env([0,1,1,0],[ris,dur - ris - dec, dec], \lin));

    trigger = Dust.ar(grainFreq); // <-- Dust gives us an asynchronous trigger!
    granSig = GrainSin.ar(trigger: trigger, dur: grainDur, freq: wavFreq);

    granSig = amp * ampEnv * granSig;
    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * granSig;  // <-- Panning happens here!

    Out.ar(bus, out)
});


sinGrainSynth = CtkSynthDef.new(\sinGrainSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, carRatio = 1, modRatio = 1, modIndex = 1.0, formFreq = 1760.0, q = 1.0,  panAngle = 0.0, noiseGain = 0;
    var bus = 0;
    var aTrigger, sTrigger;
    var aGranSig, sGranSig, xGranSig;
    var out;
    var grainDur, grainFreq, envFreq, wavFreq;
    var ampEnv;

    // initial calcs
    grainFreq = freq;
    envFreq = q.reciprocal * (formFreq/2);
    wavFreq = formFreq;
    grainDur = envFreq.reciprocal;

    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    aTrigger = Dust.ar(1000); // async trigger
	sTrigger = Impulse.ar(grainFreq + LFNoise1.ar(2000, grainFreq * noiseGain.pow(1/2))); // sync trigger

    aGranSig = GrainSin.ar(trigger: aTrigger, dur: grainDur, freq: wavFreq);
	sGranSig = GrainSin.ar(trigger: sTrigger, dur: grainDur, freq: wavFreq);

	xGranSig = (aGranSig * noiseGain.pow(1/2)) + (sGranSig * (1 - noiseGain).pow(1/2));


	//xGranSig = GrainSin.ar(trigger: sTrigger, dur: grainDur, freq: wavFreq);

    xGranSig = gain.dbamp * ampEnv * xGranSig;
    out = sinCosPanLaw.value(panAngle) * xGranSig;

    Out.ar(bus, out)
});

/*
noisyFMSinGrainSynth = CtkSynthDef.new(\noisyFMSinGrainSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, carRatio = 1, modRatio = 1, modIndex = 1, formFreq = 1760.0, q = 1.0,  panAngle = 0.0, noiseGain = 0;
    var bus = 0;
    var aTrigger, sTrigger;
    var aGranSig, sGranSig, xGranSig;
    var out;
    var grainDur, grainFreq, envFreq, wavFreq;
    var ampEnv;

	var cFreq, mFreq;

    // initial calcs
    grainFreq = freq;
    envFreq = q.reciprocal * (formFreq/2);
    wavFreq = formFreq;
    grainDur = envFreq.reciprocal;

	cFreq = freq * carRatio;
	mFreq = freq * modRatio;

    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    aTrigger = Dust.ar(1000); // async trigger
	sTrigger = Impulse.ar(grainFreq + LFNoise1.ar(2000, grainFreq * noiseGain.pow(1/2))); // sync trigger

    aGranSig = GrainFM.ar(trigger: aTrigger, dur: grainDur, carFreq: cFreq, modFreq: mFreq, index: modIndex);
	sGranSig = GrainFM.ar(trigger: sTrigger, dur: grainDur, carFreq: cFreq, modFreq: mFreq, index: modIndex);

	xGranSig = (aGranSig * noiseGain.pow(1/2)) + (sGranSig * (1 - noiseGain).pow(1/2));

    xGranSig = gain.dbamp * ampEnv * xGranSig;
    out = sinCosPanLaw.value(panAngle) * xGranSig;

    Out.ar(bus, out)
});*/

noisyFMSinGrainSynth = CtkSynthDef.new(\noisyFMSinGrainSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, carRatio = 1, modRatio = 1, modIndex = 1, formFreq = 1760.0, q = 1.0,  panAngle = 0.0, noiseGain = 0;
    var bus = 0;
    var aTrigger, sTrigger;
    var aGranSig, sGranSig, xGranSig;
    var out;
    var grainDur, envFreq, wavFreq;
    var ampEnv;

	var cFreq, mFreq;

	cFreq = freq * carRatio;
	mFreq = freq * modRatio;

    envFreq = q.reciprocal * (formFreq/2);
    wavFreq = formFreq;
    grainDur = envFreq.reciprocal;

	ampEnv = EnvGen.kr(Env([0,1,1,0],[ris,dur - ris - dec, dec], \lin));

    aTrigger = Dust.ar(1000); // async trigger
	sTrigger = Impulse.ar(cFreq + SinOsc.ar(mFreq, 0, modIndex * mFreq)); // sync trigger

	aGranSig = GrainSin.ar(trigger: aTrigger, dur: grainDur, freq: wavFreq);
	sGranSig = GrainSin.ar(trigger: sTrigger, dur: grainDur, freq: wavFreq);

	xGranSig = (aGranSig * noiseGain.pow(1/2)) + (sGranSig * (1 - noiseGain).pow(1/2));

    xGranSig = gain.dbamp * ampEnv * xGranSig;
    out = sinCosPanLaw.value(panAngle) * xGranSig;

    Out.ar(bus, out)
});

// Band limited noise with a percussive envelope. The noise frequency change sover time
percussiveNoise = CtkSynthDef.new(\percussiveNoise, {arg dur, gain, ris = 0.05, carFreq = 440.0, noiStartFreq = 440.0, noiEndFreq = 440.0,  panAngle = 0.0;

    // variables
    var bus = 0;      // var to specify output bus: first output
    var noise, carOsc;
    var out;          // output!
    var amp;          // a few vars for synthesis
    var ampEnv;       // var for envelope signal
	var noiEnv;


    // initial calcs
    amp = gain.dbamp; // convert from gain in dB to linear amplitude scale

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(Env([0,1,0], [ris, dur - ris], [3, -3]));

	noiEnv = EnvGen.kr(Env([noiStartFreq, noiEndFreq], [dur], \exp));

	noise = LFNoise2.ar(noiEnv);              // (quadratic interpolation sample-and-hold noise)
    carOsc = SinOsc.ar(carFreq);               // simple carrier (single sinusoid)

    // apply the amplitude envelope and Ring Modulate
    noise = amp * ampEnv * noise * carOsc;

    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * noise;  // <-- Panning happens here!

    // out!!
    Out.ar(bus, out)
});

fmSinSynth = CtkSynthDef.new(\FMSinSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, carRatio = 1, modRatio = 1, modIndex = 1.0, panAngle = 0.0;
    var bus = 0;
    var carOsc, modOsc;
    var out;
    var amp;
    var carFreq, modFreq;
    var modDev;
    var ampEnv;

    amp = gain.dbamp;
    carFreq = carRatio * freq;
    modFreq = modRatio * freq;
    modDev = modIndex * modFreq;

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    modOsc = SinOsc.ar(modFreq, 0, modDev);         // simple modulator (single sinusoid)
    carOsc = SinOsc.ar(carFreq + modOsc, 0, amp);   // simple carrier (single sinusoid)

    // apply the amplitude envelope
    carOsc = ampEnv * carOsc;

    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * carOsc;

    Out.ar(bus, out)
});

sinRingModSynth = CtkSynthDef.new(\sinRingModSynth, {arg dur, gain = -12, cFreq, mFreq, ris = 0.1, panAngle;
	var env, envGen, amp, modulator;
	env = EnvGen.kr(Env([0, 1, 0], [ris, dur - ris], [4, -4])); // env define within synthDef
	amp = env * gain.dbamp;
	Out.ar(0,
		SinOsc.ar(cFreq, 0, SinOsc.ar(mFreq, 0, amp) * sinCosPanLaw.value(panAngle))
	)
});


vocalEAhhSynth = CtkSynthDef.new(\vocalEAhhSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, vowel = 0, panAngle = 0.0;
    var bus = 0;
    var out;
    var amp;
    var ampEnv;

	var baseSig, outSig;

	var formantFreqs = [[270, 2290, 3010], [570, 840, 2410]];
	var formantFreqEnvs;
	var formantGains = [10, 9, 8];
	var formantQs = [8, 7, 10];

	var osc1, osc2, osc3, oscNoise;

	formantFreqEnvs = formantFreqs.flop.collect({arg formants;
		Env([formants[0], formants[1]], [1], \exp);
	});

	formantFreqs.flop.postln;

    amp = gain.dbamp;

    // the amplitude envelope nested in the UGen that synthesises the envelope
	ampEnv = EnvGen.kr(Env([0,1,1,0],[ris,dur - ris - dec, dec], \lin));

	oscNoise = LFNoise1.ar(3000, -47.dbamp * freq);
	osc3 = SinOsc.ar(freq: freq + oscNoise, mul: -10.dbamp * (freq + oscNoise));
	osc2 = SinOsc.ar(freq: freq + osc3, mul: -3.dbamp * (freq + osc3));
	osc1 = SinOsc.ar(freq: freq + osc2, mul: -12.dbamp);

	baseSig = osc1;

	outSig = baseSig;
	formantFreqs.flop.do{arg item, index;
		var formFreq;
		var formGain;
		var formQ;

		formFreq = vowel.linlin(0, 1, item[0], item[1]);
		formGain = formantGains.at(index);
		formQ = formantQs.at(index);
		outSig = outSig + BPF.ar(in: baseSig, freq: formFreq, rq: 1 / (formQ * 2), mul: formGain);
	};
    // expand to two channels - panning
    out = sinCosPanLaw.value(panAngle) * outSig * ampEnv;

    Out.ar(bus, out)
});

sinRingModSynth = CtkSynthDef.new(\sinRingModSynth, {arg dur, gain = -12, cFreq, mFreq, ris = 0.1, panAngle;
	var env, envGen, amp, modulator;
	env = EnvGen.kr(Env([0, 1, 0], [ris, dur - ris], [4, -4])); // env define within synthDef
	amp = env * gain.dbamp;
	Out.ar(0,
		SinOsc.ar(cFreq, 0, SinOsc.ar(mFreq, 0, amp) * sinCosPanLaw.value(panAngle))
	)
});

//////////////////// Note Generation Function ///////////////////
randomDingsRM = {arg partialData, start, duration, gain;
	var lambda, noteTimes, env;

	env = Env([0.1, 1, 0.1], [duration * 0.5, duration * 0.5], \sin);
	lambda = 20.0; // play an average of 20 notes a second;
	noteTimes = [];
	(0.0).forBy (duration, 1.0 / lambda, {arg i;
		noteTimes = noteTimes.add(((0.0).rrand(1.0) * (1.0 / lambda)) + i);
	});
	noteTimes.do({arg noteTime;
		var thisPartialData;
		var globalNoteTime;
		thisPartialData = partialData[rand(partialData.size)];
		globalNoteTime = noteTime + start;
		score.add(
			sinRingModSynth.note(starttime: globalNoteTime, duration: 1 / lambda)
			.dur_(1 / lambda)
			.gain_(((thisPartialData[0] + gain).dbamp * env.at(noteTime)).ampdb)
			.cFreq_(thisPartialData[1])
			.mFreq_(420)
			.panAngle_(-90.rrand(90))
			.ris_(0.01));
	});
};


/////////////////// Notes //////////////////////
{
	var freqStarts = [etudeBaseFreq, etudeBaseFreq * 5/4, etudeBaseFreq * 3/2, etudeBaseFreq * 2, etudeBaseFreq * 2] / 2;
	var freqEnds = [etudeBaseFreq, etudeBaseFreq * 5/4, etudeBaseFreq * 3/2, etudeBaseFreq * 2, etudeBaseFreq * 2] * (5/4) / 2;
	var gains = [0, -2, -3, -6, -7];
	var notesData = [freqStarts, freqEnds, gains].flop;

	var noiseDecayTime = beatsToTime.value(32);
	var majHoldTime = beatsToTime.value(8);
	var majToMaj7DecayTime = beatsToTime.value(1);
	var chordSustainTime = beatsToTime.value(4);
	var endSustain = beatsToTime.value(32);
	var endDecayTime = beatsToTime.value(8);
	var closingTime = beatsToTime.value(16);

	var totalTime = noiseDecayTime + majHoldTime + chordSustainTime + chordSustainTime + endSustain + closingTime;

	notesData.do{arg noteData;
		var freqStart = noteData[0];
		var freqEnd = noteData[1];
		var gain = noteData[2];

		var freqEnv = Env(
			levels:[freqStart, freqStart, freqEnd, freqEnd, freqStart, freqStart, freqStart * 3, freqStart / 4],
			times: [noiseDecayTime + majHoldTime, majToMaj7DecayTime, chordSustainTime - majToMaj7DecayTime, majToMaj7DecayTime, chordSustainTime - majToMaj7DecayTime, endSustain, endDecayTime],
			curve: \exp
		);

		score.add(noisyFMSinGrainSynth.note(starttime: 0, duration: totalTime)
			.dur_(totalTime)
			.gain_(CtkControl.env(Env([-21, -25], [noiseDecayTime], \lin)))
			.freq_(CtkControl.env(freqEnv))
			.carRatio_(cmRatioFunc.value(1/2, 2).at(0))
			.modRatio_(cmRatioFunc.value(1/2, 2).at(1))
			.formFreq_(CtkControl.env(Env(
				levels: [etudeBaseFreq, freqStart, freqStart, freqEnd, freqEnd, freqStart, freqStart, freqStart * 3, freqStart / 4],
				times: [noiseDecayTime, majHoldTime, majToMaj7DecayTime, chordSustainTime - majToMaj7DecayTime, majToMaj7DecayTime, chordSustainTime , endSustain - majToMaj7DecayTime, endDecayTime],
				curve: \exp
			)))
			.modIndex_(0.8)
			.q_(CtkControl.env(Env(
				levels: [1.5, 5],
				times: [noiseDecayTime],
				curve: \lin)))
			.panAngle_(0)
			.noiseGain_(CtkControl.env(Env(
				levels: [0.9, 0.02],
				times:[noiseDecayTime],
				curve: \lin)))
			.ris_(beatsToTime.value(4))
			.dec_(beatsToTime.value(8))
		);
	}
}.value;



{
	var duration = beatsToTime.value(48);
	var start = beatsToTime.value(48);

	var freqMultEnv = Env([1, 3], [duration], \exp);

	var gainEnv = Env([-9, 5], beatsToTime.value(32), \lin);
	((duration / 60) * etudeBPM * 2).do({arg i;
		var timeOffset = beatsToTime.value(i / 2);
		score.add(percussiveNoise.note(starttime: start + timeOffset, duration: (60 / etudeBPM))
			.dur_(60 / etudeBPM)
			//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
			.gain_(-25 + gainEnv.at(timeOffset))
			.carFreq_(etudeBaseFreq * 2)
			.noiStartFreq_(etudeBaseFreq * 4 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
			.noiEndFreq_(etudeBaseFreq * 3 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset)));

		if(i.mod(8) == 0, {
			score.add(percussiveNoise.note(starttime: start + timeOffset, duration: beatsToTime.value(4))
				.dur_(beatsToTime.value(4))
				//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
				.gain_(-10 + gainEnv.at(timeOffset))
				.carFreq_(etudeBaseFreq)
				.noiStartFreq_(etudeBaseFreq * 3 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
				.noiEndFreq_(etudeBaseFreq * 2 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset)));
		});
	});
}.value;

{
	var duration = beatsToTime.value(8);
	var start = beatsToTime.value(96);

	var freqMultEnv = Env([1, 3], [duration], \exp);

	var gainEnv = Env([-12, 5], beatsToTime.value(32), \lin);
	((duration / 60) * etudeBPM * 4).do({arg i;
		var timeOffset = beatsToTime.value(i / 4);

		score.add(percussiveNoise.note(starttime: start + timeOffset, duration: (60 / etudeBPM))
			.dur_(60 / etudeBPM)
			//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
			.gain_(-25 + gainEnv.at(timeOffset))
			.carFreq_(etudeBaseFreq * 2)
			.noiStartFreq_(etudeBaseFreq * 4 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
			.noiEndFreq_(etudeBaseFreq * 3 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
			.panAngle_(-45.rrand(45)));

		/*
		if(i.mod(16) == 0, {
			score.add(percussiveNoise.note(starttime: start + timeOffset, duration: beatsToTime.value(4))
				.dur_(beatsToTime.value(4))
				//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
				.gain_(-10 + gainEnv.at(timeOffset))
				.carFreq_(etudeBaseFreq)
				.noiStartFreq_(etudeBaseFreq * 3 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
				.noiEndFreq_(etudeBaseFreq * 2 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset)));
		});
		*/
	});
}.value;


score.add(metallicAMSynth.note(starttime: beatsToTime.value(88), duration: beatsToTime.value(8 + 32))
	.dur_(beatsToTime.value(8 + 32))
	.gain_(-12)
	.cFreq_(etudeBaseFreq * 3/2)
	.mFreq_(CtkControl.env(Env([etudeBaseFreq * 2 * 0.99, etudeBaseFreq * 2 * 0.98, etudeBaseFreq], [beatsToTime.value(16), beatsToTime.value(8)], \exp)))
	.mIndexGain_(-6)
	.panAngle_(0)
	.ris_(beatsToTime.value(16))
);
score.add(metallicAMSynth.note(starttime: beatsToTime.value(100), duration: beatsToTime.value(32))
	.dur_(beatsToTime.value(32))
	.gain_(-12)
	.cFreq_(etudeBaseFreq * 0.5 * 3/2)
	.mFreq_(etudeBaseFreq * 0.99)
	.mIndexGain_(-6)
	.panAngle_(0)
	.ris_(beatsToTime.value(4))
);

{
	var duration = 30;
	var numSwells = 12;
	var startTime = beatsToTime.value(108);

	numSwells.do({arg i;
		var freq = if (i < 6, etudeBaseFreq / 2, etudeBaseFreq * (3/2) / 4);

		score.add(fmSinSynth.note(starttime: startTime + (i * duration / numSwells), duration: 1.3 * duration / numSwells)
			.dur_(1.3 * duration / numSwells)
			.gain_(-16 + i)
			.ris_(0.4)
			.dec_(0.4)
			.freq_(freq)
			.carRatio_(cmRatioFunc.value(1/2, i.mod(6)).at(0))
			.modRatio_(cmRatioFunc.value(1/2, i.mod(6)).at(1)));
	});

	(numSwells + 1).do{arg index;
		var peaktime = (30 / 12) * (index + 0.09);
		var duration = 30 / 12 / 2;
		var partialData =
		[   [0, etudeBaseFreq * index ],
			[0, etudeBaseFreq * index * 2],
			[0, etudeBaseFreq * index * 3],
			[0, etudeBaseFreq * index * 2/3],
			[0, etudeBaseFreq * index * 3/4],
			[0, etudeBaseFreq * index * 4/5] ];
		randomDingsRM.value(
			partialData: partialData,
			start: startTime + peaktime - (duration / 2),
			duration: duration,
			gain: -4);
	};

	startTime = startTime + duration;
	numSwells.do({arg i;
		var freq = if (i < 6, etudeBaseFreq / 2, etudeBaseFreq * (3/2) / 4);
		var dur = 1.3 * duration / numSwells;
		if (i == (numSwells - 1), {dur = 2 * duration / numSwells});
		score.add(fmSinSynth.note(starttime: startTime + (i * duration / numSwells), duration: dur * 1.3)
			.dur_(dur * 1.3)
			.gain_(-16 + (i * 0.6))
			.ris_(0.4)
			.dec_(0.4)
			.freq_(freq)
			.carRatio_(cmRatioFunc.value(1/2, i.mod(6)).at(0))
			.modRatio_(cmRatioFunc.value(1/2, i.mod(6)).at(1))
			.panAngle_(-10));

		if (i.mod(2) == 0,
			{
				var firstNoteStart = startTime + (i * duration / numSwells);
				var secondNoteStart = startTime + ((i + 1) * duration / numSwells);
				var noteDur = dur;

				score.add(vocalEAhhSynth.note(starttime: firstNoteStart, duration: noteDur + 0.07)
					.dur_((duration / numSwells) + 0.07)
					.gain_(-23)
					.freq_(freq * 2)
					.vowel_(1)
					.panAngle_(-15 + (-5.0.rrand(5.0)))
				);

				score.add(vocalEAhhSynth.note(starttime: secondNoteStart, duration: noteDur + 0.07)
					.dur_(noteDur + 0.07)
					.gain_(-22)
					.freq_(freq * 2)
					.vowel_(0)
					.panAngle_(15 + (-5.0.rrand(5.0)))
					.ris_(beatsToTime.value(1))
				);

				// Band limited noises
				score.add(percussiveNoise.note(starttime: firstNoteStart - noteDur, duration: noteDur + 0.2)
					.dur_(noteDur + 0.2)
					.ris_(noteDur)
					//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
					.gain_(-13 + (i * 0.8))
					.carFreq_(etudeBaseFreq * 2)
					.noiStartFreq_(etudeBaseFreq * 2 * 0.8.rrand(1.2) * (1 + ((i+1) / 8)))
					.noiEndFreq_(etudeBaseFreq * 4 * 0.8.rrand(1.2) * (1 + ((i+1) / 8)))
					.panAngle_(-45.rrand(45))
				);

				8.do{arg i;
					var timeOffset = i * (noteDur / 8);
					var gain = (-6 - i);
					if (i == 0, {gain = gain + 9});
					score.add(percussiveNoise.note(starttime: firstNoteStart + timeOffset, duration: timeOffset)
						.dur_(timeOffset)
						//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
						.gain_(gain)
						.carFreq_(etudeBaseFreq * 2)
						.noiStartFreq_(etudeBaseFreq * 2 * 0.8.rrand(1.2))
						.noiEndFreq_(etudeBaseFreq * 1 * 0.8.rrand(1.2)));
				}
			}
		);

		score.add(percussiveNoise.note(starttime: startTime + 30, duration: dur + 0.2)
			.dur_(dur + 0.2)
			.ris_(0.1)
			//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
			.gain_(-19)
			.carFreq_(etudeBaseFreq * 2)
			.noiStartFreq_(etudeBaseFreq * 2 * 0.8.rrand(1.2) * (1 + ((i+1) / 8)))
			.noiEndFreq_(etudeBaseFreq * 4 * 0.8.rrand(1.2) * (1 + ((i+1) / 8)))
			.panAngle_(-45.rrand(45))
		);
	});
}.value;

{
	var startTime = beatsToTime.value(108) + 60;

	var freq = etudeBaseFreq / 2;

	var freqMultEnv, gainEnv;

	var partialData = [
		[1, 1/2, beatsToTime.value(4), beatsToTime.value(0)],
		[2, 1/3, beatsToTime.value(4), beatsToTime.value(8)],
		[3, 1/4, beatsToTime.value(4), beatsToTime.value(16)],
		[4, 1/5, beatsToTime.value(4), beatsToTime.value(24)],
		[5, 1/6, beatsToTime.value(4), beatsToTime.value(32)],
		[6, 1/7, beatsToTime.value(4), beatsToTime.value(40)],
		[7, 1/8, beatsToTime.value(4), beatsToTime.value(40)],
	];

	var numPartials = 8;
	partialData.do{arg item, index;
		var partialNum = item[0];
		var partialAmp = item[1];
		var partialRis = item[2];
		var partialStartOffset = item[3];
		var partialDur = beatsToTime.value(68) - partialStartOffset;

		var thisFreq = freq;

		//simpleAMSynth = CtkSynthDef.new(\simpleAMSynth, {arg dur, ris = 0.1, dec = 0.1, gain = -12, cFreq, mFreq, mIndexGain, panAngle;
		score.add(simpleAMSynth.note(starttime: startTime + partialStartOffset, duration: partialDur)
			.dur_(partialDur)
			.ris_(partialRis)
			.dec_(beatsToTime.value(4))
			.gain_(-12 + (partialAmp.ampdb))
			.cFreq_(thisFreq * partialNum)
			.mFreq_(thisFreq)
			.mIndexGain_(-0.dbamp)
			.panAngle_(index.linlin(0, numPartials - 1, -10, 10))
		);

		thisFreq = thisFreq * 3 / 2;
		score.add(simpleAMSynth.note(starttime: startTime + partialStartOffset, duration: partialDur)
			.dur_(partialDur)
			.ris_(partialRis)
			.dec_(beatsToTime.value(16))
			.gain_(-15 + (partialAmp.ampdb))
			.cFreq_(thisFreq * partialNum)
			.mFreq_(thisFreq)
			.mIndexGain_(0)
			.panAngle_(index.linlin(0, numPartials - 1, 15, -15))
		);

		// agsNoiseSynth = CtkSynthDef.new(\agsNoiseSynth, {arg dur, gain, ris = 0.1, dec = 0.1, freq = 440.0, formFreq = 1760.0, q = 1.0,  panAngle = 0.0;
		score.add(agsNoiseSynth.note(starttime: startTime + partialStartOffset, duration: partialDur)
			.dur_(partialDur)
			.ris_(partialRis)
			.dec_(beatsToTime.value(16))
			.gain_(-25 + (partialAmp.ampdb))
			.freq_(thisFreq)
			.formFreq_(thisFreq * partialNum)
			.q_(25)
			.panAngle_(index.linlin(0, numPartials - 1, -10, 10))
		);
	};

	freqMultEnv = Env([2, 0.5], [beatsToTime.value(52)], \exp);
	gainEnv = Env([-40, 0, -30], [beatsToTime.value(52), beatsToTime.value(4)], 3);
	(56 * 4).do({arg i;
		var noteDur = beatsToTime.value(1/4);
		var timeOffset = noteDur * i;
		score.add(percussiveNoise.note(starttime: startTime + timeOffset, duration: noteDur * 1.1)
			.dur_(noteDur * 1.1)
			//.gain_(Env([-45, -30, -20], [beatsToTime.value(12), beatsToTime.value(8)], \lin).at(i))
			.gain_(gainEnv.at(timeOffset))
			.ris_(noteDur)
			.carFreq_(etudeBaseFreq * 2)
			.noiStartFreq_(etudeBaseFreq * 2 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
			.noiEndFreq_(etudeBaseFreq * 3 * 0.8.rrand(1.2) * freqMultEnv.at(timeOffset))
			.panAngle_(CtkControl.env(env: Env([0, 45], [noteDur], \sin), levelScale: (i.mod(2) * 2) - 1)));
	});
}.value;

score.write(
	outputPath.standardizePath,
	sampleRate: sampleRate,
	headerFormat: headerFormat,
	sampleFormat: sampleFormat,
	options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)
Stethoscope.new(s, 1);
FreqScope.new;
SFPlayer("~/Desktop/petroske_final.wav".standardizePath).gui;