begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/extensiontask'
  require 'rake/javaextensiontask'

  # Hack to avoid "allocator undefined for Proc" issue when unpacking Gems:
  # gemspec provided by Jeweler uses Rake::FileList for files, test_files and
  # extra_rdoc_files, and procs cannot be marshalled.
  def gemspec
    @clean_gemspec ||= eval("#{Rake.application.jeweler.gemspec.to_ruby}") # $SAFE = 3\n
  end

  Rake::ExtensionTask.new('do_postgres', gemspec) do |ext|

    postgres_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'pgsql'))

    ext.lib_dir = "lib/#{gemspec.name}"

    ext.cross_compiling do |gemspec|
      gemspec.post_install_message = "You're installing the binary version of #{gemspec.name}. It was built using PostgreSQL version #{BINARY_VERSION}. Is recommended to use the exact same version to avoid potential issues."
    end

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
      ext.config_options << "--with-pgsql-server-include=#{postgres_lib}/include/server"
      ext.config_options << "--with-pgsql-client-include=#{postgres_lib}/include"
      ext.config_options << "--with-pgsql-win32-include=#{postgres_lib}/include/server/port/win32"
      ext.config_options << "--with-pgsql-client-lib=#{postgres_lib}/lib"
    else
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
      ext.cross_config_options << "--with-pgsql-server-include=#{postgres_lib}/include/server"
      ext.cross_config_options << "--with-pgsql-client-include=#{postgres_lib}/include"
      ext.cross_config_options << "--with-pgsql-win32-include=#{postgres_lib}/include/server/port/win32"
      ext.cross_config_options << "--with-pgsql-client-lib=#{postgres_lib}/lib"

      ext.cross_compiling do |gemspec|
        gemspec.post_install_message = <<-POST_INSTALL_MESSAGE

  ======================================================================================================

    You've installed the binary version of #{gemspec.name}.
    It was built using PostgreSQL version #{BINARY_VERSION}.
    It's recommended to use the exact same version to avoid potential issues.

    At the time of building this gem, the necessary DLL files where available
    in the following download:

    http://wwwmaster.postgresql.org/redir/107/h/binary/v#{BINARY_VERSION}/win32/postgresql-#{BINARY_VERSION}-1-binaries-no-installer.zip

    You can put the following files available in this package in your Ruby bin
    directory, for example C:\\Ruby\\bin

    - lib\\libpq.dll
    - bin\\ssleay32.dll
    - bin\\libeay32.dll
    - bin\\libintl-8.dll
    - bin\\libiconv-2.dll
    - bin\\krb5_32.dll
    - bin\\comerr32.dll
    - bin\\k5sprt32.dll
    - bin\\gssapi32.dll

  ======================================================================================================

    POST_INSTALL_MESSAGE
      end

    end

  end

  Rake::JavaExtensionTask.new('do_postgres', gemspec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.lib_dir   = "lib/#{gemspec.name}"
	ext.debug     = ENV.has_key?('DO_JAVA_DEBUG') && ENV['DO_JAVA_DEBUG']
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem|
      gem.add_dependency 'jdbc-postgres', '>=8.2'
      gem.add_dependency 'do_jdbc',       '0.10.1'
      gem.post_install_message = <<EOF
==========================================================================

  DataObjects PostgreSQL Driver:
    You've installed the binary extension for JRuby (Java platform)

==========================================================================
EOF
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end