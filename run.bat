set RAILS_ENV=production
ruby bin/delayed_job restart
bundle exec rails s -e production