package Math::ProductRatings::Bayesian;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(starRatingBayesianScore);
our %EXPORT_TAGS = (
                    'all' => [qw(starRatingBayesianScore)]
                   );

use Math::ProductRatings::Common qw(pNormalDist);

use List::Util qw(sum);

# https://medium.com/tech-that-works/wilson-lower-bound-score-and-bayesian-approximation-for-k-star-scale-rating-to-rate-products-c67ec6e30060
sub starRatingBayesianScore {
    my $confidence = 0.95;
    my @n = @_;
    my $K = scalar @n;
    my $z = pNormalDist(1 - (1 - $confidence) / 2);
    my $N = sum(@n);
    if ($N == 0) {
        return 0;
    }
    my $firstPart = 0;
    my $secondPart = 0;
    for (my $k = 0; $k < scalar(@n); $k += 1) {
        my $nk = $n[$k];
        $firstPart  += ($k + 1) *            ($nk + 1) / ($N + $K);
        $secondPart += ($k + 1) * ($k + 1) * ($nk + 1) / ($N + $K);
    }
    my $score = $firstPart - $z * sqrt(($secondPart - $firstPart * $firstPart) / ($N + $K + 1));
    return $score;
}

1;
