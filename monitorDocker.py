import docker
import time
import sys

def monitor_container_usage(container_id, duration=605, interval=2):
    client = docker.from_env()

    try:
        container = client.containers.get(container_id)
        if not container.status == 'running':
            print(f"O container '{container_id}' não está em execução.")
            return
    except docker.errors.NotFound:
        print(f"O container '{container_id}' não foi encontrado.")
        return
    except Exception as e:
        print(f"Erro ao acessar o container: {e}")
        return

    print(f"Iniciando monitoramento do container '{container_id}'...")
    start_time = time.time()
    while time.time() - start_time < duration:
        try:
            stats = container.stats(stream=False)

            cpu_usage = stats['cpu_stats']['cpu_usage']['total_usage']
            system_cpu_usage = stats['cpu_stats']['system_cpu_usage']
            cpu_delta = cpu_usage - stats['precpu_stats']['cpu_usage']['total_usage']
            system_cpu_delta = system_cpu_usage - stats['precpu_stats']['system_cpu_usage']
            cpu_percent = 0.0

            if system_cpu_delta > 0.0 and cpu_delta > 0.0:
                cpu_percent = (cpu_delta / system_cpu_delta) * len(stats['cpu_stats']['cpu_usage']['percpu_usage']) * 100.0

            memory_usage = stats['memory_stats']['usage']
            memory_limit = stats['memory_stats']['limit']
            memory_percent = (memory_usage / memory_limit) * 100.0

            print(f"C| {cpu_percent:.1f}% | M | {memory_percent:.1f}%")
        except Exception as e:
            print(f"Erro ao coletar estatísticas: {e}")
            break

        time.sleep(interval)

    print("Monitoramento concluído.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 monitorDocker.py <nome_do_container>")
    else:
        container_name = sys.argv[1]
        monitor_container_usage(container_name)
