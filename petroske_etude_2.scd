(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "out" +/+ "petroske_etude_2.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var score = CtkScore.new;

var schroederCoeffFunc, regaliaMitraCoeff, combDelayFunc, combT60Func;
var sinCosPanLaw;

var env_player;
var sync_grain_buf_synth, shepard_synth;
var odd_comb_synth, even_comb_synth;
var fir_filter;

var filtCoeffsFunc, synthDefLPHP;

var allPass2ndOrderCoeffs, synthDefBPBR;

var route1 = CtkAudio.new(2);
var route2 = CtkAudio.new(2);

var sample1_buf_0;
var sample1_buf_1;
var sample1_path = rootDir +/+ "sounds" +/+ "dull_jingle.wav";
var sample2_buf_0;
var sample2_buf_1;
var sample2_path = rootDir +/+ "sounds" +/+ "group_1_bells.wav";
var sample3_buf_0;
var sample3_buf_1;
var sample3_path = rootDir +/+ "sounds" +/+ "group_1_bells_scratchy.wav";
var sample4_buf_0;
var sample4_buf_1;
var sample4_path = rootDir +/+ "sounds" +/+ "group_1_noise_rhythmic.wav";
var sample5_buf_0;
var sample5_buf_1;
var sample5_path = rootDir +/+ "sounds" +/+ "group_2_bell.wav";
var sample6_buf_0;
var sample6_buf_1;
var sample6_path = rootDir +/+ "sounds" +/+ "group_5_ding_2.wav";

var kernel1_buf = CtkBuffer(rootDir +/+ "fir" +/+ "kernels" +/+ "group_6_bell.wav");
score.add(kernel1_buf);

sample1_buf_0 = CtkBuffer.playbuf(sample1_path, channels: 0);
sample1_buf_1 = CtkBuffer.playbuf(sample1_path, channels: 1);
sample2_buf_0 = CtkBuffer.playbuf(sample2_path, channels: 0);
sample2_buf_1 = CtkBuffer.playbuf(sample2_path, channels: 1);
sample3_buf_0 = CtkBuffer.playbuf(sample3_path, channels: 0);
sample3_buf_1 = CtkBuffer.playbuf(sample3_path, channels: 1);
sample4_buf_0 = CtkBuffer.playbuf(sample4_path, channels: 0);
sample4_buf_1 = CtkBuffer.playbuf(sample4_path, channels: 1);
sample5_buf_0 = CtkBuffer.playbuf(sample5_path, channels: 0);
sample5_buf_1 = CtkBuffer.playbuf(sample5_path, channels: 1);
sample6_buf_0 = CtkBuffer.playbuf(sample6_path, channels: 0);
sample6_buf_1 = CtkBuffer.playbuf(sample6_path, channels: 1);

score.add(sample1_buf_0);
score.add(sample1_buf_1);
score.add(sample2_buf_0);
score.add(sample2_buf_1);
score.add(sample3_buf_0);
score.add(sample3_buf_1);
score.add(sample4_buf_0);
score.add(sample4_buf_1);
score.add(sample5_buf_0);
score.add(sample5_buf_1);
score.add(sample6_buf_0);
score.add(sample6_buf_1);

schroederCoeffFunc = { arg bFac;
    var tanFac, gFac;
    tanFac = tan(pi/2 * bFac);
    gFac = (1 - tanFac) / (1 + tanFac);
    gFac;
};

regaliaMitraCoeff = { arg gain;
    var kFac;
    kFac = (gain.dbamp - 1) / 2;
    kFac;
};

combDelayFunc = { arg freq;
    var delay;
    delay = (2*freq).reciprocal;
    delay;
};


combT60Func = { arg delay, gFac;
    var t60;
    t60 = gFac.sign * (-3 * delay / log10(gFac.abs));
    t60;
};


sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

// drywet: 0 = no filtering, 1 = maximum filtering
fir_filter = CtkSynthDef.new(\fir_filter, {
	arg inbus, outbus = 0, filterBuf, drywet = 1;

	var dry = In.ar(inbus, 2);
	var wet = Convolution2.ar(dry, filterBuf, framesize: filterBuf.size);

	Out.ar(outbus, XFade2.ar(dry, wet, (drywet * 2) - 1));
});

filtCoeffsFunc = { arg freq, sampleRate;
    var tanFac, cFac, a0, a1, b1;

    tanFac = tan(pi * freq / sampleRate);
    cFac = (tanFac - 1) / (tanFac + 1);

    a0 = cFac;
    a1 = 1;
    b1 = -1 * cFac;

    Array.with(a0, a1, b1);
};

// lphp: negative = lp, positive = hp
allPass2ndOrderCoeffs = { arg centerFreq, bandwidth, sampleRate;
	var c = (tan(pi * bandwidth / sampleRate) - 1) / (tan(pi * bandwidth / sampleRate) + 1);
	var d = -1 * cos(2 * pi * centerFreq / sampleRate);

    [-1*c, d*(1-c), 1, -1*d*(1-c), c];
};

// PROBLEM 1
// 2nd-order bandpass/reject
// bpbr is negative: band pass, bpbr is positive: band reject
synthDefBPBR = CtkSynthDef.new(\filtAnalysisLP, {
	arg freq = 440.0, q, bpbr, drywet, inbus, outbus = 0;
	var bandwidth;
    var tanFac, cFac, a0, a1, a2, b1, b2;
	var dry, wet;

	bandwidth = freq / q;

    #a0, a1, a2, b1, b2 = allPass2ndOrderCoeffs.value(freq, bandwidth, SampleRate.ir);

	dry = In.ar(inbus, 2);
    wet = (SOS.ar(dry, a0, a1, a2, b1, b2) + (bpbr * dry)) * 0.5;

    // record into analysis buffer
	Out.ar(outbus, XFade2.ar(dry, wet, (drywet * 2) - 1));
});

sync_grain_buf_synth = CtkSynthDef.new(\sync_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, playbackRate = 1, envFreq, grainFreq, periodFreq = 200, buffer_left = 0, buffer_right = 0, outbus = 0, panAngle = 0.0;
    var trigger;
    var granSig0, granSig1;
    var out;
    var ampEnv;
	var index;
	var numPeriods = periodFreq * BufDur.kr(buffer_left);

    ampEnv = EnvGen.kr(
        Env.linen(ris, dur - (ris + dec), dec),
    );

    trigger = Impulse.ar(grainFreq); // async trigger
	// Does the same thing as the Line.ar version, but handles playbackRate changes better
	index = Phasor.ar(0, playbackRate / (SampleRate.ir * BufDur.kr(buffer_left)), 0, 1);
	index = (index * numPeriods).floor / numPeriods; // periodize the index
	// index = ((LFSaw.ar(BufDur.kr(buffer).reciprocal * playbackRate, 1) + 1) * numPeriods).floor / numPeriods;

    granSig0 = GrainBuf.ar(
		numChannels: 2,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer_left,
		rate: playbackRate,
		pos: index,
		pan: -1
	);

	granSig1 = GrainBuf.ar(
		numChannels: 2,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer_right,
		rate: playbackRate,
		pos: index,
		pan: 1
	);

    Out.ar(outbus, gain.dbamp * ampEnv * (granSig0 + granSig1) * sinCosPanLaw.value(panAngle));
});


