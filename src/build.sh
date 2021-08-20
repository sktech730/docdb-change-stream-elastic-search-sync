#!/usr/bin/env bash

# Change to the script directory
echo "$(dirname "$0")"
cd "$(dirname "$0")"
rm -r pymongo_elasticsearch_lambda_layer/python/*
pip install -r requirements.txt -t pymongo_elasticsearch_lambda_layer/python/