# Minimum Vertex Cover using CUDA

This project implements a parallel algorithm for solving the **Minimum Vertex Cover** problem using **CUDA** to leverage GPU acceleration. The implementation is optimized for performance and designed to handle large graphs efficiently.

## 📌 Problem Statement

Given an undirected graph **G = (V, E)**, a *vertex cover* is a subset of vertices such that every edge in the graph is incident to at least one vertex in the subset. The **Minimum Vertex Cover (MVC)** problem seeks the smallest such subset.

This project implements a heuristic, parallel solution using multiple CUDA kernels.

## 🚀 Features

- Graph input using adjacency list representation.
- CUDA-based parallel kernels for:
  - Initialization of candidate cover sets.
  - Neighbor checking and adjustment.
  - Conflict resolution via thread prioritization.
  - Iterative refinement and termination detection.
- Host-device coordination using unified memory and synchronization flags.
- Designed for scalable performance on large graphs.

## 📁 File Structure

├── graph_gen.cpp # C++ file to generate random undirected graphs
├── min_vertx.cu # CUDA implementation of the MVC algorithm
├── un_graph.h # C code which defines the structre of the Undirected graph.


## ⚙️ Build Instructions

Make sure you have the **CUDA toolkit** installed and `nvcc` available.

```bash
# Compile the graph generator
g++ graph_gen.cpp -o gen

# Generate a random graph and save it to a file
./gen graph_output.txt

# Compile the CUDA MVC implementation
nvcc -O2 -arch=sm_89 -o mvc min_vertx.cu
# You can also use: nvcc -O2 -o mvc min_vertx.cu (for default architecture)

# Run the MVC program with input and output file arguments
./mvc graph_output.txt output.txt
```
🧩 Data Structures
The algorithm uses several key arrays for parallel computation:

PMvc (int* PMvc) — Previous Minimum Vertex Cover:
A binary array indicating whether a vertex is proposed to be part of the cover set in the current iteration.
PMvc[i] = 1 means vertex i is being considered for inclusion.

Mvc (int* Mvc) — Final Vertex Cover:
The actual cover set being constructed. A value of 1 at index i means vertex i is included in the final cover.
This array is updated across iterations based on PMvc and neighbor state.

Adj (int* Adj) — Adjacency Status:
Marks whether all neighbors of a vertex are already covered.
Adj[i] = 1 means all neighbors of vertex i are already in the cover (safe), otherwise 0 (still needs to be handled).

These arrays are updated iteratively by different CUDA kernels, enabling convergence to a valid cover set.

🔍 Key Kernels

kernel1: Initializes potential vertex cover set.

kernel2: Marks nodes with uncovered neighbors.

kernel3: Updates PMvc set and adjusts Mvc set.

kernel4: Resolves tie-breaking conditions by thread ID priority.

🧠 Notes
The termination condition is flagged by a host-visible variable updated by device threads.

Edge cases (like isolated nodes) are handled.

Performance and correctness improve with large, sparse graphs.

🖥️ Recommended GPU Specs
At least 6 GB VRAM

CUDA Compute Capability 6.0+

Recommended: NVIDIA RTX series or A100 for best performance




