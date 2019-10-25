#!/bin/bash
set -eux
cd phuntainer
docker build -t phuntainer:latest $@ .
