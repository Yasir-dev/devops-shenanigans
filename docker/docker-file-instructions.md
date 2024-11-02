## Docker file

A Dockerfile is a text file that contains a series of commands or instructions executed in the order they are written, with the execution taking place on a base image. When the Dockerfile is built, the successive actions create a new image derived from the base parent image.

### Docker file Instructions

`FROM`

Sets the base image (mandatory in every Dockerfile).

Usage: `FROM <image>:<tag>`

Example:
```
# This sets the base image for the Dockerfile to the latest Ubuntu image.
FROM ubuntu:latest
```

`RUN`

Executes a command during the image build process (e.g., installing software).

Usage: `RUN <command>`
Example:
```
# This command installs Python3 and pip during the image build process.
RUN apt-get update && apt-get install -y python3 python3-pip
```

`COPY`

The COPY instruction is used to copy files or directories from the host machine into the filesystem of the container at the specified destination path.

Usage: COPY <src> <dest>
Example:
```
COPY index.html /usr/share/nginx/html/
```

`ADD`

COPY and ADD are Dockerfile instructions for copying files into a Docker image. COPY only allows local files or directories, while ADD also supports URLs and can auto-extract tar files.

Usage: `ADD <src> <dest>` (also handles URLs and auto-decompression)
Example:
```
ADD https://example.com/my_file.tar.gz /app/
```

`ARG`

The ARG instruction in a Dockerfile defines a variable that can be set when building the image. It has a default value, which can be changed using the --build-arg <parameter name>=<value> option in the docker build command.

Usage: `ARG <name> <default value>`
Example:
```
ARG WELCOME_MESSAGE=hello
```

`CMD`

The CMD instruction in a Dockerfile specifies the default command that will be executed when a container is run from the image. It can be overridden by providing a different command when starting the container.

Usage: `CMD ["executable","param1","param2"]``
Example:
```
CMD ["python", "app.py"]
```

`ENTRYPOINT`

The ENTRYPOINT instruction allows your container to run as a program. You can set it up in two ways:

1. Exec Form:
   The Exec Form of the ENTRYPOINT instruction allows you to specify the command and its parameters as a JSON array. This form is preferred because it does not invoke a shell, which means that the command is executed directly. This results in better handling of signals and allows for more predictable behavior. Additionally, it ensures that the command runs as the main process of the container, which is important for proper signal handling and process management.

   Example:
   ```
   ENTRYPOINT ["executable", "param1", "param2"]
   ```
   In this example, `executable` is the command that will be run, and `param1` and `param2` are the arguments passed to that command. This form is particularly useful when you want to ensure that the command is executed exactly as specified, without any shell interpretation.

   ENTRYPOINT ["executable", "param1", "param2"]

2. Shell Form:
   The Shell Form of the ENTRYPOINT instruction allows you to specify the command as a simple string. This form invokes a shell to run the command, which means that it can be useful for commands that require shell features like pipes or redirection. However, it may lead to issues with signal handling and process management since the command runs in a subshell.

   Example:
   ```
   ENTRYPOINT executable param1 param2
   ```
   In this example, `executable` is the command that will be run, and `param1` and `param2` are the arguments passed to that command. This form is less preferred compared to the Exec Form due to the potential for unexpected behavior in signal handling.


Passing arguments to a container with an existing ENTRYPOINT appends them. To override the ENTRYPOINT, use the --entrypoint flag when running the container.

`ENV`

The ENV instruction in a Dockerfile sets environment variables within the container. These variables can be accessed by applications running inside the container and can influence their behavior. The values set by ENV persist in the container's environment and can be overridden at runtime.

Usage: `ENV <key>=<value>`
Example:
```
ENV MY_VARIABLE "hello"
```

`EXPOSE`

The EXPOSE instruction in a Dockerfile informs Docker that the container listens on the specified network ports at runtime. It serves as documentation between the person who builds the image and the person who runs the container, indicating which ports are intended to be published.

Usage: `EXPOSE <port>[/<protocol>]`
Example:
```
EXPOSE 5000
```

`HEALTHCHECK`

The HEALTHCHECK instruction in a Dockerfile allows you to specify a command that Docker will run to check the health of a running container. If the command fails, Docker can mark the container as unhealthy, which can trigger restart policies or alerts.

Usage: `HEALTHCHECK [OPTIONS] CMD <command>`
Example:
```
HEALTHCHECK --interval=5m --timeout=3s \
  --start-period=30s --retries=3 CMD curl -f http://localhost:8080/healthz || exit 1
```

The parameters specify:
- interval: how often to run the check (every 5 minutes)
- timeout: how long to wait for the check to complete (3 seconds)
- start-period: initial delay before starting health checks (30 seconds)
- retries: number of consecutive failures needed to consider the container unhealthy (3)

`LABEL`

Add labels to your image for organization, licensing, automation, or other purposes. Use the LABEL instruction followed by key-value pairs. Docker supports custom metadata through labels.

Usage: `LABEL <key>=<value>`
```
LABEL version="1.0"
```

`MAINTAINER`

The MAINTAINER instruction sets the Author field of the generated images (The LABEL instruction is a much more flexible version of this and you should use it instead)

Usage: MAINTAINER <name>
```
MAINTAINER John Doe <johndoe@example.com>
```

`ONBUILD`

The ONBUILD instruction adds a trigger to the image that will be executed when the image is used as a base for another build. This is useful for defining actions that should occur in derived images.

Usage: `ONBUILD <INSTRUCTION>`
Example:
```
ONBUILD RUN echo "This image will run this command when used as a base for another image."
```

`SHELL`

The SHELL instruction allows you to specify the command shell that will be used for the RUN, CMD, and ENTRYPOINT instructions in the Dockerfile. This is useful when you want to use a different shell than the default `/bin/sh -c`.

Usage: `SHELL ["executable", "parameters"]`
Example:
```
SHELL ["/bin/bash", "-c"]
```

`WORKDIR`

The WORKDIR directive sets the working directory for subsequent Dockerfile instructions. It does not create a new image layer but adds metadata. If the specified directory doesn't exist, it will be created. Multiple WORKDIR instructions can be used, and relative paths are based on the last WORKDIR.

Usage: `WORKDIR /path/to/workdir`
Example:
```
WORKDIR /app
```

`VOLUME`

Creates a mount point and stores data in it, preserving data across container restarts.

Usage: `VOLUME ["/path/to/volume"]`
Example:
```
VOLUME /myvol
```

`USER`

The USER directive, like WORKDIR, modifies the environment state and influences subsequent layers. While WORKDIR sets the working directory, USER specifies the user identity for commands such as RUN, CMD, and ENTRYPOINT.
Similar to WORKDIR, USER facilitates switching to the designated user, which must be pre-defined; otherwise, the switch will fail.

Usage: `USER <user>[:<group>]`
Example:
```
USER patrick
```

`STOPSIGNAL`


The STOPSIGNAL instruction specifies the signal that will be sent to the container to request its termination. This signal can be represented either as a signal name in the format SIG<NAME> (e.g., SIGKILL) or as an unsigned integer corresponding to a position in the kernel's syscall table (e.g., 9). If not explicitly defined, the default signal used is SIGTERM.

Usage: `STOPSIGNAL signal`
Example:
```
STOPSIGNAL SIGTERM
```