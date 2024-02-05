#!/bin/bash

# Define os valores que você quer usar
valores=(10 20 30 40 50)
# Itera sobre cada valor no array
for contador in "${valores[@]}"
do
   bash 1SWCP.sh
   sleep 30  
   echo "Executando para o valor ${contador}. 1SW TCP CP"

   # Setar os comandos a serem executados
   # Inicia o receptor no host 2
   startH2="docker exec h2 ./TH >> 1SW/TCP/CP/${contador}r.txt &"
   # Inicia o gerador no host 1 
   startH1="docker exec h1 ./TGP 600 ${contador} 10.0.2.2 >>  1SW/TCP/CP/${contador}s.txt &"
   # Inicia o monitoramento do switch
   md1="python3 monitorDocker.py sw1 >>  1SW/TCP/CP/${contador}c1.txt &"

   sleep 5
   # Executa os comandos de monitoramento e recebimento
   eval "$startH2"
   eval "$md1"
   # Inicia o envio
   sleep 2
   eval "$startH1" 
   
   # Espera 630 segundos antes da próxima execução sendo que o gerador permanece ativo por 10 min
   sleep 630
   # limpa o ambiente antes do próximo experimento, respeitando tempo de esfriamento para a próxima interação
   bash scriptLimpeza.sh   
   sleep 30
done

echo "Script concluido."


