(
// Score params
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "out" +/+ "petroske_462_final.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var score = CtkScore.new;

// utility funcs
var sinCosPanLaw, equalPower;
var sync_grain_buf_synth;
var sync_grain_buf_with_comb_synth;
var t60Func;
var schroederCoeffFunc, regaliaMitraCoeff, combDelayFunc, combT60Func;
var iirCombCoeffsFunc;
var vibSinDelTimeFunc, sinCosPanMatrix, widthMatrix, rotateMatrix, spatFilt;


// synth defs
var lesSynthDef;
var lpf_synth;
var fir_filter;
var infinite_sustain_synth;
var reverb1;
var sweeper;
var enhancer;
var part4magicFilter;

var odd_comb_synth, even_comb_synth;


// busses
var route1 = CtkAudio.new(2);
var route2 = CtkAudio.new(2);
var route3 = CtkAudio.new(2);
var route4 = CtkAudio.new(2);
var route5 = CtkAudio.new(2);
var route6 = CtkAudio.new(2);
var route7 = CtkAudio.new(2);
var route8 = CtkAudio.new(2);

// note generation funcs
var stack_grain_bufs;

// buffer loading stuff
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
var sample4_path = rootDir +/+ "sounds" +/+ "group_2_noise.wav";
var sample5_buf_0;
var sample5_buf_1;
var sample5_path = rootDir +/+ "sounds" +/+ "group_2_bell.wav";
var sample6_buf_0;
var sample6_buf_1;
var sample6_path = rootDir +/+ "sounds" +/+ "group_5_ding_2.wav";

var kernel1_buf = CtkBuffer(rootDir +/+ "fir" +/+ "kernels" +/+ "group_6_bell.wav");
var kernel2_buf = CtkBuffer(rootDir +/+ "fir" +/+ "kernels" +/+ "group_5_ding_2.wav");
score.add(kernel1_buf);
score.add(kernel2_buf);

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

// function to calculate sinus delay time
//
// Sinus Delay Time
vibSinDelTimeFunc = { arg ratio, rate;

        var delayTime;

        delayTime = (ratio - 1) / (pi * rate);

        // return
        delayTime;
};


// a function to return amplitude coefficients for Sine-Cosine Panning Law - Matrix form
// position argument in degrees
sinCosPanMatrix = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    Array2D.fromArray(
        2, // rows, outputs
        1, // columns, inputs
        [
            theta.cos,
            theta.sin
        ]
    )
};


// a function to return coefficients for Width- Matrix form
// width argument in degrees
widthMatrix = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = angleInRadians;

    Array2D.fromArray(
        2, // rows, outputs
        2, // columns, inputs
        [
            theta.cos, -1 * theta.sin,
            -1 * theta.sin, theta.cos
        ]
    )
};


// a function to return coefficients for Rotate- Matrix form
// position argument in degrees
rotateMatrix = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = angleInRadians;

    Array2D.fromArray(
        2, // rows, outputs
        2, // columns, inputs
        [
            theta.cos, theta.sin,
            -1 * theta.sin, theta.cos
        ]
    )
};


// spatial filter - a function we'll use inside our synthDef below...
spatFilt = { arg in, coeffMatrix;

    // wrap input as array if needed, for mono inputs
    in.isArray.not.if({ in = [in] });

    Mix.fill( coeffMatrix.cols, { arg i; // fill input
        UGen.replaceZeroesWithSilence(
            coeffMatrix.asArray.reshape(coeffMatrix.rows, coeffMatrix.cols).flop.at(i) * in.at(i)
        )
    })
};


sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

equalPower = { arg sig1, sig2, mix = 0.5;
	(sig1*(1-mix).sqrt) + (sig2*mix.sqrt);
};

t60Func = { arg delay, gFac;

    var t60;

    t60 = gFac.sign * (-3 * delay / log10(gFac.abs));

    // return
    t60;
};

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

// function to calculate filter coefficients
//
// IIR Comb (Even)
iirCombCoeffsFunc = { arg gain;

    var kFac, gFac, cFac;

    // convert gain to scalar
    kFac = gain.dbamp;

    // filter coefficients
    gFac = (1-kFac)/(1+kFac);
    cFac = 1-gFac.abs;

    // return
    Array.with(cFac, gFac);
};

part4magicFilter = CtkSynthDef.new(\magic_filter, {arg inbus, outbus = 0, drywet = 1;
	var dry = In.ar(inbus, 2);
	var wet;

	wet = dry;
	
	Out.ar(outbus, equalPower.(dry, wet, drywet));
});

