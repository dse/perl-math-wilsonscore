package Math::WilsonScore;

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

sub ciLowerBound {
    my ($pos, $n, $confidence) = @_;
    $confidence //= 0.95;

    if ($n == 0) {
        return 0;
    }
    my $z = pNormalDist(1 - (1 - $confidence) / 2);
    my $phat = 1.0 * $pos / $n;
    return ($phat + $z * $z / (2 * $n) -
            $z * sqrt(($phat * (1 - $phat) + $z * $z / (4 * $n)) / $n)) /
              (1 + $z * $z / $n);
}

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
