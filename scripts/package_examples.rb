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

def replace_in_file(filepath, pattern, replacement)
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub(pattern, replacement)
  end
end

##########################
# Script
##########################

# Create Xcode 6 and Xcode 7 versions of the iOS examples
FileUtils.mkdir 'examples/ios/xcode-6'
FileUtils.move 'examples/ios/objc', 'examples/ios/xcode-6'
FileUtils.move 'examples/ios/rubymotion', 'examples/ios/xcode-6'
FileUtils.cp_r 'examples/ios/xcode-6', 'examples/ios/xcode-7'

# Update the paths to the prebuilt frameworks
replace_in_file('examples/ios/xcode-6/objc/RealmExamples.xcodeproj/project.pbxproj', '/build/ios-static', '/../ios/static/xcode-6')
replace_in_file('examples/ios/xcode-7/objc/RealmExamples.xcodeproj/project.pbxproj', '/build/ios-static', '/../ios/static/xcode-7')
replace_in_file('examples/osx/objc/RealmExamples.xcodeproj/project.pbxproj', '/build/osx', '/osx')
replace_in_file('examples/tvos/objc/RealmExamples.xcodeproj/project.pbxproj', '/build/tvos', '/tvos')

# Remove Realm target and dependencies from all example objc projects
objc_examples = [
  "examples/ios/xcode-6/objc/RealmExamples.xcodeproj",
  "examples/ios/xcode-7/objc/RealmExamples.xcodeproj",
  "examples/osx/objc/RealmExamples.xcodeproj"
]

objc_examples.each do |example|
  remove_all_dependencies(example)
  remove_target(example, "Realm")
end

# Remove RealmSwift target and dependencies from all example swift projects

swift_examples = [
  "examples/ios/swift-1.2/RealmExamples.xcodeproj",
  "examples/ios/swift-2.1.1/RealmExamples.xcodeproj",
  "examples/tvos/swift/RealmExamples.xcodeproj"
]

swift_examples.each do |example|
  remove_all_dependencies(example)
  remove_target(example, "RealmSwift")
  filepath = File.join(example, "project.pbxproj")
  replace_in_file(filepath, "/build/ios", "/ios")
  replace_in_file(filepath, "/build/tvos", "/tvos")
end

# Update RubyMotion sample

replace_in_file('examples/ios/xcode-6/rubymotion/Simple/Rakefile', '/build/ios', '/ios/static/xcode-6')
replace_in_file('examples/ios/xcode-7/rubymotion/Simple/Rakefile', '/build/ios', '/ios/static/xcode-7')
