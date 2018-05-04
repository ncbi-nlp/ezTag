require 'test_helper'

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
  end

  test "should get index" do
    get tasks_url
    assert_response :success
  end

  test "should get new" do
    get new_task_url
    assert_response :success
  end

  test "should create task" do
    assert_difference('Task.count') do
      post tasks_url, params: { task: { begin_at: @task.begin_at, collection_id: @task.collection_id, end_at: @task.end_at, model_url: @task.model_url, pre_trained_model: @task.pre_trained_model, status: @task.status, tagger: @task.tagger, task_type: @task.task_type, user_id: @task.user_id, xml_url: @task.xml_url } }
    end

    assert_redirected_to task_url(Task.last)
  end

  test "should show task" do
    get task_url(@task)
    assert_response :success
  end

  test "should get edit" do
    get edit_task_url(@task)
    assert_response :success
  end

  test "should update task" do
    patch task_url(@task), params: { task: { begin_at: @task.begin_at, collection_id: @task.collection_id, end_at: @task.end_at, model_url: @task.model_url, pre_trained_model: @task.pre_trained_model, status: @task.status, tagger: @task.tagger, task_type: @task.task_type, user_id: @task.user_id, xml_url: @task.xml_url } }
    assert_redirected_to task_url(@task)
  end

  test "should destroy task" do
    assert_difference('Task.count', -1) do
      delete task_url(@task)
    end

    assert_redirected_to tasks_url
  end
end
