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

.
├── graph_gen.cpp # C++ file to generate random undirected graphs
├── min_vertx.cu # CUDA implementation of the MVC algorithm
├── un_graph.h # C code which defines the structre of the Undirected graph.


## ⚙️ Build Instructions

Make sure you have the **CUDA toolkit** installed and `nvcc` available.
