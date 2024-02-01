%% read data
srcFolder="./csv";
disFolder="./data";
disp("read data");

tempdata = readmatrix(srcFolder+"/data1.csv");
saveData = tempdata';
saveData = saveData(2, :);
%saveData=cat(2, saveData, saveData);
save(disFolder+'/data1.mat', 'saveData');

tempdata = readmatrix(srcFolder+"/data3.csv");
saveData = tempdata';
saveData = saveData(2, :);
save(disFolder+'/data3.mat', 'saveData');

tempdata = readmatrix(srcFolder+"/data4.csv");
saveData = tempdata';
saveData = saveData(2, :);
save(disFolder+'/data4.mat', 'saveData');