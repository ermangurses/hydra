% Hydra raw data analysis code.

function analysis()
    accdata = csvread('raw_data/20170113_202528.acc');
    time = accdata(:,1);
    time = time - time(1);
    time = time / 1000;
    
    sX = smoothWindowSquared(accdata(:,2));
    sZ = smoothWindowSquared(accdata(:,4));
    
    drawAccAxis(accdata(:,2), accdata(:,3), accdata(:,4), time);
    %drawAccAxis(sX, smoothWindowSquared(accdata(:,3)), sZ, time);
    
    gyrodata = csvread('raw_data/20170113_202528.gyro');
    time = gyrodata(:,1);
    time = time - time(1);
    time = time / 1000;
    %drawGyroAxis(smoothWindow(gyrodata(:,2)), smoothWindow(gyrodata(:,3)), smoothWindow(gyrodata(:,4)), time);
    drawGyroAxis(gyrodata(:,2), gyrodata(:,3), gyrodata(:,4), time);
    
    index1 = process1(sX, 1, 5, 0.5);
    index2 = process1(sZ, 3.5, 12, 0.5);
    
    process2(sX, sZ, index1, index2, 10);
end

function drawAccAxis(x, y, z, time) 
    f = figure();
    f.Name = 'Acceleration';
    
    subplot(3,1,1);
    plot(time, x); grid on;
    title('X');
    %subplot(3,1,2);
    %plot(time, y); grid on;
    %title('Y');
    subplot(3,1,3);
    plot(time, z); grid on;
    title('Z');
end

function drawGyroAxis(x, y, z, time) 
    f = figure();
    f.Name = 'Gyroscope';
    
    subplot(3,1,1);
    plot(time, x); grid on;
    title('X');
    subplot(3,1,2);
    plot(time, y); grid on;
    title('Y');
    subplot(3,1,3);
    plot(time, z); grid on;
    title('Z');
end

% Method which smooths out the data by using a window.
function filtered = smoothWindow(data)
    filtered = zeros(length(data));

    f = 1;     % 5Hz sampling rate.
    p = ceil(5 * 1);  % 1 second window size;
    
    filtered(1:p) = 0;
    
    for a=p:length(data)
        filtered(a) = data(a) - (sum(data(a-p+1:a)) / p);
    end
end

% Method which smooths out the data by using a window.
function filtered = smoothWindowSquared(data)
    filtered = zeros(length(data));

    f = 1;     % 5Hz sampling rate.
    p = ceil(5 * 1);  % 1 second window size;
    
    filtered(1:p) = 0;
    
    for a=p:length(data)
        filtered(a) = data(a) - (sum(data(a-p+1:a)) / p);
        filtered(a) = filtered(a) * filtered(a);
    end
end

% Method which gives the average sampling rate for the data taken.
function f = getAverageSamplingRate(time)
    index = 1;
    
    for a=2:length(time)
        d(index) = time(a) - time(a-1);
        index = index + 1;
    end
    
    md = median(d);
    md = md / 1000;
    
    f = 1 / md;
end

% Method which squares up all the value.
function squared = getSquared(data) 
    squared = zeros(length(data));
    
    for a=1:length(data)
        squared(a) = data(a) * data(a);
    end
end

% Method which does some of the hard work finding things.
% 
function index = process1(x, PL, PH, down_threshold)
    % 0 : default non triggered state.
    % 1 : start peak located.
    % 2 : down state.
    
    state = 0;
    count = 0;  % Stores how many points long the peak we detected is.
    down_state_count = 0;   % Temp variable which holds the count when we are in down state. 
    start_index = 0;    % The index on which the peak started.
    
    i = 1;  % index for the index array.
    
    for a=1:length(x)
        switch state
            case 0
                if x(a) >= PL && x(a) <= PH
                    state = 1;
                    start_index = a;
                    count = count + 1;
                end
            case 1
                if x(a) >= PL && x(a) <= PH
                    state = 1;
                    count = count + 1;
                end
                if x(a) <= down_threshold
                   state = 2;
                   down_state_count = down_state_count + 1;
                end
            case 2
                if down_state_count > 10
                   state = 0;
                   index(i) = start_index;
                   i = i + 1;
                   start_index = 0;
                   count = 0;
                   down_state_count = 0;
                else
                    if x(a) >= PL && x(a) <= PH
                        state = 1;
                        count = count + 1;
                    end
                end
                
                down_state_count = down_state_count + 1;
        end
    end
end

% Process 2 just makes sure that peaks detected on both the X and Z axis
% align close enough. If they do it returns the distance beetween the
% consecutive peaks. It going to be a bit tricky to match the peaks but
% lets try.
function process2(sX, sY, index1, index2, pair_threshold, down_threshold, drink_threshold)
    % Find pairs of values in both the arrays which are 10 points / 2
    % seconds apart from each other.
    
    array_index1 = 1;
    array_index2 = 1;
    pair_index = 1;
    
    while array_index1 <= length(index1) && array_index2 <= length(index2)
        temp = abs(index1(array_index1) - index2(array_index2));
        if temp <= pair_threshold
           % Thats the first pair.
           pairs(pair_index) = floor((index1(array_index1) + index2(array_index2)) / 2);
           pair_index = pair_index + 1;
           array_index1 = array_index1 + 1;
           array_index2 = array_index2 + 1;
        else
            if index1(array_index1) < index2(array_index2) 
                array_index1 = array_index1 + 1;
            else
                array_index2 = array_index2 + 1;
            end
        end
    end
    
    % For each pair of peaks look at the segment in the middle. This was
    % the time when the user was drinking water. Look and see if everything
    % is below the downthreshold in this period.
    
    for a=1:length(pairs)-1
        display(floor(abs(pairs(a)-pairs(a+1)) / 5));
    end
end
