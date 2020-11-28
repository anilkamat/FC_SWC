clc; clear all; close all;
names = {'S7-D14';'S7-D13';'S7-D12';'S7-D11';'S6-D12';'S6-D11';'S6-D10';'S6-D9';'S5-D10';'S5-D9';'S5-D8';...
    'S5-D7';'S4-D8';'S4-D7';'S4-D6';'S4-D5';'S8-D16';'S8-D15';'S3-D4';'S3-D3';...
    'S2-D3';'S2-D2';'S1-D2';'S1-D1'};
connections = {'RPMC-LPMC';'RPMC-LSMA ';'RPMC-LSMA';'RPMC-RPFC';'RPMC-LPFC';'LPMC-RSMA';...
    'LPMC-LSMA';'LPMC-RPFC';'LPMC-LPFC';'RSMA-LSMA ';'RSMA-RPFC';'RSMA-LPFC';...
    'LSMA-RPFC';'LSMA-LPFC';'RPFC-LPFC'};
MWC = cell(8,8);  % row = subjects
reg_conn = cell(8,4);    % row = subjects and column = windows (depends upon the time of trial.)
for s = 1:8   % subject
    currentdirectory = pwd;
    cd = currentdirectory(1:3);
    fpath = sprintf('D:\\RPI\\ResearchWork\\Papers_\\Arun_data_codes\\FLS\\SWC_FC\\Sub_%d',s);  % current directory to read from
    for i = 1:1          % day
        for t = 1:1      % trial
            p = 1;       % initialization of # of windows
            close all;
            A = zeros(6);
            file = sprintf('D%dT%d.txt',i,t);
            fullFileName = fullfile(fpath, file);
            D = importdata(fullFileName);
            C = D.data(:,2:33);   % extracting HBO
            B = C;
            %B(:,23) = [];
            B(:,abs(min(B))<3.3220e-10) = [];
            [M,N] = size(B);
            window_size = 1260;   % window size of 1 min %420 for 20 sec
            T = 378;              %stride of 1 min
            for w = window_size+1:T:M
                %B(w-window_size:w,:);
                [MWC{s,p},P_val] = corrcoef(B(w-window_size:w,:));
                Corre_HbO = MWC{s,p};
                %indices of p value greater than 0.01 for permutation threshold
                indices=[];
                Corre_thres_HbO = Corre_HbO;
                for r = 1:size((P_val),1)     % going through Rows
                    for c = 1:size((P_val),2)     % going through Cols
                        if P_val(r,c)> 0.01 && r~= c
                            indices =[indices;[r,c]];
                            Corre_thres_HbO(r,c) = 0;
                        end
                    end
                end
                figure(1) % heat map
                h = heatmap(Corre_thres_HbO,'Colormap', jet,'FontSize',10);
                h.XDisplayLabels = names;
                h.YDisplayLabels = names;
                title_HbO = sprintf('Heat Map:Correlation of  HbO from all the channels,day%d',i);
                h.Title = title_HbO;
                xlabel('Channel Name')
                ylabel('Channel Name')
                baseFileName = sprintf('day%d-T%d-WS-1min-SWC-HbO%d.png',i,t,p);
                fullFileName = fullfile(fpath, baseFileName);
                saveas(figure(1),fullFileName)
                % connectogram
                A = region_connectivity(Corre_thres_HbO);
                thres = 0.001;
                A = A + A' + diag(ones(6,1));
                A(A <= thres) = 0;
                reg_conn{s,p} = A;
                
                figure(2)
                circ_graph_region(A);
                title = sprintf('Connectogram-HbO-day%d-T%d trial-SWC%d-Hbo',i,t,p);
                colorbar;
                baseFileName = sprintf('day%d_T%d-WS-1min-trials_SWC%d_Hbo.png',i,t,p);
                fullFileName = fullfile(fpath, baseFileName);
                %saveas(figure(2),fullFileName)
                p = p+1;
            end
        end
    end
end
%% distribution Connectivity distribution across subjects
Q = cell(1,11);      % column = number of windows
for i = 1:11
    L = zeros(8,36);
    for j = 1:8
        %reshape(M{i,j},1,[])
        L(j,:) = reshape(tril(reg_conn{j,i},-1),1,[]); % reshape(M{i,j},1,[]);% K = array after  reshape of each sub; M == array regional connect across daysto reshape
    end
    L(:,all(L == 0))=[]; % removes the columns with all zero
    Q{1,i} = L;          % Q is for Windows
