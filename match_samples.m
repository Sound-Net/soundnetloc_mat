function [absclicksample, abseulersample] = match_samples(clicks, ...
    eulerangles, varargin)
%MATCH_SAMPLES Matches samples between detected clicks and euler angles
%
%  [ABSSMPLSCLK, ABSSMPLSEUL] = MATCH_SAMPLES(CLICKS, EULERANGLES)
%  calculates the absolute samples for a list of CLICKS and EULERANGLES
%  using absolute clock values. This can be used to accurately time align
%  CLICKS and EULERANGLES. ABSSMPLSCLK is [absolute sample, click heading in
%  DEGREES] and ABSSMPLSEUL is [absolute sample, heading in DEGREES] for
%  every euler angle. Input clicks should have been processed *with* zero
%  padding for accurate matching. The sample rate is assumed to be 384000
%  S/s for the output samples.
%
%  [...] = MATCH_SAMPLES(CLICKS, EULERANGLES, WAVINFO) uses the sample
%  information for each wav file in WAVINFO instead of absolute clocks.
%  Input clicks should have been processed *without* zero padding for
%  accurate matching.
%
%  [...] = MATCH_SAMPLES(..., 'EulerOffset', EULEROFFSET) adds a time offset
%  EULEROFFSET to the EULERANGLES in days. 'TimeOffset' is accepted as a
%  synonym. The offset is applied for both datetime and sample matching.
%
%  [...] = MATCH_SAMPLES(..., 'ClockSpeed', CLOCKSPEED) specifies the
%  CLOCKSPEED compared to the sample rate, e.g. 4 means that the clock is
%  running at 4 times the sample rate, usually because a 4 channel system is
%  being used. This only applies to sample matching, i.e. when a WAVINFO
%  struct is supplied.
%
%  [...] = MATCH_SAMPLES(..., 'MatchDateTime', true) forces the function to
%  match based on datetime. This can be useful because samples will be
%  counted from the first file in WAVINFO rather than from the first
%  detection.
%
%  See also GEO_REF_CLKS, PARSE_GEOREF_ARGS.

%in previous tests the sensor seems to start roughly 70000 wav samples after
%the first sample. Remember that ST samples = wavsamples*4;

SR = 384000;            % default samplerate
SAMPLEOFFSET = 0;       % add an offset CAREFUL!
ULONGMAX = 4294967295;  % the maximum value of an unsigned 32 bit long

opt = parse_georef_args(varargin);

wavinfo = opt.wavinfo;
if ~isempty(wavinfo)
    wavfiletimes = [wavinfo.datenumstart];
end

if isempty(opt.matchdatetime)
    usedatetime = isempty(wavinfo);
else
    usedatetime = opt.matchdatetime;
    %force the use of datetime even if there is a wavinfo struct.
    if (usedatetime == false && isempty(wavinfo))
        error('match_samples:noWavInfo', ...
            'Cannot use sample matching without a wavinfo struct')
    end
end

if (~usedatetime)
    disp('Using samples to match times - make sure wav data is not zero padded. Recommend using datetime matching instead');
end

%apply the euler angle time offset up front so that it is applied on both
%matching paths - it used to be applied only when sample matching.
eulerangles(:,1) = eulerangles(:,1) + opt.euleroffset;

if (usedatetime)
    if isempty(wavinfo)
        datestart = clicks(1).date;
    else
        datestart = wavinfo(1).datenumstart;
    end
end

%AIM to calculate the absolute samples for all clicks and euler angles,
%then use these samples to compare.

%Now calculate the absolute sample for each click (total samples since start)
nclicks = length(clicks);
absclicksample = zeros(nclicks,2);
for i = 1:nclicks

    absclicksample(i, 2) = rad2deg(clicks(i).angles(1));

    if (usedatetime)
        absclicksample(i, 1) = (clicks(i).date - datestart)*60*60*24*SR;
    else
        index = wavfile_index(wavfiletimes, wavinfo, clicks(i).date);
        absclicksample(i, 1) = clicks(i).startSample + wavinfo(index).wavsampletotal;
    end
end

%Now calculate the values for the euler angles in much the same way as the
%clicks
neuler = size(eulerangles,1);
abseulersample = zeros(neuler,2);
abseulersample(:,2) = eulerangles(:,5);

if (usedatetime)
    % Use microsecond time to match samples
    abseulersample(:,1) = (eulerangles(:,1) - datestart)*60*60*24*SR + SAMPLEOFFSET;
else
    %Use cumulative samples and wavinfo to match time.
    for i = 1:neuler

        time = eulerangles(i,1);
        stsample = eulerangles(i,2);

        % find the correct wav file (roughly, will be a few lost ones here)
        index = wavfile_index(wavfiletimes, wavinfo, time);

        ulongoffset = 0;
        if (stsample < wavinfo(index).stsamplestart)
            % the sample has reset within the wav file...
            ulongoffset = ULONGMAX;
        end

        %samples into wav file
        samplesin = stsample - wavinfo(index).stsamplestart + ulongoffset;
        abseulersample(i,1) = wavinfo(index).wavsampletotal + samplesin/opt.clockspeed;
    end
end

end


function index = wavfile_index(wavfiletimes, wavinfo, time)
%WAVFILE_INDEX The wav file containing a given time.
[~, index] = min(abs(wavfiletimes - time));
if (time < wavinfo(index).datenumstart)
    index = max([index-1, 1]);
end
end
