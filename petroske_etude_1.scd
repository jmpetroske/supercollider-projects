(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_etude_1.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

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
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    trigger = Impulse.ar(grainFreq); // async trigger
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

score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

