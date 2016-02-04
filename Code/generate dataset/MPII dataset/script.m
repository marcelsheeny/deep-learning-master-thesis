%close all;
%clear all;
clc;

%load('mpii_human_pose_v1_u12_1.mat')

id1 = 179;
id2 = 1;

im = imread(strcat('images/',RELEASE.annolist(id1).image.name));

figure;
imshow(im); hold on;

x1_r = RELEASE.annolist(id1).annorect(id2).x1;
x2_r = RELEASE.annolist(id1).annorect(id2).x2;
y1_r = RELEASE.annolist(id1).annorect(id2).y1;
y2_r = RELEASE.annolist(id1).annorect(id2).y2;

%pos = [x1_r, y1_r, x2_r - x1_r, y2_r - y1_r];

%rectangle('Position',pos)

for i=1:size(RELEASE.annolist(id1).annorect(id2).annopoints.point,2)
    vis = RELEASE.annolist(id1).annorect(id2).annopoints.point(i).is_visible;
    if (ischar(vis)) vis = str2num(vis); end
    if (isempty(vis) || vis == 1)
        joint_id = RELEASE.annolist(id1).annorect(id2).annopoints.point(i).id;
        if (joint_id ~= 6 && joint_id ~= 7)
            x = RELEASE.annolist(id1).annorect(id2).annopoints.point(i).x;
            y = RELEASE.annolist(id1).annorect(id2).annopoints.point(i).y;
            plot(x, y, '*');
            t = text(x,y,num2str(joint_id));
            t.Color = [1 0 1];
        end
    end
end
