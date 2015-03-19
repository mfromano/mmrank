function [team_ranks] = colleyrank(weight, threshold)
data = csvread('massey.csv');
if nargin < 1
    weight = 'uniform';
end
if nargin < 2
    threshold = 0;
end

data_labels = fopen('teams.txt');
team_names = textscan(data_labels,'%d,%s');
% 
rel_game_dates = data(:,1)-data(1,1);

fclose(data_labels);
team_list = team_names{1};

all_teams = data(:,5);
all_scores = data(:,7);
home_or_away = data(:,6);
gamenum = data(:,3);

C = zeros(length(team_names{2}),length(team_names{2}));

b = zeros(length(team_names{2}),1);

for t = 1:length(team_list)
    team = team_list(t);
    game_numbers = gamenum(find(all_teams == team));
    totalgames = length(game_numbers);
    C(team,team) = 2;
    win_loss_diff = 0;  
    
    if totalgames < threshold
        continue
    end
    
    for g = 1:length(game_numbers)
        game = game_numbers(g);
        game_date = unique(rel_game_dates(find(gamenum==game)));
        assert(length(game_date) == 1, 'More than one date for given game!');     
        teams_playing = all_teams(find(gamenum == game));
        this_team = team;
        other_team =  teams_playing(find(teams_playing ~= team));
        assert(length(teams_playing) == 2, 'more or less than two teams playing this game!');
        team_scores = all_scores(find(gamenum == game));
        curr_team_score = team_scores(find(teams_playing == team));
        other_team_score = team_scores(find(teams_playing ~= team));
         
        if nargin > 0 && strcmp(weight,'linear');
            wt = game_date/rel_game_dates(end);
        elseif nargin > 0 && strcmp(weight, 'step')
            wt = diag(floor(game_date/14+1));
        elseif nargin > 0 && strcmp(weight, 'log')
            wt = diag(log(1+game_date/rel_game_dates(end)));
        elseif nargin > 0 && strcmp(weight, 'exp')
            wt = diag(1-exp(-game_date/rel_game_dates(end)/.2));    
        else
            wt = 1;
        end
        C(this_team,other_team) =  C(this_team,other_team)-wt;
        C(this_team,this_team) = C(this_team,this_team) + wt;
        win_loss_diff = win_loss_diff + ((curr_team_score > other_team_score)...
            - (curr_team_score < other_team_score))*wt;
    end
    
    b(team) = 1+0.5*win_loss_diff;
    
end

noteam = find(diag(C) == 2);

for z=length(noteam):-1:1
    C(noteam(z),:) = [];
    C(:,noteam(z)) = [];
    team_names{2}(noteam(z)) = [];
    b(noteam(z)) =[];
end

nogames = find(diag(C) < (2 + threshold));

for z=length(nogames):-1:1
    C(nogames(z),:) = [];
    C(:,nogames(z)) = [];
    team_names{2}(nogames(z)) = [];
    b(nogames(z)) =[];
end

r = linsolve(C,b);

[r,I] = sort(r,'descend');
team_names = team_names{2}(I);
team_names(isnan(r)) = [];
r(isnan(r)) = [];
team_ranks{1} = r;
team_ranks{2} = team_names;

outfile = fopen(['ColleyRankings_' weight '_weight_' num2str(threshold) '_threshold.txt'],'w');

fprintf(outfile,'%s.\t %s \t %s\n','Colley Rank','Rating','Team');
for i=1:length(team_ranks{1})
    fprintf(outfile,'%d.\t %f rating for %s\n',i,team_ranks{1}(i),char(team_ranks{2}(i)));
end
fclose(outfile);
end