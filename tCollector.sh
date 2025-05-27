#!/bin/bash

echo "Starting tCollector"
sleep 10
python3 tcollector/tcollector.py -H localhost -p 4242 -c /opt/home_collectors/ -v
