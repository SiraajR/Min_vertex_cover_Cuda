
//#include <stdc++.h>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <cstring>
#include <iostream>
#include <cuda.h>
#include "un_graph.h"
using namespace std;

#define MAX_THREAD 1024

void catchError(cudaError_t error , const char* funct){
    if (error  != cudaSuccess){
        printf("\n>>>>>Cuda error code %i <<<<<\n %s line of error and function : %s\n" , error , cudaGetErrorString(error) , funct);
        exit(-1);
    }
   
}

__global__ void kernel1(int* Mvc , int* PMvc , int* AdjList , int* AdjListPtr , int* Deg , int num_node){
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if(tid >= num_node){
        return;
    }
    int deg = Deg[tid];
    int mdeg = deg;
    for(int i = AdjListPtr[tid] ; i < AdjListPtr[tid + 1] ; i ++ ){
        int neighbour = AdjList[i];
        int deg2 = Deg[neighbour];
        mdeg = min(mdeg , deg2);
    }
    if (deg == mdeg){
        Mvc[tid] = 0;

    }
}
__global__ void kernel2(int* Mvc , int * PMvc , int* AdjList , int* AdjListPtr , int* Adj , int* terminate , int num_node){
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if(tid >= num_node){
        return;
    }
    Adj[tid] = 1;
    for(int i = AdjListPtr[tid] ; i < AdjListPtr[tid + 1] ; i++){
        int neighbour = AdjList[i];
        if(Mvc[neighbour] == 0){
            Adj[tid] = 0;
            break;
        }
    }
    //printf("\n🧵 Thread ID: %d\n", tid);
    //printf("╭──────────────────────────────╮\n");
    //printf("│ Mvc[tid]  = %d\n" ,  Mvc[tid]);
    //printf("│ PMvc[tid] = %d\n", PMvc[tid]);
    //printf("│ Adj[tid]  = %d\n", Adj[tid]);
    //printf("╰──────────────────────────────╯\n");

    if (Mvc[tid] != (1 - Adj[tid])) {
        *terminate = 0;
        //printf("🔁 Recompute Triggered by tid %d ⚠️\n", tid);
    } else {
        //printf("✅ Computation Complete for tid %d\n", tid);
    }
    PMvc[tid] = Mvc[tid];
}
__global__ void kernel3(int* Mvc , int * PMvc , int* AdjList , int* AdjListPtr , int* Adj , int num_node){
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if(tid >= num_node){
        return;
    }
    bool u_cond = false;
    bool w_cond = false;    
    for(int i = AdjListPtr[tid] ; i < AdjListPtr[tid + 1] ; i++){
        int neighbour = AdjList[i];
        if((Mvc[neighbour] == 1 &&  Adj[neighbour] == 0 && Adj[tid] == 1 )){
            u_cond = true;
            
        }
        if(Mvc[neighbour] == 0 && Adj[neighbour] == 1){
            w_cond = true;
        }
        if(u_cond && w_cond){
            break;
        }
    }  

    if(u_cond && !w_cond){
        Mvc[tid] = 0;
    } 
}
__global__ void kernel4(int* PMvc , int* AdjListPtr , int* Adj , int* AdjList, int* Mvc , int num_node ){
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    if(tid >= num_node){
        return;
    }
    if (PMvc[tid] == 0 && Adj[tid] == 0){
        for (int i = AdjListPtr[tid] ; i < AdjListPtr[tid + 1] ; i++){
            int neighbour = AdjList[i];
            if(PMvc[neighbour] == 0 && Adj[neighbour] == 0 && neighbour < tid){
                Mvc[tid] = 1;

            }

        }
    }
}
int main(int argc, char *argv[]){
    if(argc < 2){
        cout << "Usage:" << argv[0] << "<graph_input> [output_file] \n";
        return 0;
    }
    if (!freopen(argv[1] , "r" , stdin)){
        perror("Failed to open the file");
        return 1;
    }
    
    
    int* D_AdjList , *D_AdjListPtr , *D_Deg;
    int* d_Mvc , * d_Adj , *d_PMvc;
    //Cuda Event creating 
    cudaEvent_t start , stop;

    catchError(cudaEventCreate(&start) , "Event Creation start");
    catchError(cudaEventCreate(&stop) , "Event Creation stop");
    un_graph *host_graph = new un_graph();
    un_graph *device_Graph;
    catchError(cudaMalloc((void**) &device_Graph , sizeof(un_graph)) , "Mem alloc for graph");
    host_graph->graph();
    int num_node = host_graph -> getNode();
    int num_edge = host_graph-> getEdges();
    int* h_Mvc;
    int* h_Adj ;
    int* h_PMvc ;
    // minimum vertex cover
    int* V;
    catchError(cudaMallocHost((void**) &V , num_node * sizeof(int)) , "Min vertex cover Mem Alloc");

    int* H_AdjList = host_graph->adjList;
    int* H_AdjListPtr = host_graph->adjListPtr;
    int* H_Deg= host_graph->Degr;
    int* D_terminate;
    //Allocate memory to memcpy 
    catchError(cudaMallocHost((void**)&h_Mvc , num_node*sizeof(int)) , "host side MVC alloc");
    catchError(cudaMallocHost((void**)&h_Adj , num_node*sizeof(int)) , "host side Adj mem alloc");
    catchError(cudaMallocHost((void**)&h_PMvc , num_node*sizeof(int)) , "Previous PMvc host side malloc ");

    //initializing the host arrays with dummy values 
    for (int i = 0; i < num_node; ++i) h_Mvc[i] = 1;
    memset(h_Adj , 0 , num_node * sizeof(int));
   // memset(h_PMvc , 0 , num_node * sizeof(int));

    //Allocating memory
    catchError(cudaMalloc((void**)&d_Mvc, num_node * sizeof(int)) , "device side MVC Malloc");
    catchError(cudaMalloc((void**)&d_Adj, num_node * sizeof(int)) , "device side Adj Malloc");
    catchError(cudaMalloc((void**)&d_PMvc, num_node * sizeof(int)) , "device side PMVC Malloc");
    catchError(cudaMalloc((void**)&D_AdjList, (2*num_edge + 1) * sizeof(int)) , "device side AdjList Malloc");
    catchError(cudaMalloc((void**)&D_AdjListPtr, (num_node + 1) * sizeof(int)) , "device side AdjListPtr Malloc");
    catchError(cudaMalloc((void**)&D_Deg, num_node * sizeof(int)) , "device side Deg Malloc");
    catchError(cudaMalloc((void**) &D_terminate , sizeof(int)) , "device side terminate Malloc");

    
    catchError(cudaMemcpy(D_AdjList , H_AdjList , sizeof(int)* (2*num_edge + 1) , cudaMemcpyHostToDevice) , "MemCpy1");
    catchError(cudaMemcpy(D_AdjListPtr , H_AdjListPtr , sizeof(int) * (num_node + 1) , cudaMemcpyHostToDevice) , "MemCpy2");
    catchError(cudaMemcpy(D_Deg , H_Deg , num_node*sizeof(int) , cudaMemcpyHostToDevice) , "MemCpy3");
    catchError(cudaMemcpy(device_Graph , host_graph , sizeof(un_graph) , cudaMemcpyHostToDevice) , "MemCpy4");
    catchError(cudaMemcpy(d_Mvc , h_Mvc, num_node * sizeof(int) , cudaMemcpyHostToDevice) , "MemCpy5");
    catchError(cudaMemcpy(d_Adj , h_Adj , num_node * sizeof(int) , cudaMemcpyHostToDevice) , "MemCpy6");
    catchError(cudaMemcpy(d_PMvc ,h_PMvc , num_node*sizeof(int) , cudaMemcpyHostToDevice) , "MemCpy7");

   

    int Num_blocks = (num_node + MAX_THREAD - 1) / MAX_THREAD;
    catchError(cudaEventRecord(start) , "start event record");
    kernel1<<<Num_blocks  , MAX_THREAD>>>(d_Mvc, d_PMvc,  D_AdjList,  D_AdjListPtr, D_Deg , num_node);
    catchError(cudaGetLastError() , "last err");
    catchError(cudaMemcpy(d_PMvc , d_Mvc , num_node * sizeof(int) , cudaMemcpyDeviceToDevice) , "MemCpy8");
    int H_terminate = 1;

    do{
        H_terminate = 1;
        cudaMemcpy(D_terminate , &H_terminate , sizeof(int) , cudaMemcpyHostToDevice );
        kernel3<<<Num_blocks , MAX_THREAD>>>(d_Mvc, d_PMvc, D_AdjList, D_AdjListPtr, d_Adj , num_node);
        //kernel 3 initialization
        catchError(cudaGetLastError() , "kernel 3");
        kernel2<<<Num_blocks , MAX_THREAD>>>(d_Mvc, d_PMvc, D_AdjList, D_AdjListPtr, d_Adj, D_terminate , num_node);
        //kernel 2 initialization
        catchError(cudaGetLastError() ,"kernel 2 pt1");
        kernel4<<<Num_blocks , MAX_THREAD>>>(d_PMvc, D_AdjListPtr, d_Adj, D_AdjList, d_Mvc , num_node);
        //kernel 4 initialization 
        catchError(cudaGetLastError() , "kernel 4");
        kernel2<<<Num_blocks , MAX_THREAD>>>(d_Mvc, d_PMvc, D_AdjList, D_AdjListPtr, d_Adj, D_terminate , num_node);
        //syncing PMvc and Mvc
        catchError(cudaGetLastError() ,"kernel 2 pt2");
        //cudaDeviceSynchronize();
        cudaMemcpy(&H_terminate , D_terminate , sizeof(int) , cudaMemcpyDeviceToHost);
        //printf("H_terminate = %d\n", H_terminate);
        /*if(H_terminate == 0) {
            printf("🔁 Recompute Triggered by tid");
        }else{
            printf("✅ Computation Complete");
        }
        */
        //cudaMemcpy(d_PMvc , d_Mvc , num_node * sizeof(int) , cudaMemcpyDeviceToDevice);
        //kernel 2 initialization
    
    }while(H_terminate == 0); // if its 0 then something changed , if its 1 then its over

    printf("Number of Nodes: %d\n" , num_node);
    printf("Number of Edges: %d\n" , num_edge);

    catchError(cudaMemcpy(V , d_Mvc , num_node*sizeof(int) , cudaMemcpyDeviceToHost) , "MemCpy9");
    catchError(cudaEventRecord(stop) , "Event record: stop");
    catchError(cudaEventSynchronize(stop) , "Event sync");
    float total_time = 0;
    catchError(cudaEventElapsedTime( &total_time, start , stop) , "Total time taken: ");
    printf("GPU time takes: %f\n" , total_time);
    if(argc == 3){
        if (!freopen(argv[2], "w", stdout)) {
            perror("Failed to open output file");
            return 1;
        }
        for(int i = 0 ; i < num_node ; ++i){
            cout << V[i] << " ";
        }
        cout << endl;
    }

    // freeing up allocated memeory
    //cuda free device side memory allocation

    //host side freeing 
    catchError(cudaFreeHost(h_Mvc) , "free h_Mvc");
    catchError(cudaFreeHost(h_Adj) , "free h_Adj");
    catchError(cudaFreeHost(h_PMvc) , "free h_PMvc");
    
    //device side freeing 
    catchError(cudaFree(d_Mvc) , "free d_Mvc");
    catchError(cudaFree(d_Adj) , "free d_adj");
    catchError(cudaFree(d_PMvc) , "free d_PMvc");
    catchError(cudaFree(D_AdjList) , "free D_AdjList");
    catchError(cudaFree(D_AdjListPtr) , "free D_AdjListPtr");
    catchError(cudaFree(D_Deg) , "free D_Deg");
    catchError(cudaFree(D_terminate) , "free D_terminate");
}