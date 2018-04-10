#!/bin/sh


docker build --tag quack .
docker run --rm quack