function Mb = binarize_softmask(M, varargin)
% BINARIZE_SOFTMASK
% binarize mask so that mask is first put on the [0,1] interval

    binary_threshold = 0.5;
    if length(varargin) > 0
        binary_threshold = varargin{1};
    end

    max_val = max(M(:));
    if max_val <= 0
        max_val = 1.;
    end

    M = M./max_val;
    Mb = M;
    Mb(Mb>binary_threshold) = 1;
    Mb(Mb<1) = 0;

end  % endfunction