end
%% box plot across subjects
for z = 1:11 %1:4  % windows
    close all;
    fpath1 = sprintf('D:\\RPI\\ResearchWork\\Papers_\\Arun_data_codes\\FLS\\distribution_SW');
    % box plot
    figure(8)
    boxplot(Q{1,z},connections)
    %title(sprintf('Box plot across subjects,Window %d',z));
    xtickangle(45)
    xlabel('Connections or Edge')
    ylabel('Connectivity')
    baseFileName = sprintf('Window%d-D5T1-boxplot-connectivity.png',z);
    fullFileName = fullfile(fpath1, baseFileName);
    %saveas(figure(8),fullFileName)
end
%% One-way ANOVA , Kolmogorov-Smirnov and F-test
connect_temp = cell(15,1);
h_ftest = cell(15,1);
h_kstest = cell(15,1);
p_ftest = cell(15,1);
p_kstest = cell(15,1);
for k = 1:size(Q{1,i},2)  % connections i.e. 15 numbers
    fpath2 = sprintf('D:\\RPI\\ResearchWork\\Papers_\\Arun_data_codes\\FLS\\distribution_SW\\D5T1');
    close all;
    %     f = figure(11);
    %     f.WindowState = 'maximized';
    %     title(sprintf('Connectivity across days of sub %d ',i));
    for i = 1:11            % windows
        connect_temp{k,1}(:,i) = Q{1,i}(:,k);
    end
    [p_val,tbl,A_stats] = anova1(connect_temp{k,1}); % ,'CType','bonferroni'   figure(). anova1()
    %         hanova = figure(8);
    %         hbox = figure(9);
    %title(sprintf('ANOVA test %s',connections{k}))
    baseFileName = sprintf('ANOVA_D5T1_conn_%s.png',connections{k});
    fullFileName = fullfile(fpath2, baseFileName);
    %saveas(figure(1),fullFileName)
    close all;
    for i = 1:10 % i = (windows-1) F-test
        [h_ftest{k}(1,i),p_ftest{k}(1,i),~,T_stats] = vartest2(connect_temp{k,1}(:,i),connect_temp{k,1}(:,(i+1))); % one sample f-test
    end
    for i = 1:11  % windows
        [h_kstest{k}(1,i),p_kstest{k}(1,i),ksstat,cv] = kstest(connect_temp{k,1}(:,i));
    end
    cdfplot(connect_temp{k,1}(:,i)) % plot of emperical cfd and standard cfd
    hold on
    x_values = linspace(min(connect_temp{k,1}(:,i)),max(connect_temp{k,1}(:,i)));
    plot(x_values,normcdf(x_values,0,1),'r-')
    legend('Empirical CDF','Standard Normal CDF','Location','best')
    % multiple comparision of the means
    [c,m,h,nms] = multcompare(A_stats,'CType','bonferroni');
    figure(h)
    xlabel(sprintf('pairwise comparison of means: %s',connections{k})) %
    ylabel('Windows')
    baseFileName = sprintf('multi_comp_D5T1_conn_%s.png',connections{k});
    fullFileName = fullfile(fpath2, baseFileName);
    %saveas(figure(h),fullFileName)
end
%% extract the statistics to the xls sheet for easy access
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(p_ftest)),'sheet1');
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(h_ftest)),'sheet2');
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(p_kstest)),'sheet3');
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(h_kstest)),'sheet4');
%% Dickey-fuller test of Hypothesis; H0 : that there is a unit root
h_dftest = cell(8,1); % subjects
p_dftest = cell(8,1);
for i = 1:8 % number of subjects
    for k = 1:15 % number of regional connectivity
        [h_dftest{i}(k,1),p_dftest{i}(k,1),~,T_dfstats] = adftest(connect_temp{k,1}(i,:),'lags',0);
    end
end
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(p_dftest')),'sheet5'); % DF test p value
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(h_dftest')),'sheet6'); % DF test h decision
%% Two way ANOVA
A2_p_val = cell(15,1);
p_ftest = cell(15,1);
for k = 1:size(Q{1,i},2)  % connections i.e. 15 numbers
    fpath2 = sprintf('D:\\RPI\\ResearchWork\\Papers_\\Arun_data_codes\\FLS\\distribution_SW\\D1T1');
    close all;
    [A2_p_val{k},tbl,A2_stats] = anova2(connect_temp{k,1}); % ,'CType','bonferroni'   figure(). anova1()
    baseFileName = sprintf('Two-ANOVA_D5T1_W18sec_%s.png',connections{k});
    fullFileName = fullfile(fpath2, baseFileName);
    saveas(figure(1),fullFileName)
end
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(A2_p_val)),'sheet7'); % two way anova pvalues
%% Shapiro Wilks test
h_swtest = cell(15,1);
p_swtest = cell(15,1);
for k = 1:15 % number of regional connectivity
    for i = 1:11 % Window's number
        [h_swtest{k}(1,i),p_swtest{k}(1,i),swstats] = swtest(connect_temp{k,1}(:,i));
    end
