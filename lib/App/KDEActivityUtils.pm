package App::KDEActivityUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
use IPC::System::Options 'system', -log=>1;

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(
                       set_current_kde_activity
                       list_kde_activities
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to KDE Activities',
};

$SPEC{list_kde_activities} = {
    v => 1.1,
    summary => "List all known KDE activities",
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    deps => {
        prog => 'kactivities-cli',
    },
};
sub list_kde_activities {
    my %args = @_;

    system({capture_stdout => \my $stdout}, "kactivities-cli", "--list-activities");
    return [500, "Can't run kactivities-cli"] if $?;
    my @rows;

    for my $line (split /^/m, $stdout) {
        my ($status, $guid, $name, $icon) = $line =~ /^\[(.+?)\] ([0-9a-f-]+) (.+?) \((.*?)\)/;
        push @rows, {
            is_running => ($status =~ /RUNNING|CURRENT/),
            is_current => ($status =~ /CURRENT/),
            guid => $guid,
            name => $name,
            icon => $icon,
        };
    }

    unless ($args{detail}) {
        @rows = map { $_->{name} } @rows;
    }

    return [200, "OK", \@rows];
}

my $_comp_kde_activity_name = sub {
    require Complete::Util;

    my %args = @_;
    my $word = $args{word};

    my $res = list_kde_activities(detail => 1);
    return undef unless $res->[0] == 200;

    Complete::Util::complete_array_elem(word => $word, array=>[ map { $_->{name} } @{$res->[2] }]);
};

$SPEC{set_current_kde_activity} = {
    v => 1.1,
    summary => 'Set KDE current activity',
    args => {
        name => {
            schema => 'str*',
            req => 1,
            pos => 0,
            completion => $_comp_kde_activity_name,
        },
        # TODO: guid as alternative way to specify the activity
    },
    deps => {
        prog => 'qdbus',
    },
};
sub set_current_kde_activity {
    my %args = @_;
    defined(my $name = $args{name}) or return [400, "Please specify name"];

    my $res = list_kde_activities(detail => 1);
    return $res unless $res->[0] == 200;

    my $guid;
    for my $row (@{ $res->[2] }) {
        do { $guid = $row->{guid}; last } if $row->{name} eq $name;
    }
    return [404, "Cannot find activity named '$name'"] unless $guid;

    system("qdbus", "org.kde.ActivityManager", "/ActivityManager/Activities", "SetCurrentActivity", $guid);
    return [500, "Can't run qdbus"] if $?;
    [200];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to KDE activities as
alternatives/wrappers to L<kactivities-cli>:

#INSERT_EXECS_LIST


=head1 SEE ALSO
