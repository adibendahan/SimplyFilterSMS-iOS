#!/bin/bash

docker run --rm --volume "$(pwd)/Report Message Lambda/:/src" --workdir "/src/" swift56 \
    swift build --product "Report Message Lambda" -c release -Xswiftc -static-stdlib
