#!/usr/bin/env bash

# ElixirClaw Stress Test - 72 Hour Uptime Verification
# This script runs ElixirClaw continuously for 72 hours, monitoring:
# - Memory usage
# - Process count
# - Connection stability
# - Event throughput
# - Error rates

set -e

DURATION_HOURS=72
REPORT_INTERVAL=300  # 5 minutes
LOG_FILE="stress_test_$(date +%Y%m%d_%H%M%S).log"

echo "========================================" | tee -a "$LOG_FILE"
echo "ElixirClaw Stress Test - 72 Hour Run" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Initialize counters
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_HOURS * 3600))
ITERATIONS=0
ERRORS=0
TOTAL_MEMORY=0
MAX_MEMORY=0
MIN_MEMORY=999999999

# Function to log metrics
log_metrics() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local elapsed_hours=$((elapsed / 3600))
    local elapsed_mins=$(((elapsed % 3600) / 60))
    
    # Get memory usage (in KB)
    local memory=$(ps -o rss= -p "$BEAM_PID" 2>/dev/null || echo "0")
    
    # Get process count
    local processes=$(ps -o pid= -g $(ps -o pgid= -p "$BEAM_PID") 2>/dev/null | wc -l)
    
    # Calculate statistics
    TOTAL_MEMORY=$((TOTAL_MEMORY + memory))
    ITERATIONS=$((ITERATIONS + 1))
    
    if [ "$memory" -gt "$MAX_MEMORY" ]; then
        MAX_MEMORY=$memory
    fi
    
    if [ "$memory" -lt "$MIN_MEMORY" ]; then
        MIN_MEMORY=$memory
    fi
    
    # Format memory as MB
    local memory_mb=$((memory / 1024))
    local avg_memory_mb=$((TOTAL_MEMORY / ITERATIONS / 1024))
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Elapsed: ${elapsed_hours}h ${elapsed_mins}m | Memory: ${memory_mb}MB (Avg: ${avg_memory_mb}MB, Max: $((MAX_MEMORY / 1024))MB, Min: $((MIN_MEMORY / 1024))MB) | Processes: $processes | Errors: $ERRORS" | tee -a "$LOG_FILE"
}

# Function to test node capabilities
test_capabilities() {
    # Test system.notify (safe operation)
    if ! iex -S mix run -e "
ElixirClaw.Node.execute(\"system.notify\", %{title: \"Stress Test\", body: \"Heartbeat $(date +%s)\"})
" >> "$LOG_FILE" 2>&1; then
        ERRORS=$((ERRORS + 1))
        echo "ERROR: Failed to execute system.notify" | tee -a "$LOG_FILE"
    fi
}

# Function to test event streaming
test_events() {
    if ! iex -S mix run -e "
{:ok, _} = ElixirClaw.Events.emit_started(\"test\", \"stress_node\", \"test_$(date +%s)\")
{:ok, _} = ElixirClaw.Events.emit_completed(\"test\", \"stress_node\", \"test_$(date +%s)\", %{status: \"ok\"})
" >> "$LOG_FILE" 2>&1; then
        ERRORS=$((ERRORS + 1))
        echo "ERROR: Event streaming failed" | tee -a "$LOG_FILE"
    fi
}

# Function to check gateway connection
check_connection() {
    if iex -S mix run -e "
case Process.whereis(ElixirClaw.Gateway) do
    nil -> IO.puts(\"WARNING: Gateway not running\")
    pid -> IO.puts(\"Gateway running: #{inspect(pid)}\")
end
" >> "$LOG_FILE" 2>&1; then
        :
    else
        ERRORS=$((ERRORS + 1))
        echo "ERROR: Gateway check failed" | tee -a "$LOG_FILE"
    fi
}

# Function to cleanup on exit
cleanup() {
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Stress Test Terminated" | tee -a "$LOG_FILE"
    echo "Ended: $(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    
    # Generate summary
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local elapsed_hours=$((elapsed / 3600))
    local avg_memory_mb=$((TOTAL_MEMORY / ITERATIONS / 1024))
    
    echo "" | tee -a "$LOG_FILE"
    echo "Summary:" | tee -a "$LOG_FILE"
    echo "  Total Duration: ${elapsed_hours}h $(((elapsed % 3600) / 60))m" | tee -a "$LOG_FILE"
    echo "  Total Iterations: $ITERATIONS" | tee -a "$LOG_FILE"
    echo "  Average Memory: ${avg_memory_mb}MB" | tee -a "$LOG_FILE"
    echo "  Max Memory: $((MAX_MEMORY / 1024))MB" | tee -a "$LOG_FILE"
    echo "  Min Memory: $((MIN_MEMORY / 1024))MB" | tee -a "$LOG_FILE"
    echo "  Total Errors: $ERRORS" | tee -a "$LOG_FILE"
    
    if [ $ERRORS -eq 0 ]; then
        echo "  Status: PASSED ✓" | tee -a "$LOG_FILE"
        exit 0
    else
        echo "  Status: FAILED ✗" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "" | tee -a "$LOG_FILE"
echo "Starting ElixirClaw node..." | tee -a "$LOG_FILE"

# Start the node in background
iex -S mix &
BEAM_PID=$!

# Wait for startup
sleep 5

echo "Node started with PID: $BEAM_PID" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Main test loop
echo "Beginning stress test..." | tee -a "$LOG_FILE"
echo "Report interval: ${REPORT_INTERVAL}s" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

while [ $(date +%s) -lt $END_TIME ]; do
    # Log current metrics
    log_metrics
    
    # Test capabilities
    test_capabilities
    
    # Test event streaming
    test_events
    
    # Check connection
    check_connection
    
    # Wait for next interval
    sleep $REPORT_INTERVAL
done

# Run cleanup
cleanup