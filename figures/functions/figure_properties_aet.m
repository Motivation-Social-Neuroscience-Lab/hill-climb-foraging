% figure properties for AET paper 

% format = 'png'; % for panels tricky for EPS (e.g. Pcolour plots)
% colour = 'rgb';
% dpi = 600;
% brewermap('demo') 
scale_inkscape = 1.25;

fontsize = 12 * scale_inkscape;
fontname = 'Arial';
M_alpha = 0.6; % marker alpha for scatter plots

Units = 'centimeters';

% line widths
widths.plot = 2;
widths.error = 0.5;
widths.axis = 0.5;

% panel sizes
figsize.square = [20 20 7*scale_inkscape 7*scale_inkscape];
figsize.horizontal = [20 20 10*scale_inkscape 5*scale_inkscape];
figsize.vertical = [20 20 5*scale_inkscape 7*scale_inkscape];
figsize.small_panel = [20 20 5.5*scale_inkscape 5.5*scale_inkscape];


% colours for lines
colour.easy = "#3C6B9D";
colour.hard = "#D85F59";
colour.subj_easy = "#A0B6CF";
colour.subj_hard = "#EEB1AC";

colour.effort = "#3E91A5";
colour.subj_effort = '#A3C8D3';

colour.reward = "#60487A";
colour.subj_reward = '#AEA5BB';

colour.model = "#F0BFAC";
colour.model_highlight = '#DE7F56';

colour.text = [0.3 0.3 0.3];

% line types 

% exportpath
export_path = './plots/';
