function vis_joints(im,joints)
    figure;
    imshow(im); hold;
    for i = 1:14
       plot(joints(i,1),joints(i,2),'*');
       t = text(joints(i,1),joints(i,2),num2str(i));
       t.Color = [1,0,1];
    end
end