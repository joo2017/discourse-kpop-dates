# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::AdminKpopEntitiesController do
  fab!(:admin)
  fab!(:user)

  let!(:entity) do
    Fabricate(
      :kpop_entity,
      display_name: "IU",
      native_name: "아이유",
      slug: "iu",
      entity_kind: "solo",
      active: true,
      birthday_month: 5,
      birthday_day: 16,
      anniversary_month: 9,
      anniversary_day: 18,
    )
  end

  before { SiteSetting.kpop_dates_enabled = true }

  describe "#index" do
    before do
      entity
      Fabricate(:kpop_entity, display_name: "BoA", native_name: "보아", slug: "boa", entity_kind: "solo", active: false)
      Fabricate(
        :kpop_entity,
        display_name: "BTS",
        native_name: "방탄소년단",
        slug: "bts",
        entity_kind: "group",
        active: true,
        birthday_month: nil,
        birthday_day: nil,
        birthday_year: nil,
      )
    end

    it "returns 404 for anonymous users" do
      get "/admin/plugins/discourse-kpop-dates/kpop-entities.json"

      expect(response.status).to eq(404)
    end

    it "returns 404 for non-admin users" do
      sign_in(user)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities.json"

      expect(response.status).to eq(404)
    end

    it "returns the serialized entity list for admins" do
      sign_in(admin)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities.json"

      expect(response.status).to eq(200)

      body = response.parsed_body
      expect(body.keys).to contain_exactly("kpop_entities", "total", "has_more")
      expect(body["total"]).to eq(3)
      expect(body["has_more"]).to eq(false)
      expect(body["kpop_entities"].map { |row| row["slug"] }).to eq(%w[boa bts iu])
    end

    it "filters by text search across display_name native_name and slug" do
      sign_in(admin)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities.json", params: { q: "boa" }

      expect(response.status).to eq(200)
      expect(response.parsed_body["kpop_entities"].map { |row| row["slug"] }).to eq(["boa"])
      expect(response.parsed_body["total"]).to eq(1)
    end

    it "filters by entity_kind" do
      sign_in(admin)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities.json", params: { entity_kind: "group" }

      expect(response.status).to eq(200)
      expect(response.parsed_body["kpop_entities"].map { |row| row["slug"] }).to eq(["bts"])
      expect(response.parsed_body["total"]).to eq(1)
    end

    it "filters by active flag" do
      sign_in(admin)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities.json", params: { active: "false" }

      expect(response.status).to eq(200)
      expect(response.parsed_body["kpop_entities"].map { |row| row["slug"] }).to eq(["boa"])
      expect(response.parsed_body["total"]).to eq(1)
    end

    it "paginates results with has_more" do
      sign_in(admin)

      stub_const(DiscourseKpopDates::AdminKpopEntitiesController, :PAGE_SIZE, 2) do
        get "/admin/plugins/discourse-kpop-dates/kpop-entities.json", params: { page: 0 }
        first_page = response.parsed_body

        expect(first_page["kpop_entities"].map { |row| row["slug"] }).to eq(%w[boa bts])
        expect(first_page["has_more"]).to eq(true)
        expect(first_page["total"]).to eq(3)

        get "/admin/plugins/discourse-kpop-dates/kpop-entities.json", params: { page: 1 }
        second_page = response.parsed_body

        expect(second_page["kpop_entities"].map { |row| row["slug"] }).to eq(["iu"])
        expect(second_page["has_more"]).to eq(false)
      end
    end
  end

  describe "#show" do
    it "returns the serialized entity for admins" do
      sign_in(admin)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id}.json"

      expect(response.status).to eq(200)

      body = response.parsed_body
      expect(body.keys).to contain_exactly("kpop_entity")
      expect(body["kpop_entity"]).to eq(serialized_entity(entity))
    end

    it "returns 404 when the entity does not exist" do
      sign_in(admin)

      get "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id + 1}.json"

      expect(response.status).to eq(404)
    end
  end

  describe "#create" do
    it "creates an entity for admins and casts active to boolean" do
      sign_in(admin)

      expect do
        post "/admin/plugins/discourse-kpop-dates/kpop-entities.json",
             params: {
               display_name: "BTS",
               native_name: "방탄소년단",
               slug: "bts",
               entity_kind: "group",
               active: "false",
               anniversary_month: 6,
               anniversary_day: 13,
               anniversary_year: 2013,
             }
      end.to change(DiscourseKpopDates::KpopEntity, :count).by(1)

      expect(response.status).to eq(200)

      created_entity = DiscourseKpopDates::KpopEntity.find_by!(slug: "bts")
      expect(created_entity.active).to eq(false)

      body = response.parsed_body
      expect(body.keys).to contain_exactly("kpop_entity")
      expect(body["kpop_entity"]).to eq(serialized_entity(created_entity))
    end

    it "returns JSON errors for invalid payloads without creating a record" do
      sign_in(admin)

      expect do
        post "/admin/plugins/discourse-kpop-dates/kpop-entities.json",
             params: {
               display_name: "Invalid",
               slug: "Not Valid",
               entity_kind: "solo",
               active: "true",
               birthday_month: 2,
               birthday_day: 30,
             }
      end.not_to change(DiscourseKpopDates::KpopEntity, :count)

      expect(response.status).to eq(422)
      expect(response.parsed_body.keys).to include("errors")
    end
  end

  describe "#import" do
    let(:valid_payload) do
      {
        payload: {
          source: "kpopping-calendar",
          entities: [
            {
              display_name: "BTS",
              native_name: "방탄소년단",
              slug: "bts",
              entity_kind: "group",
              anniversary: { month: 6, day: 13, year: 2013 },
            },
          ],
        },
      }
    end

    it "imports valid JSON payloads for admins" do
      sign_in(admin)

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json", params: valid_payload

      expect(response.status).to eq(200)
      expect(response.parsed_body["import_summary"]).to include(
        "created_count" => 1,
        "updated_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
      )
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "bts")).to eq(true)
    end

    it "also accepts payload_json like the admin UI sends" do
      sign_in(admin)

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json",
           params: {
             payload_json:
               {
                 source: "kpopping-calendar",
                 entities: [
                   {
                     display_name: "BTS JSON",
                     native_name: "방탄소년단",
                     slug: "bts-json",
                     entity_kind: "group",
                     anniversary: { month: 6, day: 13, year: 2013 },
                   },
                 ],
               }.to_json,
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body["import_summary"]).to include(
        "created_count" => 1,
        "updated_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
      )
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "bts-json")).to eq(true)
    end

    it "accepts an uploaded JSON file" do
      sign_in(admin)

      file = Tempfile.new(["kpop-entities-upload", ".json"])
      file.write(valid_payload[:payload].to_json)
      file.flush

      uploaded = Rack::Test::UploadedFile.new(file.path, "application/json")

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json", params: { file: uploaded }

      expect(response.status).to eq(200)
      expect(response.parsed_body["import_summary"]).to include(
        "created_count" => 1,
        "updated_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
      )
    ensure
      file.close!
    end

    it "accepts an uploaded top-level array snapshot file" do
      sign_in(admin)

      file = Tempfile.new(["kpop-entities-snapshot-upload", ".json"])
      file.write(
        [
          {
            display_name: "Snapshot BTS",
            native_name: "방탄소년단",
            slug: "snapshot-bts",
            entity_kind: "group",
            active: true,
            birthday: nil,
            anniversary: { month: 6, day: 13, year: 2013 },
          },
        ].to_json,
      )
      file.flush

      uploaded = Rack::Test::UploadedFile.new(file.path, "application/json")

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json", params: { file: uploaded }

      expect(response.status).to eq(200)
      expect(response.parsed_body["import_summary"]).to include(
        "created_count" => 1,
        "updated_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
      )
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "snapshot-bts")).to eq(true)
    ensure
      file.close!
    end

    it "returns 404 for anonymous users" do
      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json", params: valid_payload

      expect(response.status).to eq(404)
    end

    it "returns 404 for non-admin users" do
      sign_in(user)

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json", params: valid_payload

      expect(response.status).to eq(404)
    end

    it "returns 400 when payload is missing" do
      sign_in(admin)

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json", params: {}

      expect(response.status).to eq(400)
      expect(response.parsed_body.keys).to include("errors")
    end

    it "returns 200 with row errors when part of the payload is invalid" do
      sign_in(admin)

      post "/admin/plugins/discourse-kpop-dates/kpop-entities/import.json",
           params: {
             payload: {
               entities: [
                 {
                   display_name: "Invalid Group",
                   slug: "invalid-group",
                   entity_kind: "group",
                   birthday: { month: 1, day: 1, year: nil },
                   anniversary: { month: 6, day: 13, year: 2013 },
                 },
                 {
                   display_name: "IU",
                   slug: "iu-import",
                   entity_kind: "solo",
                   birthday: { month: 5, day: 16, year: 1993 },
                   anniversary: nil,
                 },
               ],
             },
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body["import_summary"]).to include(
        "created_count" => 1,
        "error_count" => 1,
      )
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "iu-import")).to eq(true)
    end
  end

  describe "#update" do
    it "updates an entity for admins and casts active to boolean" do
      sign_in(admin)

      put "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id}.json",
          params: {
            id: entity.id + 10,
            display_name: "IU Updated",
            native_name: "아이유",
            slug: "iu-updated",
            entity_kind: "solo",
            active: "0",
            birthday_month: 5,
            birthday_day: 16,
            anniversary_month: 9,
            anniversary_day: 18,
          }

      expect(response.status).to eq(200)

      entity.reload
      expect(entity.display_name).to eq("IU Updated")
      expect(entity.slug).to eq("iu-updated")
      expect(entity.active).to eq(false)

      body = response.parsed_body
      expect(body.keys).to contain_exactly("kpop_entity")
      expect(body["kpop_entity"]).to eq(serialized_entity(entity))
    end

    it "returns 404 for non-admin users" do
      sign_in(user)

      put "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id}.json",
          params: {
            display_name: "Nope",
            slug: "nope",
            entity_kind: "solo",
          }

      expect(response.status).to eq(404)
      expect(entity.reload.display_name).to eq("IU")
    end

    it "returns JSON errors for invalid updates without partial writes" do
      sign_in(admin)

      put "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id}.json",
          params: {
            display_name: entity.display_name,
            native_name: entity.native_name,
            slug: "bad slug",
            entity_kind: "solo",
            active: "true",
            birthday_month: 2,
            birthday_day: 30,
            anniversary_month: entity.anniversary_month,
            anniversary_day: entity.anniversary_day,
          }

      expect(response.status).to eq(422)
      expect(response.parsed_body.keys).to include("errors")

      entity.reload
      expect(entity.slug).to eq("iu")
      expect(entity.birthday_month).to eq(5)
      expect(entity.birthday_day).to eq(16)
    end
  end

  describe "#destroy" do
    it "destroys an entity for admins" do
      sign_in(admin)

      expect do
        delete "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id}.json"
      end.to change(DiscourseKpopDates::KpopEntity, :count).by(-1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq("success" => "OK")
    end

    it "returns 404 when the entity does not exist" do
      sign_in(admin)

      delete "/admin/plugins/discourse-kpop-dates/kpop-entities/#{entity.id + 100}.json"

      expect(response.status).to eq(404)
    end
  end

  def serialized_entity(kpop_entity)
    {
      "id" => kpop_entity.id,
      "display_name" => kpop_entity.display_name,
      "native_name" => kpop_entity.native_name,
      "slug" => kpop_entity.slug,
      "entity_kind" => kpop_entity.entity_kind,
      "active" => kpop_entity.active,
      "birthday_month" => kpop_entity.birthday_month,
      "birthday_day" => kpop_entity.birthday_day,
      "birthday_year" => kpop_entity.birthday_year,
      "anniversary_month" => kpop_entity.anniversary_month,
      "anniversary_day" => kpop_entity.anniversary_day,
      "anniversary_year" => kpop_entity.anniversary_year,
    }
  end
end
