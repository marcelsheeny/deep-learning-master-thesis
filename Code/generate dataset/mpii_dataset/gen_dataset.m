clc;
close all;
clear all;

%options
nJoints = 14;             %number of joints
nBorders = 4;             %number of borders
start_from = 20000;       %a number to define were to start the save files
scale = 0.3;              %changing the scale from the original image to become faster
scale_bbox = 0.35;        %set how bigger this bounding box will be

%setting correspondent ids in ths lsp and mpii datasets
%           lsp_id x mpii_id
ids_match = [1,      0;
             2,      1;
             3,      2;
             4,      3;
             5,      4;
             6,      5;
             7,      10;
             8,      11;
             9,      12;
             10,     13;
             11,     14;
             12,     15;
             13,     8;
             14,     9];
         
%load dataset annotation
load('mpii_human_pose_v1_u12_1.mat');

%number of images
N = size(RELEASE.annolist,2);

%init cnt
cnt = 1;

tic
%mirror images after computed to have a larger dataset
for flip=1:2
    %for all images
    for i=1:N
        
        %show progress in the screen
        clc
        if (flip == 1)
            disp(strcat(num2str((i/(2*N))*100),'%'));
        else
            disp(strcat(num2str(((N+i)/(2*N))*100),'%'));
        end
        
        %create structe to be saved
        s = struct;
        
        %image name
        name = RELEASE.annolist(i).image.name;
        
        %check if file exists
        if (~exist(strcat('images/',name),'file')) 
           missing_files{cnt_miss} = strcat('images/',name);
           cnt_miss = cnt_miss + 1;
           disp(strcat('file:','images/',name,'does not exist!'));
           continue;
        end
        
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
            if (isfield(RELEASE.annolist(i).annorect(1,p), 'annopoints') && ...
                    ~isempty(RELEASE.annolist(i).annorect(1,p).annopoints))
            
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
                
                
                size_h = size(ceil(yymin):ceil(yymax),2);
                size_w = size(ceil(xxmin):ceil(xxmax),2);
                
                temp3DDT_bbox = zeros(size_h,size_w,nJoints+nBorders);
                
                for jj=1:nJoints
                    if (s.joints(jj,3) == 1)
                        
                        xxmax = ceil(xxmax);
                        xxmin = ceil(xxmin);
                        yymax = ceil(yymax);
                        yymin = ceil(yymin);
                        
                        %avoid problems with borders
                        %if (xxmax > xxmin+size_w) xxmax = xxmin+size_w; end
                        %if (yymax > size_h) yymax = yymin+size_h; end
                        %if (xxmin <= 0) 
                        %    xxmin = 1; 
                        %end
                        %if (yymin <= 0)
                        %    yymin = 1; 
                       % end
                        
                        %compute distance transform
                        dtim = bwdist(temp3DImg_scale(yymin:yymax, xxmin:xxmax,jj));

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
                s.img_train = RELEASE.img_train(i);
                s.act = RELEASE.act(i);
                
                save(strcat('save/m',num2str(start_from+cnt),'.mat'),'s');

                cnt = cnt + 1;
            end
        end
    end
end
toc
%im = imread('cameraman.tif');
%bw = edge(im);
%d = bwdist(bw);
%imshow(d,[]);