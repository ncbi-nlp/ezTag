require 'test_helper'

class ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_key = api_keys(:one)
  end

  test "should get index" do
    get api_keys_url
    assert_response :success
  end

  test "should get new" do
    get new_api_key_url
    assert_response :success
  end

  test "should create api_key" do
    assert_difference('ApiKey.count') do
      post api_keys_url, params: { api_key: { access_count: @api_key.access_count, key: @api_key.key, last_access_at: @api_key.last_access_at, last_access_ip: @api_key.last_access_ip, user_id: @api_key.user_id } }
    end

    assert_redirected_to api_key_url(ApiKey.last)
  end

  test "should show api_key" do
    get api_key_url(@api_key)
    assert_response :success
  end

  test "should get edit" do
    get edit_api_key_url(@api_key)
    assert_response :success
  end

  test "should update api_key" do
    patch api_key_url(@api_key), params: { api_key: { access_count: @api_key.access_count, key: @api_key.key, last_access_at: @api_key.last_access_at, last_access_ip: @api_key.last_access_ip, user_id: @api_key.user_id } }
    assert_redirected_to api_key_url(@api_key)
  end

  test "should destroy api_key" do
    assert_difference('ApiKey.count', -1) do
      delete api_key_url(@api_key)
    end

    assert_redirected_to api_keys_url
  end
end
