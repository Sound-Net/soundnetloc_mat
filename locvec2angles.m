function [bearing, slantangle] = locvec2angles(loc_vec)
%LOCVEC2ANGLES Converts a loc vector to PAMGuard localisation angles
%
%   [BEARING, SLANTANGLE] = LOCVEC2ANGLES(LOC_VEC) converts a vector
%   LOC_VEC (does not need to be normalised) to a PAMGuard BEARING and
%   SLANTANGLE in RADIANS, where BEARING is 0 at +y with positive angles
%   towards +x and range -pi to pi, and SLANTANGLE has range -pi/2 to pi/2
%   with positive angles pointing upwards.
%
%   LOC_VEC may be a single 3 element vector (row or column) or an N-by-3
%   array of row vectors, in which case BEARING and SLANTANGLE are N-by-1.
%
%   This is the exact inverse of ANGLES2LOCVEC.
%
%   See also ANGLES2LOCVEC, GEO_REF_VEC.

if isvector(loc_vec) && numel(loc_vec) == 3
    loc_vec = loc_vec(:)';
end

x = loc_vec(:,1);
y = loc_vec(:,2);
z = loc_vec(:,3);

% atan2 rather than asin(z/r) - no divide by zero for a zero length vector
% and better conditioned close to +/-90 degrees.
slantangle = atan2(z, hypot(x, y));

% bearing measured from +y towards +x, i.e. atan2 with the arguments
% swapped compared to the usual maths convention.
bearing = atan2(x, y);

end