end
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(p_swtest)),'sheet8'); % SW test p value
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(h_swtest)),'sheet9'); % SW test h decision
%% Variance ratio test
h_vrtest = cell(8,1); % subjects
p_vrtest = cell(8,1);
for i = 1:8 % number of subjects
    for k = 1:15 % number of regional connectivity
        [h_vrtest{i}(k,1),p_vrtest{i}(k,1),~,T_vrstats] = vratiotest(connect_temp{k,1}(i,:));
    end
end
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(p_vrtest')),'sheet10'); % DF test p value
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(h_vrtest')),'sheet11'); % DF test h decision
%% KPSS test of Hypothesis; H0 : that the series is trend stationary over a range of lags.
h_kpsstest = cell(8,1); % subjects
p_kpsstest = cell(8,1);
for i = 1:8 % number of subjects
    for k = 1:15 % number of regional connectivity
        [h_kpsstest{i}(k,1),p_kpsstest{i}(k,1),~,T_kpssstats] = kpsstest(connect_temp{k,1}(i,:));
    end
end
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(p_kpsstest')),'sheet12'); % KPSS test p value
xlswrite('D1T1-stat-ftest-kstest.xls',num2cell(cell2mat(h_kpsstest')),'sheet13'); % KPSS test h decision
%% ARIMA model fit
close all;
fpath3 = sprintf('D:\\RPI\\ResearchWork\\Papers_\\Arun_data_codes\\FLS\\distribution_SW\\Autocorr_residual_arima');
Arima_optimal_fit = cell(15,1);
residuals = cell(15,1);
prediction = cell(15,1);
Ari_model = "Arima(0,1,0)";                         %;cell(1);
[~,n_obs] = size(connect_temp{1,1}(1,:));           % for number of windows
for qq = 1:15                                         % number of connection
    for mm = 1:8                                    % no of sub
        if (qq == 2 && mm == 3) || (qq == 7 && mm == 2) || (qq == 8 && mm == 2) || (qq == 8 && mm == 4) ||(qq == 8 && mm == 7)
            continue;
        end
        Temp = (connect_temp{qq,1}(mm,:))';
        W = 1;
        p = 0;
        for i = 1:2                                 % p parameter of arima model
            q = 0;
            for j = 1:2                             % q paramter of arima model
                d = 0;
                for n = 1:2                         % for d parameter of arima model
                    [T,~] = size(Temp);
                    Mdl(W,1) = arima(p,d,q);
                    presample = 1:Mdl(W,1).P;
                    estsample = (Mdl(W,1).P+1): T;
                    [EstMdl(W,1),~,Loglikehood] = estimate(Mdl(W,1),Temp(estsample),'Y0',Temp(presample));
                    numPara = p+d+q+1;
                    [aic(W,1),bic(W,1)] = aicbic(Loglikehood,numPara,n_obs);
                    a = sprintf('Arima(%d,%d,%d)',p,d,q);
                    Ari_model(W,1) = a;
                    W = W+1;
                    d = d+1;
                end
                q = q+1;
            end
            p = p+1;
        end
        T                        = table;
        T.Properties.Description = 'Brain Connectivity';
        sub_conn                 = sprintf('sub-%d-%s',d,connections{qq}); % description of subject and regional connection
        T                        = table(Ari_model,aic,bic);
        T.Properties.VariableNames = {sub_conn ,'AIC', 'BIC'};
        [~,idx_aic]              = min(aic);
        [~,idx_bic]              = min(bic);
        Arima_optimal_fit{qq}{mm}(1,:) = T(idx_aic,:);
        Arima_optimal_fit{qq}{mm}(2,:) = T(idx_bic,:);
        % residuals of the optimal model
        residuals{qq}{mm}        = infer(EstMdl(idx_aic,1),Temp);
        resid                   = residuals{qq}{mm};
        mean_residual(qq,mm)    = mean(residuals{qq}{mm})
        variance_residual(qq,mm)    = var(residuals{qq}{mm});
        predict                  = Temp + resid;
        prediction{qq}{mm}       = predict;
        figure(1)
        autocorr(residuals{qq}{mm},'NumSTD',2);
        baseFileName = sprintf('Residual_autocorr_sub%d_conn_%s.png',mm,connections{qq});
        fullFileName = fullfile(fpath3, baseFileName);
        saveas(figure(1),fullFileName)
    end
end