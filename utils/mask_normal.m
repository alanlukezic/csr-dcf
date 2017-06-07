function ok = mask_normal(mask_bin, obj_area, varargin)

    lower_thresh = 0.05;
    if length(varargin) > 0
        lower_thresh = varargin{1};
    end

    area_m = sum(mask_bin(:) > 0);

    ok = true;
    if isnan(area_m) || area_m < obj_area*lower_thresh
        ok = false;
    end

end  % endfunction
