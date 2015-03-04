function [B, dev, stats, team_list] = glmrank

data = csvread('massey.csv');
team_list = unique(data(:,5));
teams = data(:,5);
score = data(:,7);
homeaway = data(:,6);
gamenum = data(:,3);

% first, get matrix with rows = games, columns = teams. Will treat games as
% repetitions and team and opponent as categorical variables

team_mat = zeros(length(unique(gamenum)),length(team_list));
opponent_mat = zeros(length(unique(gamenum)),length(team_list));
result_mat = zeros(length(unique(gamenum)),1);
% for g = 1:length(unique(gamenum))
for g = 1:27479
    a = find(gamenum(:) == g);
    assert(length(a) == 2,'more than two teams in single game!');
    first_team = teams(a(1));
    second_team = teams(a(2));
    team_mat(g,find(team_list == first_team)) = 1;
    opponent_mat(g,find(team_list == second_team)) = 1;
    result_mat(g) = (score(a(1))-score(a(2))) > 0;
   
    team_mat(g,find(team_list == second_team)) = 1;
    opponent_mat(g,find(team_list == first_team)) = 1;
    result_mat(g) = (score(a(1))-score(a(2))) < 0;
end
disp('Beginning glm!');
[B, dev, stats] = glmfit([team_mat opponent_mat], result_mat, 'binomial');