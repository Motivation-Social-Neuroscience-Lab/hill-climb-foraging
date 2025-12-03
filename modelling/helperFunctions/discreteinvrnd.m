%For example, the following function implements an inversion method for a discrete distribution with probability mass vector p:

function X = discreteinvrnd(p,m,n)
    X = zeros(m,n); % Preallocate memory
    for i = 1:m*n
        u = rand;
        I = find(u < cumsum(p));
        X(i) = min(I);
    end
end
