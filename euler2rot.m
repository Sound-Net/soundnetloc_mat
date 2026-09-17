function R = euler2rot(rx, ry, rz)
%EULER2ROT Converts euler angles into a rotation matrix.
%
%   R = EULER2ROT(RX, RY, RZ) builds the rotation matrix for a rotation of
%   RX about the x axis, RY about the y axis and RZ about the z axis, all
%   in RADIANS. The rotations are composed in the order
%
%       R = Rz(rz) * Ry(ry) * Rx(rx)
%
%   i.e. the standard intrinsic ZYX (yaw, pitch, roll) sequence, applied to
%   column vectors. Equivalent to EUL2ROTM([rz ry rx], 'ZYX').
%
%   Note the arguments are named for the AXIS each one turns about, not for
%   roll/pitch/yaw. Which reported angle drives which axis is a property of
%   how the sensor is mounted and is defined in GEO_REF_FRAME.
%
%   See also GEO_REF_FRAME, GEO_REF_VEC.

X = eye(3,3);
Y = eye(3,3);
Z = eye(3,3);

X(2,2) = cos(rx);
X(2,3) = -sin(rx);
X(3,2) = sin(rx);
X(3,3) = cos(rx);

Y(1,1) = cos(ry);
Y(1,3) = sin(ry);
Y(3,1) = -sin(ry);
Y(3,3) = cos(ry);

Z(1,1) = cos(rz);
Z(1,2) = -sin(rz);
Z(2,1) = sin(rz);
Z(2,2) = cos(rz);

R = Z*Y*X;

end