lesSynthDef = CtkSynthDef.new(\stereoInLeslieSynth, {arg dur, gain = 0.0, ris = 0.01, dec = 0.01, mix = 1.0, panAngle = 0.0, widthAngle = 35.0, rate = 2.0, minRate = 6.0, ratio = 1.01, maxRatio = 1.01, receiveBus;
    var bus = 0;      // var to specify output bus: first output
    var numChannels = 2; // stereo bus!
    var amp;          // a few vars for synthesis
    var maxDelayTime, delayTime;
    var sig, out;     // vars assigned to audio signals
    var delay, delayPos, delayNeg;
    var modLFO;
    var ampEnv;       // var for envelope signal

    // calcs
    amp = gain.dbamp;  // convert from gain in dB to linear amplitude scale
    maxDelayTime = vibSinDelTimeFunc.value(maxRatio, minRate);
    delayTime = vibSinDelTimeFunc.value(ratio, rate);

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    // read sound in
    sig = In.ar(receiveBus, numChannels);

    // delay line modulator (unscaled)
    modLFO = SinOsc.ar(rate, pi/2);

    // modulated delay line
    delayPos = DelayC.ar(sig, maxDelayTime, modLFO.range(0, 1) * delayTime);
    delayNeg = DelayC.ar(sig, maxDelayTime, (-1 * modLFO).range(0, 1) * delayTime);

    // tremelo
    delayPos = delayPos * modLFO.range(0, 1);
    delayNeg = delayNeg * (-1 * modLFO).range(0, 1);

    // width
    delay = spatFilt.value(delayPos, rotateMatrix.value(widthAngle)) + spatFilt.value(delayNeg, rotateMatrix.value(-1 * widthAngle));

    // rotate
    delay = spatFilt.value(delay, rotateMatrix.value(panAngle));

    // out & envelope
    out = amp * ampEnv * delay;

    // out!!
    Out.ar(bus, out)
});


fir_filter = CtkSynthDef.new(\fir_filter, {
	arg inbus, outbus = 0, filterBuf, drywet = 1;

	var dry = In.ar(inbus, 2);
	var wet = Convolution2.ar(dry, filterBuf, framesize: filterBuf.size);

	Out.ar(outbus, equalPower.(dry, wet, drywet));
});

even_comb_synth = CtkSynthDef(\evencomb, {
    arg freq, minFreq, inbus, gain, combGain, outbus = 0, panAngle = 0;

	var dry, wet;
	var cFac, gFac;
	var maxDelayTime, delayTime, decayTime;
	
    dry = In.ar(inbus, 2);

    maxDelayTime = combDelayFunc.value(minFreq);
    delayTime = combDelayFunc.value(freq);
	#cFac, gFac = iirCombCoeffsFunc.value(combGain);
    decayTime = combT60Func.value(delayTime, gFac);

	wet = CombC.ar(dry, maxDelayTime, delayTime, decayTime, cFac * gFac, cFac * dry);
	wet = LeakDC.ar(wet);

    Out.ar(outbus, wet * sinCosPanLaw.value(panAngle) * gain.dbamp);
});

reverb1 = CtkSynthDef.new(\my_reverb1, {arg dur, drywet = 1, inbus, outbus, gain,
	feedbackGain = -9, maxDelay = 0.15, feedbackDelay = 0.1, feedbackDelayRandom = 0.05, filterAmount = 0.19, lowpassMix = 0.95, lowpassRand = 0.05;

	var feedbackRandomFreq = 10;
	var lowpassFreq = 4000;

	var wet;
	var filtered;
	var lowpassedWet;


	var samplerate = 20000;
	var combsparams = [
		[901, 0.805],
		[778, 0.827],
		[1011, 0.783],
		[1123, 0.764]].collect({arg item;
			[item[0] / samplerate, item[1]];
		});
	
	var allpass1params = [125 / samplerate, 0.7];
	var allpass2params = [42 / samplerate, 0.7];
	var allpass3params = [12 / samplerate, 0.7];

	var dry = In.ar(inbus, 2) * gain.dbamp;

	filtered = dry + (feedbackGain.dbamp * LocalIn.ar(2));
	filtered = combsparams.collect({arg item;
		CombC.ar(filtered, item[0], item[0], t60Func.value(item[0], item[1]));
	}).sum;

	filtered = AllpassC.ar(filtered, allpass1params[0], allpass1params[0], t60Func.value(allpass1params[0], allpass1params[1]));
	filtered = AllpassC.ar(filtered, allpass2params[0], allpass2params[0], t60Func.value(allpass2params[0], allpass2params[1]));
	filtered = AllpassC.ar(filtered, allpass3params[0], allpass3params[0], t60Func.value(allpass3params[0], allpass3params[1]));
	filtered = LeakDC.ar(filtered);
	wet = equalPower.value(dry, filtered, filterAmount);
	lowpassedWet = LPF.ar(wet, LFNoise2.ar(feedbackRandomFreq, lowpassRand, lowpassMix));
	lowpassedWet = equalPower.value(wet, lowpassedWet, lowpassMix);
	
	LocalOut.ar(
		DelayN.ar(
			lowpassedWet,
			maxDelay,
			LFNoise2.ar(feedbackRandomFreq, feedbackDelayRandom, feedbackDelay)));
	
	Out.ar(outbus, equalPower.value(dry, wet, drywet));
});

