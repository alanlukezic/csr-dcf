function H = create_csr_filter(img, Y, P)
% CREATE_CSR_FILTER
% create filter with Augmented Lagrangian iterative optimization method
% input parameters:
% img: image patch (already normalized)
% Y: gaussian shaped labels (note that the peak must be at the top-left corner)
% P: padding mask (zeros around, 1 around the center), shape: box
% lambda: regularization parameter, i.e. 10e-2

mu = 5;
beta =  3;
mu_max = 20;
max_iters = 4;
lambda = mu/100;

F = fft2(img);

Sxy = bsxfun(@times, F, conj(Y));
Sxx = F.*conj(F);

% mask filter
H = fft2(bsxfun(@times, ifft2(bsxfun(@rdivide, Sxy, (Sxx + lambda))), P));
% initialize lagrangian multiplier
L = zeros(size(H));

iter = 1;
while true
    G = (Sxy + mu*H - L) ./ (Sxx + mu);
    H = fft2(real((1/(lambda + mu)) * bsxfun(@times, P, ifft2(mu*G + L))));

    % stop optimization after fixed number of steps
    if iter >= max_iters
        break;
    end
    
    % update variables for next iteration
    L = L + mu*(G - H);
    mu = min(mu_max, beta*mu);
    iter = iter + 1;
end

end  % endfunction
