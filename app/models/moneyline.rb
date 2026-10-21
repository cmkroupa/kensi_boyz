# Fair odds for a bet between the two sides of a game, with no house cut. The
# underdog puts up the bet amount and the favourite risks enough to make it
# even in expectation, so each side wins exactly what the other risks.
#
# A $5 bet on a 58% favourite: the underdog risks $5 to win $7, the favourite
# risks $7 to win $5.
class Moneyline
  STEP_CENTS = 25
  MAX_FAVORITE_CHANCE = 0.9

  Terms = Struct.new(:favorite_side, :favorite_stake_cents, :underdog_stake_cents)

  def self.terms(chance_a:, underdog_stake_cents:)
    favorite_side = chance_a >= 0.5 ? "a" : "b"
    chance = [ [ chance_a, 1 - chance_a ].max, MAX_FAVORITE_CHANCE ].min
    stake = (underdog_stake_cents * chance / (1 - chance) / STEP_CENTS).round * STEP_CENTS

    Terms.new(favorite_side, stake, underdog_stake_cents)
  end
end
