%% TSP heuristike: Nearest Neighbor, 2-opt, Simulated Annealing, Genetic Algorithm
% Pokretanje (iz bilo kog foldera):
%   run('matlab/tsp_heuristics.m')
% Ulaz:  data/cities.csv  (kolone City,Lon,Lat)
% Izlaz: results/results_matlab.csv + po jedna figura za svaku heuristiku
%
% Tura je permutacija gradova koja počinje od startnog grada; povratak na
% start se podrazumeva (tour_length ga uvek računa).

clc; clearvars; close all;
rng(42);  % ponovljivi rezultati

here = fileparts(mfilename('fullpath'));
root = fileparts(here);

%% učitavanje podataka
[cities, coords] = load_cities(fullfile(root, 'data', 'cities.csv'));
n = size(coords, 1);

% stvarne udaljenosti u km (haversine), ne euklidska udaljenost u stepenima
distMatrix = zeros(n);
for i = 1:n
    for j = 1:n
        distMatrix(i,j) = haversine_km(coords(i,:), coords(j,:));
    end
end

start = 1;

%% nearest neighbor (NN)
visited = false(1,n);
visited(start) = true;
tour_NN = start;
for k = 2:n
    dists = distMatrix(tour_NN(end), :);
    dists(visited) = inf;  % ne biraj već posećene
    [~, next] = min(dists);
    visited(next) = true;
    tour_NN(end+1) = next;
end
len_NN = tour_length(tour_NN, distMatrix);
fprintf("NN dužina ture: %.1f km\n", len_NN);
plot_tour(coords, cities, tour_NN, sprintf('Nearest Neighbor: %.0f km', len_NN));

%% 2-opt
tour_2opt = two_opt(tour_NN, distMatrix);
len_2opt = tour_length(tour_2opt, distMatrix);
fprintf("2-opt dužina ture: %.1f km\n", len_2opt);
plot_tour(coords, cities, tour_2opt, sprintf('NN + 2-opt: %.0f km', len_2opt));

%% simulirano kaljenje (2-opt potezi, start ostaje na prvom mestu)
iterations = 50000;
T = 0.1 * len_NN;                       % početna temperatura u skali dužine ture
Tend = 1e-3;
alpha = (Tend / T)^(1 / iterations);    % temperatura pada do Tend tačno na kraju

currentSA = tour_NN;
currentDistSA = len_NN;
tour_SA = currentSA;
len_SA = currentDistSA;

for k = 1:iterations
    idx = sort(randperm(n-1, 2) + 1);   % pozicije 2..n, start se ne pomera
    i = idx(1); j = idx(2);
    a = currentSA(i-1); b = currentSA(i);
    c = currentSA(j);   d = currentSA(mod(j, n) + 1);
    delta = distMatrix(a,c) + distMatrix(b,d) - distMatrix(a,b) - distMatrix(c,d);

    if delta < 0 || rand < exp(-delta / T)
        currentSA(i:j) = fliplr(currentSA(i:j));
        currentDistSA = currentDistSA + delta;
        if currentDistSA < len_SA
            tour_SA = currentSA;
            len_SA = currentDistSA;
        end
    end
    T = T * alpha;
end
len_SA = tour_length(tour_SA, distMatrix);
fprintf("SA dužina ture: %.1f km\n", len_SA);
plot_tour(coords, cities, tour_SA, sprintf('Simulated Annealing: %.0f km', len_SA));

%% genetski algoritam
% Jedinka je redosled gradova BEZ starta; start se dodaje na početak pri evaluaciji.
popSize = 100;
numGenerations = 300;
mutationRate = 0.2;
others = setdiff(1:n, start);
m = numel(others);

population = zeros(popSize, m);
for p = 1:popSize
    population(p,:) = others(randperm(m));
end
fitness = zeros(popSize, 1);
for p = 1:popSize
    fitness(p) = tour_length([start population(p,:)], distMatrix);
end

for gen = 1:numGenerations
    newPopulation = zeros(popSize, m);

    % elitizam: zadrži najboljeg
    [~, idxBest] = min(fitness);
    newPopulation(1,:) = population(idxBest,:);

    for p = 2:popSize
        parentA = tournament(population, fitness);
        parentB = tournament(population, fitness);
        child = order_crossover(parentA, parentB);

        % mutacija (swap)
        if rand < mutationRate
            idx = randperm(m, 2);
            child(idx) = child(fliplr(idx));
        end
        newPopulation(p,:) = child;
    end

    population = newPopulation;
    for p = 1:popSize
        fitness(p) = tour_length([start population(p,:)], distMatrix);
    end

    if mod(gen, 50) == 0
        fprintf("Generacija %d, najbolja dužina: %.1f km\n", gen, min(fitness));
    end
