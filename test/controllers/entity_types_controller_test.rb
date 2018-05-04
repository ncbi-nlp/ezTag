require 'test_helper'

class EntityTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entity_type = entity_types(:one)
  end

  test "should get index" do
    get entity_types_url
    assert_response :success
  end

  test "should get new" do
    get new_entity_type_url
    assert_response :success
  end

  test "should create entity_type" do
    assert_difference('EntityType.count') do
      post entity_types_url, params: { entity_type: { collection_id: @entity_type.collection_id, color: @entity_type.color, name: @entity_type.name } }
    end

    assert_redirected_to entity_type_url(EntityType.last)
  end

  test "should show entity_type" do
    get entity_type_url(@entity_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_entity_type_url(@entity_type)
    assert_response :success
  end

  test "should update entity_type" do
    patch entity_type_url(@entity_type), params: { entity_type: { collection_id: @entity_type.collection_id, color: @entity_type.color, name: @entity_type.name } }
    assert_redirected_to entity_type_url(@entity_type)
  end

  test "should destroy entity_type" do
    assert_difference('EntityType.count', -1) do
      delete entity_type_url(@entity_type)
    end

    assert_redirected_to entity_types_url
  end
end
