package Math::ProductRatings::Common;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(pNormalDist);
our %EXPORT_TAGS = (
                    'all' => [qw(pNormalDist)]
                   );

# https://stackoverflow.com/questions/6116770/whats-the-equivalent-of-rubys-pNormalDist-statistics-function-in-haskell
sub pNormalDist {
    my ($qn) = @_;
    my @b = (1.570796288, 0.03706987906, -0.8364353589e-3,
             -0.2250947176e-3, 0.6841218299e-5, 0.5824238515e-5,
             -0.104527497e-5, 0.8360937017e-7, -0.3231081277e-8,
             0.3657763036e-10, 0.6936233982e-12);
    if ($qn < 0 || $qn > 1) {
        die("pNormalDist: value supplied must be in the range [0, 1].\n");
    }
    if ($qn == 0.5) {
        return 0;
    }
    my $w1 = $qn;
    if ($qn > 0.5) {
        $w1 = 1.0 - $w1;
    }
    my $w3 = -log(4.0 * $w1 * (1.0 - $w1));
    $w1 = $b[0];
    for (my $i = 1; $i <= 10; $i += 1) {
        $w1 = $w1 + $b[$i] * $w3 ** $i;
    }
    if ($qn > 0.5) {
        return sqrt($w1 * $w3);
    }
    return -sqrt($w1 * $w3);
}

1;
