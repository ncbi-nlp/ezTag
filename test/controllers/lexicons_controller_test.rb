require 'test_helper'

class LexiconsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lexicon = lexicons(:one)
  end

  test "should get index" do
    get lexicons_url
    assert_response :success
  end

  test "should get new" do
    get new_lexicon_url
    assert_response :success
  end

  test "should create lexicon" do
    assert_difference('Lexicon.count') do
      post lexicons_url, params: { lexicon: { collection_id: @lexicon.collection_id, lexicon_id: @lexicon.lexicon_id, ltype: @lexicon.ltype, name: @lexicon.name } }
    end

    assert_redirected_to lexicon_url(Lexicon.last)
  end

  test "should show lexicon" do
    get lexicon_url(@lexicon)
    assert_response :success
  end

  test "should get edit" do
    get edit_lexicon_url(@lexicon)
    assert_response :success
  end

  test "should update lexicon" do
    patch lexicon_url(@lexicon), params: { lexicon: { collection_id: @lexicon.collection_id, lexicon_id: @lexicon.lexicon_id, ltype: @lexicon.ltype, name: @lexicon.name } }
    assert_redirected_to lexicon_url(@lexicon)
  end

  test "should destroy lexicon" do
    assert_difference('Lexicon.count', -1) do
      delete lexicon_url(@lexicon)
    end

    assert_redirected_to lexicons_url
  end
end
