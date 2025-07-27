//#include "bits/stdc++.h"

#include <string>
#include <vector>
#include <iostream>
using namespace std;
//Undirected graph
class un_graph {

public:

    int num_node , num_edge;
    int* Degr;
    int* adjList , *adjListPtr;

public:
    int getNode(){
        return num_node;
    }
    int getEdges(){
        return num_edge;
    }

    void graph(){
        int u , v;
        cin >> num_node >> num_edge;

        vector<int> *adj = new vector<int>[num_node];
        for(int i = 0; i < num_edge ; i++){
            cin >> u >> v;
            adj[u].push_back(v);
            adj[v].push_back(u);
        }
        adjList = new int[2 * num_edge + 1];
        adjListPtr = new int[num_node + 1];

        int index = 0;
        for(int i = 0 ; i < num_node ; i++){
            adjListPtr[i] = index;
            for(int j : adj[i]){
                adjList[index++] = j;
            }
        }
        adjListPtr[num_node] = index;
        Degr = new int[num_node];
        for(int i = 0 ; i < num_node; ++i){
            Degr[i] = adjListPtr[i + 1] - adjListPtr[i];
        }
        delete[] adj;
        adj = nullptr;
    }

    void printAdjacencyList() {
        cout << "Adjacency List Pointers (adjListPtr):\n";
        for (int i = 0; i <= num_node; ++i) {
            cout << "adjListPtr[" << i << "] = " << adjListPtr[i] << endl;
        }

        cout << "\nAdjacency List (adjList):\n";
        for (int i = 0; i < num_node; ++i) {
            cout << "Vertex " << i << ": ";
            for (int j = adjListPtr[i]; j < adjListPtr[i + 1]; ++j) {
                cout << adjList[j] << " ";
            }
            cout << endl;
        }

        cout << "\nDegrees:\n";
        for (int i = 0; i < num_node; ++i) {
            cout << "Degree[" << i << "] = " << Degr[i] << endl;
        }
    }
};

