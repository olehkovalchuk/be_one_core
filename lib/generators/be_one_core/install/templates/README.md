
docker-compose up --build

docker-compose exec --user "$(id -u):$(id -g)" website rails db:reset
#If you’re on OSX or Windows, do not include the --user flag

docker-compose exec --user "$(id -u):$(id -g)" website rails db:migrate
#If you’re on OSX or Windows, do not include the --user flag

rails generate be_one_core:install
rails generate be_one_core:operation MODEL_NAME NAMESPACE