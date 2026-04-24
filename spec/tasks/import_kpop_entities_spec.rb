# frozen_string_literal: true

RSpec.describe "discourse_kpop_dates:import_kpop_entities" do
  before do
    Rake::Task.clear
    Discourse::Application.load_tasks
  end

  def invoke_task(file_path)
    previous_file = ENV["FILE"]
    ENV["FILE"] = file_path

    begin
      Rake::Task["discourse_kpop_dates:import_kpop_entities"].reenable
      Rake::Task["discourse_kpop_dates:import_kpop_entities"].invoke
    ensure
      ENV["FILE"] = previous_file
    end
  end

  it "imports the file and prints a concise summary" do
    file = Tempfile.new(["kpop-entities", ".json"])
    file.write(
      {
        source: "kpopping-calendar",
        generated_at: "2026-04-20T00:00:00Z",
        entities: [
          {
            display_name: "IU",
            native_name: "아이유",
            slug: "iu",
            entity_kind: "solo",
            birthday: { month: 5, day: 16, year: 1993 },
            anniversary: { month: 9, day: 18, year: 2008 },
          },
        ],
      }.to_json,
    )
    file.flush

    expect { invoke_task(file.path) }.to output(
      /Imported K-pop entities from .*created=1 updated=0 skipped=0 errors=0/,
    ).to_stdout
    expect(DiscourseKpopDates::KpopEntity.find_by!(slug: "iu").display_name).to eq("IU")
  ensure
    file.close!
  end
end
