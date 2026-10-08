function [rotangles, uvecned] = rotate_bearings(angles, hpr)
%ROTATE_BEARINGS applies a platform heading, pitch and roll to a list of
% horizontal and slant angles.
%
% ROTATE_BEARINGS(ANGLES, HPR) rotates a list of angles from the platform
% (body) frame into the geographic frame. ANGLES is an [N x 2] array of
% [horizontal angle, slant angle] in RADIANS, i.e. the same format as the
% bearings used by GRDSRCH_POS. The horizontal angle is measured clockwise
% from the forward axis of the platform and the slant angle is positive
% upwards. HPR is [heading, pitch, roll] in DEGREES and is either a
% [1 x 3] array, which is applied to every angle pair, or an [N x 3] array
% with one orientation per angle pair (e.g. IMU data interpolated onto the
% click times).
%
% The rotation is the standard Tait-Bryan (ZYX, "aircraft") sequence, so
% roll is applied first, then pitch, then heading:
%
%   heading - positive clockwise from north, rotation about the down axis
%   pitch   - positive forward axis up, rotation about the starboard axis
%   roll    - positive starboard side down, rotation about the forward axis
%
% A platform lying flat and pointing north has HPR = [0 0 0] and the angles
% are returned unchanged. With no pitch or roll the heading is simply added
% to the horizontal angle.
%
% [ROTANGLES] = ROTATE_BEARINGS(...) returns an [N x 2] array of rotated
% [horizontal angle, slant angle] in RADIANS. The horizontal angle is
% wrapped to +/-pi and the slant angle is within +/-pi/2.
%
% [ROTANGLES, UVECNED] = ROTATE_BEARINGS(...) also returns the [N x 3]
% array of rotated unit vectors in north, east, down co-ordinates.

if isempty(angles)
    rotangles = zeros(0, 2);
    uvecned = zeros(0, 3);
    return;
end

nang = size(angles, 1);

if size(hpr, 1) ~= 1 && size(hpr, 1) ~= nang
    error('rotate_bearings:hprsize', ...
        'HPR must be a [1 x 3] array or have the same number of rows as ANGLES');
end

%unit vector of each angle pair in the platform frame
% (forward, starboard, down)
vf = cos(angles(:,2)).*cos(angles(:,1));
vs = cos(angles(:,2)).*sin(angles(:,1));
vd = -sin(angles(:,2));

%the rotation matrix terms - column vectors so a single orientation is
%expanded over all the angles and an orientation per angle pair is applied
%row by row
ch = cosd(hpr(:,1)); sh = sind(hpr(:,1));
cp = cosd(hpr(:,2)); sp = sind(hpr(:,2));
cr = cosd(hpr(:,3)); sr = sind(hpr(:,3));

%body to north east down rotation
vn = vf.*(ch.*cp) + vs.*(ch.*sp.*sr - sh.*cr) + vd.*(ch.*sp.*cr + sh.*sr);
ve = vf.*(sh.*cp) + vs.*(sh.*sp.*sr + ch.*cr) + vd.*(sh.*sp.*cr - ch.*sr);
vdn = -vf.*sp     + vs.*(cp.*sr)              + vd.*(cp.*cr);

uvecned = [vn, ve, vdn];

%back to a horizontal and slant angle
rotangles = [atan2(ve, vn), asin(max(min(-vdn, 1), -1))];

end
