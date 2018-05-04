require 'test_helper'

class LexiconGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lexicon_group = lexicon_groups(:one)
  end

  test "should get index" do
    get lexicon_groups_url
    assert_response :success
  end

  test "should get new" do
    get new_lexicon_group_url
    assert_response :success
  end

  test "should create lexicon_group" do
    assert_difference('LexiconGroup.count') do
      post lexicon_groups_url, params: { lexicon_group: { name: @lexicon_group.name, user_id: @lexicon_group.user_id } }
    end

    assert_redirected_to lexicon_group_url(LexiconGroup.last)
  end

  test "should show lexicon_group" do
    get lexicon_group_url(@lexicon_group)
    assert_response :success
  end

  test "should get edit" do
    get edit_lexicon_group_url(@lexicon_group)
    assert_response :success
  end

  test "should update lexicon_group" do
    patch lexicon_group_url(@lexicon_group), params: { lexicon_group: { name: @lexicon_group.name, user_id: @lexicon_group.user_id } }
    assert_redirected_to lexicon_group_url(@lexicon_group)
  end

  test "should destroy lexicon_group" do
    assert_difference('LexiconGroup.count', -1) do
      delete lexicon_group_url(@lexicon_group)
    end

    assert_redirected_to lexicon_groups_url
  end
end
