function run_caffeine_pilot
% Group-mean curve and summary feasibility pilot; base MATLAB only.
% Digitized points are approximate and are not individual records.
root = fileparts(mfilename('fullpath'));
out = fullfile(root, 'output');
if ~exist(out, 'dir'), mkdir(out); end
S = readtable(fullfile(root, 'data', 'teekachunhatean2013_oral_summary.csv'), TextType='string', Delimiter=',', NumHeaderLines=0);
P = readtable(fullfile(root, 'data', 'teekachunhatean2013_protocol.csv'), Delimiter=',', NumHeaderLines=0);
L = readtable(fullfile(root, 'data', 'lin2022_saliva_summary.csv'), TextType='string', Delimiter=',', NumHeaderLines=0);
getMean = @(name) S.mean(S.metric == name);
D = P.dose_mg;
ke = log(2) / getMean("half_life");
tp = getMean("tmax");
ka = fzero(@(a) log(a/ke)/(a-ke) - tp, [ke*1.0001, 100]);
V = D*ka/(ka-ke)*(exp(-ke*tp)-exp(-ka*tp))/getMean("cmax");
% These effective parameters match three aggregate summaries by construction.
writetable(table(ka,ke,V,log(2)/ke,'VariableNames', ...
    {'ka_per_h','ke_per_h','apparent_volume_L','half_life_h'}), fullfile(out,'effective_parameters.csv'));

t = unique([linspace(0,12,2401), tp])';
[C,X] = solveModel(t,0,D,ka,ke,V,1e-7,[0;0;0]);
[Ct,~] = solveModel(t,0,D,ka,ke,V,1e-10,[0;0;0]);
Ca = analytic(t,0,D,ka,ke,V);
C0 = analytic(t,0,D,Inf,ke,V);
auc1 = trapz(t,C); auc0 = trapz(t,C0);
aucInf1 = D/(V*ke); aucInf0 = aucInf1;
metric = ["auc_0_12";"auc_inf"];
observed = [getMean("auc_0_12");getMean("auc_inf")];
candidate = [auc1;aucInf1]; baseline = [auc0;aucInf0];
context = repmat("Unused same-study summaries; not independent validation",2,1);
writetable(table(metric,observed,baseline,candidate,100*(candidate./observed-1),context, ...
    'VariableNames',{'metric','observed','baseline','candidate','candidate_error_percent','interpretation'}), ...
    fullfile(out,'summary_checks.csv'));

% External, scale-free endpoint check: a different study and saliva matrix.
W = sortrows(L(L.condition=="acute_caffeine_deprivation" & L.analyte=="caffeine",:),'sample_id');
observedRatio = W.mean_mg_L(end)/W.mean_mg_L(1);
predictedRatio = exp(-ke*(43-24));
effectiveTailHalfLife = -(43-24)*log(2)/log(observedRatio);
writetable(table(observedRatio,predictedRatio,effectiveTailHalfLife, ...
    "Ratio of group means; constant saliva/plasma scaling and negligible background assumed", ...
    'VariableNames',{'observed_43h_over_24h','predicted_ratio','endpoint_effective_half_life_h','limitation'}), ...
    fullfile(out,'external_endpoint_check.csv'));

% Numerical checks cover special cases that are not fitted to observations.
tr = unique([linspace(0,20,2001),6])';
[Cr,Xr] = solveModel(tr,[0,6],[100,100],ka,ke,V,1e-9,[0;0;0]);
repeatError = max(abs(Cr-analytic(tr,[0,6],[100,100],ka,ke,V)));
[Cn,~] = solveModel(tr,[],[],ka,ke,V,1e-9,[0;20;0]);
initialError = max(abs(Cn-20/V*exp(-ke*tr)));
balanceError = max(abs(sum(X,2)-D));
tolChange = abs(trapz(t,Ct)-auc1)/auc1;
checks = [max(abs(C-Ca));repeatError;initialError;balanceError;tolChange;min(X(:))];
name = ["single_dose_max_abs_error_mg_L";"repeat_dose_max_abs_error_mg_L"; ...
    "nonzero_initial_max_abs_error_mg_L";"mass_balance_max_error_mg"; ...
    "auc_relative_tolerance_change";"minimum_state_mg"];
passed = [checks(1:3)<1e-5;checks(4)<1e-5;checks(5)<0.01;checks(6)>-1e-8];
writetable(table(name,checks,passed),fullfile(out,'numerical_checks.csv'));
assert(all(passed),'A numerical verification failed.');

