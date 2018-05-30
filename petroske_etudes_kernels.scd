(
var rootDir = thisProcess.nowExecutingPath.asString.dirname;
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var make_fir_kernel = {
	arg sourceFilePath, skipTime = 0, analysisFreq, analysisQ, normKind = 'fir';

	var startFrame, filterCoeffs, filterBuf;
	
	startFrame = (skipTime * SoundFile.new(sourceFilePath).sampleRate).asInteger;
	filterCoeffs = Signal.readKernel(sourceFilePath, startFrame, analysisFreq, analysisQ * 2, normKind: normKind);
	filterCoeffs = filterCoeffs.linearPhase;

	filterCoeffs;
};

var make_and_write_fir_kernel = {
	arg sourceFilePath, outputFilePath, skipTime, analysisFreq, analysisQ, normKind, plot = true;

	var kernel = make_fir_kernel.value(sourceFilePath, skipTime, analysisFreq, analysisQ, normKind);
	plot.if({
		kernel.plot(
			name: "Filter Kernel - Impulse Response",
			bounds: Rect.fromPoints(Point.new(400, 0), Point.new(800, 300))
		);
		plotKernelSpectrum.value(kernel, -60, 3);
	});
	kernel.writeKernel(outputFilePath, sampleRate, headerFormat, sampleFormat)
};

var plotKernelSpectrum = {
	arg kernel,
	plotDbMin,
	plotDbMax,
	rect = plotKernelSpectrum.value(kernel, -60, 3, Rect.fromPoints(Point.new(800, 0), Point.new(1200, 300)));
	
	var fftResponse, fftMagnitude;

	// FFT analysis here!
	fftResponse = fft(
		kernel.as(Signal),
		Signal.newClear(kernel.size),
		Signal.fftCosTable(kernel.size)
	);

	// find (& trim magnitude)
	fftMagnitude = fftResponse.magnitude;
	fftMagnitude = fftMagnitude.copyFromStart((kernel.size/2).asInteger);


	// look at the magnitude spectrum of the kernel
	fftMagnitude.copyFromStart((kernel.size/2).asInteger).ampdb.plot(
		name: "Filter Magnitude Response",
		// bounds: Rect.fromPoints(Point.new(800, 0), Point.new(1200, 300)),
		bounds: rect,
		minval: plotDbMin,
		maxval: plotDbMax
	);
};


// 1765 reference frequency found using audacity
// From group 6, person one. group_6_bell_for_fir.wav is a section of the recoreding that has only been amplified
// make_and_write_fir_kernel.value(rootDir +/+ "fir" +/+ "src" +/+ "group_6_bell.wav", rootDir +/+ "fir" +/+ "kernels" +/+ "group_6_bell.wav", 0, 1765, 150, 'fir', plot: false);

make_and_write_fir_kernel.value(rootDir +/+ "fir" +/+ "src" +/+ "group_5_ding_2.wav", rootDir +/+ "fir" +/+ "kernels" +/+ "group_5_ding_2.wav", 0.387, 167, 20, 'fir', plot: false);
)



