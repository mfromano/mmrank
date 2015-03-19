function [team_ranks] = brianrank(weighting)
data = csvread('massey.csv');
if nargin < 1
    weighting = 'Uniform';
end
data_labels = fopen('teams.txt');
team_names = textscan(data_labels,'%d,%s');

fclose(data_labels);
team_list = unique(data(:,5));
dates = data(:,1);
all_teams = data(:,5);
all_scores = data(:,7);
home_or_away = data(:,6);
gamenum = data(:,3);
unique_games = unique(gamenum);

M1 = zeros(length(unique_games),length(team_list));
p1 = zeros(length(unique_games),1);
game_dates = zeros(length(unique_games),1);
mean_score = zeros(length(team_list));

for g = 1:length(unique_games)
    currgame = unique_games(g);
    game_dates(g) = unique(dates(find(gamenum == currgame)));
    teams_playing = all_teams(find(gamenum == currgame));
    this_team = teams_playing(1);
    other_team = teams_playing(2);
    M1(g,this_team) =  1;
    M1(g,other_team) = -1;
    assert(length(teams_playing) == 2, 'more or less than two teams playing this game!');
    team_scores = all_scores(find(gamenum == currgame));  
    curr_team_score = team_scores(1);
    mean_score(this_team) = mean_score(this_team) + curr_team_score / length(find(all_teams == this_team));
    other_team_score = team_scores(2);
    p1(g) = curr_team_score-other_team_score;
    if p1(g) > 40
        p1(g) = 40;
    elseif p1(g) < -40
        p1(g) = -40;
    end
end
game_dates = (game_dates - game_dates(1));

noteam = find(sum(abs(M1),1) == 0);

for t = 1:length(noteam)
    M1(:,noteam(t)) = [];
    team_names{2}(noteam(t)) = [];
end

if nargin > 0 && strcmp(weighting, 'linear')
    game_dates = game_dates/game_dates(end);
    G = diag(game_dates);

elseif nargin > 0 && strcmp(weighting, 'step')
    G = diag(floor(game_dates/14+1));

elseif nargin > 0 && strcmp(weighting, 'log')
    G = diag(log(1+game_dates/game_dates(end)));
    
elseif nargin > 0 && strcmp(weighting, 'exp')
    G = diag(1-exp(-game_dates/game_dates(end)/.2));
    
else
    G = eye(length(M1));
end

plot(game_dates,diag(G));

xlabel('Days since beginning of season');
ylabel('Weight')
title([weighting 'weights']);
save_as_pdf(gcf,['BrianRankings' weighting 'Weighting']);

M = M1'*G*M1;

p = M1'*G*p1;

clear M1 G

M(end,:) = ones(1,length(M));

r = linsolve(M,p);

[r,I] = sort(r,'descend');
team_names = team_names{2}(I);
mean_score = mean_score(I);
team_names(isnan(r)) = [];
mean_score(isnan(r)) = [];
r(isnan(r)) = [];
team_ranks{1} = r;
team_ranks{2} = team_names;
team_ranks{3} = mean_score;

outfile = fopen(['BrianRankings' weighting 'Weighting.txt'],'w');

fprintf(outfile,'%s.\t %s \t %s\n','Rank','Rating','Team');
for i=1:length(team_ranks{1})
    fprintf(outfile,'%d.\t %f \t %s \t %f\n',i,team_ranks{1}(i),char(team_ranks{2}(i)),team_ranks{3}(i));
end
fclose(outfile);
end