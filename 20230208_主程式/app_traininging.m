function oil_traininging
clear all;
close all;
clc;
addpath HelperFunctions\
addpath svm\
%load trained model
dataFolder="./data";
%% read data
disp("read data");
tempdata = load(dataFolder+"/data1");
normal_pop = tempdata.saveData';
tempdata = load(dataFolder+"/data3");
abnormal_pop_screw_water = tempdata.saveData';
tempdata = load(dataFolder+"/data4");
abnormal_pop_centre_water = tempdata.saveData';

%% preprocess
disp("preprocess");
%預設參數
lowpass_f = 200;
fs = 977;
overlap_window = 2500;
window = 5000;

%異常螺絲訊號合併
abnormal_pop_screw_water = abnormal_pop_screw_water;
framed_abnormal_screw_water_signal = frame_signal(abnormal_pop_screw_water, overlap_window, window);
framed_abnormal_screw_water_label = cell(length(framed_abnormal_screw_water_signal),1);
for o = 1:length(framed_abnormal_screw_water_label)
    framed_abnormal_screw_water_label{o,1} = 23;
end

%正常訊號
 
 low_pass_normal_pop = normal_pop;
 framed_normal_signal = frame_signal(low_pass_normal_pop, overlap_window, window); 
 framed_normal_label = cell(length(framed_normal_signal),1);
 for o = 1:length(framed_normal_signal)
     framed_normal_label{o,1} = 1;
 end
%異常偏心訊號合併

 abnormal_pop_centre_water = abnormal_pop_centre_water;
 framed_abnormal_centre_signal = frame_signal(abnormal_pop_centre_water, overlap_window, window);
 framed_abnormal_centre_label = cell(length(framed_abnormal_centre_signal),1);
 for o = 1:length(framed_abnormal_centre_signal)
     framed_abnormal_centre_label{o,1} = 4;
 end

signal = [framed_normal_signal;framed_abnormal_screw_water_signal;framed_abnormal_centre_signal];
label = [framed_normal_label;framed_abnormal_screw_water_label;framed_abnormal_centre_label];
save("lowpassdata.mat","label","signal");

framed_normal_signal(1:12)=[]; %去除前面12筆資料(120000-150000)
framed_normal_label(1:12)=[];  %去除前面12筆資料(120000-150000)
one_fivth = ceil(length(framed_normal_signal)/5);
framed_normal_signal(1:one_fivth)=[]; %留下後面4/5筆資料來訓練
framed_normal_label(1:one_fivth)=[];  %留下後面4/5筆資料來訓練
one_fivth = ceil(length(framed_abnormal_screw_water_signal)/5);
framed_abnormal_screw_water_signal(1:one_fivth)=[]; %留下後面4/5筆資料來訓練
framed_abnormal_screw_water_label(1:one_fivth)=[];  %留下後面4/5筆資料來訓練
one_fivth = ceil(length(framed_abnormal_centre_signal)/5);
framed_abnormal_centre_signal(1:one_fivth)=[]; %留下後面4/5筆資料來訓練
framed_abnormal_centre_label(1:one_fivth)=[];  %留下後面4/5筆資料來訓練

signal = [framed_normal_signal;framed_abnormal_screw_water_signal;framed_abnormal_centre_signal];
label = [framed_normal_label;framed_abnormal_screw_water_label;framed_abnormal_centre_label];

%rand_num = randperm(length(signal))'; % 不隨機了
% rand_signal = signal(rand_num(1:end),:);
% rand_label = cell2mat(label(rand_num(1:end),:));
label = cell2mat(label);

%% feature extraction
disp("feature extraction");

feature_train = [];
for idx = 1:length(signal)
    disp("Feature extraction (training): #" + idx)
    train_signal = signal{idx};

    fs = 977;
    lowpass_f = 200;

    %低通濾波
    lowPassInput=lowpass(train_signal, lowpass_f, fs);
    train_signal=lowPassInput(201:4800);
    %statistical features
    satistical_features = Extract_Sattistical_Features(train_signal,fs);

    % Extract Mel-frequency cepstral coefficients
    %Tw = window_length*1000;      % analysis frame duration (ms)
    Tw = 25;                % analysis frame duration (ms)
    Ts = 10;                % analysis frame shift (ms)
    alpha = 0.97;           % preemphasis coefficient
    M = 20;                 % number of filterbank channels
    C = 12;                 % number of cepstral coefficients
    L = 22;                 % cepstral sine lifter parameter
    LF = 5;                 % lower frequency limit (Hz)
    HF = 500;               % upper frequency limit (Hz)

    [MFCCs, ~, ~] = mfcc(train_signal, fs, Tw, Ts, alpha, @hamming, [LF HF], M, C+1, L);
    feature = [satistical_features;MFCCs];
    feature_train = [feature_train,feature];
end
%normalizatioin
[rand_feature, PS]= mapminmax(feature_train);
rand_feature=rand_feature';
save("PS.mat","PS");

train_feature = rand_feature;
train_label = label;
% training
t = templateSVM('KernelFunction','gaussian');
Md1 = fitcecoc(train_feature,train_label,'Learners',t);
save("oil_svmmodel.mat","Md1",'-mat');
end