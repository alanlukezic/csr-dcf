function [fg_prior, bg_prior] = get_location_prior(roi, target_sz, img_sz)
    x1 = round(max(min(roi(1), img_sz(1)), 1));
    y1 = round(max(min(roi(2), img_sz(2)), 1));
    x2 = round(min(max(roi(3), 1), img_sz(1)));
    y2 = round(min(max(roi(4), 1), img_sz(2)));

    % make it rotationaly invariant
    target_sz = [min(target_sz) min(target_sz)];

    wh_i = 1/(0.5*target_sz(1)*1.4142+1);
    hh_i = 1/(0.5*target_sz(2)*1.4142+1);
    cx = x1+0.5*(x2-x1);
    cy = y1+0.5*(y2-y1);

    fg_prior = kernelProfileMultiple((repmat((x1-cx):(x2-cx), ...
        [length(y1:y2) 1]).*wh_i).^2 + (repmat([(y1-cy):(y2-cy)]', ...
        [1 length(x1:x2)]).*hh_i).^2);
    
    fg_prior = double(fg_prior./max(fg_prior(:)));
    
    fg_prior(fg_prior < 0.5) = 0.5;
    fg_prior(fg_prior > 0.9) = 0.9;
    bg_prior = double(1-fg_prior);

end

function [val] = kernelProfileMultiple(x)
    idx = x > 1;
    val = (2/3.14)*(ones(size(x,1), size(x,2))-x);
    val(idx) = 0;
end
