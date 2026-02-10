clc; clearvars; close all;

% učitavanje pod
data = readtable('cities.xlsx');

cities = data.City;
coords = [data.X, data.Y];

n = size(coords, 1);
distMatrix = zeros(n);

for i = 1:n
    for j = 1:n
        distMatrix(i,j) = sqrt( (coords(i,1) - coords(j,1))^2 + (coords(i,2) - coords(j,2))^2 );
    end
end

% prikaz
disp(distMatrix(1:5, 1:5));

start = 1;

%% nearest neighbor (NN)
visited = false(1,n);
visited(start) = true;
tour = start;
current = start;

for k = 2:n
    dists = distMatrix(current, :);
    dists(visited) = inf;  % ne biraj već posećene
    [~, next] = min(dists);
    visited(next) = true;
    tour(end+1) = next;
    current = next;
end

% povratak kući
tour(end+1) = start;

% ukupna dužina puta (NN)
totalDist = tour_length(tour, distMatrix);
fprintf("NN duzina ture: %.2f\n", totalDist);

figure;
plot(coords(tour,1), coords(tour,2), '-o', 'LineWidth', 2);
title('Nearest Neighbor TSP ruta');
grid on; axis equal;
text(coords(tour,1), coords(tour,2), string(cities(tour)), ...
    'VerticalAlignment','bottom','HorizontalAlignment','right');
drawnow;

% 2opt
improvedTour = two_opt(tour, distMatrix);
figure;
plot(coords(improvedTour,1), coords(improvedTour,2), '-o', 'LineWidth', 2);
title('2-OPT poboljšana ruta');
grid on; axis equal;
text(coords(improvedTour,1), coords(improvedTour,2), string(cities(improvedTour)), ...
    'VerticalAlignment','bottom','HorizontalAlignment','right');
drawnow;

%simulirano kaljenje
T = 1000;
alpha = 0.995;
iterations = 50000;

% Koristi NN rutu bez završnog povratka kao inicijalnu permutaciju
currentSA = tour(1:end-1);
currentDistSA = tour_length([currentSA start], distMatrix);

bestSA = currentSA;
bestDistSA = currentDistSA;

for k = 1:iterations
    newSA = currentSA;
    idx = randperm(n,2);
    % Inversion mutacija: swap dva grada
    tmp = newSA(idx(1));
    newSA(idx(1)) = newSA(idx(2));
    newSA(idx(2)) = tmp;
    
    newDist = tour_length([newSA start], distMatrix);
    
    if newDist < currentDistSA || rand < exp((currentDistSA - newDist)/T)
        currentSA = newSA;
        currentDistSA = newDist;
    end
    
    if newDist < bestDistSA
        bestSA = newSA;
        bestDistSA = newDist;
    end
    
    T = T * alpha;
end

tour_SA = [bestSA start];  % dodaj povratak
fprintf("SA duzina ture: %.2f\n", bestDistSA);

figure;
plot(coords(tour_SA,1), coords(tour_SA,2), '-o', 'LineWidth',2);
title('Simulated Annealing ruta');
grid on; axis equal;
text(coords(tour_SA,1), coords(tour_SA,2), string(cities(tour_SA)), ...
    'VerticalAlignment','bottom','HorizontalAlignment','right');
drawnow;

%% ----- CUSTOM GENETIC ALGORITHM ZA TSP -----
% Parametri
popSize = 100;
numGenerations = 300;
mutationRate = 0.2;

% Inicijalna populacija (nasumične permutacije)
population = zeros(popSize, n);
for i = 1:popSize
    population(i,:) = randperm(n);
end

% Evaluacija (dodaj povratak kući pri evaluaciji)
fitness = zeros(popSize,1);
for i = 1:popSize
    fitness(i) = tour_length([population(i,:) start], distMatrix);
end

bestDistGA = inf;
bestTourGA = population(1,:);  % inicijalizacija

