#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

##########################
# Helpers
##########################

def remove_reference_to_realm_xcode_project(workspace_path)
  workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
  file_references = workspace.file_references.reject do |file_reference|
    file_reference.path == '../../../Realm.xcodeproj'
  end
  workspace = Xcodeproj::Workspace.new(nil)
  file_references.each { |ref| workspace << ref }
  workspace.save_as(workspace_path)
end

def set_framework_search_path(project_path, search_path)
  project = Xcodeproj::Project.open(project_path)
  project.build_configuration_list.set_setting("FRAMEWORK_SEARCH_PATHS", search_path)
  project.save
end

def replace_in_file(filepath, pattern, replacement)
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub(pattern, replacement)
  end
end

##########################
# Script
##########################

base_examples = [
  "examples/ios/objc",
  "examples/osx/objc",
  "examples/tvos/objc",
  "examples/ios/swift",
  "examples/tvos/swift",
]

swift_versions = %w(3.1 3.2 3.2.2 3.2.3 3.3 4.0 4.0.2 4.0.3 4.1 4.1.2)

# Remove reference to Realm.xcodeproj from all example workspaces.
base_examples.each do |example|
  remove_reference_to_realm_xcode_project("#{example}/RealmExamples.xcworkspace")
end

# Make a copy of each Swift example for each Swift version.
base_examples.each do |example|
  if example =~ /\/swift$/
    swift_versions.each do |swift_version|
      FileUtils.cp_r example, "#{example}-#{swift_version}"
    end
    FileUtils.rm_r example
  end
end

framework_directory_for_example = {
  'examples/ios/objc' => '../../../ios/static',
  'examples/osx/objc' => '../../../osx',
  'examples/tvos/objc' => '../../../tvos'
}
swift_versions.each do |swift_version|
  framework_directory_for_example["examples/ios/swift-#{swift_version}"] = "../../../ios/swift-#{swift_version}"
  framework_directory_for_example["examples/tvos/swift-#{swift_version}"] = "../../../tvos/swift-#{swift_version}"
end

# Update the paths to the prebuilt frameworks
framework_directory_for_example.each do |example, framework_directory|
  project_path = "#{example}/RealmExamples.xcodeproj"

  replace_in_file("#{project_path}/project.pbxproj", /path = (Realm|RealmSwift).framework; sourceTree = BUILT_PRODUCTS_DIR;/, "path = \"#{framework_directory}/\\1.framework\"; sourceTree = SOURCE_ROOT;")
  set_framework_search_path(project_path, framework_directory)
end

# Update Playground imports and instructions

swift_versions.each do |swift_version|
  playground_file = "examples/ios/swift-#{swift_version}/GettingStarted.playground/Contents.swift"
  replace_in_file(playground_file, 'choose RealmSwift', 'choose PlaygroundFrameworkWrapper')
  replace_in_file(playground_file,
                  "import Foundation\n",
                  "import Foundation\nimport PlaygroundFrameworkWrapper // only necessary to use a binary release of Realm Swift in this playground.\n")
end

# Update RubyMotion sample

replace_in_file('examples/ios/rubymotion/Simple/Rakefile', '/build/ios-', '/ios/')
