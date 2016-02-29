#!/bin/sh

cd /usr/lib/rmp-prerecord-schedule
exec scl enable ruby193 'bundle exec ruby app.rb -p 9292 -e production'
