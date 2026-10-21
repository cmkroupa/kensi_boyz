require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "delta text shows a sign" do
    assert_equal "+5", delta_text(5.2)
    assert_equal "−5", delta_text(-5.2)
  end
end
