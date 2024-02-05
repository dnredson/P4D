import os
import sys
import numpy as np
import scipy.stats

def format_number(number):
    return f"{number:.6f}".replace('.', ',')

def calcular_estatisticas(nome_arquivo):
    try:
        with open(nome_arquivo, 'r') as arquivo:
            linhas = [linha for linha in arquivo if linha.startswith('C|')]
            if len(linhas) < 32:
                print(f"Aviso: Arquivo {nome_arquivo} não possui linhas suficientes.")
                return None

            parte_tamanho = len(linhas) // 32
            partes = [linhas[i * parte_tamanho:(i + 1) * parte_tamanho] for i in range(1, 31)]

            medias = []
            for parte in partes:
                total_cpu = sum(float(linha.split('|')[1].strip().strip('%')) for linha in parte)
                medias.append(total_cpu / len(parte))

            media = np.mean(medias)
            desvio_padrao = np.std(medias, ddof=1)
            ic_inferior, ic_superior = scipy.stats.norm.interval(0.95, loc=media, scale=desvio_padrao/np.sqrt(len(medias)))

            return format_number(media), format_number(desvio_padrao), format_number(ic_inferior), format_number(ic_superior)
    except FileNotFoundError:
        print(f"Erro: Arquivo {nome_arquivo} não encontrado.")
        return None

def main(diretorio, numero_containers):
    valores_base = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]
    #valores_base = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 1000, 1500, 2000, 2500, 3000,35000, 4000, 4500, 5000]
    estatisticas_agrupadas = {valor: [] for valor in valores_base}

    for valor in valores_base:
        for container in range(1, numero_containers + 1):
            nome_arquivo = os.path.join(diretorio, f"{valor}c{container}.txt")
            estatisticas = calcular_estatisticas(nome_arquivo)
            if estatisticas:
                estatisticas_agrupadas[valor].append((f"c{container}",) + estatisticas)

    for valor, estatisticas in estatisticas_agrupadas.items():
        linha_saida = " | ".join([" | ".join(map(str, est)) for est in estatisticas])
        print(f"{valor} | {linha_saida}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python programa.py <diretorio> <numero_containers>")
        sys.exit(1)
    main(sys.argv[1], int(sys.argv[2]))
