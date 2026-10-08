function [dif] = angdiffd(angle1, angle2)
%ANGDIFFD Difference between two angles
%
%   Computes the signed angular difference between two angles in degrees.
%   The result is comprised between -180 and +180.

dif  = rad2deg( angdiff(deg2rad(angle1), deg2rad(angle2))); 

end