infinite_sustain_synth = CtkSynthDef.new(\infinite_sustain_synth, {
	arg dur, ris = 0.03, dec = 0.03, gain, kernelbuf, drywet = 1, outbus = 0, panAngle = 0.0;
	
	var ampEnv;
	var dry, wet;

	dry = WhiteNoise.ar;
	wet = Convolution2.ar(dry, kernelbuf, framesize: kernelbuf.size);
	
	ampEnv = EnvGen.kr(Env.linen(ris, dur - (ris + dec), dec));

	Out.ar(outbus, equalPower.(dry, wet, drywet) * ampEnv * gain.dbamp * sinCosPanLaw.(panAngle));
});

sync_grain_buf_synth = CtkSynthDef.new(\sync_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, pitchshift = 1, playbackRate = 1, envFreq, grainFreq, periodFreq = 200, buffer_left = 0, buffer_right = 0, outbus = 0, panAngle = 0.0, skiptime = 0;
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
	// index = Line.ar(0, 1, BufDur.kr(buffer_left));
	// Does the same thing as the Line.ar version, but handles playbackRate changes better in my opinion
	index = Phasor.ar(Impulse.ar(0), playbackRate / (SampleRate.ir * BufDur.kr(buffer_left)), 0, 1);
	index = (index + (skiptime / BufDur.kr(buffer_left))) % 1;
	// index = index.round(1 / numPeriods);
	index = (index * numPeriods).floor / numPeriods; // periodize the index

    granSig0 = GrainBuf.ar(
		numChannels: 2,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer_left,
		rate: pitchshift,
		pos: index,
		pan: -1
	);

	granSig1 = GrainBuf.ar(
		numChannels: 2,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer_right,
		rate: pitchshift,
		pos: index,
		pan: 1
	);

    Out.ar(outbus, gain.dbamp * ampEnv * (granSig0 + granSig1) * sinCosPanLaw.value(panAngle));
});

sync_grain_buf_with_comb_synth = CtkSynthDef.new(\sync_grain_buf_with_comb_synth, {arg dur, gain, ris = 8, dec = 8, pitchshift = 1, playbackRate = 1, envFreq, grainFreq, periodFreq = 200, buffer_left = 0, buffer_right = 0, outbus = 0, panAngle = 0.0, skiptime = 0, minFreq = 20, combFreq = 440, combGain = -60;
    var trigger;
    var granSig0, granSig1;
    var out;
    var ampEnv;
	var index;
	var numPeriods = periodFreq * BufDur.kr(buffer_left);

	var maxDelayTime, delayTime, decayTime;
    var cFac, gFac;
	
	maxDelayTime = combDelayFunc.value(minFreq);
    delayTime = combDelayFunc.value(combFreq);
    #cFac, gFac = iirCombCoeffsFunc.value(combGain);
    decayTime = combT60Func.value(delayTime, gFac);


    ampEnv = EnvGen.kr(
        Env.linen(ris, dur - (ris + dec), dec),
    );

    trigger = Impulse.ar(grainFreq); // async trigger
	// index = Line.ar(0, 1, BufDur.kr(buffer_left));
	// Does the same thing as the Line.ar version, but handles playbackRate changes better in my opinion
	index = Phasor.ar(Impulse.ar(0), playbackRate / (SampleRate.ir * BufDur.kr(buffer_left)), 0, 1);
	index = (index + (skiptime / BufDur.kr(buffer_left))) % 1;
	// index = index.round(1 / numPeriods);
	index = (index * numPeriods).floor / numPeriods; // periodize the index

    granSig0 = GrainBuf.ar(
		numChannels: 2,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer_left,
		rate: pitchshift,
		pos: index,
		pan: -1
	);
	granSig0 = CombC.ar(granSig0, maxDelayTime, delayTime, -1 * decayTime, -1 * cFac * gFac, cFac * granSig0);

	granSig1 = GrainBuf.ar(
		numChannels: 2,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer_right,
		rate: pitchshift,
		pos: index,
		pan: 1
	);
	granSig1 = CombC.ar(granSig1, maxDelayTime, delayTime, -1 * decayTime, -1 * cFac * gFac, cFac * granSig1);

    Out.ar(outbus, gain.dbamp * ampEnv * (granSig0 + granSig1) * sinCosPanLaw.value(panAngle));
});

