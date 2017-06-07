function labels = gaussian_shaped_labels(magnitude, sigma, sz)
%   GAUSSIAN_SHAPED_LABELS
%   Gaussian-shaped labels for all shifts of a sample.
%
%   LABELS = GAUSSIAN_SHAPED_LABELS(MAGNITUDE, SIGMA, SZ)
%   Creates an array of labels (regression targets) for all shifts of a
%   sample of dimensions SZ. The output will have size SZ, representing
%   one label for each possible shift. The labels will be Gaussian-shaped,
%   with the peak at 0-shift (top-left element of the array), decaying
%   as the distance increases, and wrapping around at the borders.
%   The Gaussian function is scaled by MAGNITUDE and has spatial bandwidth
%   SIGMA.
%
%   Joao F. Henriques, 2013

% 	%for reference, a Diract delta instead of a Gaussian would look like:
% 	labels = zeros(sz(1:2));  %labels for all shifted samples
% 	labels(1,1) = magnitude;  %label for 0-shift (original sample)


	%evaluate a Gaussian with the peak at the center element
	[rs, cs] = ndgrid((1:sz(1)) - floor(sz(1)/2), (1:sz(2)) - floor(sz(2)/2));
	labels = exp(-0.5 / sigma^2 * (rs.^2 + cs.^2));
	
	%move the peak to the top-left, with wrap-around
	labels = circshift(labels, -floor(sz(1:2) / 2) + 1);
	
	%sanity check: make sure it's really at top-left
	assert(labels(1,1) == 1)
	
	%scale by magnitude
	labels = magnitude * labels;

end