f = figure('Visible','off','Position',[100,100,1100,450]);
subplot(1,2,1);
plot(t,C0,'--',t,C,'-','LineWidth',1.6); hold on;
plot(tp,getMean("cmax"),'ko','MarkerFaceColor','k');
xlabel('Hours after intake'); ylabel('Plasma caffeine (mg/L)');
legend('Instant absorption baseline','Absorption model','Published mean peak anchor','Location','northeast');
title('Summary-anchored illustration; not a trajectory fit'); grid on;
subplot(1,2,2);
bar([observed,baseline,candidate]);
xticklabels({'AUC 0-12 h','AUC 0-infinity'}); ylabel('AUC (mg h/L)');
legend('Published summary','Baseline','Absorption model','Location','northwest');
title('Unused summary checks from the same study');
exportgraphics(f,fullfile(out,'summary_anchor_check.png'),'Resolution',180); close(f);

% Fixed within-curve split. These holdouts are not new participants or studies.
R=readtable(fullfile(root,'data','teekachunhatean2013_cc_digitized.csv'), ...
    TextType='string',Delimiter=',',NumHeaderLines=0);
train=R.split=="calibration"; test=R.split=="holdout";
opts=optimset('Display','off','MaxFunEvals',5000,'MaxIter',2500,'TolX',1e-9,'TolFun',1e-11);
fitRows=[];
for a=[1,3,10]
    for h=[3,5,8]
        e=log(2)/h;
        [q,sse]=fminsearch(@(q) curveLoss(q,R.time_h(train),R.mean_mg_L(train),D,false), ...
            [log(e),log(a-e),log(40)],opts);
        fitRows(end+1,:)=[sse,exp(q(1))+exp(q(2)),exp(q(1)),exp(q(3))];
    end
end
fitRows=sortrows(fitRows,1); ka=fitRows(1,2); ke=fitRows(1,3); V=fitRows(1,4);
[qb,~]=fminsearch(@(q) curveLoss(q,R.time_h(train),R.mean_mg_L(train),D,true), ...
    [log(0.14),log(40)],opts);
ke0=exp(qb(1)); V0=exp(qb(2));
writetable(table(ke0,V0,log(2)/ke0,'VariableNames', ...
    {'ke_per_h','apparent_volume_L','effective_half_life_h'}),fullfile(out,'baseline_parameters.csv'));
fitCandidate=analytic(R.time_h,0,D,ka,ke,V);
fitBaseline=analytic(R.time_h,0,D,Inf,ke0,V0);
model=["instant_absorption";"gut_plus_central"];
trainRMSE=[sqrt(mean((fitBaseline(train)-R.mean_mg_L(train)).^2)); ...
    sqrt(mean((fitCandidate(train)-R.mean_mg_L(train)).^2))];
holdoutRMSE=[sqrt(mean((fitBaseline(test)-R.mean_mg_L(test)).^2)); ...
    sqrt(mean((fitCandidate(test)-R.mean_mg_L(test)).^2))];
writetable(table(model,trainRMSE,holdoutRMSE),fullfile(out,'curve_evaluation.csv'));
writetable(array2table(fitRows,'VariableNames',{'sse','ka_per_h','ke_per_h','apparent_volume_L'}), ...
    fullfile(out,'curve_multistart.csv'));
writetable(table(ka,ke,V,log(2)/ke,'VariableNames', ...
    {'ka_per_h','ke_per_h','apparent_volume_L','effective_half_life_h'}),fullfile(out,'curve_parameters.csv'));
