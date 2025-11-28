function r2 = pseudoR2(nll, task)
%function r2 = pseudoR2(nll, nsubj, ntrials)
% Function to calculate the pseudo R squared of a model
%   calculated as follows: pseudo-r^2 = 1 - (L/R) where L is the log likelihood of the
%   observed data under the winning model and R is the log likelihood of the data under chance
%   (Camerer & Ho, 1999; Daw, 2011)
%
%   Written by Jo Cutler April 2020, edited by Todd Vogel 2024
% edited by Emma Scholey 19 November 2025 for AET (n_trials depends on
% choices)

arguments
    nll (:, 1) double
    task struct
end

% calcuate the fit of the null model - repeated for the number of participants
n_choices = (task.blockTime*task.nBlocks)/mean([task.acceptTime, task.rejectTime] + 1);
nll_chance = -log(0.5)*n_choices;

L = mean(nll);
R = mean(nll_chance);

r2 = 1 - (L/R);
