defmodule PinpointWeb.RelationshipLiveTest do
  use PinpointWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pinpoint.RelationshipsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_relationship(_) do
    relationship = relationship_fixture()
    %{relationship: relationship}
  end

  describe "Index" do
    setup [:create_relationship]

    test "lists all relationships", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/relationships")

      assert html =~ "Listing Relationships"
    end

    test "saves new relationship", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/relationships")

      assert index_live |> element("a", "New Relationship") |> render_click() =~
               "New Relationship"

      assert_patch(index_live, ~p"/relationships/new")

      assert index_live
             |> form("#relationship-form", relationship: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#relationship-form", relationship: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/relationships")

      html = render(index_live)
      assert html =~ "Relationship created successfully"
    end

    test "updates relationship in listing", %{conn: conn, relationship: relationship} do
      {:ok, index_live, _html} = live(conn, ~p"/relationships")

      assert index_live |> element("#relationships-#{relationship.id} a", "Edit") |> render_click() =~
               "Edit Relationship"

      assert_patch(index_live, ~p"/relationships/#{relationship}/edit")

      assert index_live
             |> form("#relationship-form", relationship: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#relationship-form", relationship: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/relationships")

      html = render(index_live)
      assert html =~ "Relationship updated successfully"
    end

    test "deletes relationship in listing", %{conn: conn, relationship: relationship} do
      {:ok, index_live, _html} = live(conn, ~p"/relationships")

      assert index_live |> element("#relationships-#{relationship.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#relationships-#{relationship.id}")
    end
  end

  describe "Show" do
    setup [:create_relationship]

    test "displays relationship", %{conn: conn, relationship: relationship} do
      {:ok, _show_live, html} = live(conn, ~p"/relationships/#{relationship}")

      assert html =~ "Show Relationship"
    end

    test "updates relationship within modal", %{conn: conn, relationship: relationship} do
      {:ok, show_live, _html} = live(conn, ~p"/relationships/#{relationship}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Relationship"

      assert_patch(show_live, ~p"/relationships/#{relationship}/show/edit")

      assert show_live
             |> form("#relationship-form", relationship: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#relationship-form", relationship: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/relationships/#{relationship}")

      html = render(show_live)
      assert html =~ "Relationship updated successfully"
    end
  end
end