for gen = 1:numGenerations
    newPopulation = zeros(popSize, n);
    
    % Elitizam: zadrži najboljeg
    [~, idxBest] = min(fitness);
    newPopulation(1,:) = population(idxBest,:);
    
    % Kreiraj novu populaciju
    for i = 2:popSize
        % Selekcija (turnir 2)
        idx1 = randi(popSize);
        idx2 = randi(popSize);
        if fitness(idx1) < fitness(idx2)
            parentA = population(idx1,:);
            parentB = population(idx2,:);
        else
            parentA = population(idx2,:);
            parentB = population(idx1,:);
        end
        
        % Crossover (Order Crossover - OX)
        cut1 = randi(n);
        cut2 = randi(n);
        if cut1 > cut2
            tmp = cut1; cut1 = cut2; cut2 = tmp;
        end
        child = zeros(1,n);
        child(cut1:cut2) = parentA(cut1:cut2);
        pos = cut2 + 1;
        for j = 1:n
            city = parentB(mod(cut2 + j - 1, n) + 1);
            if ~ismember(city, child)
                if pos > n, pos = 1; end
                child(pos) = city;
                pos = pos + 1;
            end
        end
        
        % Mutacija (swap)
        if rand < mutationRate
            idx = randperm(n,2);
            tmp = child(idx(1));
            child(idx(1)) = child(idx(2));
            child(idx(2)) = tmp;
        end
        
        newPopulation(i,:) = child;
    end
    
    % Evaluacija nove populacije
    population = newPopulation;
    for i = 1:popSize
        fitness(i) = tour_length([population(i,:) start], distMatrix);
    end
    
    % Najbolji u ovoj generaciji
    [minFit, idxBest] = min(fitness);
    if minFit < bestDistGA
        bestDistGA = minFit;
        bestTourGA = population(idxBest,:);
    end
    
    % Prikaz napretka
    if mod(gen,50)==0
        fprintf("Generacija %d, najbolja dužina: %.2f\n", gen, bestDistGA);
    end
end

% Normalizuj da ruta počinje od 'start' i dodaj povratak
idxStart = find(bestTourGA == start, 1);
if ~isempty(idxStart)
    bestTourGA = [bestTourGA(idxStart:end), bestTourGA(1:idxStart-1)];
else
    % Ako se 'start' ne pojavi (ne bi trebalo), dodaj ga na početak
    bestTourGA = [start, bestTourGA(bestTourGA ~= start)];
end

tour_GA = [bestTourGA start];
fprintf("Custom GA duzina ture: %.2f\n", bestDistGA);

figure;
plot(coords(tour_GA,1), coords(tour_GA,2), '-o', 'LineWidth',2);
title('Custom Genetic Algorithm ruta');
grid on; axis equal;
text(coords(tour_GA,1), coords(tour_GA,2), string(cities(tour_GA)), ...
    'VerticalAlignment','bottom','HorizontalAlignment','right');
drawnow;

%% ----- POREĐENJE HEURISTIKA -----
Results = table({'NN'; '2-OPT'; 'SA'; 'GA'}, ...
    [totalDist; tour_length(improvedTour, distMatrix); bestDistSA; bestDistGA], ...
    'VariableNames', {'Heuristika','DuzinaRute'});

disp(Results);
writetable(Results, 'TSP_results.xlsx');

%% ===== LOKALNE FUNKCIJE (MORAJU BITI NA KRAJU FAJLA) =====

function bestTour = two_opt(tour, distMatrix)
% two_opt radi na zatvorenoj turi (prvi i poslednji čvor su isti).
% Ova verzija čuva početni čvor i optimizuje unutrašnje ivice.

    n = length(tour);
    improved = true;

    while improved
        improved = false;
        bestDistance = tour_length(tour, distMatrix);

        % preskačemo prvi i poslednji indeks (početak/kraj su isti)
        for i = 2:n-2
            for j = i+1:n-1
                % 2-opt swap segmenta i:j
                newTour = [tour(1:i-1), fliplr(tour(i:j)), tour(j+1:end)];
                newDistance = tour_length(newTour, distMatrix);
                if newDistance < bestDistance
                    tour = newTour;
                    bestDistance = newDistance;
                    improved = true;
                end
            end
        end
    end

    bestTour = tour;
end

function L = tour_length(t, distMatrix)
% tour_length očekuje zatvorenu rutu (poslednji čvor je povratak na prvi).
% Ako nije zatvorena, funkcija će je implicitno zatvoriti.

    if t(1) ~= t(end)
        t = [t, t(1)];
    end
    L = 0;
    for i = 1:length(t)-1
        L = L + distMatrix(t(i), t(i+1));
    end
end
