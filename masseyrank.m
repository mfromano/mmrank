function [team_ranks] = masseyrank(weighting)
data = csvread('massey.csv');

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
    other_team_score = team_scores(2);
    p1(g) = curr_team_score-other_team_score;
end
game_dates = (game_dates - game_dates(1));

noteam = find(sum(abs(M1),1) == 0);
% noteam = [noteam find(sum(abs(M1),1) < threshold)];

for t = length(noteam):-1:1
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
    G = diag(exp(-(game_dates(end)-game_dates)/game_dates(end)));
else
    G = eye(length(M1));
end

M = M1'*G*M1;

p = M1'*G*p1;

M(end,:) = ones(1,length(M));

r = linsolve(M,p);

[r,I] = sort(r,'descend');
team_names = team_names{2}(I);
team_names(isnan(r)) = [];
r(isnan(r)) = [];
team_ranks{1} = r;
team_ranks{2} = team_names;
if nargin > 0 && strcmp(weighting, 'linear')
    outfile = fopen('MasseyRankingsLinearWeighting.txt','w');
elseif nargin > 0 && strcmp(weighting, 'step')
    outfile = fopen('MasseyRankingsStepWeighting.txt','w');
elseif nargin > 0 && strcmp(weighting,'log')
    outfile = fopen('MasseyRankingsLogWeighting.txt','w');
elseif nargin > 0 && strcmp(weighting, 'exp')
    outfile = fopen('MasseyRankingsExpWeighting.txt','w');
else
    outfile = fopen('MasseyRankingsEqualWeighting.txt','w');
end
fprintf(outfile,'%s.\t %s \t %s\n','Massey Rank','Rating','Team');
for i=1:length(team_ranks{1})
    fprintf(outfile,'%d.\t %f rating for %s\n',i,team_ranks{1}(i),char(team_ranks{2}(i)));
end
fclose(outfile);
end