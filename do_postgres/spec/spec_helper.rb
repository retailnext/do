$TESTING=true
JRUBY = RUBY_PLATFORM =~ /java/

require 'rubygems'

gem 'rspec', '>1.1.12'
require 'spec'

require 'date'
require 'ostruct'
require 'pathname'
require 'fileutils'

dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
# put data_objects from repository in the load path
# DO NOT USE installed gem of data_objects!
do_lib_path = File.expand_path("#{dir}/../../data_objects/lib")
$LOAD_PATH.unshift do_lib_path unless $LOAD_PATH.include?(do_lib_path)

if JRUBY
  jdbc_lib_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'do_jdbc', 'lib'))
  $LOAD_PATH.unshift jdbc_lib_path unless $LOAD_PATH.include?(jdbc_lib_path)
  require 'do_jdbc'
end

require 'data_objects'

DATAOBJECTS_SPEC_ROOT = Pathname(__FILE__).dirname.parent.parent + 'data_objects' + 'spec'
Pathname.glob((DATAOBJECTS_SPEC_ROOT + 'lib/**/*.rb').to_s).each { |f| require f }
require 'do_postgres'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::Postgres.logger = DataObjects::Logger.new(log_path, :debug)

at_exit { DataObjects.logger.flush }

Spec::Runner.configure do |config|
  config.include(DataObjects::Spec::PendingHelpers)
end

CONFIG = OpenStruct.new
CONFIG.scheme    = 'postgres'
CONFIG.user      = ENV['DO_POSTGRES_USER'] || 'postgres'
CONFIG.pass      = ENV['DO_POSTGRES_PASS'] || ''
CONFIG.user_info = unless CONFIG.pass.empty?
  "#{CONFIG.user}:#{CONFIG.pass}@"
else
  "#{CONFIG.user}@"
end
CONFIG.host      = ENV['DO_POSTGRES_HOST'] || 'localhost'
CONFIG.port      = ENV['DO_POSTGRES_PORT'] || '5432'
CONFIG.database  = ENV['DO_POSTGRES_DATABASE'] || '/do_test'

CONFIG.uri = ENV["DO_POSTGRES_SPEC_URI"] ||"#{CONFIG.scheme}://#{CONFIG.user_info}#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}"
CONFIG.sleep = "SELECT pg_sleep(1)"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS "invoices"
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS "users"
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS "widgets"
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "users" (
        "id" SERIAL,
        "name" VARCHAR(200) default 'Billy' NULL,
        "fired_at" timestamp,
        PRIMARY KEY  ("id")
      );
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "invoices" (
        "id" SERIAL,
        "invoice_number" varchar(50) NOT NULL,
        PRIMARY KEY  ("id")
      );
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "widgets" (
        "id" SERIAL,
        "code" char(8) default 'A14' NULL,
        "name" varchar(200) default 'Super Widget' NULL,
        "shelf_location" text NULL,
        "description" text NULL,
        "image_data" bytea NULL,
        "ad_description" text NULL,
        "ad_image" bytea NULL,
        "whitepaper_text" text NULL,
        "cad_drawing" bytea NULL,
        "flags" boolean default false,
        "number_in_stock" smallint default 500,
        "number_sold" integer default 0,
        "super_number" bigint default 9223372036854775807,
        "weight" float default 1.23,
        "cost1" double precision default 10.23,
        "cost2" decimal(8,2) default 50.23,
        "release_date" date default '2008-02-14',
        "release_datetime" timestamp default '2008-02-14 00:31:12',
        "release_timestamp" timestamp with time zone default '2008-02-14 00:31:31',
        PRIMARY KEY  ("id")
      );
    EOF

    1.upto(16) do |n|
      conn.create_command(<<-EOF).execute_non_query(::Extlib::ByteArray.new("CAD \001 \000 DRAWING"))
        insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number, weight) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'String', ?, 1234, 13.4)
      EOF
    end

    conn.create_command(<<-EOF).execute_non_query
      update widgets set flags = true where id = 2
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set ad_description = NULL where id = 3
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set flags = NULL where id = 4
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set cost1 = NULL where id = 5
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set cost2 = NULL where id = 6
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_date = NULL where id = 7
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_datetime = NULL where id = 8
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_timestamp = NULL where id = 9
    EOF

    conn.close

  end

end
