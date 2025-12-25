#!/bin/bash

# 默认值
CLIENT_EXEC="./client/client.out"
CLIENT_COUNT=2

# 解析参数
if [ "$#" -ge 1 ]; then
    CLIENT_EXEC=$1
fi

if [ "$#" -ge 2 ]; then
    CLIENT_COUNT=$2
fi

# 检查可执行文件是否存在
if [ ! -f "$CLIENT_EXEC" ]; then
    echo "Error: $CLIENT_EXEC not found. Please compile first or provide correct path."
    echo "Usage: $0 [client_path] [client_count]"
    exit 1
fi

run_client_input() {
    echo "connect"
    sleep 0.5
    echo "127.0.0.1"
    echo "6230"
    
    sleep 1      # 等待连接建立
    echo "time"  # 发送请求（触发100次发送）
    
    sleep 3      # 等待接收所有响应
    echo "exit"
}

echo "=== Starting Concurrent Test ==="
echo "Client Path: $CLIENT_EXEC"
echo "Client Count: $CLIENT_COUNT"
echo "Make sure your server is running in another terminal!"

PIDS=""

for ((i=1; i<=CLIENT_COUNT; i++)); do
    LOG_FILE="client_$i.log"
    echo "[TEST] Launching Client $i..."
    run_client_input | $CLIENT_EXEC > "$LOG_FILE" 2>&1 &
    PIDS="$PIDS $!"
done

echo "[TEST] Clients running with PIDs: $PIDS"
echo "[TEST] Waiting for tests to complete..."

# 等待所有进程结束
for pid in $PIDS; do
    wait $pid
done

echo "=== Test Finished ==="
echo "Check the server terminal for concurrent logs."

# 显示每个客户端日志的最后几行
for ((i=1; i<=CLIENT_COUNT; i++)); do
    LOG_FILE="client_$i.log"
    echo -e "\n--- Client $i Log (Last 5 lines) ---"
    tail -n 5 "$LOG_FILE"
done
