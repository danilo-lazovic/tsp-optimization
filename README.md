# TSP Heuristic Optimization

A comprehensive implementation and comparison of multiple heuristic algorithms for solving the Traveling Salesman Problem (TSP).

## Project Overview

This project implements and compares four different heuristic approaches to solve the TSP:
- **Nearest Neighbor (NN)** - Greedy constructive heuristic
- **2-OPT** - Local search improvement algorithm
- **Simulated Annealing (SA)** - Metaheuristic with probabilistic acceptance
- **Genetic Algorithm (GA)** - Custom evolutionary algorithm with Order Crossover

## Features

- **Data Collection**: Python script for automated geocoding of city coordinates
- **Multiple Algorithms**: Four different optimization approaches implemented from scratch
- **Visualization**: Graphical route representation for each algorithm
- **Performance Analysis**: Comparative results and route length optimization
- **Real-world Application**: Tested on European cities dataset

## Results

The algorithms were tested on a dataset of 17 European cities. Performance comparison:

| Algorithm | Route Length | Approach |
|-----------|--------------|----------|
| Nearest Neighbor | baseline | Constructive |
| 2-OPT | improved | Local Search |
| Simulated Annealing | optimized | Metaheuristic |
| Genetic Algorithm | best | Evolutionary |

All results are automatically exported to `TSP_results.xlsx` for further analysis.

## Technical Stack

- **Python 3.x** - Data collection and preprocessing
- **MATLAB R2020+** - Algorithm implementation and visualization
- **Excel** - Data storage and results export

## Project Structure

```
TSP-Heuristic-Optimization/
├── 4.py                    # Python geocoding script
├── cities.txt              # Input city list
├── cities.xlsx             # Generated coordinates
├── projekat_kraj.m         # Main MATLAB implementation
└── TSP_results.xlsx        # Algorithm comparison results
```

## Usage

### Step 1: Generate City Coordinates
```bash
python 4.py
```
This reads `cities.txt` and creates `cities.xlsx` with coordinates.

### Step 2: Run TSP Optimization
```matlab
% In MATLAB
run projekat_kraj.m
```

The script will:
1. Load city coordinates from Excel
2. Calculate distance matrix
3. Run all four heuristics
4. Generate route visualizations
5. Export comparison results

## Algorithm Details

### Nearest Neighbor (NN)
- Time Complexity: O(n²)
- Greedy approach: always visit nearest unvisited city
- Fast but often suboptimal

### 2-OPT
- Iteratively removes crossing edges
- Swaps route segments to reduce total distance
- Local search refinement of NN solution

### Simulated Annealing
- Temperature: 1000, Cooling: α=0.995
- Iterations: 50,000
- Probabilistic escape from local optima

### Genetic Algorithm (Custom)
- Population: 100 individuals
- Generations: 300
- Order Crossover (OX) operator
- Tournament selection (size 2)
- Mutation rate: 20%

## Applications

- Logistics route optimization
- Supply chain management
- Transportation planning
- Vehicle routing problems

## Key Learnings

- Comparison of constructive vs. metaheuristic approaches
- Trade-offs between computation time and solution quality
- Practical implementation of evolutionary algorithms
- MATLAB optimization and visualization techniques

## Author

**Danilo Lazović**
- Student of Management and Organization - Operations Management
- Faculty of Organizational Sciences, University of Belgrade

## License

This project is available for educational and research purposes.
