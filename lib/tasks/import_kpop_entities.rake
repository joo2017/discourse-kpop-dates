# frozen_string_literal: true

namespace :discourse_cakeday do
  if Rake::Task.task_defined?("discourse_cakeday:import_kpop_entities")
    Rake::Task["discourse_cakeday:import_kpop_entities"].clear
  end

  desc "Import offline-saved kpopping calendar entities from FILE=/absolute/path/to/file.json"
  task import_kpop_entities: :environment do
    file_path = ENV["FILE"]

    if file_path.blank?
      raise DiscourseCakeday::KpopEntitiesImporter::InvalidFileError,
              "FILE=/absolute/path/to/file.json is required"
    end

    summary = DiscourseCakeday::KpopEntitiesImporter.import_file(file_path)

    puts(
      "Imported K-pop entities from #{file_path}: " \
        "created=#{summary[:created_count]} updated=#{summary[:updated_count]} " \
        "skipped=#{summary[:skipped_count]} errors=#{summary[:error_count]}",
    )

    if summary[:error_count].zero?
      next
    end

    summary[:errors].each do |error|
      puts(
        "row #{error[:row]} slug=#{error[:slug] || '(missing)'}: #{error[:messages].join(', ')}",
      )
    end

    exit 1
  rescue DiscourseCakeday::KpopEntitiesImporter::ImportError => e
    puts e.message
    exit 1
  end
end
