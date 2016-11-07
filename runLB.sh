#!/bin/bash

docker run -dP \
    -p 8080:8080 \
    -p 6379:6379 \
    --name lb \
    dynamiclb