endpointCheck=readtable(fullfile(out,'external_endpoint_check.csv'),Delimiter=',',NumHeaderLines=0);
endpointCheck.curve_fitted_predicted_ratio=exp(-ke*19);
writetable(endpointCheck,fullfile(out,'external_endpoint_check.csv'));
writetable([R,table(fitBaseline,fitCandidate)],fullfile(out,'curve_predictions.csv'));
tc=unique([linspace(0,12,2401),R.time_h'])';
[odeC,~]=solveModel(tc,0,D,ka,ke,V,1e-8,[0;0;0]);
[odeCt,~]=solveModel(tc,0,D,ka,ke,V,1e-11,[0;0;0]);
curveOdeError=max(abs(odeC-analytic(tc,0,D,ka,ke,V)));
curveToleranceChange=abs(trapz(tc,odeC)-trapz(tc,odeCt))/trapz(tc,odeCt);
assert(curveOdeError<1e-5,'Fitted curve ODE check failed.');
assert(curveToleranceChange<0.01,'Fitted curve tolerance check failed.');
writetable(table(curveOdeError,curveToleranceChange),fullfile(out,'curve_numerical_checks.csv'));
f=figure('Visible','off','Position',[100,100,1100,450]);
subplot(1,2,1);
plot(tc,analytic(tc,0,D,Inf,ke0,V0),'--',tc,odeC,'-','LineWidth',1.6); hold on;
errorbar(R.time_h(train),R.mean_mg_L(train),R.extraction_envelope_mg_L(train),'ko','MarkerFaceColor','k');
errorbar(R.time_h(test),R.mean_mg_L(test),R.extraction_envelope_mg_L(test),'rs','MarkerFaceColor','w');
xlabel('Hours after oral coffee'); ylabel('Mean plasma caffeine (mg/L)'); grid on;
legend('Fitted baseline','Fitted absorption model','Calibration means','Withheld means');
title('Digitized group means; extraction bars', 'FontSize',12);
subplot(1,2,2);
bar([trainRMSE,holdoutRMSE]); xticklabels({'Instant absorption','Gut + central'});
ylabel('RMSE (mg/L)'); legend('Calibration','Within-curve holdout');
title('Withheld points from the same curve', 'FontSize',12);
exportgraphics(f,fullfile(out,'first_plot.png'),'Resolution',180); close(f);

% Keep calibration uncertainty distinct: bounded pixel perturbation scenarios.
rng(213,'twister'); perturb=zeros(100,5);
for j=1:100
    y=R.mean_mg_L(train)+(2*rand(sum(train),1)-1).*R.extraction_envelope_mg_L(train);
    q=fminsearch(@(q) curveLoss(q,R.time_h(train),y,D,false), ...
        [log(ke),log(ka-ke),log(V)],opts);
    ej=exp(q(1)); aj=ej+exp(q(2)); vj=exp(q(3));
    perturb(j,:)=[aj,ej,vj,analytic(14,[0,6],[100,100],aj,ej,vj), ...
        sqrt(mean((analytic(R.time_h(test),0,D,aj,ej,vj)-R.mean_mg_L(test)).^2))];
end
writetable(array2table(perturb,'VariableNames',{'ka_per_h','ke_per_h','volume_L','split_c22_mg_L','holdout_rmse_mg_L'}), ...
    fullfile(out,'extraction_sensitivity.csv'));

% Paired scenarios: identical clearance draws for all four schedules.
scheduleNames = ["200mg_08";"100mg_08_14";"100mg_08_12";"100mg_08_16"];
times = {0,[0,6],[0,4],[0,8]}; doses = {200,[100,100],[100,100],[100,100]};
ts = (0:0.01:24)';
f = figure('Visible','off','Position',[100,100,1100,450]);
results = zeros(4,7);
for k=1:4
    a = analytic(ts,times{k},doses{k},ka,ke,V);
    b = analytic(ts,times{k},doses{k},Inf,ke0,V0);
    results(k,:) = [max(a(ts<=14)),a(ts==14),a(end),max(b(ts<=14)),b(ts==14),b(end),sum(doses{k})];
    subplot(1,2,1+(k>2)); hold on;
    plot(ts,a,'LineWidth',1.6,'DisplayName',strrep(scheduleNames(k),'_',' '));
end
for k=1:2
    subplot(1,2,k); xline(14,':','22:00','HandleVisibility','off'); xlabel('Hours after 08:00');
    ylabel('Plasma caffeine (mg/L)'); legend('Location','northeast'); grid on;
end
exportgraphics(f,fullfile(out,'schedule_comparison.png'),'Resolution',180); close(f);
writetable([table(scheduleNames),array2table(results,'VariableNames', ...
    {'candidate_peak_to_22','candidate_at_22','candidate_next_08','baseline_peak_to_22', ...
    'baseline_at_22','baseline_next_08','total_dose_mg'})],fullfile(out,'schedule_metrics.csv'));

rng(212,'twister'); n = 5000;
muH = getMean("half_life"); sdH = S.sd(S.metric=="half_life");
sigma = sqrt(log(1+(sdH/muH)^2)); mu = log(muH)-sigma^2/2;
half = exp(mu+sigma*randn(n,1));
c22 = zeros(n,4);
for j=1:n
    for k=1:4
        c22(j,k) = analytic(14,times{k},doses{k},ka,log(2)/half(j),V);
    end
end
delta = [c22(:,2)-c22(:,1),c22(:,4)-c22(:,3)];
caseName = ["Split afternoon minus all morning";"16:00 dose minus 12:00 dose"];
q = zeros(2,3);
for k=1:2, q(k,:) = localQuantile(delta(:,k),[0.025,0.5,0.975]); end
writetable([table(caseName),array2table(q,'VariableNames',{'delta22_p025','delta22_median','delta22_p975'})], ...
    fullfile(out,'paired_uncertainty.csv'));
writetable(table(half,c22(:,1),c22(:,2),c22(:,3),c22(:,4),'VariableNames', ...
    {'half_life_h','c22_all_morning','c22_split_14','c22_split_12','c22_split_16'}), ...
    fullfile(out,'scenario_draws.csv'));

% One-at-a-time exploratory sensitivity, not empirical population ranges.
sen = []; label = strings(0,1);
for h=[2,4.87,8]
    sen(end+1,:)=[ka,h,analytic(14,[0,6],[100,100],ka,log(2)/h,V)];
    label(end+1,1)="half_life_sweep";
end
for a=[1,3,10]
    sen(end+1,:)=[a,log(2)/ke,analytic(14,[0,6],[100,100],a,ke,V)];
    label(end+1,1)="absorption_sweep";
end
writetable([table(label),array2table(sen,'VariableNames',{'ka_per_h','half_life_h','c22_mg_L'})], ...
    fullfile(out,'sensitivity.csv'));
fprintf('Pilot complete. Effective ka=%.6f /h; ke=%.6f /h; V/F=%.6f L.\n',ka,ke,V);
fprintf('The following AUC table is the separate summary-anchor check, not the curve fit.\n');
disp(readtable(fullfile(out,'summary_checks.csv')));
fprintf('Schedule predictions below use the fitted group-mean curve parameters.\n');
disp(readtable(fullfile(out,'schedule_metrics.csv')));
end

function loss=curveLoss(q,t,y,dose,isBaseline)
ke=exp(q(1));
if isBaseline, ka=Inf; V=exp(q(2)); else, ka=ke+exp(q(2)); V=exp(q(3)); end
if ke<0.02 || ke>1 || V<5 || V>150 || (~isBaseline && ka>100)
    loss=1e9+sum(q.^2); return
end
loss=sum((analytic(t,0,dose,ka,ke,V)-y).^2);
end

function C = analytic(t,doseTimes,doses,ka,ke,V)
C = zeros(size(t));
for k=1:numel(doseTimes)
    use = t>=doseTimes(k); lag=t(use)-doseTimes(k);
    if isinf(ka)
        C(use)=C(use)+doses(k)/V*exp(-ke*lag);
    elseif abs(ka-ke)<1e-10
        C(use)=C(use)+doses(k)/V*ka*lag.*exp(-ke*lag);
    else
        C(use)=C(use)+doses(k)/V*ka/(ka-ke)*(exp(-ke*lag)-exp(-ka*lag));
    end
end
end

function [C,X] = solveModel(t,doseTimes,doses,ka,ke,V,tol,initial)
% Third state is cumulative eliminated dose-equivalent mass for verification.
knots=unique([0,doseTimes,t(end)]); X=nan(numel(t),3); state=initial;
opts=odeset('RelTol',tol,'AbsTol',tol*0.01,'NonNegative',1:3);
for k=1:numel(knots)-1
    left=knots(k); right=knots(k+1);
    state(1)=state(1)+sum(doses(doseTimes==left));
    sol=ode45(@(~,x)[-ka*x(1);ka*x(1)-ke*x(2);ke*x(2)],[left,right],state,opts);
    use=t>=left & t<=right;
    X(use,:)=deval(sol,t(use))'; state=deval(sol,right);
end
C=X(:,2)/V;
end

function q = localQuantile(x,p)
x=sort(x); pos=1+(numel(x)-1)*p; lo=floor(pos); hi=ceil(pos);
q=x(lo)'.*(hi-pos)+x(hi)'.*(pos-lo);
same=lo==hi; q(same)=x(lo(same));
end
