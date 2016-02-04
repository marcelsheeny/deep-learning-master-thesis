function  vis_dist_transf( cube )
%VIS_DIST_TRANSF Summary of this function goes here
%   Detailed explanation goes here

figure;
for i=1:18
    subplot(3,6,i)
    imshow(cube(:,:,i),[]);
end


end

