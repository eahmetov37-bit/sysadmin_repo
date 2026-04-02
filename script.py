from collections import defaultdict

log_file = "nginx.log"
output_file = "result.txt"

ip_count = defaultdict(int)

with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        parts = line.split()
        if not parts:
            continue
        ip = parts[0]
        ip_count[ip] += 1

with open(output_file, "w", encoding="utf-8") as f:
    for ip, count in ip_count.items():
        f.write(f"{ip}: {count}\n")

print("Готово. Результат сохранён в result.txt")
