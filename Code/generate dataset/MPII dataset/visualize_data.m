function visualize_data(filename)

    load(strcat('save/',filename));

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
    imshow(im); hold;
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