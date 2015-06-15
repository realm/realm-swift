#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

##########################
# Helpers
##########################

def remove_target(project_path, target_name)
  project = Xcodeproj::Project.open(project_path)

  project.targets.each do |target|
    if target.name == target_name
      target.remove_from_project
    end
  end

  project.save

  FileUtils.rm("#{project_path}/xcshareddata/xcschemes/#{target_name}.xcscheme", :force => true)
end

def remove_all_dependencies(project_path)
  project = Xcodeproj::Project.open(project_path)

  project.targets.each do |target|
    target.dependencies.each do |dependency|
      dependency.remove_from_project
    end
  end

  project.save
end

##########################
# Script
##########################

# Remove Realm target and dependencies from all example objc projects

objc_examples = [
  "examples/ios/objc/RealmExamples.xcodeproj",
  "examples/osx/objc/RealmExamples.xcodeproj"
]

objc_examples.each do |example|
  remove_all_dependencies(example)
  remove_target(example, "Realm")

  filepath = File.join(example, "project.pbxproj")
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub("/build/ios", "/ios/static")
                      .gsub("/build/osx", "/osx")
  end
end

# Remove RealmSwift target and dependencies from all example swift projects

swift_examples = [
  "examples/ios/swift/RealmExamples.xcodeproj"
]

swift_examples.each do |example|
  remove_all_dependencies(example)
  remove_target(example, "RealmSwift")

  filepath = File.join(example, "project.pbxproj")
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub("/build/ios/swift", "/ios")
  end
end

# Update RubyMotion sample

rakefile_path = "examples/ios/rubymotion/Simple/Rakefile"
contents = File.read(rakefile_path)
File.open(rakefile_path, "w") do |file|
  file.puts contents.gsub("/build/ios", "/ios/static")
end
