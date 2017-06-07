function regions = read_vot_regions(filename)
% READ_VOT_REGIONS
% reads vot ground-truth regions and transforms them to axis-aligned

    regions = dlmread(filename);
    if size(regions,2) > 4,
        x1 = round(min(regions(:, 1:2:end), [], 2));
        x2 = round(max(regions(:, 1:2:end), [], 2));
        y1 = round(min(regions(:, 2:2:end), [], 2));
        y2 = round(max(regions(:, 2:2:end), [], 2));
        regions = round([x1, y1, x2 - x1, y2 - y1]);
    end

end  % endfunction

