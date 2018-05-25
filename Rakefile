require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec
task "db:prepare" do
  require "dotenv"
  Dotenv.load(".env.development")
  sh "createdb #{env_database_name}" do
    # Ignore errors
  end

  Dotenv.overload(".env.test")
  sh "createdb #{env_database_name}" do
    # Ignore errors
  end
end

task "db:drop" do
  require "dotenv"
  Dotenv.load(".env.development")
  sh "dropdb #{env_database_name}" do
    # Ignore errors
  end

  Dotenv.overload(".env.test")
  sh "dropdb #{env_database_name}" do
    # Ignore errors
  end
end

def env_database_name
  require "uri"
  ENV.fetch("DATABASE_URL").split("/").last
end
