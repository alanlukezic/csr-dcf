function [tracker, region] = track_csr_tracker(tracker, img)

    % is the previous frame same as this one ?
    if duplicate_frames(img, tracker.img_prev)
        tracker.img_prev = img;
        region = tracker.bb;
        return;
    end

    tracker.img_prev = img;

    %% ------------------- TRACKING PHASE -------------------
    % extract features
    f = get_csr_features(img, tracker.c, tracker.currentScaleFactor, ...
        tracker.template_size, tracker.rescale_template_size, ...
        tracker.cos_win, tracker.feature_type, tracker.w2c, tracker.cell_size);

    if ~tracker.use_channel_weights
        response = real(ifft2(sum(fft2(f).*conj(tracker.H), 3)));
    else
        response_chann = real(ifft2(fft2(f).*conj(tracker.H)));
        response = sum(bsxfun(@times, response_chann, reshape(tracker.chann_w, 1, 1, size(response_chann,3))), 3);
    end
    
    % find position of the maximum
    [row, col] = ind2sub(size(response),find(response == max(response(:)), 1));

    % calculate detection-based weights
    if tracker.use_channel_weights
        channel_discr = ones(1, size(response_chann, 3));
        for i = 1:size(response_chann, 3)
            norm_response = normalize_img(response_chann(:, :, i));
            local_maxs_sorted = localmax_nonmaxsup2d(squeeze(norm_response(:, :)));

            if local_maxs_sorted(1) == 0, continue; end;
            channel_discr(i) = 1 - (local_maxs_sorted(2) / local_maxs_sorted(1));

            % sanity checks
            if channel_discr(i) < 0.5, channel_discr(i) = 0.5; end;
        end
    end

    % subpixel accuracy: response map is smaller than image patch -
    % due to HoG histogram (cell_size > 1)
    v_neighbors = response(mod(row + [-1, 0, 1] - 1, size(response,1)) + 1, col);
    h_neighbors = response(row, mod(col + [-1, 0, 1] - 1, size(response,2)) + 1);
    row = row + subpixel_peak(v_neighbors);
    col = col + subpixel_peak(h_neighbors);

    % wrap around 
    if row > size(response,1) / 2,
        row = row - size(response,1);
    end
    if col > size(response,2) / 2,
        col = col - size(response,2);
    end

    % displacement
    d = tracker.currentScaleFactor * tracker.cell_size * ...
        (1/tracker.rescale_ratio) * [col - 1, row - 1];
    
    % new object center
    c = tracker.c + d;

    % object bounding-box
    region = [c - tracker.currentScaleFactor * tracker.base_target_sz/2, ...
        tracker.currentScaleFactor * tracker.base_target_sz];

    %do a scale space search aswell
    xs = get_scale_subwindow(img, c([2,1]), tracker.base_target_sz([2,1]), ...
        tracker.currentScaleFactor * tracker.scaleSizeFactors, ...
        tracker.scale_window, tracker.scale_model_sz([2,1]), []);
    xsf = fft(xs,[],2);
    % scale correlation response
    scale_response = real(ifft(sum(tracker.sf_num .* xsf, 1) ./ (tracker.sf_den + 1e-2) ));
    recovered_scale = ind2sub(size(scale_response),find(scale_response == max(scale_response(:)), 1));
    %set the scale
    currentScaleFactor = tracker.currentScaleFactor * tracker.scaleFactors(recovered_scale);

    % check for min/max scale
    if currentScaleFactor < tracker.min_scale_factor
        currentScaleFactor = tracker.min_scale_factor;
    elseif currentScaleFactor > tracker.max_scale_factor
        currentScaleFactor = tracker.max_scale_factor;
    end
    % new tracker scale
    tracker.currentScaleFactor = currentScaleFactor;

    % put new object location into the tracker structure
    tracker.c = c;
    tracker.bb = region;
    
    %% ------------------- LEARNING PHASE -------------------
    if tracker.use_segmentation
        % convert image in desired colorspace
        if strcmp(tracker.seg_colorspace, 'rgb')
            seg_img = img;
        elseif strcmp(tracker.seg_colorspace, 'hsv')
            seg_img = rgb2hsv(img);
            seg_img = seg_img * 255;
        else
            error('Unknown colorspace parameter');
        end

        % object rectangle region: subtract 1 because C++ indexing starts with zero
        obj_reg = round([region(1), region(2), region(1)+region(3), region(2)+region(4)]) - [1 1 1 1];

        % extract histograms and update them
        hist_fg = mex_extractforeground(seg_img, obj_reg, tracker.nbins);
        hist_bg = mex_extractbackground(seg_img, obj_reg, tracker.nbins);
        tracker.hist_fg = (1-tracker.hist_lr)*tracker.hist_fg + tracker.hist_lr*hist_fg;
        tracker.hist_bg = (1-tracker.hist_lr)*tracker.hist_bg + tracker.hist_lr*hist_bg;

        % extract masked patch: mask out parts outside image
        [seg_patch, valid_pixels_mask] = get_patch(seg_img, tracker.c, ...
            tracker.currentScaleFactor, tracker.template_size);

        % segmentation
        [fg_p, bg_p] = get_location_prior([1, 1, size(seg_patch,2), size(seg_patch,1)], ...
            tracker.currentScaleFactor*tracker.base_target_sz, [size(seg_patch,2), size(seg_patch, 1)]);
        [~, fg, ~] = mex_segment(seg_patch, tracker.hist_fg, tracker.hist_bg, tracker.nbins, fg_p, bg_p);
        
        % cut out regions outside from image
        mask = single(fg).*single(valid_pixels_mask);
        mask = binarize_softmask(mask);

        % resize to filter size
        mask = imresize(mask, size(tracker.Y), 'nearest');

        % check if mask is too small (probably segmentation is not ok then)
        if mask_normal(mask, tracker.target_dummy_area)
            if tracker.mask_diletation_sz > 0
                D = strel(tracker.mask_diletation_type, tracker.mask_diletation_sz);
                mask = imdilate(mask, D);
            end
        else
            mask = tracker.target_dummy_mask;
        end

    else
        
        mask = tracker.target_dummy_mask;

    end

    % extract features from image
    f = get_csr_features(img, tracker.c, tracker.currentScaleFactor, ...
        tracker.template_size, tracker.rescale_template_size, tracker.cos_win, ...
        tracker.feature_type, tracker.w2c, tracker.cell_size);

    % calcualte new filter - using segmentation mask
    H_new = create_csr_filter(f, tracker.Y, single(mask));

    % calculate per-channel feature weights
    if tracker.use_channel_weights
        w_lr = tracker.weight_lr;
        response = real(ifft2(fft2(f).*conj(H_new)));
        chann_w = max(reshape(response, [size(response,1)*size(response,2), size(response,3)]), [], 1) .* channel_discr;
        chann_w = chann_w / sum(chann_w);
        tracker.chann_w = (1-w_lr)*tracker.chann_w + w_lr*chann_w;
        tracker.chann_w = tracker.chann_w / sum(tracker.chann_w);
    end

    % auto-regresive filter update
    lr = tracker.learning_rate;
    tracker.H = (1-lr)*tracker.H + lr*H_new;

    % make a scale search model aswell
    xs = get_scale_subwindow(img, tracker.c([2,1]), tracker.base_target_sz([2,1]), ...
        tracker.currentScaleFactor * tracker.scaleSizeFactors, ...
        tracker.scale_window, tracker.scale_model_sz([2,1]), []);
    % fft over the scale dim
    xsf = fft(xs,[],2);
    new_sf_num = bsxfun(@times, tracker.ysf, conj(xsf));
    new_sf_den = sum(xsf .* conj(xsf), 1);
    % auto-regressive scale filters update
    slr = tracker.scale_lr;
    tracker.sf_den = (1 - slr) * tracker.sf_den + slr * new_sf_den;
    tracker.sf_num = (1 - slr) * tracker.sf_num + slr * new_sf_num;

end  % endfunction


function delta = subpixel_peak(p)
	%parabola model (2nd order fit)
	delta = 0.5 * (p(3) - p(1)) / (2 * p(2) - p(3) - p(1));
	if ~isfinite(delta), delta = 0; end
end  % endfunction

function dupl = duplicate_frames(img, img_prev)
    dupl = false;
    I_diff = abs(single(img) - single(img_prev));
    if mean(I_diff(:)) < 0.5
        dupl = true;
    end
end  % endfunction

function [local_max] = localmax_nonmaxsup2d(response)
    BW = imregionalmax(response);
    CC = bwconncomp(BW);

    local_max = [max(response(:)) 0];
    if length(CC.PixelIdxList) > 1
        local_max = zeros(length(CC.PixelIdxList));
        for i = 1:length(CC.PixelIdxList)
            local_max(i) = response(CC.PixelIdxList{i}(1));
        end
        local_max = sort(local_max, 'descend');
    end
end  % endfunction

function out = normalize_img(img)
    min_val = min(img(:));
    max_val = max(img(:));
    if (max_val - min_val) > 0
        out = (img - min_val)/(max_val - min_val);
    else
        out = zeros(size(img));
    end
end  % endfunction
