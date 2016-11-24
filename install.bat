set RAILS_ENV=production
bundle
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed