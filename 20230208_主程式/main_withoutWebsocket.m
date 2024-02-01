%%初始化
clear all;
close all;
clc;
addpath HelperFunctions\
addpath svm\

Md1 = load("oil_svmmodel.mat"); %載入模型
serialObject = serialport("COM1", 115200); %設定傳輸速率

AdcData=[]; %初始化ADC陣列

%overlap還沒寫好
for i = 1:100
    if length(AdcData)>=5000 %給第一次只讀2500筆用的
        AdcData=AdcData(end-2499:end); %取最後2500筆
        %testFlag=i
    end
    t0 = clock; %計時用的
    for readDataCount = 1:2500 %一次讀5000筆
        readTemp=double(readline(serialObject));
        
        if isnan(readTemp) %如果是NAN就變0
            readTemp=0;
        end
        AdcData = [AdcData, readTemp]; %加到後面
    end
    ms = round(etime(clock,t0) * 1000); %看看花了多少時間
    %disp(i+":"+ms); %看看花了多少時間
    
    %disp(AdcData(1:100));
    plot(AdcData);
    if length(AdcData) == 5000
        result=getClass(AdcData);
    else
        result=0;
    end
    disp(i+":"+ms+", Class="+result);
end
serialObject=[]; %關閉COMPROT

function [test_predict_label]=getClass(input)

    load("oil_svmmodel.mat");
    load("PS.mat"); %載入PS，normalizatioin用

    fs = 977;
    lowpass_f = 200;

    %低通濾波
    lowPassInput=lowpass(input', lowpass_f, fs);
    lowPassInput=lowPassInput(201:4800);

    %%先來計算統計特徵和MFCC吧
    
    satistical_features = Extract_Sattistical_Features(lowPassInput,fs);
    
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
    
    [MFCCs, ~, ~] = mfcc(lowPassInput, fs, Tw, Ts, alpha, @hamming, [LF HF], M, C+1, L);
    feature_train = [satistical_features;MFCCs];

    %normalizatioin
    rand_feature = mapminmax('apply', feature_train, PS);
    rand_feature=rand_feature';
    
    test_predict_label = predict(Md1, rand_feature);
    %return test_predict_label
    %disp(test_predict_label);
end