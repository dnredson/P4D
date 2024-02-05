import os
import sys
import re
import numpy as np
import scipy.stats as stats

def extract_number(file_name):
    match = re.search(r'(\d+)', file_name)
    return int(match.group(1)) if match else None

def process_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    values = [int(line.split('|')[1].strip()) for line in lines if line.startswith('D|')]
    chunk_size = len(values) // 32
    chunks = [values[i:i + chunk_size] for i in range(0, len(values), chunk_size)][1:-1]
    means = [np.mean(chunk) for chunk in chunks]

    return np.mean(means), len(values), np.std(means, ddof=1), means

def count_lines(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    return len(lines)

def format_number(number):
    return f"{number:.6f}".replace('.', ',')

def analyze_folder(folder_path):
    results = []
    for file in os.listdir(folder_path):
        if file.endswith('r.txt'):
            r_file_path = os.path.join(folder_path, file)
            mean_of_means, r_line_count, std_dev, means = process_file(r_file_path)
            confidence_interval = stats.t.interval(0.99, len(means)-1, loc=mean_of_means, scale=stats.sem(means))

            s_file_path = r_file_path.replace('r.txt', 's.txt')
            s_line_count = count_lines(s_file_path) if os.path.exists(s_file_path) else None

            formatted_mean = format_number(mean_of_means)
            formatted_std = format_number(std_dev)
            formatted_ci = (format_number(confidence_interval[0]), format_number(confidence_interval[1]))
            cimais = format_number(confidence_interval[0])
            cimenos = format_number(confidence_interval[1])
            relacao_percentual = ((r_line_count) *100)/s_line_count
            ci = float(cimenos.replace(',', '.')) - float(formatted_mean.replace(',', '.'))
        
            results.append((file, formatted_mean, formatted_std, cimais,cimenos, ci, relacao_percentual))

    # Ordena os resultados pelo número extraído do nome do arquivo
    results.sort(key=lambda x: extract_number(x[0]))
    return results

def main():
    if len(sys.argv) != 2:
        print("Uso: python processadorDelay.py <caminho_para_pasta>")
        sys.exit(1)

    folder_path = sys.argv[1]
    results = analyze_folder(folder_path)
    for file, mean_of_means, std, cimais, cimenos, ci,  relacao_percentual in results:
        mean_of_means = float(mean_of_means.replace(',', '.'))
        std = float(std.replace(',', '.'))
        cimais = float(cimais.replace(',', '.'))
        cimenos = float(cimenos.replace(',', '.'))
        ci = float(ci)
        relacao_percentual = float(relacao_percentual)
        mean_of_means_str = f"{mean_of_means:.2f}".replace('.', ',')
        std_str = f"{std:.2f}".replace('.', ',')
        cimais_str = f"{cimais:.2f}".replace('.', ',')
        cimenos_str = f"{cimenos:.2f}".replace('.', ',')
        ci_str = f"{ci:.2f}".replace('.', ',')
        relacao_percentual_str = f"{relacao_percentual:.2f}".replace('.', ',')

        print(f" {mean_of_means_str} | {std_str} | {cimais_str} | {cimenos_str} | {ci_str} | {relacao_percentual_str} ")

if __name__ == "__main__":
    main()
