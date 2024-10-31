


## $ dollar sign

- `$0`: The name of the script itself (or the command that started the script).
- `$#`: The total number of arguments passed to the script.
- `$@`: All arguments passed to the script, as separate quoted strings (useful for loops).
- `$*`: All arguments passed to the script as a single unquoted string.
- `$?`: The exit status of the last command run. 0 means success, and any other value indicates an error.
- `$$`: The process ID (PID) of the current shell or script. Useful for creating unique temporary file names.
- `$!`: The PID of the most recently executed background command.
- `$_`: The last argument of the previous command (also works in interactive shells).
