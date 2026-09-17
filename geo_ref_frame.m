function frame = geo_ref_frame(frametype)
%GEO_REF_FRAME Definition of a sensor to PAMGuard co-ordinate frame.
%
%   FRAME = GEO_REF_FRAME(FRAMETYPE) returns the complete definition of how
%   euler angles from the orientation sensor are turned into a rotation
%   matrix, and how the resulting bearing is corrected for the way the
%   hydrophones are arranged in PAMGuard's array manager. Everything that
%   is specific to a particular sensor package / array configuration lives
%   here and nowhere else.
%
%   The sensor reports [roll, pitch, yaw]. Those three angles are mapped
%   onto the three rotation axes as
%
%       a(k) = anglesign(k) * wrap( eul(angleindex(k)) + angleoffset(k) )
%
%   for k = 1 (rotation about x), 2 (about y) and 3 (about z), and the
%   rotation matrix is then
%
%       R = euler2rot(a(1), a(2), a(3)) * mount
%         = Rz(a(3)) * Ry(a(2)) * Rx(a(1)) * mount
%
%   FRAME fields:
%     name        - the frame name
%     angleindex  - which reported angle drives x, y and z. [1 2 3] is the
%                   usual roll->x, pitch->y, yaw->z. Anything else means
%                   the angles are being interchanged - see NOTE below.
%     angleoffset - offset in RADIANS added to each angle before the sign.
%                   pi is used to compensate for a sensor mounted upside
%                   down, or for a sensor whose zero is not the array zero.
%     anglesign   - sign applied to each angle after the offset. -1 on the z
%                   term converts a compass heading (clockwise from north)
%                   into a right handed rotation about z.
%     anglewrap   - wrap each angle to +/-pi before use.
%     mount       - constant rotation from the array frame into the sensor
%                   frame, applied before the sensor rotation. This is the
%                   correct place to put a fixed mounting geometry (sensor
%                   bolted in rotated, axes interchanged, hydrophones set at
%                   an angle). Identity for every frame defined below.
%     bearingswap - reflect the localisation vector in the plane x = y
%                   before rotating it. See NOTE 2 below.
%     horzoffset  - offset in RADIANS added to the geo referenced bearing.
%     bearingsign - sign applied to the geo referenced bearing.
%
%   Frames:
%     'none'         - no transformation of the reported euler angles. Note
%                      that this is not an identity transformation: the
%                      bearing convention fields (bearingswap, horzoffset,
%                      bearingsign) still apply, so a 'none' frame with zero
%                      euler angles does not return the PAMGuard bearing.
%     'xsens_pg'     - DEFRA project, i.e. pre 2024.
%     'xsens_pg_2'   - CIBBRiNA project, post 2024. Identical rotation to
%                      'xsens_pg'; the two differ only in horzoffset.
%     'xsens_pg_TD'  - used when rotating hydrophone positions for time
%                      delay work.
%
%   NOTE on angleindex and bearingsign. Two of the frames below do things
%   that are worth being aware of before relying on them at large tilt:
%
%   1. 'xsens_pg' and 'xsens_pg_2' use angleindex [2 1 3], i.e. the reported
%      roll drives the rotation about y and the reported pitch drives the
%      rotation about x. Interchanging the angles inside a ZYX composition
%      is NOT the same as interchanging the axes, which would be a constant
%      matrix in `mount`. The two agree when the package is level and when
%      roll and pitch happen to be equal, and differ by up to ~25 degrees of
%      slant angle at 30 degrees of tilt. Bearing is barely affected (<1
%      degree), so boat calibrations cannot distinguish the two.
%
%   2. bearingswap and bearingsign = -1 are both reflections, not rotations,
%      so the full transformation from array frame to world frame has
%      determinant -1. bearingswap used to be implicit: GEO_REF_CLKS handed
%      the raw PAMGuard angle (measured anticlockwise from the x axis) to
%      ANGLES2LOCVEC, which expects a bearing (clockwise from the y axis),
%      and swapping the two is exactly a reflection in x = y. GEO_REF_VEC is
%      now given a real bearing, from CLKSTRUCT2BEARINGS, and does the
%      reflection explicitly instead - the numbers are unchanged. The two
%      reflections cancel exactly for a level package (a reflection commutes
%      with a rotation about z and with nothing else) and progressively
%      disagree as the package tilts. Setting bearingswap = false and
%      bearingsign = +1 together is the transformation with no reflection in
%      it at all, but that is a different transformation, not a tidier
%      spelling of this one, and it needs its own calibration.
%
%   Both are kept exactly as they were so that existing results reproduce.
%   Fixing either one means changing `mount` and re-doing the calibration,
%   so they are documented here rather than silently corrected.
%
%   See also GEO_REF_VEC, GEO_REF_CLKS, EULER2ROT.

