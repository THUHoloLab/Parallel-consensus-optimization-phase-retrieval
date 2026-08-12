function [A, xx, yy, mask_nan] = legendrebasis2(img, orders, n_rect, mask_nan)

n1 = size(img,1);
n2 = size(img,2);

c1 = linspace(0,1,n1);
c2 = linspace(0,1,n2);

[xx,yy] = meshgrid(c2,c1);

img_tmp = img;

o1 = orders(1);
o2 = orders(2);

mask = zeros(n1,n2);

if isempty(mask_nan)

    for i = 1:n_rect
        fig = figure;
        [~,rect_tmp] = imcrop((img_tmp - min(img_tmp(:)))/(max(img_tmp(:)) - min(img_tmp(:))));
        close(fig);
        mask(round(rect_tmp(2)):round(rect_tmp(2)+rect_tmp(4)), ...
            round(rect_tmp(1)):round(rect_tmp(1)+rect_tmp(3))) = 1;
        img_tmp(round(rect_tmp(2)):round(rect_tmp(2)+rect_tmp(4)), ...
            round(rect_tmp(1)):round(rect_tmp(1)+rect_tmp(3))) = min(img_tmp(:));
    end

    mask_nan = nan(n1,n2);
    mask_nan(mask == 1) = 1;
end

xxx = mask_nan .* xx;
yyy = mask_nan .* yy;

xxx = xxx(:);
yyy = yyy(:);

xxx(isnan(xxx)) = [];
yyy(isnan(yyy)) = [];

n_coef = (o1+1)*(o2+1);
A = nan(length(xxx),n_coef);

for i = 0:o1
    for j = 0:o2
        
        index = i*(o2+1)+j+1;
%         A(:,index) = legendreP(i,xxx).*legendreP(j,yyy);
        A(:,index) = myLegendreP(i,xxx).*myLegendreP(j,yyy);
    end
end

end

