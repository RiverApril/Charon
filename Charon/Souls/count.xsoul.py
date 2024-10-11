
import sys
import time

n = int(sys.argv[1])

for i in range(n, 0, -1):
    print(str(i)+" ", end="", flush=True)
    time.sleep(1)
