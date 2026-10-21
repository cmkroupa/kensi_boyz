require "test_helper"

class FormulaVersionTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn = %w[ Cam Quinn ].map { |name| Player.create!(name: name) }
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 3,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
  end

  test "the version is a short fingerprint of the formula code" do
    assert_match(/\A\h{8}\z/, FormulaVersion.current)
    assert_equal FormulaVersion.current, FormulaVersion.current
  end

  test "saving a game rebuilds everything and marks the current version applied" do
    assert_equal FormulaVersion.current, FormulaVersion.applied
    assert_not FormulaVersion.stale?
  end

  test "a version recorded by older code is stale, and refreshing rebuilds the numbers" do
    Setting.store(FormulaVersion::KEY, "old-code")
    @cam.update_columns(singles_rating: 1500)

    assert_predicate FormulaVersion, :stale?

    FormulaVersion.refresh_if_stale

    assert_not FormulaVersion.stale?
    assert_operator @cam.reload.singles_rating, :<, 1100
  end

  test "nothing is rebuilt when the version is already current" do
    @cam.update_columns(singles_rating: 1500)
    FormulaVersion.refresh_if_stale

    assert_equal 1500, @cam.reload.singles_rating
  end

  test "settings can be stored and read back without duplicating rows" do
    Setting.store("thing", "a")
    Setting.store("thing", "b")

    assert_equal "b", Setting.fetch("thing")
    assert_equal 1, Setting.where(key: "thing").count
    assert_nil Setting.fetch("missing")
  end
end
