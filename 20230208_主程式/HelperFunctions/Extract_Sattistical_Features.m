function [satistical_features]=Extract_Sattistical_Features(train_signal,fs)
    meanValue = mean(train_signal); % Calculate mean value feature
    medianValue = median(train_signal); % Calculate median value feature
    standardDeviation = std(train_signal); % Calculate standard deviation feature
    meanAbsoluteDeviation = mad(train_signal); % Calculate mean absolute deviation feature
    quantile25 = quantile(train_signal, 0.25); % Calculate signal 25th percentile feature
    quantile75= quantile(train_signal, 0.75); % Calculate signal 75th percentile feature
    signalIQR = iqr(train_signal); % Calculate signal inter quartile range feature
    sampleSkewness = skewness(train_signal); % Calculate skewness of the signal values
    sampleKurtosis = kurtosis(train_signal); % Calculate kurtosis of the signal values  
    signalEntropy = signal_entropy(train_signal'); % Calculate Shannon's entropy value of the signal 
    spectralEntropy = spectral_entropy(train_signal, fs, 256); % Calculate spectral entropy of the signal
    % Extract features from the power spectrum
    [maxfreq, maxval, maxratio] = dominant_frequency_features(train_signal, fs, 256, 0);
    dominantFrequencyValue = maxfreq;
    dominantFrequencyMagnitude = maxval;
    dominantFrequencyRatio = maxratio;
    satistical_features = [meanValue;medianValue;standardDeviation;meanAbsoluteDeviation;quantile25;
          quantile75;signalIQR;sampleSkewness;sampleKurtosis;signalEntropy;spectralEntropy;
           dominantFrequencyValue;dominantFrequencyMagnitude;dominantFrequencyRatio];
end