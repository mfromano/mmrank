function [team_ranks] = masseyrank
data = csvread('massey.csv');

data_labels = fopen('teams.txt');
team_names = textscan(data_labels,'%d,%s');

fclose(data_labels);
team_list = unique(data(:,5));

all_teams = data(:,5);
all_scores = data(:,7);
home_or_away = data(:,6);
gamenum = data(:,3);

M = zeros(length(team_list)+1,length(team_list)+1);

p = zeros(length(team_list)+1,1);

for t = 1:length(team_list)
    team = team_list(t);
    game_numbers = gamenum(find(all_teams == team));
    totalgames = length(game_numbers);
    M(team,team) = totalgames;
    point_diff = 0;  
    for g = 1:length(game_numbers)
        game = game_numbers(g);
        teams_playing = all_teams(find(gamenum == game));
        this_team = team;
        other_team =  teams_playing(find(teams_playing ~= team));
        M(this_team,other_team) =  M(this_team,other_team)-1;
        assert(length(teams_playing) == 2, 'more or less than two teams playing this game!');
        team_scores = all_scores(find(gamenum == game));
        curr_team_score = team_scores(find(teams_playing == team));
        other_team_score = team_scores(find(teams_playing ~= team));
        point_diff = point_diff + curr_team_score - other_team_score;
    end 
    p(team) = point_diff;
    
end
noteam = find(diag(M) == 0);

for z=1:length(noteam)
    M(noteam(z),:) = [];
    M(:,noteam(z)) = [];
    team_names{2}(noteam(z)) = [];
    p(noteam(z)) =[];
end

M(end,:) = ones(1,length(M));

r = linsolve(M,p);

[r,I] = sort(r,'descend');
team_names = team_names{2}(I);
team_names(isnan(r)) = [];
r(isnan(r)) = [];
team_ranks{1} = r;
team_ranks{2} = team_names;
outfile = fopen('MasseyRankingsEqualWeighting.txt','w');
fprintf(outfile,'%s.\t %s \t %s\n','Massey Rank','Rating','Team');
for i=1:length(team_ranks{1})
    fprintf(outfile,'%d.\t %f rating for %s\n',i,team_ranks{1}(i),char(team_ranks{2}(i)));
end
fclose(outfile);
end