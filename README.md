# Cassandra on Alpine Linux

This Dockerfile provides everything you need to run Cassandra in Docker out of the box. It is based on the official [Cassandra](https://github.com/docker-library/cassandra/) Docker image.

## Getting Started

To download this image from the public docker hub:

```sh
docker pull albertc/alpine-cassandra
```

As a convenience, you can use the build script to build the `alpine-cassandra` image locally.

```sh
# Build
$ ./bin/build.sh <tagging_version>

# Example
$ ./bin/build.sh 3.11.2
```

## Usage

To run the image:

```
$ docker run -d -p 9042:9042 albertc/alpine-cassandra:<cassandra_version>
```

## References
- [Official Cassandra](https://hub.docker.com/_/cassandra/) Docker repository
- Nebo15's alpine-cassandra [Dockerfile](https://github.com/Nebo15/alpine-cassandra/blob/master/Dockerfile)
