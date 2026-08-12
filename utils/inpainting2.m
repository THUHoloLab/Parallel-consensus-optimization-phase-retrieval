function [img_o, mask] = inpainting2(img_i, n_rect, lam, n_iters, select_valid, mask)

n1 = size(img_i,1);
n2 = size(img_i,2);

img_tmp = img_i;

if select_valid
    val = 0;
else
    val = 1;
end

if isempty(mask)
    mask = val*ones(n1,n2);
    for i = 1:n_rect
        fig = figure;
        tmp = (img_tmp - min(img_tmp(:)))/(max(img_tmp(:)) - min(img_tmp(:)));
        [~,rect_tmp] = imcrop(tmp);
        close(fig);
        mask(round(rect_tmp(2)):round(rect_tmp(2)+rect_tmp(4)), ...
            round(rect_tmp(1)):round(rect_tmp(1)+rect_tmp(3))) = 1-val;
        
        img_tmp(round(rect_tmp(2)):round(rect_tmp(2)+rect_tmp(4)), ...
            round(rect_tmp(1)):round(rect_tmp(1)+rect_tmp(3))) = min(img_tmp(:));
    end
end

img_p = img_i(mask==1);
img_i = img_i / mean(img_p(:));
img_o = img_i;
mask_new = mask;
% figure
for i = 1:n1
    disp([num2str(i),'/',num2str(n1)])
    slice = mask(i,:);
    if sum(slice == 1) > 0
        idx1 = find(slice == 1,1,'first');
        idx2 = find(slice == 1,1,'last');
        if idx1 > 1
            img_o(i,1:idx1-1) = mean(img_o(max([i-5,1]):min([i+5,n1]),idx1));
            mask_new(i,1:idx1-1) = 1;
        end
        if idx2 < n2
            img_o(i,idx2+1:end) = mean(img_o(max([i-5,1]):min([i+5,n1]),idx2));
            mask_new(i,idx2+1:end) = 1;
        end
    end
%     imshow(img_o.*mask_new,[]);drawnow;
end
% close

% figure
for j = 1:n2
    disp([num2str(j),'/',num2str(n2)])
    slice = mask_new(:,j);
    if sum(slice == 1) > 0
        idx1 = find(slice == 1,1,'first');
        idx2 = find(slice == 1,1,'last');
        if idx1 > 1
            img_o(1:idx1-1,j) = mean(img_o(idx1,max([j-5,1]):min([j+5,n2])));
            mask_new(1:idx1-1,j) = 1;
        end
        if idx2 < n1
            img_o(idx2+1:end,j) = mean(img_o(idx2,max([j-5,1]):min([j+5,n2])));
            mask_new(idx2+1:end,j) = 1;
        end
    end
%     imshow(img_o.*mask_new,[]);drawnow;
end
% close

gam = 1;
n_subiters = 1;

x_est = img_o;
z_est = x_est;
v_est = zeros(size(x_est,1),size(x_est,2),2);
w_est = zeros(size(x_est,1),size(x_est,2),2);

for iter = 1:n_iters

    % print status
    fprintf('iter: %4d / %4d \n', iter, n_iters);
    
    % gradient update
    u = mask_new.*(z_est - img_o);
    u = z_est - gam * u;
    
    % proximal update
    v_est(:) = 0; w_est(:) = 0;
    for subiter = 1:n_subiters
        w_next = v_est + 1/8/gam*Df(u-gam*DTf(v_est));
        w_next = min(abs(w_next),lam).*exp(1i*angle(w_next));
        v_est = w_next + subiter/(subiter+3)*(w_next-w_est);
        w_est = w_next;
    end
    x_next = u - gam*DTf(w_est);
    
    % Nesterov extrapolation
    z_est = x_next + (iter/(iter+3))*(x_next - x_est);
    x_est = x_next;
end
img_o = x_est;



function w = Df(x)
% =========================================================================
% Calculate the 2D gradient (finite difference) of an input image.
% -------------------------------------------------------------------------
% Input:    - x  : The input 2D image.
% Output:   - w  : The gradient (3D array).
% =========================================================================
w = cat(3,x(1:end,:) - x([2:end,end],:),x(:,1:end) - x(:,[2:end,end]));
end


function u = DTf(w)
% =========================================================================
% Calculate the transpose of the gradient operator.
% -------------------------------------------------------------------------
% Input:    - w  : 3D array.
% Output:   - x  : 2D array.
% =========================================================================
u1 = w(:,:,1) - w([end,1:end-1],:,1);
u1(1,:) = w(1,:,1);
u1(end,:) = -w(end-1,:,1);

u2 = w(:,:,2) - w(:,[end,1:end-1],2);
u2(:,1) = w(:,1,2);
u2(:,end) = -w(:,end-1,2);

u = u1 + u2;
end


end

