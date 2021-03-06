% @author: Maziar Raissi

function main()
%% Pre-processing
clc; close all;
rng('default')

save_plt = 1;

addpath ./Utilities
addpath ./Utilities/export_fig

    function CleanupFun()
        rmpath ./Utilities
        rmpath ./Utilities/export_fig
    end

finishup = onCleanup(@() CleanupFun());
set(0,'defaulttextinterpreter','latex')

%% Setup
N_L = 11;
N_H = 4;
D = 1;
lb = 0.0*ones(1,D);
ub = 1.0*ones(1,D);
noise_L = 0.00;
noise_H = 0.00;

%% Generate Data
function f=f_H(x)
    f = (6.0*x-2.0).^2.*sin(12.0*x-4.0);   
end
X_H = bsxfun(@plus,lb,bsxfun(@times,   lhsdesign(N_H,D)    ,(ub-lb)));
y_H = f_H(X_H);
y_H = y_H + noise_H*std(y_H)*randn(N_H,1);

function f=f_L(x)
    f = 0.5*f_H(x) + 10.0*(x-0.5) - 5.0;
end
X_L = bsxfun(@plus,lb,bsxfun(@times,   lhsdesign(N_L,D)    ,(ub-lb)));
y_L = f_L(X_L);
y_L = y_L + noise_L*std(y_L)*randn(N_L,1);

N_star = 200;
X_star = linspace(lb(1), ub(1), N_star)';
f_H_star = f_H(X_star);
f_L_star = f_L(X_star);

%% Model Definition
model = Multifidelity_GP(X_L, y_L, X_H, y_H);

%% Model Training
model = model.train();

%% Make Predictions
[mean_f_H_star, var_f_H_star] = model.predict_H(X_star);

fprintf(1,'Relative L2 error f_H: %e\n', (norm(mean_f_H_star-f_H_star,2)/norm(f_H_star,2)));

%% Plot results
color = [217,95,2]/255;

fig = figure(1);
set(fig,'units','normalized','outerposition',[0 0 1 0.4])

subplot(1,2,1);
clear h;
clear leg;
hold
h(1) = plot(X_star, f_L_star,'b','LineWidth',3);
h(2) = plot(X_L, y_L,'ro','MarkerSize',14, 'LineWidth',2);

leg{1} = '$f_L(x)$';
leg{2} = sprintf('%d low-fidelity training data', N_L);

hl = legend(h,leg,'Location','northwest');
legend boxoff
set(hl,'Interpreter','latex')
xlabel('$x$')
ylabel('$f_L(x)$')
title('(A)');

axis square
ylim(ylim + [-diff(ylim)/10 0]);
xlim(xlim + [-diff(xlim)/10 0]);
set(gca,'FontSize',16);
set(gcf, 'Color', 'w');

subplot(1,2,2);
clear h;
clear leg;
hold
h(1) = plot(X_star, f_H_star,'b','LineWidth',3);
h(2) = plot(X_H, y_H,'ro','MarkerSize',14, 'LineWidth',2);
h(3) = plot(X_star,mean_f_H_star,'r--','LineWidth',3);
[l,h(4)] = boundedline(X_star, mean_f_H_star, 2.0*sqrt(var_f_H_star), ':', 'alpha','cmap', color);
outlinebounds(l,h(4));

leg{1} = '$f_H(x)$';
leg{2} = sprintf('%d high-fidelity training data', N_H);
leg{3} = '$\overline{f}_H(x)$'; leg{4} = 'Two standard deviations';

hl = legend(h,leg,'Location','northwest');
legend boxoff
set(hl,'Interpreter','latex')
xlabel('$x$')
ylabel('$f_H(x), \overline{f}_H(x)$')
title('(B)');

axis square
ylim(ylim + [-diff(ylim)/10 0]);
xlim(xlim + [-diff(xlim)/10 0]);
set(gca,'FontSize',16);
set(gcf, 'Color', 'w');

if save_plt == 1
    export_fig ./Figures/MGP_1D_Example.png -r300
end

end