function [pferr] = particle_filter_err(xh, pf)
%PARTICLE_FILTER_ERR Extract error measurments from result of particle
%   3D particle filter.
%   PFERR = PARTICLE_FILTER_ERR(XH, PF) calculates the error predicted by a
%   particle filter around a dive track. XH are the results from the
%   particle filter and PF is a struct output of the particle filter
%   containing the individual particles for each iteration. The algorithm
%   calculates the 95% confidence interval in the positon of particles for
%   x, y and z PFERR.XYZERR and also calculates the 95% confidence surface by
%   collpasing particles onto a evenly distributed set of vector
%   orthogonal to the track direction PFERR.ERRBOUNDARY. PFERR.ERRBOUNDARY
%   can be used to create an error v'volume' for the track. 


%dot product of orthognal vector = 0; So solve v1x+v2y+v3z = 0;
p = [0,0,1];

nangs=25;

%now the line is defined as
% for i = 1:length(pf.particles(:,1,:))-1
for i=1:length(xh(1,:))-1
    
    %the particles for this time
    particles = pf.particles(:,:,i);
    
    %calculate the vector
    p1 =  [xh(1,i) xh(2,i) xh(3,i)];
    p2 =  [xh(1, i+1) xh(2, i+1) xh(3, i+1)];
    v = p2-p1;
    
    %generate and orthogonal vector
    orthv = cross(p,v);
    
    % Now calculate a set of vectors rotating around v. Then collapse the particles
    % onto that dimension to get an idea of the error. The line are only 0-180
    % degree because we will be using both points on the line.
    angles =  linspace(0, pi, nangs);
    errboundry = zeros(2*nangs, 3);
    for j=1:nangs
        
        vrot1 = rodrigues_rot(orthv,v,angles(j));
        
        vrot1 = vrot1./norm(vrot1);
        
        %generate a large line from this vector
        linestart = 1000*vrot1;
        lineend = -1000*vrot1;
        
        %collapse the particles onto the line
        linedist=zeros(length(particles), 1); % pre allocate array
%         linedist=[];
        for k =1:length(particles)
            closestpoint = closestPointOnLine(linestart, lineend,  particles(1:3, k)'-p1);
            %distance between the closest point and the start of the vector is
            %the distance along the line.
            linedist(k,1) = sqrt(closestpoint(1)^2 + closestpoint(2)^2 + closestpoint(3)^2);
        end
        
        err = std(linedist);
        
%         hold on
%         plot3([linestart(1), lineend(1)], [linestart(2), lineend(2)], [linestart(3), lineend(3)])
%         scatter3(particles(1,:)-p1(1), particles(2,:)-p1(2), particles(3,:)-p1(3)); 
%         hold off
%         
        %save the err points.
        errboundry(2*j-1,:)=err*vrot1;
        errboundry(2*j,:)=-err*vrot1;
    end
    
    xyzerr(1) = std(particles(1,:));
    xyzerr(2) = std(particles(2,:));
    xyzerr(3) = std(particles(3,:));
    
    pferr(i).errboundry = errboundry+p1;
    pferr(i).xyzerr =xyzerr;
    
end

% hold on
% plot3([0 v(1)], [0 v(2)], [0 v(3)], 'Color','b', 'LineWidth', 3);
% plot3([0 orthv(1)], [0 orthv(2)], [0 orthv(3)]);
% for i=1:length(vrot(:,1))
%     plot3([0 vrot(i,1)], [0 vrot(i,2)], [0 vrot(i,3)], 'Color', 'g');
% end
% axis equal
% ylabel('y')
% xlabel('x')
% zlabel('z')

    function result = closestPointOnLine(a, b, p)
        % Calculate the closest point on the line.
        ap = p-a;
        ab = b-a;
        result = a + dot(ap,ab)/dot(ab,ab) * ab;
    end


end



