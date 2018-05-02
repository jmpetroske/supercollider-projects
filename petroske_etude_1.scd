(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_etude_1.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var score = CtkScore.new;

var sinCosPanLaw;

var env_player;
var sync_grain_buf_synth, shepard_synth;

var sample1_buf;
var sample1_path = rootDir +/+ "dull_jingle.wav";
var sample2_buf;
var sample2_path = rootDir +/+ "group_1_bells.wav";
var sample3_buf;
var sample3_path = rootDir +/+ "group_1_bells_scratchy.wav";
var sample4_buf;
var sample4_path = rootDir +/+ "group_1_noise_rhythmic.wav";
var sample5_buf;
var sample5_path = rootDir +/+ "group_2_bell.wav";

sample1_buf = CtkBuffer.playbuf(sample1_path, channels: 0);
score.add(sample1_buf);
sample2_buf = CtkBuffer.playbuf(sample2_path, channels: 0);
score.add(sample2_buf);
sample3_buf = CtkBuffer.playbuf(sample3_path, channels: 0);
score.add(sample3_buf);
sample4_buf = CtkBuffer.playbuf(sample4_path, channels: 0);
score.add(sample4_buf);
sample5_buf = CtkBuffer.playbuf(sample5_path, channels: 0);
score.add(sample5_buf);

sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

sync_grain_buf_synth = CtkSynthDef.new(\sync_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, playbackRate = 1, envFreq, grainFreq, periodFreq = 200, buffer = 0, panAngle = 0.0;
    var trigger;
    var granSig = 0;
    var out;
    var ampEnv;
	var index;
	var numPeriods = periodFreq * BufDur.kr(buffer);

    ampEnv = EnvGen.kr(
        Env.linen(ris, dur - (ris + dec), dec),
    );

    trigger = Impulse.ar(grainFreq); // async trigger
	// Does the same thing as the Line.ar version, but handles playbackRate changes better
	index = Phasor.ar(0, playbackRate / (SampleRate.ir * BufDur.kr(buffer)), 0, 1);
	index = (index * numPeriods).floor / numPeriods; // periodize the index
	// index = ((LFSaw.ar(BufDur.kr(buffer).reciprocal * playbackRate, 1) + 1) * numPeriods).floor / numPeriods;

    granSig = GrainBuf.ar(
		numChannels: 1,
		trigger: trigger,
		dur: envFreq.reciprocal,
		sndbuf: buffer,
		rate: playbackRate,
		pos: index
	);

    Out.ar(0, gain.dbamp * ampEnv * granSig * sinCosPanLaw.value(panAngle));
});

{
	arg duration, gain = -6;
	
	var doubleSpeedTime = 10;
	var env1 = Env.circle([0.125, 0.25, 0.5, 1], [1,1,1,0], \exp);
	var env2 = Env.circle([0.25, 0.5, 1, 0.125], [1,1,0,1], \exp);
	var env3 = Env.circle([0.5, 1, 0.125, 0.25], [1,0,1,1], \exp);

	score.add(sync_grain_buf_synth.note(starttime: 0, duration: 120)
		.dur_(120)
		.gain_(4)
		.envFreq_(CtkControl.env(env1, timeScale: doubleSpeedTime, levelScale: 50 * 4))
		.grainFreq_(CtkControl.env(env1, timeScale: doubleSpeedTime, levelScale: 100 * 4))
		.buffer_(sample1_buf)
		.panAngle_(0)
		.playbackRate_(CtkControl.env(env1, timeScale: doubleSpeedTime, levelScale: 4))
	);
}.value;

score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)
SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_etude_1.wav").gui;