if nargin < 1 || isempty(frametype)
    frametype = 'none';
end

% allow an already resolved frame struct to be passed straight through, so
% callers in a loop do not have to look it up for every click
if isstruct(frametype)
    frame = frametype;
    if ~isfield(frame, 'bearingswap')
        % a frame struct built before bearingswap existed. It must have
        % been used with the raw PAMGuard angles, which is the swap.
        frame.bearingswap = true;
    end
    return;
end

% defaults - a straight through frame
frame.name        = frametype;
frame.angleindex  = [1 2 3];
frame.angleoffset = [0 0 0];
frame.anglesign   = [1 1 1];
frame.anglewrap   = [false false false];
frame.mount       = eye(3);
frame.bearingswap = true;
frame.horzoffset  = pi/2;
frame.bearingsign = -1;

switch lower(frametype)

    case 'none'
        % nothing to do - the defaults already pass the reported euler
        % angles straight through. The bearing convention fields are not
        % straight through though - see the note on 'none' above.

    case {'xsens_pg', 'xsens_pg_2'}
        % Sensor is mounted upside down (the pi on roll) and its zero is
        % not the array zero (the pi on yaw). The yaw sign converts the
        % compass heading into a rotation about z.
        frame.angleindex  = [2 1 3];    % x<-pitch, y<-roll, z<-yaw
        frame.angleoffset = [0 pi pi];
        % frame.anglesign   = [-1 -1 -1];

        %4/09/2026 - change the this form [-1,-1,-1] to [1,-1,-1] as this
        %seemed to overall provide better results...not sure why
        frame.anglesign   = [1 -1 -1]; 

        frame.anglewrap   = [true true true];

        if strcmpi(frametype, 'xsens_pg_2')
            % 45 degrees for the hydrophone layout, plus 20 degrees that
            % was found experimentally and has never been explained. If the
            % mounting geometry is ever pinned down this belongs in `mount`
            % as a rotation of the array frame, not as an offset added to
            % the bearing after the rotation - the two differ by up to
            % ~13 degrees at 30 degrees of tilt.
            frame.horzoffset = deg2rad(45+20);
        else
            frame.horzoffset = pi/2;
        end

    case 'xsens_pg_td'
        % Used for rotating hydrophone positions. PAMGuard references
        % bearing = 0 at x = 0, y = inf rather than the other way round.
        % Note this frame uses the conventional roll->x, pitch->y mapping,
        % so it does NOT produce the same rotation as 'xsens_pg_2' for the
        % same attitude - they are 80 degrees apart in azimuth even when
        % level. Take care if bearings and hydrophone positions from the
        % two frames are consumed together.
        frame.angleindex  = [1 2 3];    % x<-roll, y<-pitch, z<-yaw
        frame.angleoffset = [pi 0 0];
        frame.anglesign   = [1 1 1];
        frame.anglewrap   = [true false true];

    otherwise
        error('geo_ref_frame:unknownFrame', ...
            ['Unknown frame ''' frametype '''. Valid frames are: ' ...
             'none, xsens_pg, xsens_pg_2, xsens_pg_TD.']);
end

end
