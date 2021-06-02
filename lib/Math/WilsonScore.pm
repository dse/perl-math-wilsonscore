package Math::WilsonScore;
use warnings;
use strict;
use feature 'state';

use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(ciLowerBound
                    pNormalDist
                    ratingLowerBound
                    starRatingLowerBound);
our %EXPORT_TAGS = (
                    'all' => [qw(ciLowerBound
                                 pNormalDist
                                 ratingLowerBound
                                 starRatingLowerBound)]
                   );

=head1 NAME

Math::WilsonScore - Wilson score confidence interval ratings function

=head1 SYNOPSIS

    use Math::WilsonScore qw(starRatingLowerBound ratingLowerBound
                             ciLowerBound, pNormalDist);

    my $stars = starRatingLowerBound(5, 4, 9, 17, 64);
    # returns about 3.98, for 3.98 out of 5 stars.
    # given:
    #     5 one-star reviews
    #     4 two-star reviews
    #     9 three-star reviews
    #     17 four-star reviews
    #     64 five-star reviews2

    my $rating = ratingLowerBound(5, 14, 9, 17, 64);
    # returns about 0.745, or 3.98 as returned above and
    # converted from the range [1, 5] to [0, 1].

    my $lower = ciLowerBound(39, 45);
    my $lower = ciLowerBound(39, 45, 0.99);     # for 99% confidence
    # 39 positive reviews out of 45 total

    my $z = pNormalDist(1 - (1 - 0.95) / 2);

=cut

sub starRatingLowerBound {
    my @ratings = @_;
    if (scalar(@ratings) < 2) {
        return 0;
    }
    my ($result, $phat) = ratingLowerBound(@ratings);
    $result = 1 + $result * (scalar(@ratings) - 1);
    $phat   = 1 + $phat   * (scalar(@ratings) - 1);
    if (wantarray) {
        return ($result, $phat);
    }
    return $result;
}

# given:
#     @ratings - the number of ratings giving each score from 0 to 1,
#                where the first member is the number of ratings at score 0,
#                and the last member is the number of ratings at score 1.
#                e.g., (14, 8, 3, 5, 28)
#                represents 14 one-star (score of 0.0) ratings,
#                           8 two-star (0.25) ratings,
#                           3 three-star (0.5) ratings,
#                           5 four-star (0.75) ratings, and
#                           28 five-star (1.0) ratings
# For this forumula, we take the average of the ratings, and compute
# a lower bound in the range [0, 1] from it.
#
# returns, in scalar context:
#     $result - the lower bound at 95% confidence interval, in [0, 1]
#
# returns, in array context:
#     ($result, $phat)
#     $result - same as above
#     $phat - the weighted average of the scores, also in [0, 1]
sub ratingLowerBound {
    my @ratings = @_;
    if (scalar(@ratings) < 2) {
        return 0;
    }
    my $n = 0;                  # number of reviews
    my $phat = 0;		# average rating (scale of 0 to 1)
    foreach my $i (0 .. (scalar(@ratings) - 1)) {
        my $weight = $i / (scalar(@ratings) - 1);
        my $p = $ratings[$i] * $weight;
        $phat += $ratings[$i] * $weight;
        $n += $ratings[$i];
    }
    $phat /= $n;
    my $confidence = 0.95;
    my $z = pNormalDist(1 - (1 - $confidence) / 2);
    my $result = (($phat + $z * $z / (2 * $n) -
                   $z * sqrt(($phat * (1 - $phat) + $z * $z / (4 * $n)) / $n))
                  / (1 + $z * $z / $n));
    if (wantarray) {
        return ($result, $phat);
    }
    return $result;
}

# https://www.evanmiller.org/how-not-to-sort-by-average-rating.html
#
# This function is for simple positive/negative reviews.
# Negative reviews are considered 0; positive considered 1.
#
# given:
#     $pos        - number of positive reviews
#     $n          - total number of reviews
#     $confidence - chance we want that the lower bound returned is correct
#                   e.g., 0.95 for a 95% chance
#                   default is 0.95
#
# returns:
#     the lower bound of the average score in the range [0, 1]
#     given a 95% confidence interval.
sub ciLowerBound {
    state %pNormalDist;
    my ($pos, $n, $confidence) = @_;
    $confidence //= 0.95;

    if ($n == 0) {
        return 0;
    }
    my $z = ($pNormalDist{$confidence} //=
             pNormalDist(1 - (1 - $confidence) / 2));
    my $phat = 1.0 * $pos / $n;
    return ($phat + $z * $z / (2 * $n) -
            $z * sqrt(($phat * (1 - $phat) + $z * $z / (4 * $n)) / $n)) /
              (1 + $z * $z / $n);
}

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