odd_comb_synth = CtkSynthDef(\oddcomb, {
    arg freq, minFreq, bFac, inbus, outbus = 0, dur, gain, combGain;
    var src, oddComb, maxDelayTime, delayTime, g, decayTime, env, freqEnv;
    var gFac, kFac, amp;

    amp = gain.dbamp;

    src = In.ar(inbus, 2);

     // comb filter calcs
    maxDelayTime = combDelayFunc.value(minFreq);
    delayTime = combDelayFunc.value(freq);
    gFac = schroederCoeffFunc.value(bFac);
    decayTime = combT60Func.value(delayTime, gFac);
    kFac = regaliaMitraCoeff.value(combGain);

    // test filter
    oddComb = src + (kFac * AllpassC.ar(src, maxDelayTime, delayTime, -1 * decayTime, 1, src));    // need to invert decayTime to mirror g for odd


    Out.ar(outbus, oddComb /* env*/);
});

even_comb_synth = CtkSynthDef(\evencomb, {
    arg freq, minFreq, bFac, inbus, outbus = 0, dur, gain, combGain;
    var src, maxDelayTime, delayTime, g, decayTime, ampPlay, evenComb;
    var gFac, kFac, amp;

    amp = gain.dbamp;

    src = In.ar(inbus, 2);

     // comb filter calcs
    maxDelayTime = combDelayFunc.value(minFreq);
    delayTime = combDelayFunc.value(freq);
    gFac = schroederCoeffFunc.value(bFac);
    decayTime = combT60Func.value(delayTime, gFac);
    kFac = regaliaMitraCoeff.value(combGain);

    evenComb = src + (kFac * AllpassC.ar(src, maxDelayTime, delayTime, decayTime, -1, src));


    Out.ar(outbus, evenComb /* env*/);
});

