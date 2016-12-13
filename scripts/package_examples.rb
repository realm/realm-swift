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

examples = [
  "examples/ios/objc",
  "examples/osx/objc",
  "examples/tvos/objc",
  "examples/ios/swift-2.2",
  "examples/tvos/swift-2.2",
  "examples/ios/swift-3.0",
  "examples/tvos/swift-3.0",
  "examples/ios/swift-3.0.1",
  "examples/tvos/swift-3.0.1",
]

# Remove reference to Realm.xcodeproj from all example workspaces and realize symlinks.
examples.each do |example|
  if File.lstat(example).symlink?
    real_example = File.readlink(example)
    File.rm(example)
    File.cp_r(real_example, example)
  end
  remove_reference_to_realm_xcode_project("#{example}/RealmExamples.xcworkspace")
end

framework_directory_for_example = {
  'examples/ios/objc' => '../../../ios/static',
  'examples/osx/objc' => '../../../osx',
  'examples/tvos/objc' => '../../../tvos',
  'examples/ios/swift-2.2' => '../../../ios/swift-2.2',
  'examples/tvos/swift-2.2' => '../../../tvos/swift-2.2',
  'examples/ios/swift-3.0.1' => '../../../ios/swift-3.0.1',
  'examples/tvos/swift-3.0.1' => '../../../tvos/swift-3.0.1',
  'examples/ios/swift-3.0' => '../../../ios/swift-3.0',
  'examples/tvos/swift-3.0' => '../../../tvos/swift-3.0',
}

# Update the paths to the prebuilt frameworks
examples.each do |example|
  project_path = "#{example}/RealmExamples.xcodeproj"
  framework_directory = framework_directory_for_example[example]

  replace_in_file("#{project_path}/project.pbxproj", /path = (Realm|RealmSwift).framework; sourceTree = BUILT_PRODUCTS_DIR;/, "path = \"#{framework_directory}/\\1.framework\"; sourceTree = SOURCE_ROOT;")
  set_framework_search_path(project_path, framework_directory)
end

# Update Playground imports and instructions

playground_swift_versions = ['2.2', '3.0', '3.0.1']
playground_swift_versions.each do |swift_version|
  playground_file = "examples/ios/swift-#{swift_version}/GettingStarted.playground/Contents.swift"
  replace_in_file(playground_file, 'choose RealmSwift', 'choose PlaygroundFrameworkWrapper')
  replace_in_file(playground_file,
                  "import Foundation\n",
                  "import Foundation\nimport PlaygroundFrameworkWrapper // only necessary to use a binary release of Realm Swift in this playground.\n")
end

# Update RubyMotion sample

replace_in_file('examples/ios/rubymotion/Simple/Rakefile', '/build/ios-', '/ios/')
