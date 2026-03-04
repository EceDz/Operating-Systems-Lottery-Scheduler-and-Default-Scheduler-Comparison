#!/bin/bash
# MSE Calculator

if [ -z "$1" ]; then
    echo "Usage: $0 <test_folder>"
    exit 1
fi

TEST_FOLDER="$1"
OUTPUT_FILE="${TEST_FOLDER}_MSE_results.txt"

> "$OUTPUT_FILE"

echo "MSE ANALYSIS - $TEST_FOLDER" >> "$OUTPUT_FILE"
echo "============================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process Default Scheduler
echo "Default Scheduler MSE:" >> "$OUTPUT_FILE"
echo "+---------+----------+----------------+" >> "$OUTPUT_FILE"
echo "|   PID   |   USER   |      MSE       |" >> "$OUTPUT_FILE"
echo "+---------+----------+----------------+" >> "$OUTPUT_FILE"

if ls "$TEST_FOLDER"/default*.txt 1> /dev/null 2>&1; then
    awk '
    BEGIN {
        # Arrays to store data
    }
    /^[[:space:]]*[0-9]+/ && $NF == "infinite" {
        pid = $1
        user = $2
        cpu = $9
        gsub(/%/, "", cpu)
        
        # Store user (first occurrence)
        if (!user_names[pid]) {
            user_names[pid] = user
        }
        
        # Add CPU sample for this PID
        cpu_samples[pid] = cpu_samples[pid] " " cpu
        sample_count[pid]++
    }
    END {
        # First pass: count unique PIDs
        pid_count = 0
        for (pid in sample_count) {
            pid_count++
            pids[pid_count] = pid
        }
        
        if (pid_count == 0) {
            print "No processes found"
            exit
        }
        
        # Ideal CPU share
        ideal = 100 / pid_count
        
        total_mse_sum = 0  # Initialize accumulator for session MSE
        
        # Calculate MSE for each PID
        for (i = 1; i <= pid_count; i++) {
            pid = pids[i]
            
            # Split CPU samples into array
            split(cpu_samples[pid], samples, " ")
            
            # Calculate squared errors
            sq_error_sum = 0
            for (j = 2; j <= sample_count[pid] + 1; j++) {
                error = samples[j] - ideal
                sq_error_sum += error * error
            }
            
            # Calculate MSE for this PID
            mse = sq_error_sum / sample_count[pid]
            total_mse_sum += mse  # Accumulate for session average
            
            # Print result in table format
            printf "| %7s | %8s |     %.4f     |\n", pid, user_names[pid], mse
        }
        
        # Calculate and print session MSE
        if (pid_count > 0) {
            session_mse = total_mse_sum / pid_count
            printf "\nSession MSE (Average of all processes): %.4f\n", session_mse
        }
    }
    ' "$TEST_FOLDER"/default*.txt >> "$OUTPUT_FILE"
else
    echo "|     No default files found     |" >> "$OUTPUT_FILE"
fi

echo "+---------+----------+----------------+" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process Lottery Scheduler
echo "Lottery Scheduler MSE:" >> "$OUTPUT_FILE"
echo "+---------+----------+----------------+" >> "$OUTPUT_FILE"
echo "|   PID   |   USER   |      MSE       |" >> "$OUTPUT_FILE"
echo "+---------+----------+----------------+" >> "$OUTPUT_FILE"

if ls "$TEST_FOLDER"/lottery*.txt 1> /dev/null 2>&1; then
    awk '
    BEGIN {
        total_mse_sum = 0  # Initialize accumulator
    }
    /^[[:space:]]*[0-9]+/ && $NF == "infinite" {
        pid = $1
        user = $2
        cpu = $9
        gsub(/%/, "", cpu)
        
        if (!user_names[pid]) {
            user_names[pid] = user
        }
        
        cpu_samples[pid] = cpu_samples[pid] " " cpu
        sample_count[pid]++
    }
    END {
        pid_count = 0
        for (pid in sample_count) {
            pid_count++
            pids[pid_count] = pid
        }
        
        if (pid_count == 0) {
            print "No processes found"
            exit
        }
        
        ideal = 100 / pid_count
        
        for (i = 1; i <= pid_count; i++) {
            pid = pids[i]
            
            split(cpu_samples[pid], samples, " ")
            
            sq_error_sum = 0
            for (j = 2; j <= sample_count[pid] + 1; j++) {
                error = samples[j] - ideal
                sq_error_sum += error * error
            }
            
            mse = sq_error_sum / sample_count[pid]
            total_mse_sum += mse  # Accumulate MSE for session average
            
            printf "| %7s | %8s |     %.4f     |\n", pid, user_names[pid], mse
        }
        
        # Print session MSE
        if (pid_count > 0) {
            session_mse = total_mse_sum / pid_count
            printf "\nSession MSE (Average of all processes): %.4f\n", session_mse
        }
    }
    ' "$TEST_FOLDER"/lottery*.txt >> "$OUTPUT_FILE"
else
    echo "|     No lottery files found     |" >> "$OUTPUT_FILE"
fi

echo "+---------+----------+----------------+" >> "$OUTPUT_FILE"