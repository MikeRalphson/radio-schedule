#!/bin/sh

cd /usr/lib/rmp-prerecord-schedule
exec scl enable ruby193 'ruby app.rb -p 9292'