lpf_synth = CtkSynthDef.new(\lpf_synth, {arg inbus, outbus, freq, drywet = 1;
	var insig = In.ar(inbus, 2);
	Out.ar(outbus, equalPower.value(insig, LPF.ar(insig, freq), drywet));
});

sweeper = CtkSynthDef.new(\sweeper_synth, {arg dur, gain, ris = 0.1, dec = 0.1, leftBuf, rightBuf, startFreq = 10000, endFreq = 20, drywet = 1, q = 3, panAngle = 0.0, outbus = 0;
	var ampEnv = EnvGen.kr(Env.linen(ris, dur - (ris + dec), dec));
	
	var dry = [PlayBuf.ar(1, leftBuf, loop: 1), PlayBuf.ar(1, rightBuf, loop: 1)];
	var wet = BPF.ar(dry, EnvGen.ar(Env([startFreq, endFreq], [dur], \exp)), 1 / q);
	
	Out.ar(outbus, equalPower.(dry, wet, drywet) * sinCosPanLaw.(panAngle) * ampEnv);
});

enhancer = CtkSynthDef.new(\my_enhancer, {arg inbus, outbus, preFreq = 100, postFreq = 200, processGain, mixGain = 0;
	var dry, shaped, wet;

	dry = In.ar(inbus, 2);
	shaped = dry * processGain.dbamp;
	shaped = LPF.ar(shaped, preFreq);
	shaped = shaped.tan;
	shaped = HPF.ar(shaped, postFreq);
	wet = dry + (shaped * mixGain.dbamp);

	Out.ar(outbus, wet);
});

stack_grain_bufs = {arg left_buf, right_buf, gain = 0, num, start, duration, skipdiff = 0, outbus = 0, playbackRate = 1, pitchShift = 1, grainFreq = 400, ris = 0.1, dec = 0.1, panAngle = 0.0;
	num.do({arg i;
		score.add(sync_grain_buf_synth.note(starttime: start, duration: duration)
			.dur_(duration)
			.gain_(gain)
			.envFreq_(grainFreq * playbackRate / 2)
			.grainFreq_(grainFreq * playbackRate)
			.periodFreq_(grainFreq)
			.playbackRate_(playbackRate)
			.pitchshift_(pitchShift)
			.buffer_left_(left_buf)
			.buffer_right_(right_buf)
			.skiptime_(i * skipdiff)
			.outbus_(outbus)
			.ris_(ris)
			.dec_(dec)
			.panAngle_(panAngle)
		);
	});
};

stack_grain_bufs.(left_buf: sample1_buf_0,
	right_buf: sample1_buf_1,
	gain: 22,
	num: 5,
	start: 0.001,
	duration: 20,
	skipdiff: 2,
	outbus: route1);

score.add(infinite_sustain_synth.note(starttime: 0.001, duration: 20)
	.dur_(20)
	.gain_(CtkControl.env(Env([-30, 12], 20, \lin)))
	.kernelbuf_(kernel2_buf)
	.drywet_(1)
	.outbus_(route1)
);

score.add(lpf_synth.note(starttime: 0.0001, duration: 180)
	.inbus_(route1)
	.outbus_(route2)
	.freq_(CtkControl.env(Env([100, 3000, 3000, 500, 50], [20, 18, 22, 8], 2)))
	.drywet_(1)
);

score.add(reverb1.note(starttime: 0, duration: 180)
	.dur_(180)
	.drywet_(0.3)
	.inbus_(route2)
	.outbus_(0)
	.gain_(-3)
	.feedbackGain_(-9)
	.filterAmount_(0.3)
);



[
	[21, 5 - 0.2],
	[25, 2.5 - 0.2],
	[27.5, 1.25 - 0.2],
	[28.75, 0.625 - 0.1],
	[28.75 + (0.625 * 1), 0.625 - 0.1],
	[28.75 + (0.625 * 2), 0.625 - 0.1],
	[28.75 + (0.625 * 3), 0.625 - 0.1],
	[31.25, 0.3125 - 0.07],
	[31.25 + (0.3125 * 1), 0.3125 - 0.07],
	[31.25 + (0.3125 * 2), 0.3125 - 0.07],
	[31.25 + (0.3125 * 3), 0.3125 - 0.07],
	[31.25 + (0.3125 * 4), 0.3125 - 0.07],
	[31.25 + (0.3125 * 5), 0.3125 - 0.07],
	[31.25 + (0.3125 * 6), 0.3125 - 0.07],
	[31.25 + (0.3125 * 7), 0.3125 - 0.07],
	[31.25 + (0.3125 * 8), 0.3125 - 0.07],
].do({arg data, i;
	var start = data[0];
	var dur = data[1];
	var isd_compensation = 0.2;
	
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 15,
		num: 4,
		start: start,
		duration: dur,
		skipdiff: 2,
		playbackRate: 0.5,
		pitchShift: 0.5,
		outbus: route1,
		panAngle: -5
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 3,
		start: start,
		duration: dur,
		skipdiff: 2,
		playbackRate: 1,
		outbus: route1,
		panAngle: -5
	);

	score.add(sync_grain_buf_synth.note(starttime: start, duration: 0.45)
		.dur_(0.45)
		.gain_(20)
		.envFreq_(167 / 2)
		.grainFreq_(167)
		.periodFreq_(167)
		.pitchshift_(1)
		.playbackRate_(2)
		.buffer_left_(sample6_buf_0)
		.buffer_right_(sample6_buf_1)
		.outbus_(route1)
	);

	score.add(infinite_sustain_synth.note(starttime: start - isd_compensation, duration: dur + isd_compensation)
		.dur_(dur + isd_compensation)
		.ris_(0.1)
		.gain_(12)
		.kernelbuf_(kernel2_buf)
		.drywet_(1)
		.outbus_(route1)
	);
});

