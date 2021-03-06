#!/data/apps/bin/perl

use strict;
use Config::JSON;
use Template;
use Getopt::Long;
use File::Path qw(make_path);
use YAML;

my $project = '';
GetOptions("app=s" => \$project);

die "usage: $0 --app=AppName" unless $project;

# make folder
make_path('/data/'.$project.'/lib/'.$project.'/DB/Result');
make_path('/data/'.$project.'/etc');
make_path('/data/'.$project.'/bin/setup');
make_path('/data/'.$project.'/var');
make_path('/data/'.$project.'/dbicdh/_common/deploy/1');
make_path('/data/'.$project.'/views');
make_path('/data/'.$project.'/views/admin');
make_path('/data/'.$project.'/views/account');

# set up default configs
my $config = Config::JSON->new('/data/Wing/var/init/etc/wing.conf');
my $new_config = Config::JSON->create('/data/'.$project.'/etc/wing.conf');
$new_config->config($config->config);
$new_config->set('mkits', '/data/'.$project.'/var/mkits/');
$new_config->set('app_namespace', $project);
$new_config->set("log4perl_config", "/data/".$project."/etc/log4perl.conf",);
$new_config->write;

# set up dancer config
my $dancer_config = YAML::LoadFile('/data/Wing/var/init/config.yml');
$dancer_config->{appname} = $project;
$dancer_config->{log4perl}{config_file} = '/data/'.$project.'/etc/log4perl.conf';
YAML::DumpFile('/data/'.$project.'/config.yml', $dancer_config);

# set up needed files
my $tt = Template->new({ABSOLUTE => 1});
my $vars = {project => $project, wing_home => $ENV{WING_HOME}, };
template($tt,'lib/DB.pm', $vars, 'lib/'.$project.'/DB.pm') || die $tt->error();
template($tt,'lib/DB/Result/APIKey.pm', $vars, 'lib/'.$project.'/DB/Result/APIKey.pm');
template($tt,'lib/DB/Result/APIKeyPermission.pm', $vars, 'lib/'.$project.'/DB/Result/APIKeyPermission.pm');
template($tt,'lib/DB/Result/User.pm', $vars, 'lib/'.$project.'/DB/Result/User.pm');
template($tt,'etc/log4perl.conf', $vars);
template($tt,'etc/mime.types', $vars);
template($tt,'etc/nginx.conf', $vars);
template($tt,'bin/start_web.sh', $vars);
template($tt,'bin/start_rest.sh', $vars);
template($tt,'bin/restart_starman.sh', $vars);
template($tt,'bin/stop_starman.sh', $vars);
template($tt,'bin/web.psgi', $vars);
template($tt,'bin/rest.psgi', $vars);
template($tt,'bin/setup/install_perl_modules.sh', $vars);
template($tt,'dbicdh/_common/deploy/1/install_admin.pl', $vars);

# set up views, using alternate template tags since they're templates
my $t_alt = Template->new({ABSOLUTE => 1, START_TAG => quotemeta('[%['), END_TAG => quotemeta(']%]')});
template($t_alt,'views/footer_include.tt', $vars);
template($t_alt,'views/header_include.tt', $vars);
template($t_alt,'views/error.tt', $vars);
template($t_alt,'views/status_include.tt', $vars);
template($t_alt,'views/admin/users.tt', $vars);
template($t_alt,'views/admin/user.tt', $vars);
template($t_alt,'views/admin/footer_include.tt', $vars);
template($t_alt,'views/admin/header_include.tt', $vars);
template($t_alt,'views/account/apikey_form_include.tt', $vars);
template($t_alt,'views/account/apikeys.tt', $vars);
template($t_alt,'views/account/apikey.tt', $vars);
template($t_alt,'views/account/authenticate_include.tt', $vars);
template($t_alt,'views/account/authorize.tt', $vars);
template($t_alt,'views/account/footer_include.tt', $vars);
template($t_alt,'views/account/header_include.tt', $vars);
template($t_alt,'views/account/index.tt', $vars);
template($t_alt,'views/account/login_include.tt', $vars);
template($t_alt,'views/account/login.tt', $vars);
template($t_alt,'views/account/profile.tt', $vars);
template($t_alt,'views/account/reset-password-code.tt', $vars);
template($t_alt,'views/account/reset-password.tt', $vars);
template($t_alt,'views/account/ssosuccess.tt', $vars);

# set privs
system('cd /data/'.$project.'/bin;chmod 755 *');

sub template {
  my ($tt, $from, $vars, $to) = @_;
  $to ||= $from;
  $tt->process('/data/Wing/var/init/'.$from, $vars, '/data/'.$project.'/'.$to) || die $tt->error();
}
