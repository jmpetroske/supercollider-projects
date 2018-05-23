(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var outputPath = rootDir +/+ "petroske_assignment_5.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

var sync_grain_buf_synth;
var score = CtkScore.new;
var route1 = CtkAudio.new(2);

var p1, p2;

var firCombCoeffsFunc = { arg gain;
    var kFac, b0, bM;
    kFac = gain.dbamp;
    b0 = (1+kFac)/2;
    bM = (1-kFac)/2;
    [b0, bM];
};

var combDelayFunc = { arg freq;
    (2*freq).reciprocal;
};

var widthMatrix = { arg angleInDegrees = 0;
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
var rotateMatrix = { arg angleInDegrees = 0;
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


var spatFilt = { arg in, coeffMatrix;
    in.isArray.not.if({ in = [in] });
    Mix.fill( coeffMatrix.cols, { arg i;
        UGen.replaceZeroesWithSilence(
            coeffMatrix.asArray.reshape(coeffMatrix.rows, coeffMatrix.cols).flop.at(i) * in.at(i)
        )
    })
};

// var sample1_buf_0;
// var sample1_buf_1;
// // var sample1_path = rootDir +/+ "sounds" +/+ "group_1_bells.wav";
// var sample1_path = rootDir +/+ "sounds" +/+ "group_2_noise.wav";
// sample1_buf_0 = CtkBuffer.playbuf(sample1_path, channels: 0);
// sample1_buf_1 = CtkBuffer.playbuf(sample1_path, channels: 1);
// score.add(sample1_buf_0);
// score.add(sample1_buf_1);

sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -1 * angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

p1 = CtkSynthDef.new(\p1_filter, {
    arg inbus, outbus = 0, widthAngle, filterFreq, minFilterFreq, filterGain = -100;
    
    var insig = In.ar(inbus, 2);
    var combed;
    var maxDelayTime, delayTime;
    var b0, bM;

    maxDelayTime = combDelayFunc.value(minFilterFreq);
    delayTime = combDelayFunc.value(filterFreq);
    #b0, bM = firCombCoeffsFunc.value(filterGain);
    
    combed = DelayC.ar(insig, maxDelayTime, delayTime, bM * [1, -1], b0 * insig);

    combed = spatFilt.value(combed, rotateMatrix.value(widthAngle));

    Out.ar(outbus, combed);
});

// Zolzer's rotary loudspeaker effect
p2 = CtkSynthDef.new(\p2_filter, { arg inbus, outbus = 0, modFreq, maxResampleRatio;
    
    var insig = In.ar(inbus, 2);
    var modulator = SinOsc.ar(modFreq);
    var normalizedModulator = (modulator + 1) / 2; // a value between 0 and 1
    var oppositeNormalizedModulator = (-1 * modulator + 1) / 2; // a value between 0 and 1
    var out;

	// normalizedModulator used so that we dont have a negative delay time
    // out = [DelayC.ar(insig[0], maxResampleRatio, normalizedModulator         * maxResampleRatio) * (1 - modulator),
    //        DelayC.ar(insig[0], maxResampleRatio, oppositeNormalizedModulator * maxResampleRatio) * (1 + modulator)];
    // out = [out[0] + (out[1] * 1 / 2.sqrt),
	// 	   out[1] + (out[0] * 1 / 2.sqrt)];
	out = [DelayC.ar(insig[0], maxResampleRatio, normalizedModulator         * maxResampleRatio),
           DelayC.ar(insig[1], maxResampleRatio, oppositeNormalizedModulator * maxResampleRatio)];
	out = spatFilt.value(out, rotateMatrix.value(modulator));
	
    Out.ar(outbus, out);
});


// // Testing
// sync_grain_buf_synth = CtkSynthDef.new(\sync_grain_buf_synth, {arg dur, gain, ris = 0.1, dec = 0.1, playbackRate = 1, envFreq, grainFreq, periodFreq = 200, buffer_left = 0, buffer_right = 0, outbus = 0, panAngle = 0.0, starttime = 0;
//     var trigger;
//     var granSig0, granSig1;
//     var out;
//     var ampEnv;
// 	var index;
// 	var numPeriods = periodFreq * BufDur.kr(buffer_left);

//     ampEnv = EnvGen.kr(
//         Env.linen(ris, dur - (ris + dec), dec),
//     );

//     trigger = Impulse.ar(grainFreq); // async trigger
// 	index = ((LFSaw.ar(BufDur.kr(buffer_left).reciprocal * playbackRate, 1)) * numPeriods).floor / numPeriods;
// 	index = (index * numPeriods).floor / numPeriods; // periodize the index

//     granSig0 = GrainBuf.ar(
// 		numChannels: 2,
// 		trigger: trigger,
// 		dur: envFreq.reciprocal,
// 		sndbuf: buffer_left,
// 		rate: playbackRate,
// 		pos: index,
// 		pan: -1
// 	);

// 	granSig1 = GrainBuf.ar(
// 		numChannels: 2,
// 		trigger: trigger,
// 		dur: envFreq.reciprocal,
// 		sndbuf: buffer_right,
// 		rate: playbackRate,
// 		pos: index,
// 		pan: 1
// 	);

//     Out.ar(outbus, gain.dbamp * ampEnv * (granSig0 + granSig1) * sinCosPanLaw.value(panAngle));
// });

// score.add(sync_grain_buf_synth.note(starttime: 0.01, duration: 15)
// 	.dur_(40)
// 	.ris_(0.01)
// 	.dec_(0.3)
// 	.gain_(0)
// 	.envFreq_(40)
// 	.grainFreq_(80)
// 	.periodFreq_(80)
// 	.buffer_left_(sample1_buf_0)
// 	.buffer_right_(sample1_buf_1)
// 	.panAngle_(0)
// 	.playbackRate_(1)
// 	.outbus_(route1)
// );

// score.add(p2.note(starttime: 0, duration: 16)
// 	.inbus_(route1)
// 	.outbus_(0)
// 	.modFreq_(0.3)
// 	.maxResampleRatio_(0.01)
// );

// score.add(sync_grain_buf_synth.note(starttime: 15.01, duration: 15)
// 	.dur_(40)
// 	.ris_(0.01)
// 	.dec_(0.3)
// 	.gain_(0)
// 	.envFreq_(40)
// 	.grainFreq_(80)
// 	.periodFreq_(80)
// 	.buffer_left_(sample1_buf_0)
// 	.buffer_right_(sample1_buf_1)
// 	.panAngle_(0)
// 	.playbackRate_(1)
// 	.outbus_(route1)
// );

// //    arg inbus, outbus = 0, widthAngle, filterFreq, minFilterFreq, filterGain = -100;
// score.add(p1.note(starttime: 15, duration: 16)
// 	.inbus_(route1)
// 	.outbus_(0)
// 	.widthAngle_(CtkControl.env(Env([-45, 45], 15, \lin)))
// 	.filterFreq_(800)
// 	.minFilterFreq_(800)
// );

// score.write(
//     path: outputPath.standardizePath,
// 	sampleRate: sampleRate,
//     headerFormat: headerFormat,
//     sampleFormat: sampleFormat,
//     options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
// );
)

// SFPlayer(thisProcess.nowExecutingPath.asString.dirname +/+ "petroske_assignment_5.wav").gui;