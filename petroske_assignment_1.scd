// PROBLEM 1
(
var additiveFunc;

var score = CtkScore.new;

var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_1.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

var buf_player_synth;

var sample1_buf;
var sample1_path = rootDir +/+ "dull_jingle.wav";

sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

buf_player_synth = CtkSynthDef.new(\buf_player_synth, {arg dur, gain = 0.0, ris = 0.01, dec = 0.01, rate = 1, panAngle = 0.0, loop = 0, buffer = 0;
    var bus = 0;
    var numChannels = 1;
    var sig, out;
    var amp;
    var ampEnv;

    amp = gain.dbamp;

    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    sig = PlayBuf.ar(numChannels, buffer,  BufRateScale.kr(buffer) * rate, loop: loop);
    sig = ampEnv * amp * sig;

    out = sinCosPanLaw.value(panAngle) * sig;

    Out.ar(bus, out)
});


additiveFunc = {arg start, dur, gain = -12, ris = 0.1, dec = 0.1, tuples;
    tuples.do({arg tuple, i;
        score.add(buf_player_synth.note(starttime: start, duration: dur)
            .dur_(dur)
            .gain_(gain + tuple[0])
            .ris_(ris)
            .dec_(dec)
            .rate_(tuple[1])
            .buffer_(tuple[2])
            .loop_(1)
        );
    })
};

sample1_buf = CtkBuffer.playbuf(sample1_path.standardizePath, channels: 0);
score.add(sample1_buf);

additiveFunc.value(
    start: 0,
    dur: 30,
    gain: 12,
    tuples: [
        [0, 1, sample1_buf],
        [-3, 0.8, sample1_buf],
        [-1, 1.3, sample1_buf],
        [0, 2, sample1_buf]]
);

score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

// PROBLEM 2
(
var additiveFunc;

var score = CtkScore.new;

var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_2.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

var buf_player_synth;

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


sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

buf_player_synth = CtkSynthDef.new(\buf_player_synth, {arg dur, gain = 0.0, ris = 0.01, dec = 0.01, rate = 1, panAngle = 0.0, loop = 0, buffer = 0;
    var bus = 0;
    var numChannels = 2;
    var sig, out;
    var amp;
    var ampEnv;

    amp = gain.dbamp;

    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    sig = PlayBuf.ar(numChannels, buffer,  BufRateScale.kr(buffer) * rate, loop: loop);
    sig = ampEnv * amp * sig;

    out = sinCosPanLaw.value(panAngle) * sig;

    Out.ar(bus, out)
});


additiveFunc = {arg start, dur, gain = -12, ris = 0.1, dec = 0.1, tuples;
    tuples.do({arg tuple, i;
        score.add(buf_player_synth.note(starttime: start, duration: dur)
            .dur_(dur)
            .ris_(ris)
            .dec_(dec)
            .loop_(1)
            .buffer_(tuple[0])
            .gain_(gain + tuple[1])
            .rate_(tuple[2])
            .panAngle_(tuple[3])
        );
    })
};

sample1_buf = CtkBuffer.playbuf(sample1_path);
score.add(sample1_buf);
sample2_buf = CtkBuffer.playbuf(sample2_path);
score.add(sample2_buf);
sample3_buf = CtkBuffer.playbuf(sample3_path);
score.add(sample3_buf);
sample4_buf = CtkBuffer.playbuf(sample4_path);
score.add(sample4_buf);
sample5_buf = CtkBuffer.playbuf(sample5_path);
score.add(sample5_buf);



additiveFunc.value(
    start: 0,
    dur: 30,
    gain: 0,
    tuples: [
        [sample1_buf, -3, 1, -20],
        [sample2_buf, -3, 1, 15],
        [sample3_buf, -3, 1, 20],
        [sample4_buf, 0, 1, -5],
        [sample5_buf, -3, 1, -13]]
);

score.write(
    path: outputPath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

// PROBLEM 3
(
var additiveFunc;

var score = CtkScore.new;

var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_3.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

var buf_player_synth, async_grain_buf_synth;

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


sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

async_grain_buf_synth = CtkSynthDef.new(\async_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, playbackRate = 1, envFreq, grainFreq, buffer = 0, panAngle = 0.0;
    var trigger;
    var granSig = 0;
    var out;
    var ampEnv;
	var index;
	var numPeriods = 200 * BufDur.kr(buffer);

    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    trigger = Dust.ar(grainFreq); // async trigger
	index = Line.ar(0, numPeriods, dur).floor / numPeriods;

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

score.add(async_grain_buf_synth.note(starttime: 0, duration: sample3_buf.duration)
	.dur_(sample3_buf.duration)
	.gain_(12)
	.envFreq_(400)
	.grainFreq_(788)
	.buffer_(sample3_buf)
);

score.write(
    path: outputPath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

// PROBLEM 4
(
var additiveFunc;

var score = CtkScore.new;

var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_4.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

var buf_player_synth, async_grain_buf_synth;

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


sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

async_grain_buf_synth = CtkSynthDef.new(\async_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, playbackRate = 1, envFreq, grainFreq, buffer = 0, panAngle = 0.0;
    var trigger;
    var granSig = 0;
    var out;
    var ampEnv;
	var index;
	var numPeriods = 200 * BufDur.kr(buffer);

    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    trigger = Dust.ar(grainFreq); // async trigger
	index = ((LFSaw.ar(BufDur.kr(buffer).reciprocal * playbackRate, 1) + 1) * numPeriods).floor / numPeriods;
	//	index = Line.ar(0, numPeriods, dur).floor / numPeriods;

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


score.add(async_grain_buf_synth.note(starttime: 0, duration: 30)
	.dur_(30)
	.gain_(6)
	.envFreq_(400)
	.grainFreq_(788)
	.playbackRate_(2)
	.buffer_(sample1_buf)
);
// score.add(async_grain_buf_synth.note(starttime: 0, duration: sample2_buf.duration)
// 	.dur_(sample2_buf.duration)
// 	.gain_(3)
// 	.envFreq_(400)
// 	.grainFreq_(788)
// 	.buffer_(sample2_buf)
// );
score.add(async_grain_buf_synth.note(starttime: 0, duration: 30)
	.dur_(30)
	.gain_(3)
	.envFreq_(400)
	.grainFreq_(788)
	.buffer_(sample3_buf)
);
score.add(async_grain_buf_synth.note(starttime: 0, duration: 30)
	.dur_(30)
	.gain_(-9)
	.envFreq_(100)
	.grainFreq_(300)
	.playbackRate_(0.2)
	.buffer_(sample4_buf)
	.panAngle_(-20)
);
score.add(async_grain_buf_synth.note(starttime: 0, duration: 30)
	.dur_(30)
	.gain_(CtkControl.env(Env([-12, 3, -3], [20, 10])))
	.envFreq_(40)
	.grainFreq_(100)
	.playbackRate_(CtkControl.env(Env([0.6, 0.4, 0.6, 0.4], [10, 10, 10])))
	.buffer_(sample5_buf)
);

score.write(
    path: outputPath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_1.wav").gui;
SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_2.wav").gui;
SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_3.wav").gui;
SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_4.wav").gui;