{
	var timeOffset = 33.75;
	var now = 0.0;
	var dur = 35;
	var noteRateEnv = Env([1 / 0.3125, 167 / 4], 10, \exp);
	var curFreq = 1 / 0.3125;

	var isd_compensation = 0.1;
	
	while({now < dur}, {
		score.add(sync_grain_buf_synth.note(starttime: timeOffset + now, duration: 0.45)
			.dur_(0.45)
			.gain_(20)
			.envFreq_(167 / 2)
			.grainFreq_(167)
			.periodFreq_(167)
			.pitchshift_(1)
			.playbackRate_(2)
			.buffer_left_(sample6_buf_0)
			.buffer_right_(sample6_buf_1)
			.outbus_(route1)
		);

		score.add(infinite_sustain_synth.note(starttime: timeOffset + now - isd_compensation, duration: 0.45 + isd_compensation)
			.dur_(0.45 + isd_compensation)
			.ris_(0.1)
			.gain_(12)
			.kernelbuf_(kernel2_buf)
			.drywet_(1)
			.outbus_(route1)
		);

		now = now + (1 / noteRateEnv.at(now)) + 0.rrand(0.001);
	});
}.value();

stack_grain_bufs.(left_buf: sample1_buf_0,
	right_buf: sample1_buf_1,
	gain: 6,
	num: 12,
	start: 33.75,
	duration: 33,
	skipdiff: 2,
	playbackRate: 0.5,
	pitchShift: 0.5,
	outbus: route1
);

stack_grain_bufs.(left_buf: sample1_buf_0,
	right_buf: sample1_buf_1,
	gain: 6,
	num: 8,
	start: 33.75,
	duration: 33,
	skipdiff: 2,
	playbackRate: 1,
	outbus: route1
);

// Part 2
stack_grain_bufs.(
	left_buf: sample3_buf_0,
	right_buf: sample3_buf_1,
	gain: 6,
	num: 3,
	start: 66,
	duration: 19.32,
	skipdiff: 5,
	playbackRate: 1,
	pitchShift: CtkControl.env(Env(
		[1,   0.6, 1.2, 0.4, 0.4,  0.2, 0.2, 0.41, 0.41, 0.2, 0.2,  0.4, 0.4, 0.2],
		[ 2.9, 0.1, 2,   1.5, 0.03, 1.5, 0.1, 1.4,  0.03, 1.5, 0.03, 0.4, 0.03],
		\lin)),
	outbus: route3
);


