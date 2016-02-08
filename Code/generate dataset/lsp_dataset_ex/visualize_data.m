function visualize_data(filename)

    load(strcat('save1/',filename));

    str = '-mirror';
    
    if (~isempty(findstr(s.filename,str)))
        new_filename = strrep(s.filename,str,[]);
        is_mirror = 1;
    else
        new_filename = s.filename;
        is_mirror = 0;
    end
        
    im = imread(strcat('images/',new_filename));    
    
    if (is_mirror)
       im = fliplr(im); 
    end
    
    figure;
    if (isfield(s,'scale'))
        imshow(imresize(im,s.scale)); hold;
    else
        imshow(im); hold;
    end
    
    x = s.bounding_box(1,1);
    y = s.bounding_box(1,2);
    w = s.bounding_box(2,1);
    h = s.bounding_box(2,2);
    
    rectangle('Position', [x, y, w, h]);
    
    for i = 1:14
        if (s.joints(i,3) == 1)
           h = plot(s.joints(i,1),s.joints(i,2),'.');
           set(h, 'Markersize',20);
           t = text(s.joints(i,1),s.joints(i,2),num2str(i));
           t.Color = 'blue';
           t.FontWeight = 'bold';
        end
    end
    
    figure;
    for i=1:18 
        subplot(3,6,i)
        imshow(s.dist_transf(:,:,i),[]);
    end
end