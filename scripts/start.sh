#!/bin/sh

cd /usr/lib/radio-schedule
exec scl enable ruby193 'bundle exec rackup -p 9292 -E production'
