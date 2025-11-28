𝜌𝑖+1 = 𝜌𝑖 + [1 − (1 − 𝛼)𝜏𝑖 ] · 𝛿𝑖	(4.1)

 

𝛿𝑖
 
= 𝐸𝑖	𝜌
𝜏𝑖	𝑖
 

rho = 2;
alpha = 0.05;
e = 1;
tau = 8;

    rho = rho + (1-(1-alpha)^tau) * (e/tau - rho);

    % equivalent to: 
    rho = ((1-alpha)^tau) * rho + (1-(1-alpha)^tau) * e/tau % C&D equation (below Table 2), but they got it the wrong way round in the paper 



rho = 2;
alpha = 0.05;
e = 1;
tau = 8;

    rho = rho + alpha * (e - rho);
    for i = 1:(tau-1)
    rho = rho + alpha * (0 - rho);
    end
    rho

    % I think G&D did this because they needed to model positive vs
    % negative alpha separately. In my case, I can just do it in one lump
    % like Constantino? Very similar values suggests won't make big
    % difference



