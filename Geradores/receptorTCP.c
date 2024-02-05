#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <inttypes.h>
#include <endian.h>
#include <time.h>
#include <stdint.h> 

#define PORT 12345

// Função para obter o tempo atual em milissegundos
uint64_t get_current_time_milliseconds() {
    struct timespec current_time;
    clock_gettime(CLOCK_REALTIME, &current_time);
    uint64_t current_timestamp_milliseconds = (uint64_t)(current_time.tv_sec * 1000) + (current_time.tv_nsec / 1000000);
    return current_timestamp_milliseconds;
}

void receive_packet(int server_socket, uint64_t start_time) {
    uint64_t network_order_payload;
    ssize_t bytes_received = recv(server_socket, &network_order_payload, sizeof(uint64_t), 0);

    if (bytes_received != sizeof(uint64_t)) {
        perror("Error receiving packet");
        exit(EXIT_FAILURE);
    }

    uint64_t host_order_payload = be64toh(network_order_payload);
    uint64_t current_timestamp_milliseconds = get_current_time_milliseconds(); // Usar a função para obter o tempo atual em milissegundos
    int delay = current_timestamp_milliseconds - host_order_payload;

    // Ajuste para calcular o atraso de maneira precisa
    
   // printf("P| %" PRIu64 "\n", host_order_payload);
    //printf("C| %" PRIu64 "\n", current_timestamp_milliseconds);
    printf("D| %i \n", delay);
}

int main() {
    int server_socket, client_socket;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_length = sizeof(client_address);

    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(PORT);
    server_address.sin_addr.s_addr = INADDR_ANY;

    if (bind(server_socket, (struct sockaddr*)&server_address, sizeof(server_address)) == -1) {
        perror("Error binding");
        exit(EXIT_FAILURE);
    }

    if (listen(server_socket, 1) == -1) {
        perror("Error listening");
        exit(EXIT_FAILURE);
    }

    printf("Listening on 127.0.0.1:%d\n", PORT);

    if ((client_socket = accept(server_socket, (struct sockaddr*)&client_address, &client_address_length)) == -1) {
        perror("Error accepting connection");
        exit(EXIT_FAILURE);
    }

    printf("Connection established with %s:%d\n", inet_ntoa(client_address.sin_addr), ntohs(client_address.sin_port));

    uint64_t start_time = get_current_time_milliseconds(); // Usar a função para obter o tempo de início em milissegundos

    while (1) {
        receive_packet(client_socket, start_time);
    }

    close(client_socket);
    close(server_socket);

    return 0;
}
