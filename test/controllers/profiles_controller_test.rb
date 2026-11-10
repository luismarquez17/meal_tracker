require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Carlos Perez",
      email: "carlos.perez@example.com",
      password: "secretpassword",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
  end

  test "redirects to login when unauthenticated" do
    get profile_path
    assert_redirected_to login_path

    get edit_profile_path
    assert_redirected_to login_path

    get change_password_profile_path
    assert_redirected_to login_path
  end

  test "shows profile when logged in" do
    post login_path, params: { email: @user.email, password: "secretpassword" }
    assert_redirected_to root_path

    get profile_path
    assert_response :success
    assert_select "h2", text: /#{@user.name}/
    assert_select "p", text: /#{@user.email}/
  end

  test "edits profile successfully" do
    post login_path, params: { email: @user.email, password: "secretpassword" }

    get edit_profile_path
    assert_response :success

    patch profile_path, params: { user: { name: "Nuevo Nombre", avatar_url: "https://example.com/avatar.png" } }
    assert_redirected_to profile_path
    follow_redirect!
    assert_match "Datos actualizados correctamente", response.body

    @user.reload
    assert_equal "Nuevo Nombre", @user.name
    assert_equal "https://example.com/avatar.png", @user.avatar_url
  end

  test "changes password successfully" do
    post login_path, params: { email: @user.email, password: "secretpassword" }

    get change_password_profile_path
    assert_response :success

    patch update_password_profile_path, params: {
      user: {
        current_password: "secretpassword",
        new_password: "newsecret456",
        new_password_confirmation: "newsecret456"
      }
    }
    assert_redirected_to profile_path
    follow_redirect!
    assert_match "Contraseña cambiada con éxito", response.body

    # Check authentication with new password
    delete logout_path
    post login_path, params: { email: @user.email, password: "newsecret456" }
    assert_redirected_to root_path
  end

  test "fails to change password with wrong current password" do
    post login_path, params: { email: @user.email, password: "secretpassword" }

    patch update_password_profile_path, params: {
      user: {
        current_password: "wrongpassword",
        new_password: "newsecret456",
        new_password_confirmation: "newsecret456"
      }
    }
    assert_response :unprocessable_entity
    assert_match "Contraseña actual incorrecta", response.body
  end

  test "fails to change password when confirmation does not match" do
    post login_path, params: { email: @user.email, password: "secretpassword" }

    patch update_password_profile_path, params: {
      user: {
        current_password: "secretpassword",
        new_password: "newsecret456",
        new_password_confirmation: "different"
      }
    }
    assert_response :unprocessable_entity
    assert_match "La confirmación de la contraseña no coincide", response.body
  end

  test "dashboard displays active user profile indicator" do
    post login_path, params: { email: @user.email, password: "secretpassword" }
    get dashboard_path
    assert_response :success
    assert_select "span", text: /#{@user.name}/
    assert_select "p", text: /#{@user.email}/
  end
end
