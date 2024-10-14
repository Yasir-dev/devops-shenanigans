#!/bin/bash


show_separator() {
    echo "----------------------------------------"
}

show_cpu_usage() {
    show_separator
    # -bn1: Run 'top' in batch mode with a single iteration
    # grep "Cpu(s)": Filter the output to only include the line containing CPU information
    # awk '{print 100 - $8"%"}': Use awk to extract the 8th field (idle CPU percentage) and subtract it from 100 to get the CPU usage percentage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
    echo "CPU Total Usage: $cpu_usage"
    show_separator
}

show_memory_usage() {
    show_separator
    # The 'free' command displays the amount of free and used memory in the system.
    # The '-m' flag is used to display the memory size in megabytes.
    # The 'awk' command is used to process the output of 'free' command.
    # 'NR==2' selects the second line of the output, which contains the memory usage information.
    # The 'printf' function is used to format and print the memory usage percentage,
    # as well as the used and free memory in megabytes.
    memory_usage=$(free -m | awk 'NR==2{printf "%.2f%% (Used: %s MB, Free: %s MB)", $3*100/$2, $3, $4}')
    echo "Memory Usage: $memory_usage"
    show_separator
}

show_disk_usage() {
    show_separator
    # The 'df' command displays the amount of disk space used and available on the file system.
    # The '-h' flag is used to display the disk space in a human-readable format.
    # The 'awk' command is used to process the output of 'df' command.
    # '$NF=="/"' selects the line where the last field is "/" (root directory),
    # which represents the disk space usage of the entire file system.
    # The 'printf' function is used to format and print the disk usage percentage,
    # as well as the used and free disk space.
    disk_usage=$(df -h | awk '$NF=="/"{printf "%s (Used: %s, Free: %s)", $5, $3, $4}')
    echo "Disk Usage: $disk_usage"
    show_separator
}

show_top_processes() {
    show_separator
    # The 'ps' command displays information about active processes.
    # The '-eo' flag is used to specify the output format.
    # 'pid,ppid,uid,gid,comm,%cpu' selects the desired fields to display.
    # The '--sort=-%cpu' flag is used to sort the processes based on CPU usage in descending order.
    # The 'head -n 6' command is used to select the top 6 processes.
    top_processes=$(ps -eo pid,ppid,uid,gid,comm,%cpu --sort=-%cpu | head -n 6)
    echo "Top Processes:"
    echo "$top_processes"
    show_separator
}

show_top_processes_by_memory() {
    show_separator
    # It uses the `ps` command to list process information and sorts the output by memory usage in descending order.
    # The `-eo` flag specifies the format of the output, including the process ID (pid), parent process ID (ppid), user ID (uid), group ID (gid), command name (comm), and memory usage (%mem).
    # The `--sort=-%mem` option sorts the output by memory usage in descending order.
    # The `head -n 6` command limits the output to the top 6 processes.
    top_processes_by_memory=$(ps -eo pid,ppid,uid,gid,comm,%mem --sort=-%mem | head -n 6)
    echo "Top Processes by Memory Usage:"
    echo "$top_processes_by_memory"
    show_separator
}

show_logged_in_users() {
    show_separator
    logged_in_users=$(who)
    echo "Logged In Users:"
    echo "$logged_in_users"
    show_separator
}

show_server_uptime() {
    show_separator
    uptime=$(uptime)
    echo "Server Uptime:"
    echo "$uptime"
    show_separator
}

show_os_version() {
    show_separator
    # - `cat /etc/os-release`: This command displays the contents of the '/etc/os-release' file, which contains information about the operating system.
    # - `grep "PRETTY_NAME"`: This command filters the output of the previous command and searches for the line containing "PRETTY_NAME".
    # - `cut -d= -f2`: This command extracts the value after the '=' character in the filtered line.
    # - `tr -d '"'`: This command removes any double quotes from the extracted value.
    os_version=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2 | tr -d '"')
    echo "OS Version:"
    echo "$os_version"
    show_separator
}


show_os_version
show_server_uptime
show_cpu_usage
show_memory_usage
show_disk_usage
show_top_processes
show_top_processes_by_memory