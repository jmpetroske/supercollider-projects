(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "out" +/+ "petroske_assignment_4.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var score = CtkScore.new;

var sinCosPanLaw, t60Func, equalPower;

var route1 = CtkAudio.new(2);
var route2 = CtkAudio.new(2);
var route3 = CtkAudio.new(2);

var sync_grain_buf_synth;
var fat_super_hard_sick_dubstep_reverb;

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

t60Func = { arg delay, gFac;

    var t60;

    t60 = gFac.sign * (-3 * delay / log10(gFac.abs));

    // return
    t60;
};

equalPower = { arg sig1, sig2, mix = 0.5;
	(sig1*(1-mix).sqrt) + (sig2*mix.sqrt);
};

sync_grain_buf_synth = CtkSynthDef.new(\sync_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, playbackRate = 1, envFreq, grainFreq, periodFreq = 200, buffer_left = 0, buffer_right = 0, outbus = 0, panAngle = 0.0, starttime = 0;
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
	// index = Phasor.ar(0, playbackRate / (SampleRate.ir * BufDur.kr(buffer_left)), 0, 1);
	// index = Phasor.ar(Impulse.ar(0), playbackRate / (SampleRate.ir * BufDur.kr(buffer_left)), 0, 1, starttime / BufDur.kr(buffer_left));
	// index = Line.ar(0, 1, BufDur.kr(buffer_left));
	index = ((LFSaw.ar(BufDur.kr(buffer_left).reciprocal * playbackRate, 1)) * numPeriods).floor / numPeriods;
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

fat_super_hard_sick_dubstep_reverb = CtkSynthDef.new(\reverber, {arg dur, drywet = 1, inbus, outbus, gain,
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

score.add(sync_grain_buf_synth.note(starttime: 0.01, duration: 40.3)
	.dur_(40.3)
	.dec_(0.3)
	.gain_(CtkControl.env(Env.xyc([
		[0,3,\lin],
		[0.841,3,\lin],
		[0.941,-9,\lin],
		[4,-9,\lin],
		[5,8,\lin],
		[5.72,-9,\lin],
		[13,-9,\lin],
		[14,3,\lin],
		[15,3,\lin],
		[15.54,-9,\lin],
		[17,-9,\lin],
		[19.54,3,\lin],
		[20.77,3,\lin],
		[20.87,-9,\lin],
 	])))
	.envFreq_(40)
	.grainFreq_(80)
	.periodFreq_(80)
	.buffer_left_(sample2_buf_0)
	.buffer_right_(sample2_buf_1)
	.panAngle_(0)
	.playbackRate_(0.5)
	.outbus_(route1)
);

score.add(fat_super_hard_sick_dubstep_reverb.note(starttime: 0, duration: 45)
	.dur_(45)
	.drywet_(0.3)
	.inbus_(route1)
	// .feedbackGain_(CtkControl.env(Env([-9, -9, -20], [8, 3])))
	.feedbackGain_(-12)
	.feedbackDelay_(0.2)
	.maxDelay_(1)
	.outbus_(0)
);

score.add(sync_grain_buf_synth.note(starttime: 20.2, duration: 20)
	.dur_(40)
	.ris_(0.01)
	.dec_(0.3)
	.gain_(CtkControl.env(Env.xyc([
		[20.2,25,\lin],
		[20.5,3,\lin],
		[23.2,-20,\lin],
		
		[25.04,-20,\lin],
 		[25.05,18,\lin],
		[25.35,3,\lin],
		[28.35,-20,\lin],
		
		[29.98,-20,\lin],
		[30,20,\lin],
		[30.3,3,\lin],
		[33.3,-20,\lin],

		[34.96,-20,\lin],
		[34.98,20,\lin],
		[35.3,3,\lin],
		[38,-20,\lin],
		
		[40,6,\lin],
	].collect({arg item; [item[0] - 20.2, item[1], item[2]]}))))
	.envFreq_(40)
	.grainFreq_(80)
	.periodFreq_(80)
	.buffer_left_(sample1_buf_0)
	.buffer_right_(sample1_buf_1)
	.panAngle_(0)
	.playbackRate_(1)
	.outbus_(route2)
);

score.add(fat_super_hard_sick_dubstep_reverb.note(starttime: 0, duration: 45)
	.dur_(45)
	.drywet_(0.3)
	.inbus_(route2)
	.feedbackGain_(-20)
	.feedbackDelay_(CtkControl.env(Env.xyc([
		[0,0.04,\hold],
		[24,0.031,\hold],
		[29,0.042,\hold],
		[33,0.034,\hold],
		[37,0.022,\hold],
		[40.5,0.022,\lin],
		[43,0.02199,\lin],
	])))
	.feedbackDelayRandom_(0)
	.filterAmount_(0.8)
	.maxDelay_(1)
	.lowpassMix_(0.2)
	.outbus_(0)
);

score.write(
    path: outputPath.standardizePath,
	sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels),
	action: { AppClock.sched(0, {SFPlayer(outputPath).gui;
		sample1_buf_0.free;
		sample1_buf_1.free;
		sample2_buf_0.free;
		sample2_buf_1.free;
		sample3_buf_0.free;
		sample3_buf_1.free;
		sample4_buf_0.free;
		sample4_buf_1.free;
		sample5_buf_0.free;
		sample5_buf_1.free;
		sample6_buf_0.free;
		sample6_buf_1.free;
	})}
);
)