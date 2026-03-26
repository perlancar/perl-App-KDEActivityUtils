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
            is_running => ($status =~ /RUNNING|CURRENT/ ? 1:0),
            is_current => ($status =~ /CURRENT/ ? 1:0),
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
    return unless $res->[0] == 200;

    Complete::Util::complete_array_elem(word => $word, array=>[ map { $_->{name} } @{$res->[2] }]);
};

sub _push_activity_stack {
    require IPC::ShareLite;
    require List::Util::Uniq;

    my $name = shift;

    my $share = IPC::ShareLite->new(
        -key     => 6001,
        -create  => 'yes',
        -destroy => 'no',
    );
    my @stack = split /\|/, ($share->fetch // '');
    unshift @stack, $name;
    @stack = List::Util::Uniq::uniq_adj(@stack);
    $share->store(join "|", @stack);
}

sub _get_activity_stack {
    my $name = shift;

    require IPC::ShareLite;
    my $share = IPC::ShareLite->new(
        -key     => 6001,
        -create  => 'yes',
        -destroy => 'no',
    );
    split /\|/, ($share->fetch // '');
}

$SPEC{set_current_kde_activity} = {
    v => 1.1,
    summary => 'Set KDE current activity',
    description => <<'MARKDOWN',

Features:
- Specifying activity by name (kactivities-cli wants GUID)
- Tab completion

MARKDOWN
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

    system({capture_stdout => \my $dummy}, "qdbus", "org.kde.ActivityManager", "/ActivityManager/Activities", "SetCurrentActivity", $guid);
    return [500, "Can't run qdbus"] if $?;

    _push_activity_stack($name);
    [200];
}

$SPEC{return_to_previously_set_kde_activity} = {
    v => 1.1,
    summary => 'Return to previously set KDE activity',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        num => {
            schema => 'uint*',
            default => 1,
            pos => 0,
        },
    },
};
sub return_to_previously_set_kde_activity {
    my %args = @_;
    my $num = $args{num} // 1;

    my @stack = _get_activity_stack();
    return [304] if $num >= @stack;

    set_current_kde_activity(name => $stack[$num]);
}

$SPEC{list_kde_activities_stack} = {
    v => 1.1,
    summary => 'List KDE activities in the order of set()',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
    },
};
sub list_kde_activities_stack {
    [200, "OK", [ _get_activity_stack()]];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to KDE activities as
alternatives/wrappers to L<kactivities-cli>:

#INSERT_EXECS_LIST


=head1 SEE ALSO
