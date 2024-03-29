package Math::ProductRatings::WilsonScore;
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

use Math::ProductRatings::Common qw(pNormalDist);

=head1 NAME

Math::ProductRatings::WilsonScore - Wilson score confidence interval ratings function

=head1 SYNOPSIS

    use Math::ProductRatings::WilsonScore qw(starRatingLowerBound
                                             ratingLowerBound
                                             ciLowerBound
                                             pNormalDist);
    # (or just whichever functions you need)

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

1;
