bundle
RAILS_ENV=production bin/delayed_job stop
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bin/delayed_job start