// 77.52
{
	var offset = 77.52;
	var beatDelay = 0.4;

	var dur = 0.2;

	// uses 
	var comb_freq_vals = [[0, 20000, \lin], [0.001, 20000, \hold]];
	var comb_gain_vals = [[0, 0, \lin], [0.001, 0, \hold]];

	[
		[1, 0],
		[2, 1],
		[3.5, 0],
		[3.75, 0],
		[4, 0],
		[4.25, 0],
		[4.5, 2, 0.5],
		[5.0, 2, 1.6],
		[10.0, 3, 1.2],
		[14.0, 1],
		[15.0, 3, 1.6],
		[19.0, 0],
		[19.25, 1],
		[19.5, 3, 1.2],
	].do({arg data, i;
		var start = offset + (data[0] * beatDelay);
		var type = data[1];

		(type == 0).if({
			stack_grain_bufs.(left_buf: sample1_buf_0,
				right_buf: sample1_buf_1,
				gain: 17,
				num: 5,
				start: start,
				duration: dur,
				skipdiff: 2,
				playbackRate: 1,
				pitchShift: 0.75,
				outbus: 0
			);

			stack_grain_bufs.(left_buf: sample1_buf_0,
				right_buf: sample1_buf_1,
				gain: 14,
				num: 3,
				start: start,
				duration: dur,
				skipdiff: 2,
				playbackRate: 1,
				pitchShift: 1.5,
				outbus: 0
			);
		});
		(type == 1).if({
			stack_grain_bufs.(left_buf: sample1_buf_0,
				right_buf: sample1_buf_1,
				gain: 17,
				num: 5,
				start: start,
				duration: dur,
				skipdiff: 2,
				playbackRate: 1,
				pitchShift: 1.5,
				outbus: 0
			);

			stack_grain_bufs.(left_buf: sample1_buf_0,
				right_buf: sample1_buf_1,
				gain: 14,
				num: 3,
				start: start,
				duration: dur,
				skipdiff: 2,
				playbackRate: 2,
				pitchShift: 3,
				outbus: 0
			);
		});
		(type == 2).if({
			var sweepDur = data[2];
			
			score.add(sweeper.note(starttime: start, duration: sweepDur)
				.dur_(sweepDur)
				.gain_(0)
				.ris_(0.03)
				.dec_(0.03)
				.leftBuf_(sample4_buf_0)
				.rightBuf_(sample4_buf_1)
			);
		});
		(type == 3).if({
			var envDur = data[2];
			var startFreq = 2000;
			var endFreq = 500;
			var combGain = -12;
			var backToNormalDur = 0.05;

			comb_freq_vals = comb_freq_vals.add([start,                            startFreq, \exp]);
			comb_freq_vals = comb_freq_vals.add([start + envDur,                   endFreq,   \exp]);
			comb_freq_vals = comb_freq_vals.add([start + envDur + backToNormalDur, startFreq, \exp]);

			comb_gain_vals = comb_gain_vals.add([start - backToNormalDur, 0, \lin]);
			comb_gain_vals = comb_gain_vals.add([start, combGain, \lin]);
			comb_gain_vals = comb_gain_vals.add([start + envDur, combGain, \lin]);
			comb_gain_vals = comb_gain_vals.add([start + envDur + backToNormalDur, 0, \lin]);
		});
	});

	score.add(even_comb_synth.note(starttime: 0.001, duration: 180, addAction: \head, target: 1)
		.freq_(CtkControl.env(Env.xyc(comb_freq_vals)))
		.minFreq_(20)
		.inbus_(route3)
		.gain_(0)
		.combGain_(CtkControl.env(Env.xyc(comb_gain_vals)))
		.outbus_(0)
	);
}.value();

{
	var dur = 19;
	var timeOffset = 85.32;
	var now = 0;
	var rate = Env([10, 10, 7, 3.5], [10, 8, 0], \lin);

	var noteDur = 0.15;

	var pitch = Env([0.125, 1, 0.5], [10, 8], \lin);

	score.add(reverb1.note(starttime: 0, duration: 180)
		.dur_(180)
		.drywet_(CtkControl.env(Env([0, 0, 0.3], [timeOffset + 10, 8], \lin)))
		.inbus_(route4)
		.outbus_(0)
		.gain_(-3)
		.feedbackGain_(-15)
		.filterAmount_(0.2)
	);

	// enhancer = CtkSynthDef.new(\my_enhancer, {arg dur, inbus, outbus, preFreq = 100, postFreq = 200, processGain, mixGain = 0;
	score.add(enhancer.note(starttime: 0, duration: 180)
		.inbus_(route5)
		.outbus_(route4)
		.preFreq_(300)
		.postFreq_(600)
		.processGain_(12)
		.mixGain_(CtkControl.env(Env([6, 6, 24], [85.32, 5], \lin)))
	);
	
	while({now < dur}, {
		stack_grain_bufs.(left_buf: sample1_buf_0,
			right_buf: sample1_buf_1,
			gain: 17,
			num: 5,
			start: timeOffset + now,
			duration: noteDur,
			skipdiff: 2,
			playbackRate: 1,
			pitchShift: pitch.at(now) * (0.98.rrand(1.02)),
			ris: 0.06,
			dec: 0.06,
			panAngle: -15.rrand(15),
			outbus: route5
		);
		now = now + (1 / rate.at(now));
	});

	score.add(infinite_sustain_synth.note(starttime: timeOffset, duration: dur)
		.dur_(dur)
		.gain_(CtkControl.env(Env([-30, 12, -24], [10, 9] , \lin)))
		.kernelbuf_(kernel2_buf)
		.drywet_(1)
		.outbus_(route4)
	);
}.value();

