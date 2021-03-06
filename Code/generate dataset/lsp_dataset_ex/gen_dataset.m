clc;
close all;
clear all;

%constants
nJoints = 14;             %number of joints
nBorders = 4;             %number of borders
start_from = 0;           %a number to define were to start the save files
scale = 1;                %changing the scale from the original image to become faster
scale_bbox = 0.35;        %set how bigger this bounding box will be

%load joints
load('joints.mat')

%load set
imgSet = imageSet('images/');

%init cnt
cnt = 1;

N = imgSet.Count;

%mirror images after computed
for flip=1:2
    for i=1:imgSet.Count
        
        %show progress in the screen
        clc
        if (flip == 1)
            disp(strcat(num2str((i/(2*N))*100),'%'));
        else
            disp(strcat(num2str(((N+i)/(2*N))*100),'%'));
        end
        
        %create structe to be saved
        s = struct;
        
        %get currImage
        currImg = imread(imgSet.ImageLocation{i});
        
        % scale current image
        currImg_scale = imresize(currImg,scale); 
        
        %dataset
        s.dataset = 'lsp';
        
        %filename
        [pathstr,name,ext] = fileparts(imgSet.ImageLocation{i});
        
        %mirror it if needed
        if (flip == 1) 
            s.filename = strcat(name,ext);
        else
            s.filename = strcat(name,'-mirror',ext);
        end
        
        temp3DImg = zeros(size(currImg,1),size(currImg,2),nJoints+nBorders);
        temp3DDT  = zeros(size(currImg,1),size(currImg,2),nJoints+nBorders);
                
        temp3DImg_scale = imresize(temp3DImg,scale);
        temp3DDT_scale  = imresize(temp3DDT,scale);

        %initialize joints
        s.joints = zeros(nJoints+nBorders,3);
        
        is_joint = 1;
        
        for j = 1:nJoints
           if (joints(j,3,i) == 1)
               %set as a visible joint
               s.joints(j,3) = 1;
               
               %get row and column
               r = round(joints(j,2,i));
               c = round(joints(j,1,i));
               
               %avoid problems with borders
               if (r > size(currImg,1)) r = size(currImg,1); end
               if (c > size(currImg,2)) c = size(currImg,2); end
               if (r <= 0) r = 1; end
               if (c <= 0) c = 1; end
               
               temp3DImg(r,c,j) = 1;

               if (flip == 2)
                  temp3DImg(:,:,j) = fliplr(temp3DImg(:,:,j)); 
               end
               
               %scale image
               temp3DImg_scale(:,:,j) = imresize(temp3DImg(:,:,j),scale,'bilinear');

               %add joints
               [row,col] = find(temp3DImg_scale(:,:,j)>0);
               
               s.joints(j,1) = col(1);
               s.joints(j,2) = row(1);
               
               %compute distance transform
               dtim = bwdist(temp3DImg(:,:,j));
               
               %store in the 'cube'
               temp3DDT(:,:,j) = dtim;
               
           %if there is no joint, fill the matrix with -1
           else
               temp3DDT(:,:,j) = temp3DDT(:,:,j) -1;
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
        s.dist_transf = temp3DDT;
        
        s.scale = scale;
        s.dist_transf = temp3DDT_bbox;
        s.img_train = 1;
        s.act = [];
        
        save(strcat('save1/le',num2str(cnt),'.mat'),'s');
        
        cnt = cnt + 1;
    end
end

%im = imread('cameraman.tif');
%bw = edge(im);
%d = bwdist(bw);
%imshow(d,[]);
