
//#include "stdc++.h"

#include <iostream>
using namespace std;

int main(int argc , char *argv[]){
    if (argc < 2){
        cout << argv[0] << "<graph_output>\n";
        return 0;
    }
    int n , m;
    int x , y;
    cin >> n >> m;
    freopen(argv[1] , "w" , stdout);
    cout << n << " " << m << endl;

    for(int i = 0 ; i < m; i++){
        do {
            x = rand() % n;
            y = rand( ) % n;
        } while(x == y);

        cout << x << " " << y << endl;
    }
}