// Big percussion
{
	var part4now = 0;
	var part4noteRate = 8;
	var part4noteDur = 16;
	var part4duration = 48;
	var part4gain;
	
	var time = 104.55022705;

	score.add(enhancer.note(starttime: 0, duration: 180)
		.inbus_(route6)
		.outbus_(0)
		.preFreq_(300)
		.postFreq_(800)
		.processGain_(12)
		.mixGain_(16)
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 9,
		num: 15,
		start: time,
		duration: 0.5,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 0.46,
		panAngle: 0,
		outbus: route4
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 9,
		num: 15,
		start: time,
		duration: 0.5,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 0.46,
		panAngle: 0,
		outbus: route6
	);

	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -17,
		num: 20,
		start: time,
		duration: 1.2,
		skipdiff: 2,
		playbackRate: 0.5,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 1.13,
		panAngle: -10,
		outbus: route6
	);

	// 2nd hit
	time = time + (6/7);
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 15,
		start: time,
		duration: 4.8,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 4.74,
		panAngle: 0,
		outbus: route4
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 15,
		start: time,
		duration: 0.8,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 0.74,
		panAngle: -10,
		outbus: route6
	);

	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -17,
		num: 23,
		start: time,
		duration: 5,
		skipdiff: 1.7,
		playbackRate: 0.5,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 4.93,
		panAngle: -10,
		outbus: route6
	);

	time = time + 3.8;

	// lead up 1
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 17,
		num: 5,
		start: time,
		duration: 0.15,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 0.06,
		panAngle: -10,
		outbus: route5
	);
	time = time + (1/3.5) - 0.08;
	[0, 1/3.5, 2/3.5, 3/3.5].do({arg offset;
		stack_grain_bufs.(left_buf: sample1_buf_0,
			right_buf: sample1_buf_1,
			gain: 17,
			num: 5,
			start: time + offset,
			duration: 0.15,
			skipdiff: 2,
			playbackRate: 1,
			pitchShift: 0.5,
			ris: 0.06,
			dec: 0.06,
			panAngle: -10,
			outbus: route5
		);
	});

	time = time + (4/3.5);
	// hit 3
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 15,
		start: time,
		duration: 4.8,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 4.74,
		panAngle: -10,
		outbus: route4
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 15,
		start: time,
		duration: 0.8,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 0.74,
		panAngle: -10,
		outbus: route6
	);

	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -17,
		num: 11,
		start: time,
		duration: 5,
		skipdiff: 3.1,
		playbackRate: 0.5,
		pitchShift: 0.5 * 3/2,
		ris: 0.06,
		dec: 4.93,
		panAngle: -10,
		outbus: route6
	);

	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -17,
		num: 12,
		start: time,
		duration: 5,
		skipdiff: 1.9,
		playbackRate: 0.5,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 4.93,
		panAngle: -10,
		outbus: route6
	);

	// lead up 2
	time = time + 3.8;
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 17,
		num: 5,
		start: time,
		duration: 0.15,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 0.06,
		panAngle: 0,
		outbus: route5
	);
	time = time + (1/3.5) - 0.08;
	[0, 1/3.5, 2/3.5].do({arg offset;
		stack_grain_bufs.(left_buf: sample1_buf_0,
			right_buf: sample1_buf_1,
			gain: 17,
			num: 5,
			start: time + offset,
			duration: 0.15,
			skipdiff: 2,
			playbackRate: 1,
			pitchShift: 0.5,
			ris: 0.06,
			dec: 0.06,
			panAngle: 0,
			outbus: route5
		);
	});

	time = time + (3/3.5);
	// hit 4
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 15,
		start: time,
		duration: 4.8,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 4.74,
		panAngle: 0,
		outbus: route4
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 10,
		num: 15,
		start: time,
		duration: 0.8,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 0.74,
		panAngle: -10,
		outbus: route6
	);

	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -17,
		num: 10,
		start: time,
		duration: 4,
		skipdiff: 2.8,
		playbackRate: 0.5,
		pitchShift: 1,
		ris: 0.06,
		dec: 3.93,
		panAngle: -100,
		outbus: route6
	);
	
	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -17,
		num: 7,
		start: time,
		duration: 5,
		skipdiff: 3.1,
		playbackRate: 0.5,
		pitchShift: 0.5 * 3/2,
		ris: 0.06,
		dec: 4.93,
		panAngle: -5,
		outbus: route6
	);

	stack_grain_bufs.(left_buf: sample2_buf_0,
		right_buf: sample2_buf_1,
		gain: -16,
		num: 6,
		start: time,
		duration: 4,
		skipdiff: 1.9,
		playbackRate: 0.5,
		pitchShift: 0.5,
		ris: 0.06,
		dec: 3.93,
		panAngle: -10,
		outbus: route6
	);
	time = time + 3.8;
	// Lead up 3
	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 17,
		num: 5,
		start: time,
		duration: 0.15,
		skipdiff: 2,
		playbackRate: 1,
		pitchShift: 1,
		ris: 0.06,
		dec: 0.06,
		panAngle: 0,
		outbus: route5
	);
	time = time + (1/3.5) - 0.08;
	[0, 1/3.5, 2/3.5, 3/3.5, 4/3.5].do({arg offset;
		stack_grain_bufs.(left_buf: sample1_buf_0,
			right_buf: sample1_buf_1,
			gain: 17,
			num: 5,
			start: time + offset,
			duration: 0.15,
			skipdiff: 2,
			playbackRate: 1,
			pitchShift: 0.5,
			ris: 0.06,
			dec: 0.06,
			panAngle: 0,
			outbus: route5
		);
	});
	time = time + (5/3.5);

	while({part4now < part4duration}, {

		var startRis = part4noteDur / 2;

		(part4now == 0).if({
			startRis = 0.3;
		});

		score.add(sync_grain_buf_with_comb_synth.note(starttime: time + part4now, duration: part4noteDur)
			.dur_(part4noteDur)
			.gain_(22)
			.ris_(startRis)
			.dec_(part4noteDur / 2)
			.pitchshift_(CtkControl.env(Env([2, 0.5], [16], \exp)))
			.playbackRate_(CtkControl.env(Env([2, 0.5], [16], \exp)))
			.envFreq_(625 / 2)
			.grainFreq_(625)
			.periodFreq_(625)
			.buffer_left_(sample5_buf_0)
			.buffer_right_(sample5_buf_1)
			.skiptime_(0.rrand(15))
			.outbus_(route7)
			.combFreq_(CtkControl.env(Env([2 * 625, 0.5 * 625], [16], \exp)))
			.combGain_(-50)
			.panAngle_(-10)
		);

		score.add(sync_grain_buf_with_comb_synth.note(starttime: time + part4now, duration: part4noteDur)
			.dur_(part4noteDur)
			.gain_(20)
			.ris_(startRis)
			.dec_(part4noteDur / 2)
			.pitchshift_(CtkControl.env(Env([1, 0.25], [16], \exp)))
			.playbackRate_(CtkControl.env(Env([1, 0.25], [16], \exp)))
			.envFreq_(625 / 2)
			.grainFreq_(625)
			.periodFreq_(625)
			.buffer_left_(sample5_buf_0)
			.buffer_right_(sample5_buf_1)
			.skiptime_(0.rrand(15))
			.outbus_(route7)
			.combFreq_(CtkControl.env(Env([625, 0.25 * 625], [16], \exp)))
			.combGain_(-50)
			.panAngle_(10)
		);
		
		part4now = part4now + part4noteRate;
	});

	score.add(lesSynthDef.note(starttime: time - 1, duration: 60)
		.dur_(60)
		.ratio_(1.02)
		.maxRatio_(1.02)
		.receiveBus_(route7)
		.gain_(CtkControl.env(Env([0, 20], [50], \lin)));
	);
	
	time = time + 4;
	part4now = 0;
	part4noteRate = Env([2, 0.7, 0.15, 0.1], [36, 6, 4], \lin);
	part4noteDur = Env([1.4, 0.6, 0.2], [36, 6], \lin);
	part4duration = 50;
	part4gain = Env([4, 15], [50], \lin);
	while({part4now < part4duration}, {
		var thisStart = time + (part4now + -0.3.rrand(0.3));
		var thisDur = part4noteDur.at(part4now) * 0.7.rrand(1.3);
		var thisGain = part4gain.at(part4now) + 0.rrand(5);
		score.add(sync_grain_buf_with_comb_synth.note(starttime: thisStart, duration: thisDur)
			.dur_(thisDur)
			.gain_(thisGain)
			.ris_(0.03)
			.dec_(0.03)
			.pitchshift_(1)
			.playbackRate_(CtkControl.env(Env([2, 0.5], [16], \exp)))
			.envFreq_(400)
			.grainFreq_(800)
			.periodFreq_(800)
			.buffer_left_(sample4_buf_0)
			.buffer_right_(sample4_buf_1)
			.skiptime_(0.rrand(7))
			.outbus_(route8)
			.combFreq_(CtkControl.env(Env([700.rrand(1400), 300.rrand(3000)], [thisDur], \exp)))
			.combGain_(-30)
			.panAngle_(CtkControl.env(
				Env([-30.rrand(30), -30.rrand(30)],
					[(thisDur * 0.8).rrand(thisDur)],
					[\lin])))
		);

		// arg inbus, outbus, preFreq = 100, postFreq = 200, processGain, mixGain = 0;

		
		part4now = part4now + part4noteRate.at(part4now);
	});

	score.add(enhancer.note(starttime: time - 0.01, duration: 60)
		.inbus_(route8)
		.outbus_(0)
		.preFreq_(200)
		.postFreq_(400)
		.processGain_(12)
		.mixGain_(12)
	);

	time = time + part4now;
}.value();

score.write(
    path: outputPath.standardizePath,
	sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels).memSize_(2**21),
	action: { AppClock.sched(0, {SFPlayer(outputPath).gui;}) }
);
)
