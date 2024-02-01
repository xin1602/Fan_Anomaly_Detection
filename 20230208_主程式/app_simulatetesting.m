function oil_testing
clear all;
close all;
clc;

addpath HelperFunctions\
addpath svm\
%load trained model
load("oil_svmmodel.mat");
load("PS.mat");
%% read data
disp("read data");
load("lowpassdata.mat");

%% preprocess
disp("preprocess");
%預設參數
lowpass_f = 200;
fs = 977;
overlap_window = 2500;
window = 5000;

label = cell2mat(label);
% 前面1/5的 sample 來測試
rand_signal=[];
rand_label=[];
lindex=find(label==1);
one_fivth=ceil(length(lindex)/5);
rand_signal=[rand_signal;signal(lindex(1:one_fivth))];
rand_label=[rand_label;label(lindex(1:one_fivth))];
lindex=find(label==3);
one_fivth=ceil(length(lindex)/5);
rand_signal=[rand_signal;signal(lindex(1:one_fivth))];
rand_label=[rand_label;label(lindex(1:one_fivth))];
lindex=find(label==4);
one_fivth=ceil(length(lindex)/5);
rand_signal=[rand_signal;signal(lindex(1:one_fivth))];
rand_label=[rand_label;label(lindex(1:one_fivth))];

%% feature extraction
disp("feature extraction");

feature_train = [];
for idx = 1:length(rand_signal)
    disp("Feature extraction (training): #" + idx)
    train_signal = rand_signal{idx};

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

rand_feature = mapminmax('apply', feature_train, PS);
rand_feature=rand_feature';

test_accuracy = 0;
test_feature = rand_feature;
test_label = rand_label;
test_predict_label = predict(Md1, test_feature);
test_acc = sum(test_predict_label == test_label)/length(test_label)*100

end