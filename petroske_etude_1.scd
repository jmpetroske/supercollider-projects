(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "out" +/+ "petroske_etude_1.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var score = CtkScore.new;

var sinCosPanLaw;

var env_player;
var sync_grain_buf_synth, shepard_synth;
var fir_filter;

var route1 = CtkAudio.new(2);

var sample1_buf_0;
var sample1_buf_1;
var sample1_path = rootDir +/+ "sounds" +/+ "dull_jingle.wav";
var sample2_buf;
var sample2_path = rootDir +/+ "sounds" +/+ "group_1_bells.wav";
var sample3_buf;
var sample3_path = rootDir +/+ "sounds" +/+ "group_1_bells_scratchy.wav";
var sample4_buf_0;
var sample4_buf_1;
var sample4_path = rootDir +/+ "sounds" +/+ "group_1_noise_rhythmic.wav";
var sample5_buf;
var sample5_path = rootDir +/+ "sounds" +/+ "group_2_bell.wav";

var kernel1_buf = CtkBuffer(rootDir +/+ "fir" +/+ "kernels" +/+ "group_6_bell.wav");

sample1_buf_0 = CtkBuffer.playbuf(sample1_path, channels: 0);
sample1_buf_1 = CtkBuffer.playbuf(sample1_path, channels: 1);
score.add(sample1_buf_0);
score.add(sample1_buf_1);
sample2_buf = CtkBuffer.playbuf(sample2_path, channels: 0);
score.add(sample2_buf);
sample3_buf = CtkBuffer.playbuf(sample3_path, channels: 0);
score.add(sample3_buf);
sample4_buf_0 = CtkBuffer.playbuf(sample4_path, channels: 0);
sample4_buf_1 = CtkBuffer.playbuf(sample4_path, channels: 1);
score.add(sample4_buf_0);
score.add(sample4_buf_1);
sample5_buf = CtkBuffer.playbuf(sample5_path, channels: 0);
score.add(sample5_buf);

score.add(kernel1_buf);

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
		numChannels: 1,
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

{
	arg duration, gain = -6;
	
	var doubleSpeedTime = 10;
	var env1 = Env.circle([0.125, 0.25, 0.5, 1], [1,1,1,0], \exp);
	var env2 = Env.circle([0.25, 0.5, 1, 0.125], [1,1,0,1], \exp);
	var env3 = Env.circle([0.5, 1, 0.125, 0.25], [1,0,1,1], \exp);

	score.add(sync_grain_buf_synth.note(starttime: 0, duration: 50)
		.dur_(50)
		.gain_(CtkControl.env(Env([4,6,-3,-25,-25,-6,-25],[5,20,4,9,1,11])))
		.envFreq_(CtkControl.env(env1, timeScale: doubleSpeedTime, levelScale: 25 * 2.01))
		.grainFreq_(CtkControl.env(env1, timeScale: doubleSpeedTime, levelScale: 100 * 4))
		.buffer_left_(sample1_buf_0)
		.buffer_right_(sample1_buf_1)
		.panAngle_(-10)
		.playbackRate_(CtkControl.env(env1, timeScale: doubleSpeedTime, levelScale: 2))
	);
}.value;

score.add(sync_grain_buf_synth.note(starttime: 2, duration: 8.5)
	.dur_(8.5)
	.gain_(CtkControl.env(Env([-40,-12],[8.5],-2)))
	.envFreq_(40)
	.grainFreq_(CtkControl.env(Env([40,70])))
	.periodFreq_(80)
	.buffer_left_(sample4_buf_0)
	.buffer_right_(sample4_buf_1)
	.panAngle_(0)
	.playbackRate_(CtkControl.env(Env([0.5,0.7],[8.5])))
	.outbus_(route1)
);
score.add(sync_grain_buf_synth.note(starttime: 10.5, duration: 45)
	.dur_(45)
	.gain_(CtkControl.env(Env([0,-12,-6,-6,6,6,-12,-45],[0.08,5,13,9,6,6,5])))
	.envFreq_(200)
	.ris_(0.02)
	.grainFreq_(CtkControl.env(Env([200,400],[20],\exp)))
	.periodFreq_(400)
	.buffer_left_(sample4_buf_0)
	.buffer_right_(sample4_buf_1)
	.panAngle_(0)
	.playbackRate_(CtkControl.env(Env([3,0.7,1,-1,-0.7],[0.08,9.92,20,8])))
	.outbus_(route1) 
);

score.add(fir_filter.note(starttime: 0, duration: 55.5)
	.inbus_(route1)
	.outbus_(0)
	.filterBuf_(kernel1_buf)
	.drywet_(CtkControl.env(Env([0,0,1,1],[33,9,4])))
);


score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)
SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "out" +/+ "petroske_etude_1.wav").gui;