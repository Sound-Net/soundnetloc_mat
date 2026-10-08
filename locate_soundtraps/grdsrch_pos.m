function [location_final, chi2val, grdsurf, bearingoffset] = grdsrch_pos(clkgeobearings, srclocations, varargin)
%GRDSRCH_POS Locates the soundtrap using a grid search
%   [LOCATION_FINAL, CHI2VAL, GRDSURF] = GRDSRCH_ST_POS(CLKGEOBEARINGS,
%   SRCLOCATION) uses a grid search to find the latitiude and
%   longitude location of a small hydrophone array that is capable of
%   calculating geo-referenced horizontal and slant bearings from a known
%   depth(s). CLKGEOBEARINGS (horizontal angle, slant angle) is a list of
%   horizontal and slant bearings in RADIANS. SRCLOCATIONS is a
%   list of locations for each clicks (latitiude, longitude, depth)
%   corresponding to CLKGEOBEARINGS. (Note:  these lists should be the
%   same length). Note that depth is the difference in depth between the
%   hydrophones and the source, <i>not<i> the absolute depth.
%
%   [LOCATION_FINAL, CHI2VAL, GRDSURF] = GRDSRCH_POS(CLKGEOBEARINGS,
%   CLKDEPTHS, SRCLOCATION, VARGIN) adds extra string argumnet pairs  using VARARGIN.
% * latlims - two number array with latitude limits for the grid search
% * lonlims - two number array with longitude limits for the grid search
% * gridsize - the size of the grid (gridsize*gridsize). Higher numbers are
%   a finer grid
% * maxchi2 - the maximum chi2- this is really only needed for plotting
%   surfaces.
% * 'searchtype' -> the type of angles to use in search 'bearing', 'slant'
%   or 'all' Default is 'all'; 'bearing_offset' and 'both_offset' allow
%   the bearings a systematic offset (e.g. a heading error) so only their
%   shape over the track has to match - see ST_LOC_CHI2.
%
%   [LOCATION_FINAL, CHI2VAL, GRDSURF, BEARINGOFFSET] = GRDSRCH_POS(...)
%   also returns the bearing offset (measured - true, RADIANS) at
%   LOCATION_FINAL. GRDSURF.BEARINGOFFSET holds it for every grid point.
%   It is 0 unless an _offset search type is used.


latlims = minmax(srclocations(:,1));
lonlims = minmax(srclocations(:,2));

gridsize = 100;
maxchi2  = 200;
srchtype = 'all'; %bearing, slant, all (both bearing and slant)
pretxt='';

iArg = 0;
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'latlims'
            iArg = iArg + 1;
            latlims = varargin{iArg};
        case 'lonlims'
            iArg = iArg + 1;
            lonlims = varargin{iArg};
        case 'gridsize'
            iArg = iArg + 1;
            gridsize = varargin{iArg};
        case 'maxchi2'
            iArg = iArg + 1;
            maxchi2 = varargin{iArg};
        case 'searchtype'
            iArg = iArg + 1;
            srchtype = varargin{iArg};
        case 'pretext'
            iArg = iArg + 1;
            pretxt = varargin{iArg};
    end
end

%% grid search
xv = linspace(latlims(1), latlims(2), gridsize);
yv = linspace(lonlims(1), lonlims(2), gridsize);
% ylim([-5.055781672297898, -5.0534125878402])

latLong2 = srclocations(:, [1 2]);
dpthdiff = srclocations(:, 3);
chi2    = zeros(length(xv), length(yv));
offsets = zeros(length(xv), length(yv));
Xinterp = zeros(length(xv), length(yv));
Yinterp = zeros(length(xv), length(yv));
for i=1:length(xv)
    for j=1:length(yv)
        if (mod(j,25)==0)
            disp([pretxt 'Running grid search: ' num2str(i*length(yv)+j) ' of ' num2str(length(xv)*length(yv))])
        end
        [chi2(i,j), offsets(i,j)]=st_loc_chi2([xv(i), yv(j)], latLong2, dpthdiff, clkgeobearings, srchtype);
        if (isnan(  chi2(i,j)))
            warning(['grdsrch_pos: chi2(' num2str(i) ',' '.is nan']);
        end
        Xinterp(i,j)=xv(i);
        Yinterp(i,j)=yv(j);
        if (chi2(i,j)>maxchi2)
            chi2(i,j)=maxchi2;
        end
    end
end

[chi2val, index] = min(chi2(:));
[row, col] = ind2sub(size(chi2), index);

location_final = [xv(row), yv(col)];
bearingoffset = offsets(row, col);

grdsurf.Xinterp = Xinterp;
grdsurf.Yinterp = Yinterp;
grdsurf.chi2 = chi2;
grdsurf.bearingoffset = offsets;

end

