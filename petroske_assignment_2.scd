(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_assignment_2.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;
var bufPlayer;
var synthDefBPBR;
var freq, coeffs;
var allPass2ndOrderCoeffs, asmt2Synth;
var sinCosPanLaw;

var sample_buf;
var sample_path = rootDir +/+ "group_5_ding.wav";

var filterCoeffs, filterBuf, waveStartFrame, waveSkipTime;

var score = CtkScore.new;


sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

// PROBLEM 1
allPass2ndOrderCoeffs = { arg centerFreq, bandwidth, sampleRate;
	var c = (tan(pi * bandwidth / sampleRate) - 1) / (tan(pi * bandwidth / sampleRate) + 1);
	var d = -1 * cos(2 * pi * centerFreq / sampleRate);

    [-1*c, d*(1-c), 1, -1*d*(1-c), c];
};

// PROBLEM 1
// 2nd-order bandpass/reject
// bpbr is negative: band pass, bpbr is positive: band reject
synthDefBPBR = CtkSynthDef.new(\filtAnalysisLP, {
	arg freq = 440.0, bandwidth, bpbr, probeBuf, analysisBuf;
    var probe, response;
    var tanFac, cFac, a0, a1, a2, b1, b2;
	var out;

    #a0, a1, a2, b1, b2 = allPass2ndOrderCoeffs.value(freq, bandwidth, SampleRate.ir);

    // play probe signal (impulse)
    probe = PlayBuf.ar(numChannels: 1, bufnum: probeBuf);

    // test filter with probe
    response = (SOS.ar(probe, a0, a1, a2, b1, b2) + (bpbr * probe)) * 0.5;

    // record into analysis buffer
    RecordBuf.ar(
        inputArray: response,
        bufnum: analysisBuf,
        loop: 0
    );
});


// PROBLEM 2
bufPlayer = CtkSynthDef.new(\bufPlayer, {arg gain = 0, play_buf;
	var a0, a1, a2, b1, b2;
	var out;
	
	Out.ar(0, PlayBuf.ar(2, play_buf) * gain.dbamp);
});

asmt2Synth = CtkSynthDef.new(\asmt2, {
	arg dur, gain = 0, filter_coeffs_buf, ris, dec;
	var a0, a1, a2, b1, b2;
	var out;
	var env;
	
    #a0, a1, a2, b1, b2 = allPass2ndOrderCoeffs.value(
		EnvGen.ar(Env([494,494*2,494,494*3],[5,5,20],\exp)),
		EnvGen.ar(Env([5,100,400,5],[10,15,5],\lin)),
		SampleRate.ir);

	env = EnvGen.ar(Env([0, 1, 1, 0], [ris, dur - ris - dec, dec], \lin));
	
	// Filter an impulse using the filter contained in kernel_buf (subtractive synthesis)
	out = Convolution2.ar(WhiteNoise.ar, filter_coeffs_buf, framesize: filter_coeffs_buf.size);
	out = (SOS.ar(out, a0, a1, a2, b1, b2) + (-1 * out)) * 0.5;

	Out.ar([0, 1], out * gain.dbamp * env);
});

sample_buf = CtkBuffer.playbuf(sample_path);
score.add(sample_buf);


waveSkipTime = 0.454;
waveStartFrame = (waveSkipTime * SoundFile.new(sample_path).sampleRate).asInteger;
filterCoeffs = Signal.readKernel(sample_path, waveStartFrame, 494, normKind: "fir");
filterCoeffs = filterCoeffs.linearPhase;
filterBuf = CtkBuffer.collection(filterCoeffs);
score.add(filterBuf);

score.add(asmt2Synth.note(starttime: waveSkipTime - 0.1, duration: 30)
	.dur_(30)
	.gain_(CtkControl.env(Env([-8, 0], [3], \lin)))
	.ris_(0.12)
	.dec_(2)
	.filter_coeffs_buf_(filterBuf)
);
score.add(bufPlayer.note(starttime: 0, duration: 30)
	.gain_(0)
	.play_buf_(sample_buf)
);



score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_assignment_2.wav").gui;