function p = softmaxAccept(beta, value, oppCost, bias)

% softmaxAccept computes the probability of accepting the current offer
% P = softmaxAccept(BETA, BIAS, VALUE, OPPCOST) computes probability of accepting an offer given 
% value of offer VALUE and softmax temperature BETA, with BIAS capturing
% tendency to accept/reject options independent of values of action
%
% Emma S 15/05/23

p = (1 + exp(bias - beta * (value-oppCost)))^-1;

end