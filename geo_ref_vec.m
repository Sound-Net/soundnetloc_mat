function [loc_vec_rot, rotm, frame] = geo_ref_vec(locangles, eul, frametype)
%GEO_REF_VEC Geo reference a vector based on euler angles.
%
%   [LOC_VEC_ROT, ROTM] = GEO_REF_VEC(LOCANGLES, EUL) calculates the geo
%   referenced vector from localised angles, LOCANGLES = [BEARING, SLANT]
%   in RADIANS, with respect to x, y, z and then rotates that vector by
%   euler angles EUL (roll, pitch, yaw) in RADIANS. ROTM is the rotation
%   matrix built from the euler angles.
%
%   BEARING is a PAMGuard bearing, i.e. 0 at +y, positive towards +x, and
%   SLANT is positive upwards - the pair returned (in DEGREES) by
%   CLKSTRUCT2BEARINGS. It is NOT the raw angle pair stored in the binary
%   file: PAMGuard writes angles[0] as an anticlockwise angle from +x, so
%   BEARING = pi/2 - angles(1) and SLANT = angles(2). Prior to this
%   version, GEO_REF_CLKS handed the raw angles straight in here, which
%   swapped x and y in the vector below; that swap is now explicit, as
%   frame.bearingswap - see GEO_REF_FRAME.
%
%   [LOC_VEC_ROT, ROTM] = GEO_REF_VEC(LOCANGLES, EUL, FRAMETYPE) uses a
%   specified FRAMETYPE. 'none' is the default. See GEO_REF_FRAME for the
%   list of frames and for exactly what each one does to the angles - all
%   of the frame specific constants live there.
%
%   [LOC_VEC_ROT, ROTM, FRAME] = GEO_REF_VEC(...) also returns the frame
%   definition that was used, so that callers needing the bearing
%   correction (see GEO_REF_CLKS) do not have to look it up again.
%
%   See also GEO_REF_FRAME, EULER2ROT, ANGLES2LOCVEC, CLKSTRUCT2BEARINGS.

if nargin < 3
    frametype = 'none';
end

frame = geo_ref_frame(frametype);

% map the reported angles onto the three rotation axes
a = eul(frame.angleindex) + frame.angleoffset;
a(frame.anglewrap) = wrapToPi(a(frame.anglewrap));
a = frame.anglesign .* a;

% we assume the vector is on a flat plane. We then rotate the plane,
% rotating the vector at the same time.
rotm = euler2rot(a(1), a(2), a(3)) * frame.mount;

% convert the loc bearings to a vector and rotate it
loc_vec = angles2locvec(locangles(1), locangles(2));

if frame.bearingswap
    % Reflect the vector in the plane x = y before rotating. This is the
    % swap that used to be hidden in the caller handing the raw PAMGuard
    % angle to ANGLES2LOCVEC in place of a bearing, and it is one of the
    % two reflections that the frame constants were calibrated with - the
    % other is frame.bearingsign on the way back out. See the NOTE in
    % GEO_REF_FRAME before removing it.
    loc_vec = loc_vec(:, [2 1 3]);
end

loc_vec_rot = rotm * loc_vec';

end
