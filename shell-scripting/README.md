


## $ dollar sign

- `$0`: The name of the script itself (or the command that started the script).
  - **Example**: If you run `./myscript.sh`, then `$0` will be `./myscript.sh`.
- `$#`: The total number of arguments passed to the script.
  - **Example**: If you run `./myscript.sh arg1 arg2`, then `$#` will be `2`.
- `$@`: All arguments passed to the script, as separate quoted strings (useful for loops).
  - **Example**: If you run `./script.sh arg1 "arg 2" arg3`, then `$@` will expand to `arg1`, `arg 2`, and `arg3` in a loop.
  
- `$*`: All arguments passed to the script as a single unquoted string.
  - **Example**: If you run `./script.sh arg1 "arg 2" arg3`, then `$*` will expand to `arg1 arg 2 arg3` as a single string.

- `$?`: The exit status of the last command run. 0 means success, and any other value indicates an error.
  - **Example**: After running `ls`, you can check the exit status with `echo $?`. If the command was successful, it will print `0`.

- `$$`: The process ID (PID) of the current shell or script. Useful for creating unique temporary file names.
  - **Example**: If you run a script and want to create a temporary file, you can use `tempfile="/tmp/mytempfile_$$.tmp"` to ensure the filename is unique to that script instance.

- `$!`: The PID of the most recently executed background command.
  - **Example**: If you run `sleep 10 &`, you can get its PID with `echo $!`, which will print the PID of the `sleep` command.

- `$_`: The last argument of the previous command (also works in interactive shells).
  - **Example**: If you run `echo Hello World`, then `echo $_` will output `World`, which is the last argument of the previous command.
