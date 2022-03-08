#!/usr/bin/env bash
docker run -it --rm -p 1234:1234 launcher --port 1234 --redirect http://10.70.88.146:9999
