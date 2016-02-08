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

%mirror images after computed
for flip=1:2
    for i=1:imgSet.Count
        
        %show progress in the screen
        clc
        cnt
        
        %create structe to be saved
        s = struct;
        
        %get currImage
        currImg = imread(imgSet.ImageLocation{i});
        
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
        
        s.joints = zeros(nJoints+nBorders,3);
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
               
               %add joints
               [row,col] = find(temp3DImg(:,:,j)==1);
               
               s.joints(j,1) = col;
               s.joints(j,2) = row;
               
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
        
        save(strcat('save/s',num2str(cnt),'.mat'),'s');
        
        cnt = cnt + 1;
    end
end

%im = imread('cameraman.tif');
%bw = edge(im);
%d = bwdist(bw);
%imshow(d,[]);
