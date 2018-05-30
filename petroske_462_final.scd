(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "out" +/+ "petroske_assignment_4.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var score = CtkScore.new;

var sinCosPanLaw, equalPower;
var sync_grain_buf_synth;

var lpf_synth;
var fir_filter;
var infinite_sustain_synth;

var route1 = CtkAudio.new(2);

var stack_grain_bufs;

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

fir_filter = CtkSynthDef.new(\fir_filter, {
	arg inbus, outbus = 0, filterBuf, drywet = 1;

	var dry = In.ar(inbus, 2);
	var wet = Convolution2.ar(dry, filterBuf, framesize: filterBuf.size);

	Out.ar(outbus, equalPower.(dry, wet, drywet));
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

score.add(lpf_synth.note(starttime: 0, duration: 180)
	.inbus_(route1)
	.outbus_(0)
	.freq_(CtkControl.env(Env([100, 3000], 20, 2)))
	.drywet_(1)
);


stack_grain_bufs.(left_buf: sample1_buf_0,
	right_buf: sample1_buf_1,
	gain: 17,
	num: 5,
	start: 20.3,
	duration: 10,
	skipdiff: 2,
	playbackRate: 0.5,
	outbus: route1
);

stack_grain_bufs.(left_buf: sample1_buf_0,
	right_buf: sample1_buf_1,
	gain: 14,
	num: 3,
	start: 20.3,
	duration: 10,
	skipdiff: 2,
	playbackRate: 1,
	outbus: route1
);

score.add(sync_grain_buf_synth.note(starttime: 20.3, duration: 0.42)
	.dur_(0.85)
	.gain_(20)
	.envFreq_(167 / 2)
	.grainFreq_(167)
	.periodFreq_(167)
	.pitchshift_(1)
	.playbackRate_(2)
	.buffer_left_(sample6_buf_0)
	.buffer_right_(sample6_buf_1)
	.outbus_(0)
);

score.add(infinite_sustain_synth.note(starttime: 20.1, duration: 10)
	.dur_(20)
	.ris_(0.1)
	.gain_(12)
	.kernelbuf_(kernel2_buf)
	.drywet_(1)
	.outbus_(0)
);


score.write(
    path: outputPath.standardizePath,
	sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels),
	action: { AppClock.sched(0, {SFPlayer(outputPath).gui;}) }
);
)
