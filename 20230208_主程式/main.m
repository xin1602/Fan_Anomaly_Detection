%%初始化
clear all;
close all;
clc;

addpath("websocket");
addpath("websocket/src");
global server
server = EchoServer(30000);

%client = SimpleClient('ws://localhost:30000');

addpath HelperFunctions\
addpath svm\

Md1 = load("oil_svmmodel.mat"); %載入模型
serialObject = serialport("COM1", 115200); %設定傳輸速率

AdcData=[]; %初始化ADC陣列

%overlap
%for i = 1:100
while true
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
    %sendMessage(char(string(result)));
    
    %傳送至Websocket
    class=result;
    jsonArray=struct("class", class, "data", AdcData);
    sendMessage(jsonencode(jsonArray));

    disp(i+":"+ms+", Class="+result);
    if result ~= 1
        webData = '';
        webBody = matlab.net.http.MessageBody(webData);
        %webBody.show
        contentTypeField = matlab.net.http.field.ContentTypeField('application/json');
        type1 = matlab.net.http.MediaType('text/*');
        type2 = matlab.net.http.MediaType('application/json','q','.5');
        acceptField = matlab.net.http.field.AcceptField([type1 type2]);
        header = [acceptField contentTypeField];
        method = matlab.net.http.RequestMethod.PUT;
        request = matlab.net.http.RequestMessage(method,header,webBody);
        %show(request)
        nowTime = string(datetime('now','TimeZone','local','Format','y-MM-dd%20HH:mm:ss.SSS')); %現在時間
        url="https://maker.ifttt.com/trigger/CPC_oil/with/key/56VCoW-tWasBbzhze1mPo?value1=%E5%81%B5%E6%B8%AC%E5%88%B0%E7%95%B0%E5%B8%B8%E9%A1%9E%E5%88%A5!!%3Cbr%20/%3E%3Cbr%20/%3E%E6%99%82%E9%96%93%E3%80%80%E3%80%80%EF%BC%9A"+nowTime+"%3Cbr%20/%3E%E9%A6%AC%E9%81%94%E4%BD%8D%E7%BD%AE%EF%BC%9A%20%E9%AB%98%E9%9B%84%20(%EF%BC%83%EF%BC%91)%3Cbr%20/%3E%E9%A1%9E%E5%88%A5%E3%80%80%E3%80%80%EF%BC%9A"+class;
        [response,completedrequest,history] = send(request, url);
        
    end
end
serialObject=[]; %關閉COMPROT
server.stop

function sendMessage(message)
    global server
    ServerConnections=server.Connections; % view the result as a table: struct2table(server.Connections)
    if isempty(ServerConnections) %如果沒人連接Websocket
        return
    end
    clientCode=ServerConnections(length(ServerConnections)).HashCode;
    server.sendTo(clientCode, message);
end


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