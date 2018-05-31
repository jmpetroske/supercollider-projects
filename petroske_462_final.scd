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
var t60Func;

// synth defs
var lpf_synth;
var fir_filter;
var infinite_sustain_synth;
var reverb1;

// busses
var route1 = CtkAudio.new(2);
var route2 = CtkAudio.new(2);
var route3 = CtkAudio.new(2);
var route4 = CtkAudio.new(2);

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

fir_filter = CtkSynthDef.new(\fir_filter, {
	arg inbus, outbus = 0, filterBuf, drywet = 1;

	var dry = In.ar(inbus, 2);
	var wet = Convolution2.ar(dry, filterBuf, framesize: filterBuf.size);

	Out.ar(outbus, equalPower.(dry, wet, drywet));
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

lpf_synth = CtkSynthDef.new(\lpf_synth, {arg inbus, outbus, freq, drywet = 1;
	var insig = In.ar(inbus, 2);
	Out.ar(outbus, equalPower.value(insig, LPF.ar(insig, freq), drywet));
});

stack_grain_bufs = {arg left_buf, right_buf, gain = 0, num, start, duration, skipdiff = 0, outbus = 0, playbackRate = 1, grainFreq = 400;
	num.do({arg i;
		score.add(sync_grain_buf_synth.note(starttime: start, duration: duration)
			.dur_(20)
			.gain_(gain)
			.envFreq_(grainFreq * playbackRate / 2)
			.grainFreq_(grainFreq * playbackRate)
			.periodFreq_(grainFreq)
			.playbackRate_(playbackRate)
			.pitchshift_(playbackRate)
			.buffer_left_(left_buf)
			.buffer_right_(right_buf)
			.skiptime_(i * skipdiff)
			.outbus_(outbus)
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
		gain: 17,
		num: 5,
		start: start,
		duration: dur,
		skipdiff: 2,
		playbackRate: 0.5,
		outbus: route1
	);

	stack_grain_bufs.(left_buf: sample1_buf_0,
		right_buf: sample1_buf_1,
		gain: 14,
		num: 3,
		start: start,
		duration: dur,
		skipdiff: 2,
		playbackRate: 1,
		outbus: route1
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
	var noteRateEnv = Env([1 / 0.3125, 167 / 4], 10, \lin);
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

score.write(
    path: outputPath.standardizePath,
	sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels).memSize_(2**21),
	action: { AppClock.sched(0, {SFPlayer(outputPath).gui;}) }
);
)
