require "test_helper"
require "minitest/mock"
require "minitest/autorun"

class StandardRequirementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @organization = Organization.create!(name: "Test Org")
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      organization: @organization
    )
    # Rolify assumption
    @user.add_role(:admin) if @user.respond_to?(:add_role)
    
    sign_in @user
  end

  test "should get index" do
    get standard_requirements_path
    assert_response :success
  end

  test "should search with query" do
    # STUB embedding generation to avoid API call
    Ai::EmbeddingService.stub :generate, [0.1]*768 do
      get search_standard_requirements_path, params: { q: "test query" }
      assert_response :success
    end
  end
end