synthDefLPHP = CtkSynthDef.new(\filtAnalysisLP, { arg freq = 440.0, inbus, drywet = 1, outbus = 0, lphp = 1;
    var tanFac, cFac, a0, a1, b1;

	var dry, wet;
	
    #a0, a1, b1 = filtCoeffsFunc.value(freq, SampleRate.ir);

	dry = In.ar(inbus, 2);
	wet = 0.5 * FOS.ar(dry, a0, a1, b1, mul: -1 * lphp.sign, add: dry);

	Out.ar(outbus, XFade2.ar(dry, wet, (drywet * 2) - 1));
});

{
	var freqModifiers = [0.25, 0.5, 1, 2, 4].collect({arg i; [i, i * 32/27, i * 3/2]}).flatten.sort;
	var numFreqs = freqModifiers.size;
	var width = 5;
	var lowIndex = Env([0, numFreqs - width - 1], [40], \lin);

	var refFreq = 494;
	var playbackRate = 1;
	var q = 1;
	
	var now = 0.0;
	var totalDuration = 40;
	var panAmount = Env([0,45],[totalDuration], -20);
	while({now < totalDuration}, {
		var freqRatio = freqModifiers[lowIndex[now].rrand(lowIndex[now] + width).round(1)];
		score.add(sync_grain_buf_synth.note(starttime: now, duration: sample6_buf_0.duration * playbackRate.reciprocal)
			.dur_(sample6_buf_0.duration * playbackRate.reciprocal)
			.gain_(Env([0, 12, 24, 0], [5, totalDuration - 10, 5]).at(now) + 5)
			.grainFreq_(refFreq * freqRatio)
			.envFreq_(playbackRate * refFreq / (2 * q))
			.playbackRate_(playbackRate)
			.periodFreq_(refFreq)
			.buffer_left_(sample6_buf_0)
			.buffer_right_(sample6_buf_1)
			.panAngle_((-1 * panAmount[now]).rrand(panAmount[now]))
			.outbus_(route1)
		);
		now = now + 0.1.rrand(0.2);
	});

	{
		var freqEnv = Env([2, 2, 1, 1, 4, 4, 2, 2, 8, 8, 4, 4, 16, 16, 8, 8] * refFreq, [4,1,4,1,4,1,4,1,4,1,4,1,4,1,4,1,4,1], \exp);
		score.add(synthDefBPBR.note(starttime: 0, duration: 45)
			.inbus_(route1)
			.outbus_(0)
			.freq_(CtkControl.env(freqEnv))
			.q_(CtkControl.env(Env([2,2,1,1,2,2,1,1,2,2,1,1,2,2,1,1],[19,1,4,1,4,1,4,1,4,1,4,1])))
			.bpbr_(-1)
			.drywet_(1)
		);
	}.value
}.value;


Array.series(7, 5, 5).do({arg now, i;
	var refFreq = 788;
	var q = 1;
	var freqRatio = 1;
	var playbackRate = 1;
	now = now + -0.1.rrand(0.1);
	score.add(sync_grain_buf_synth.note(starttime: now, duration: 2.5)
		.dur_(2.5)
		.gain_(1)
		.dec_(0.3)
		.grainFreq_(refFreq * freqRatio)
		.envFreq_(playbackRate * refFreq / (2 * q))
		.playbackRate_(playbackRate)
		.periodFreq_(refFreq)
		.buffer_left_(sample5_buf_0)
		.buffer_right_(sample5_buf_1)
		.panAngle_(CtkControl.env(Env([-30.rrand(-20), 20.rrand(30)] * ((2 * i.mod(2)) - 1), [2.5])))
		.outbus_(route2)
	);
});

// lphp: negative = lp, positive = hp
// synthDefLPHP = CtkSynthDef.new(\filtAnalysisLP, { arg freq = 440.0, inbus, drywet = 1, outbus = 0, lphp = 1;

score.add(synthDefLPHP.note(starttime: 0, duration: 45)
	.freq_(CtkControl.env(Env([1500, 500], [45], \exp)))
	.inbus_(route2)
	.outbus_(0)
	.drywet_(1)
	.lphp_(1)
);

score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)
SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "out" +/+ "petroske_etude_2.wav").gui;