end
[len_GA, idxBest] = min(fitness);
tour_GA = [start population(idxBest,:)];
fprintf("GA dužina ture: %.1f km\n", len_GA);
plot_tour(coords, cities, tour_GA, sprintf('Genetic Algorithm: %.0f km', len_GA));

%% poređenje heuristika
methods = {'Nearest Neighbor'; 'NN + 2-opt'; 'Simulated Annealing'; 'Genetic Algorithm'};
lengths = [len_NN; len_2opt; len_SA; len_GA];
fprintf("\n%-22s %10s\n", 'Heuristika', 'km');
for r = 1:numel(methods)
    fprintf("%-22s %10.1f\n", methods{r}, lengths(r));
end

outDir = fullfile(root, 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
fid = fopen(fullfile(outDir, 'results_matlab.csv'), 'w', 'n', 'UTF-8');
fprintf(fid, 'Method,LengthKm\n');
for r = 1:numel(methods)
    fprintf(fid, '%s,%.1f\n', methods{r}, lengths(r));
end
fclose(fid);
fprintf("\nSačuvano: %s\n", fullfile(outDir, 'results_matlab.csv'));

%% ===== LOKALNE FUNKCIJE (MORAJU BITI NA KRAJU FAJLA) =====

function [names, coords] = load_cities(path)
% Čita CSV sa kolonama City,Lon,Lat. Radi i u MATLAB-u i u Octave-u.
    fid = fopen(path, 'r', 'n', 'UTF-8');
    if fid < 0
        error('Ne mogu da otvorim %s', path);
    end
    fgetl(fid);  % zaglavlje
    c = textscan(fid, '%s %f %f', 'Delimiter', ',');
    fclose(fid);
    names = c{1};
    coords = [c{2}, c{3}];
end

function d = haversine_km(p1, p2)
% Udaljenost po površini Zemlje u km; p = [lon lat] u stepenima.
    R = 6371;
    lon1 = deg2rad(p1(1)); lat1 = deg2rad(p1(2));
    lon2 = deg2rad(p2(1)); lat2 = deg2rad(p2(2));
    a = sin((lat2-lat1)/2)^2 + cos(lat1)*cos(lat2)*sin((lon2-lon1)/2)^2;
    d = 2 * R * asin(sqrt(a));
end

function L = tour_length(t, distMatrix)
% Dužina zatvorene ture, uključujući povratak na prvi grad.
    L = sum(distMatrix(sub2ind(size(distMatrix), t, circshift(t, -1))));
end

function tour = two_opt(tour, distMatrix)
% Obrće segmente dok god to skraćuje turu. Startni grad ostaje prvi.
    n = length(tour);
    improved = true;
    while improved
        improved = false;
        for i = 2:n-1
            for j = i+1:n
                a = tour(i-1); b = tour(i);
                c = tour(j);   d = tour(mod(j, n) + 1);
                delta = distMatrix(a,c) + distMatrix(b,d) - distMatrix(a,b) - distMatrix(c,d);
                if delta < -1e-9
                    tour(i:j) = fliplr(tour(i:j));
                    improved = true;
                end
            end
        end
    end
end

function parent = tournament(population, fitness)
% Turnirska selekcija veličine 2.
    idx = randi(size(population, 1), 1, 2);
    if fitness(idx(1)) < fitness(idx(2))
        parent = population(idx(1),:);
    else
        parent = population(idx(2),:);
    end
end

function child = order_crossover(parentA, parentB)
% Order Crossover (OX): segment iz A, ostatak redom iz B.
    m = numel(parentA);
    cuts = sort(randi(m, 1, 2));
    child = zeros(1, m);
    child(cuts(1):cuts(2)) = parentA(cuts(1):cuts(2));
    rest = circshift(parentB, -cuts(2));
    rest = rest(~ismember(rest, child));
    pos = mod((cuts(2):cuts(2)+numel(rest)-1), m) + 1;
    child(pos) = rest;
end

function plot_tour(coords, cities, tour, ttl)
    closed = [tour tour(1)];
    figure;
    plot(coords(closed,1), coords(closed,2), '-o', 'LineWidth', 2);
    hold on;
    plot(coords(tour(1),1), coords(tour(1),2), 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(coords(:,1), coords(:,2), cities, ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
    title(ttl); xlabel('geografska dužina'); ylabel('geografska širina');
    grid on;
    drawnow;
end
