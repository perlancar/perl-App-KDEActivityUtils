package App::KDEActivityUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to KDE Activities',
};

1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to KDE activities as
alternatives/wrappers to L<kactivities-cli>:

#INSERT_EXECS_LIST


=head1 SEE ALSO

L<Desktop::KDEActivity::Util> which provides the backend for some of the
utilities.
