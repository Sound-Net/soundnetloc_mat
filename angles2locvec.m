function locvec = angles2locvec(bearing, slantangle)
%ANGLES2LOCVEC Converts bearing and slant angles from PAMGuard to a vector
%
%   LOCVEC = ANGLES2LOCVEC(BEARING, SLANTANGLE) converts BEARING (0 at +y,
%   increasing towards +x, range -pi to pi) and SLANTANGLE (the vertical
%   angle, range -pi/2 to pi/2, positive pointing upwards) in RADIANS to
%   the corresponding unit vectors. LOCVEC is N-by-3 of [x y z].
%
%   BEARING and SLANTANGLE may be scalars or vectors of the same length.
%
%   This is the exact inverse of LOCVEC2ANGLES.
%
%   See also LOCVEC2ANGLES, GEO_REF_VEC.

bearing = bearing(:);
slantangle = slantangle(:);

if isscalar(slantangle) && ~isscalar(bearing)
    slantangle = repmat(slantangle, size(bearing));
elseif isscalar(bearing) && ~isscalar(slantangle)
    bearing = repmat(bearing, size(slantangle));
end

horz = cos(slantangle);

locvec = [sin(bearing).*horz, cos(bearing).*horz, sin(slantangle)];

end
