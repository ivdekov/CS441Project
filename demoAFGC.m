%% Cell 1 This is code that will go in the outer loop. I don't have the outer loop.

% Set up data on which to do the testing.
NT = 201; % 201 time steps
NCELL = 30; % 30 time series (i.e. bioluminescence data for 30 cells)
Ii = 1; % cell of interest (% in line b of the algorithm, it loops over all values of i. I am just doing this for one).
Jjtarget = 3; % cell to see if it affects cell Ii. (This is constructed so that we can detect a dependence)
time = linspace(0, 200, NT); % set up time
data = zeros(NT,NCELL); % initialize the data matrix
FList = zeros(NCELL, NCELL);

% stephanie start
% varying period over time (starts at 24 and ends at around 25)
period_over_time = 24 * linspace( 1, 1.05, length(time) );
% stephanie end

for i = 1 : NCELL,
    % Each time series is a sine curve with a slightly different period
    % near 24 h.
    data(:,i) = sin( time ./ (period_over_time+i*0.1).*(2*pi) )';
end;
% Each time series has noise in the signal
data = data + randn( size(data) );
% Cell 1's timeseries is really just a shifted version of the timeseries
% from Cell 3. So we expect Cell 3 to look connected to Cell 1.
data(3:end,Ii) = data(1:end-2,Jjtarget);
data(3:end,Ii) = data(3:end,Ii) + randn(size(data(3:end,Ii)))*0.5;

data(3:end,2) = data(1:end-2,5);
data(3:end,2) = data(3:end,2) + randn(size(data(3:end,2)))*0.5;

% We will look back up to 4 time steps
P = 4;

% Solve the full model for cell i. (eq 11 in paper)
for Ii = 1 : NCELL,
    
    % Begin code for row c of the algorithm
    Y = data(P+1:end,Ii)';
    Z = ones(1,NT-P);
    for i = 1 : P,
        Z = [Z; data(P-i+1:end-i,:)'];
    end;
    % Solve Z'*BT = Y' for BT.
    BT = Z'\Y'; % This does the least squares solving (BT means B transpose). B contains the alphas.
    % End code for row c of the algorithm
    % Begin code for row d of the algorithm
    resid1 = Z'*BT-Y';
    sigma_squared1 = resid1'*resid1/(size(Z',1)-(size(Z',2)-1)-1);
    % End code for row d of the algorithm

    % Row e is the loop control line. Here it is.
    for Jj = 1 : NCELL,
        % Begin row f of the algorithm
        % Solve the partial model to test i's dependence on j. (eq 12 in paper)
        % So we compute it without the j'th cell considered in Z.
        Y = data(P+1:end,Ii)';
        Z = ones(1,NT-P);
        cell_idxs = setdiff(1:NCELL,Jj);
        for i = 1 : P,
            Z = [Z; data(P-i+1:end-i,cell_idxs)'];
        end;
        BT = Z'\Y';
        % End row f of the algorithm
        % Begin row g of the algorithm
        resid0 = Z'*BT-Y';
        sigma_squared0 = resid0'*resid0/(size(Z',1)-(size(Z',2)-1)-1);
        % End row g of the algorithm

        % In row h of the algorithm, it mentions the F-statistic. This is where
        % things get a little confusing. The definition they describe of the
        % F-statistic is basically sigma_squared0/sigma_squared1, but I don't
        % see that definition in any stats book.
        % We could do this: F = sigma_squared0/sigma_squared1.
        % If F is big (you need to decide what "big" is -- maybe bigger than 2?), 
        % then we say there is a connection from cell Ii to cell Jj.
        % Right now, I am just printing out both sigma_squared values.
        % The threshold should be larger than 1. Maybe 1.5?
        F = sigma_squared0/sigma_squared1;
%         disp( ['sigma squared for full is ',num2str(sigma_squared1),' and partial when JJ=',num2str(Jj),' is ',num2str(sigma_squared0), ', F= ',num2str(F)]);
        FList(Ii, Jj) = F;
    end;
    fprintf('Ii = %d\n', Ii);
end;
% disp(FList);
% hist(FList);
figure;

% imagesc(FList);
imagesc( min( FList, 5 ));
xlabel('Influencer Cells');
ylabel('Influenced Cells');
title('Cell-To-Cell Connections');
set(gca, 'Fontsize', 30);