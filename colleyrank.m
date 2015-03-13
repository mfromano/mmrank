function [team_ranks] = colleyrank(weight)
data = csvread('Colley.csv');

% data = data(1:54958,:);
data_labels = fopen('teams.txt');
team_names = textscan(data_labels,'%d,%s');

rel_game_dates = data(:,1)-data(1,1);

fclose(data_labels);
team_list = unique(data(:,5));

all_teams = data(:,5);
all_scores = data(:,7);
home_or_away = data(:,6);
gamenum = data(:,3);

C = zeros(length(team_list)+1,length(team_list)+1);

b = zeros(length(team_list)+1,1);

for t = 1:length(team_list)
    team = team_list(t);
    game_numbers = gamenum(find(all_teams == team));
    totalgames = length(game_numbers);
    C(team,team) = 2;
    win_loss_diff = 0;  
    
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
            wt = exp(-(rel_game_dates(end)-game_date)/rel_game_dates(end));    
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

noteam = find(sum(C,1) == 0);
for z=1:length(noteam)
    C(noteam(z),:) = [];
    C(:,noteam(z)) = [];
    team_names{2}(noteam(z)) = [];
    b(noteam(z)) =[];
end

r = linsolve(C,b);

[r,I] = sort(r,'descend');
team_names = team_names{2}(I);
team_names(isnan(r)) = [];
r(isnan(r)) = [];
team_ranks{1} = r;
team_ranks{2} = team_names;
if nargin > 0 && strcmp(weighting, 'linear')
    outfile = fopen('ColleyRankingsLinearWeighting.txt','w');
elseif nargin > 0 && strcmp(weighting, 'step')
    outfile = fopen('ColleyRankingsStepWeighting.txt','w');
elseif nargin > 0 && strcmp(weighting,'log')
    outfile = fopen('ColleyRankingsLogWeighting.txt','w');
elseif nargin > 0 && strcmp(weighting, 'exp')
    outfile = fopen('ColleyRankingsExpWeighting.txt','w');
else
    outfile = fopen('ColleyRankingsEqualWeighting.txt','w');
end
fprintf(outfile,'%s.\t %s \t %s\n','Colley Rank','Rating','Team');
for i=1:length(team_ranks{1})
    fprintf(outfile,'%d.\t %f rating for %s\n',i,team_ranks{1}(i),char(team_ranks{2}(i)));
end
fclose(outfile);
end