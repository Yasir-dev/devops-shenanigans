#!/bin/bash


is_valid_log_entry() {

    # Assign the first argument to the local variable 'entry'
    local entry=$1

    # Extract the HTTP request method from the log entry and remove double quotes
    # awk is a command line utility for extracting fields from text, $6 is the 6th field in the log entry
    # tr is the a command line utility for translating or deleting characters, -d option is used to delete the specified characters
    http_request_method=$(echo "$entry" | awk '{print $6}' | tr -d '"')

    # Extract the status code from the log entry
    status_code=$(echo "$entry" | awk '{print $9}')

    # Array of valid HTTP request methods
    http_request_methods=("GET" "POST" "PUT" "DELETE" "HEAD" "OPTIONS" "CONNECT" "TRACE" "PATCH")

    # Check if the extracted HTTP request method is in the array of valid methods
    if [[ ! " ${http_request_methods[@]} " =~ " ${http_request_method} " ]]; then
        # Return 1 (false)
        return 1
    fi

    # Check if the status code is a three-digit number
    if ! [[ $status_code =~ ^[0-9]{3}$ ]]; then
        # Return 1 (false)
        return 1
    fi

    # Check if the status code is within the valid range (100-599)
    if [[ $status_code -lt 100 || $status_code -ge 600 ]]; then
        # Return 1 (false)
        return 1
    fi

    # Return 0 (true)
    return 0
}

print_top_matrics() {
    # Assign the first argument to the local variable 'title'
    local title=$1
    # Declare a nameref variable 'array' that references the second argument
    declare -n array=$2

    # Print a separator line
    echo "-------------------------------------------------------------------------------"
    # Print the title of the metrics
    echo "Top 5 $title:"
    # Print another separator line
    echo "-------------------------------------------------------------------------------"

    # Iterate over the keys of the associative array ${!array[@]} provides the keys of the array
    for key in "${!array[@]}"; do
        # Print the key and its corresponding value
        echo "$key - ${array[$key]} requests"
    done | sort -t '-' -k2 -nr | head -n 5
    # sort commmand is used to sort the output
    # -t specifies the delimiter
    # -k2 specifies to sort based on the second field
    # -n specifies to sort numerically
    # -r specifies to sort in reverse order
    # head command is used to get the top 5 entries (-n 5 means top 5) 
}

show_nginx_access_log_anylysis() {
    # Assign the first argument to the local variable 'log_file'
    local log_file=$1
    # -A option is used to declare an associative array
    declare -A ip_count path_count status_code_count user_agent_count

    # Read the log file line by line
    while read -r line; do

        # Validate the log entry
        if ! is_valid_log_entry "$line"; then
            # Skip the invalid log entry
            continue
        fi

        # Extract the IP address from the log entry
        ip=$(echo "$line" | awk '{print $1}')
        # Extract the path from the log entry and remove query parameters, cut command is used to remove query parameters (-d specifies the delimiter, -f specifies the field to sleect)
        path=$(echo "$line" | awk '{print $7}' | cut -d '?' -f 1)
        # Extract the status code from the log entry
        status_code=$(echo "$line" | awk '{print $9}')
        # Extract the user agent from the log entry and remove double quotes
        user_agent=$(echo "$line" | awk '{print $12}' | tr -d '"')

        # Increment the count for the extracted IP address
        ((ip_count["$ip"]++))
        # Increment the count for the extracted path
        ((path_count["$path"]++))
        # Increment the count for the extracted status code
        ((status_code_count["$status_code"]++))
        # Increment the count for the extracted user agent
        ((user_agent_count["$user_agent"]++))

    # Read from the log file
    done < "$log_file"

    print_top_matrics "IP Addresses" ip_count
    print_top_matrics "Paths" path_count
    print_top_matrics "Http Status Codes" status_code_count
    print_top_matrics "User Agents" user_agent_count
}

if [[ $# -ne 1 ]]; then
    # Check if the number of arguments is not equal to 1
    echo "Usage: $0 <nginx-access-log-file>"
    # Print the usage message
    exit 1
    # Exit with status 1 (error)
fi

LOG_FILE=$1
# Assign the first argument to the variable 'LOG_FILE'

if [[ ! -f "$LOG_FILE" ]]; then
    # Check if the log file does not exist
    echo "Log file not found!"
    # Print an error message
    exit 1
    # Exit with status 1 (error)
fi

# Call the function to analyze the nginx access log
show_nginx_access_log_anylysis "$LOG_FILE"