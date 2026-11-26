function hydrophones = read_pamguard_hydrophones(dbfile)
%READ_PAMGUARD_HYDROPHONES Hydrophone positions of the array in a PAMGuard database.
%
%   HYDROPHONES = READ_PAMGUARD_HYDROPHONES(DBFILE) returns the [n x 3]
%   positions [x y z] (m) of the hydrophones in PAMGuard's array manager,
%   in channel order, from the most recent entries of the Hydrophones table
%   of the database DBFILE. These are the positions PAMGuard used to turn
%   time delays into bearings, in the frame of the array (bearing 0 along
%   +y, z up).
%
%   See also GEO_REF_HYDROPHONES_BEARING.

conn = sqlite(dbfile, 'readonly');
c = onCleanup(@() close(conn));
T = fetch(conn, 'select Id, hydrophoneN, xPos, yPos, zPos from Hydrophones order by Id');
if isempty(T)
    error('read_pamguard_hydrophones:none', 'No hydrophones in %s', dbfile);
end
% the table gains a row per hydrophone every time PAMGuard is run: keep the
% last row of each hydrophone
n = max(double(T.hydrophoneN)) + 1;
hydrophones = nan(n, 3);
for h = 0:n-1
    r = find(double(T.hydrophoneN) == h, 1, 'last');
    hydrophones(h+1,:) = [T.xPos(r), T.yPos(r), T.zPos(r)];
end
end
