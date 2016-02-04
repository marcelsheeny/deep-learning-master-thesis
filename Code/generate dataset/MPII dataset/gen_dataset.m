clc;
close all;
clear all;

%options
nJoints = 14;
nBorders = 4;
start_from = 20000;

scale = 0.3;
use_bbox = 1;
scale_bbox = 0.4;

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
    parfor i=1:10
        
        %show progress in the screen
        clc
        cnt
        
        %create structe to be saved
        s = struct;
        
        name = RELEASE.annolist(i).image.name;
        
        %get currImage
        currImg = imread(strcat('images/',name));
        
        % scale current image
        currImg_scale = imresize(currImg,scale); 
        
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
                
                temp3DImg_scale = imresize(temp3DImg,scale);
                temp3DDT_scale  = imresize(temp3DDT,scale);
                
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
                           
                           temp3DImg_scale(:,:,j) = imresize(temp3DImg(:,:,j),scale,'bilinear');

                           %add joints
                           [row,col] = find(temp3DImg_scale(:,:,j)>0);

                           s.joints(j,1) = col(1);
                           s.joints(j,2) = row(1);

                           %compute distance transform
                           %dtim = bwdist(temp3DImg_scale(:,:,j));

                           %store in the 'cube'
                           %temp3DDT_scale(:,:,j) = dtim;
                       else
                          is_joint = 0;
                       end

                   else
                       is_joint = 0;
                   end
                   
                   %if there is no joint, fill the matrix with -1
                   if (is_joint == 0)
                       temp3DDT_scale(:,:,j) = temp3DDT_scale(:,:,j) -1;
                       s.joints(j,3) = 0;
                   end
                end
                
                tjoints = s.joints(find(s.joints(:,3) == 1),:);
                
                xmax = max(tjoints(:,1));
                ymax = max(tjoints(:,2));
                xmin = min(tjoints(:,1));
                ymin = min(tjoints(:,2));
                
                ww = xmax-xmin;
                hh = ymax-ymin;
                
                xxmin = xmin-ww*scale_bbox;
                if (xxmin <= 0) xxmin = 1; end
                yymin = ymin-hh*scale_bbox;
                if (yymin <= 0) yymin = 1; end
                
                xxmax = xmax+ww*scale_bbox;
                if (xxmax > size(currImg_scale,2)) xxmax = size(currImg_scale,2); end
                
                yymax = ymax+hh*scale_bbox;
                if (yymax > size(currImg_scale,1)) yymax = size(currImg_scale,1); end
                
                www = xxmax - xxmin;
                hhh = yymax - yymin;
                
                s.bounding_box = [xxmin, yymin; www, hhh];
                
                
                size_h = size(round(yymin):round(yymax),2);
                size_w = size(round(xxmin):round(xxmax),2);
                
                temp3DDT_bbox = zeros(size_h,size_w,nJoints+nBorders);
                
                for jj=1:nJoints
                    if (s.joints(jj,3) == 1)
                        %compute distance transform
                        dtim = bwdist(temp3DImg_scale(round(yymin):round(yymax), round(xxmin):round(xxmax),jj));

                        %store in the 'cube'
                        temp3DDT_bbox(:,:,jj) = dtim;
                    else
                        temp3DDT_bbox(:,:,jj) = temp3DDT_bbox(:,:,jj) - 1;
                    end
                end
                
                %add borders
                borders = [1,   1   ;
                           1,   size_w ;
                           size_h, size_w ;
                           size_h, 1  ];

                %add borders to the image
                for k=1:size(borders,1)
                    tempJoint = zeros(size_h,size_w);
                    tempJoint(borders(k,1),borders(k,2)) = 1;

                    %compute distance transform
                    temp3DDT_bbox(:,:,nJoints+k) = bwdist(tempJoint);

                    %add joints
                    s.joints(nJoints+k,1) = borders(k,2);
                    s.joints(nJoints+k,2) = borders(k,1);

                    %set as a visible joint
                    s.joints(nJoints+k,3) = 1;
                end

                %imgsJoints{cnt} = temp3DImg;
                %imgsDT{cnt} = temp3DDT;

                %s.joints = temp3DImg;
                s.scale = scale;
                s.dist_transf = temp3DDT_bbox;
                
                
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
