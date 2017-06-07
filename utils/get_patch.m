function [im, valid_pixels_mask] = get_patch(img, c, scale, template_size)

    % calculate size of the patch
    w = floor(scale*template_size(1));
    h = floor(scale*template_size(2));

    % extraction indexes
    xs = floor(c(1)) + (1:w) - floor(w/2);
    ys = floor(c(2)) + (1:h) - floor(h/2);

    % find which pixels are outside of image
    ym = [find(ys<1), find(ys>size(img,1))];
    xm = [find(xs<1), find(xs>size(img,2))];
    valid_pixels_mask = ones([h, w]);
    valid_pixels_mask(ym, :) = 0;
    valid_pixels_mask(:, xm) = 0;

    % handle border cases: replicate border pixels
    xs(xs < 1) = 1;
    ys(ys < 1) = 1;
    xs(xs > size(img,2)) = size(img,2);
    ys(ys > size(img,1)) = size(img,1);

    im = img(ys, xs, :);

end  % endfunction











