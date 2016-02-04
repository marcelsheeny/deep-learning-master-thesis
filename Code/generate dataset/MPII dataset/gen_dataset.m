clc;
close all;
clear all;

%constants
nJoints = 14;
nBorders = 4;
start_from = 20000;
use_scale = 1;
scale = 1;
use_bbox = 1;
size_bbox;

%           lsp_id x mpii_id
ids_match = [1,0;
             2,1;
             3,2;
             4,3;
             5,4;
             6,5;
             7,10;
             8,11;
             9,12;
             10,13;
             11,14;
             12,15;
             13,8;
             14,9];
         
%load dataset annotation
load('mpii_human_pose_v1_u12_1.mat');

%number of images
N = size(RELEASE.annolist,2);

%init cnt
cnt = 1;

%mirror images after computed
for flip=1:2
    for i=1:10
        
        %show progress in the screen
        clc
        cnt
        
        %create structe to be saved
        s = struct;
        
        name = RELEASE.annolist(i).image.name;
        
        %get currImage
        currImg = imread(strcat('images/',name));
        
        %dataset
        s.dataset = 'mpii';
        
        %filename
        [pathstr,name,ext] = fileparts(name);
        
        %mirror it if needed
        if (flip == 1) 
            s.filename = strcat(name,ext);
        else
            s.filename = strcat(name,'-mirror',ext);
        end
        
        %for each person in the image
        n_person = size(RELEASE.annolist(i).annorect,2);
        for p=1:n_person
        
            %check if field exists
            if (isfield(RELEASE.annolist(i).annorect(1,p), 'annopoints'))
            
                temp3DImg = zeros(size(currImg,1),size(currImg,2),nJoints+nBorders);
                temp3DDT  = zeros(size(currImg,1),size(currImg,2),nJoints+nBorders);
                
                %initialize joints
                s.joints = zeros(nJoints+nBorders,3);              
                
                for j = 1:nJoints
                    
                   id_array = zeros(size(RELEASE.annolist(i).annorect(p).annopoints.point(1,:),2),1);
                   for inc = 1:size(id_array,1);
                      id_array(inc,1) = RELEASE.annolist(i).annorect(p).annopoints.point(1,inc).id;
                   end
                    
                   %do in the same order as lsp
                   ind = find(id_array == ids_match(j,2));
                   
                   %flag that says if there is joint or not
                   is_joint = 1;
                   
                   if (~isempty(ind))
                       currJoint = RELEASE.annolist(i).annorect(p).annopoints.point(1,ind);
                        
                       vis = currJoint.is_visible;
                       if (ischar(vis)) vis = str2num(vis); end
                       if (isempty(vis) || vis == 1)
                 
                           %set as a visible joint
                           s.joints(j,3) = 1;

                           %get row and column
                           r = round(currJoint.y);
                           c = round(currJoint.x);

                           %avoid problems with borders
                           if (r > size(currImg,1)) r = size(currImg,1); end
                           if (c > size(currImg,2)) c = size(currImg,2); end
                           if (r <= 0) r = 1; end
                           if (c <= 0) c = 1; end

                           temp3DImg(r,c,j) = 1;

                           if (flip == 2)
                              temp3DImg(:,:,j) = fliplr(temp3DImg(:,:,j)); 
                           end

                           %add joints
                           [row,col] = find(temp3DImg(:,:,j)==1);

                           s.joints(j,1) = col;
                           s.joints(j,2) = row;

                           %compute distance transform
                           dtim = bwdist(temp3DImg(:,:,j));

                           %store in the 'cube'
                           temp3DDT(:,:,j) = dtim;
                           
                       else
                          is_joint = 0;
                       end

                   else
                       is_joint = 0;
                   end
                   
                   %if there is no joint, fill the matrix with -1
                   if (is_joint == 0)
                       temp3DDT(:,:,j) = temp3DDT(:,:,j) -1;
                       s.joints(j,3) = 0;
                   end
                end

                %add borders
                borders = [1,               1               ;
                           1,               size(currImg,2) ;
                           size(currImg,1), size(currImg,2) ;
                           size(currImg,1), 1              ];

                %add borders to the image
                for k=1:size(borders,1)
                    tempJoint = zeros(size(currImg,1),size(currImg,2));
                    tempJoint(borders(k,1),borders(k,2)) = 1;

                    %compute distance transform
                    temp3DDT(:,:,14+k) = bwdist(tempJoint);

                    %add joints
                    s.joints(14+k,1) = borders(k,2);
                    s.joints(14+k,2) = borders(k,1);

                    %set as a visible joint
                    s.joints(14+k,3) = 1;
                end

                %imgsJoints{cnt} = temp3DImg;
                %imgsDT{cnt} = temp3DDT;

                %s.joints = temp3DImg;
                s.dist_transf = temp3DDT;

                save(strcat('save/m',num2str(start_from+cnt),'.mat'),'s');

                cnt = cnt + 1;
            end
        end
    end
end

%im = imread('cameraman.tif');
%bw = edge(im);
%d = bwdist(bw);
%imshow(d,[]);