#!/bin/sh

cd /usr/lib/radio-schedule
exec scl enable ruby193 'bundle exec ruby app.rb -p 9292 -e production'
